import Foundation

/// Real AI repository implementation that wires `AIEngineResolver` and prompt templates
/// to the `AIRepositoryProtocol`.
///
/// Replaces `StubAIRepository` when AI engines are available.
/// All inference runs on-device. No user data leaves the device (P-02).
///
/// Spec ref: Foundation spec Section 6, FR-AI-01 through FR-AI-04
@MainActor
public final class AIRepositoryImpl: AIRepositoryProtocol {

    private let engineResolver: AIEngineResolver

    public init(engineResolver: AIEngineResolver) {
        self.engineResolver = engineResolver
    }

    // MARK: - AIRepositoryProtocol

    public func categorize(email: Email) async throws -> AICategory {
        let engine = await engineResolver.resolveGenerativeEngine()
        let available = await engine.isAvailable()

        guard available else {
            return .uncategorized
        }

        // Try classify() first — sanitize input to prevent prompt injection (P1-2)
        let categories = AICategory.allCases
            .filter { $0 != .uncategorized }
            .map(\.rawValue)

        let sanitizedText = PromptTemplates.buildSanitizedClassificationText(
            subject: email.subject,
            sender: email.fromName ?? email.fromAddress,
            body: email.bodyPlain ?? email.snippet ?? ""
        )

        do {
            let result = try await engine.classify(
                text: sanitizedText,
                categories: categories
            )
            return AICategory(rawValue: result) ?? .uncategorized
        } catch {
            // Fallback to generate() with prompt template
        }

        let prompt = PromptTemplates.categorization(
            subject: email.subject,
            sender: email.fromName ?? email.fromAddress,
            body: email.bodyPlain ?? email.snippet ?? ""
        )

        let stream = await engine.generate(prompt: prompt, maxTokens: 20)
        var response = ""
        for await token in stream {
            response += token
            if response.count > 50 { break }
        }

        return PromptTemplates.parseCategorizationResponse(response)
    }

    public func summarize(thread: Thread) async throws -> String {
        // Return cached summary if available
        if let cached = thread.aiSummary, !cached.isEmpty {
            return cached
        }

        let engine = await engineResolver.resolveGenerativeEngine()
        let available = await engine.isAvailable()

        guard available else {
            throw AIEngineError.engineUnavailable
        }

        // Build message tuples from thread emails
        let sortedEmails = thread.emails.sorted {
            ($0.dateReceived ?? .distantPast) < ($1.dateReceived ?? .distantPast)
        }

        let messages: [(sender: String, date: String, body: String)] = sortedEmails.map { email in
            let dateStr: String
            if let date = email.dateReceived {
                dateStr = date.formatted(date: .abbreviated, time: .shortened)
            } else {
                dateStr = "Unknown date"
            }
            return (
                sender: email.fromName ?? email.fromAddress,
                date: dateStr,
                body: email.bodyPlain ?? email.snippet ?? ""
            )
        }

        let prompt = PromptTemplates.summarize(
            subject: thread.subject,
            messages: messages
        )

        let stream = await engine.generate(prompt: prompt, maxTokens: 200)
        var response = ""
        for await token in stream {
            response += token
        }

        let parsed = PromptTemplates.parseSummarizationResponse(response)

        // Cache the summary on the thread for subsequent loads
        if let parsed, !parsed.isEmpty {
            thread.aiSummary = parsed
            return parsed
        }

        return ""
    }

    /// Hard time limit for smart reply generation (spec FR-AI-03).
    /// If generation exceeds this, we parse whatever we have so far.
    private static let smartReplyTimeout: TimeInterval = 8.0

