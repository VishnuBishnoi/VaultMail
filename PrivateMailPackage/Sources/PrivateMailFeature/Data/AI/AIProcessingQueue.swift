import Foundation

/// Background batch processing queue for AI classification after sync.
///
/// Runs categorization and spam detection on newly synced emails.
/// Respects concurrency constraints:
/// - LLM tasks (generative): serial — prevents concurrent model loads
/// - CoreML tasks (classification): may run concurrently — lightweight, ANE-backed
///
/// Batch size: 50 emails with yields between batches for responsive UI.
///
/// Spec ref: FR-AI-07, AC-A-04b, AC-A-09
@MainActor
@Observable
public final class AIProcessingQueue: Sendable {

    // MARK: - State

    /// Whether the queue is currently processing.
    public private(set) var isProcessing = false

    /// Number of emails processed in the current batch.
    public private(set) var processedCount = 0

    /// Total number of emails queued for processing.
    public private(set) var totalCount = 0

    /// Number of emails categorized in the last run.
    public private(set) var lastCategorizedCount = 0

    /// Number of emails flagged as spam in the last run.
    public private(set) var lastSpamCount = 0

    // MARK: - Dependencies

    private let categorize: CategorizeEmailUseCaseProtocol
    private let detectSpam: DetectSpamUseCaseProtocol

    /// Batch size for processing. 50 emails per batch with yields between.
    private let batchSize = 50

    /// Active processing task (for cancellation).
    private var processingTask: Task<Void, Never>?

    // MARK: - Init

    public init(
        categorize: CategorizeEmailUseCaseProtocol,
        detectSpam: DetectSpamUseCaseProtocol
    ) {
        self.categorize = categorize
        self.detectSpam = detectSpam
    }

    // MARK: - Public API

    /// Enqueue emails for background AI processing.
    ///
    /// Called after `SyncEmailsUseCase` completes a sync batch.
    /// Processes categorization and spam detection in batches of 50.
    ///
    /// - Parameter emails: Newly synced emails to process.
    public func enqueue(emails: [Email]) {
        // Filter to only uncategorized emails (don't re-process)
        let uncategorized = emails.filter { email in
            email.aiCategory == AICategory.uncategorized.rawValue || email.aiCategory == nil
        }

        guard !uncategorized.isEmpty else { return }

        totalCount = uncategorized.count
        processedCount = 0
        lastCategorizedCount = 0
        lastSpamCount = 0
        isProcessing = true

        // Cancel any existing processing
        processingTask?.cancel()

        processingTask = Task { [weak self] in
            guard let self else { return }
            await self.processBatches(uncategorized)
        }
    }

    /// Cancel any active processing.
    public func cancel() {
        processingTask?.cancel()
        processingTask = nil
        isProcessing = false
    }

    // MARK: - Processing

    private func processBatches(_ emails: [Email]) async {
        var categorizedTotal = 0
        var spamTotal = 0

        // Process in batches
        let batches = stride(from: 0, to: emails.count, by: batchSize).map { startIndex in
            let endIndex = min(startIndex + batchSize, emails.count)
            return Array(emails[startIndex..<endIndex])
        }

        for batch in batches {
            guard !Task.isCancelled else { break }

            // Categorize batch
            let categorized = await categorize.categorizeBatch(emails: batch)
            categorizedTotal += categorized

            // Spam detection batch
            let spamDetected = await detectSpam.detectBatch(emails: batch)
            spamTotal += spamDetected

            processedCount += batch.count
            lastCategorizedCount = categorizedTotal
            lastSpamCount = spamTotal

            // Yield between batches for UI responsiveness
            await Task.yield()
        }

        isProcessing = false
    }
}
