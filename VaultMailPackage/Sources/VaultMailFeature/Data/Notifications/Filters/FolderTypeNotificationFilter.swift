import Foundation

/// Filter that only allows notifications for emails in inbox folders.
/// Spec ref: NOTIF-07
@MainActor
public final class FolderTypeNotificationFilter: NotificationFilter {
    public init() {}

    public func shouldNotify(for email: Email) async -> Bool {
        email.emailFolders.contains { emailFolder in
            emailFolder.folder?.folderType == FolderType.inbox.rawValue
        }
    }
}