    public func smartReply(email: Email) async throws -> [String] {
        let engine = await engineResolver.resolveGenerativeEngine()
        let available = await engine.isAvailable()

        guard available else {
            return []
        }

        let prompt = PromptTemplates.smartReply(
            senderName: email.fromName ?? email.fromAddress,
            senderEmail: email.fromAddress,
            subject: email.subject,
            body: email.bodyPlain ?? email.snippet ?? ""
        )

        // Enforce 8-second hard limit per spec FR-AI-03.
        // LlamaEngine.generate() computes all tokens synchronously within the
        // actor before returning the stream, so a per-token deadline check
        // cannot actually cut generation short. Instead, we race the entire
        // generation against a sleep timer using a TaskGroup — whichever
        // finishes first wins, and the other is cancelled.
        let timeout = Self.smartReplyTimeout
        let response: String = await withTaskGroup(of: String?.self) { group in
            // Child 1: Generation
            group.addTask {
                let stream = await engine.generate(prompt: prompt, maxTokens: 300)
                var result = ""
                for await token in stream {
                    guard !Task.isCancelled else { break }
                    result += token
                }
                return result
            }

            // Child 2: Timeout
            group.addTask {
                try? await Task.sleep(for: .seconds(timeout))
                return nil  // signals timeout
            }

            // First child to finish determines the result.
            // If the timeout fires first (returns nil), cancel the group
            // which cancels the generation task.
            var result = ""
            if let first = await group.next() {
                if let generated = first {
                    result = generated
                }
                // else: timeout fired first — result stays empty
            }
            group.cancelAll()
            return result
        }

        let replies = PromptTemplates.parseSmartReplyResponse(response)
        return replies.isEmpty ? [] : replies
    }

    public func generateEmbedding(text: String) async throws -> Data {
        // First, try the engine's native embed() (CoreML MiniLM when available).
        let engine = await engineResolver.resolveGenerativeEngine()
        if await engine.isAvailable() {
            do {
                let floats = try await engine.embed(text: text)
                if !floats.isEmpty {
                    return floats.withUnsafeBufferPointer { buffer in
                        Data(buffer: buffer)
                    }
                }
            } catch {
                // embed() unsupported by this engine — fall through to hash embedding
            }
        }

        // Fallback: deterministic hash-based embedding (128-dimensional).
        // Produces a lightweight vector from word hashes, providing basic
        // similarity signals for SearchIndex until CoreML MiniLM is integrated.
        // This ensures SearchIndex entries always get non-nil embeddings.
        let embedding = Self.hashEmbedding(text: text)
        return embedding.withUnsafeBufferPointer { buffer in
            Data(buffer: buffer)
        }
    }

    // MARK: - Hash Embedding Fallback

    /// Dimension of the fallback hash embedding vector.
    private static let embeddingDimension = 128

    /// Generate a deterministic hash-based embedding from text.
    ///
    /// Tokenizes the text into lowercased words, hashes each word, and
    /// accumulates into a fixed-dimension vector. The result is L2-normalized.
    /// This provides basic bag-of-words similarity until CoreML MiniLM
    /// is available for proper semantic embeddings.
    ///
    /// Spec ref: FR-AI-05 (fallback path)
    static func hashEmbedding(text: String) -> [Float] {
        let dim = embeddingDimension
        var vector = [Float](repeating: 0.0, count: dim)

        // Tokenize: split on non-alphanumeric, lowercase, filter short words
        let words = text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count >= 2 }

        guard !words.isEmpty else {
            return vector
        }

        for word in words {
            // Use two independent hashes per word for better distribution
            var hasher1 = Hasher()
            hasher1.combine(word)
            hasher1.combine(0)
            let h1 = abs(hasher1.finalize()) % dim

            var hasher2 = Hasher()
            hasher2.combine(word)
            hasher2.combine(1)
            let h2 = hasher2.finalize()

            // +1 or -1 based on second hash (random sign trick)
            let sign: Float = h2 % 2 == 0 ? 1.0 : -1.0
            vector[h1] += sign
        }

        // L2-normalize
        let norm = sqrt(vector.reduce(0) { $0 + $1 * $1 })
        if norm > 0 {
            for i in 0..<dim {
                vector[i] /= norm
            }
        }

        return vector
    }
}
