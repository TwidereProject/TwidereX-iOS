// Generated using Sourcery 1.5.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT


// sourcery:inline:MastodonNotification.AutoUpdatableObject

// Generated using Sourcery
// DO NOT EDIT
public func update(notificationType: MastodonNotificationType) {
	if self.notificationType != notificationType {
		self.notificationType = notificationType
	}
}
public func update(createdAt: Date) {
	if self.createdAt != createdAt {
		self.createdAt = createdAt
	}
}
public func update(updatedAt: Date) {
	if self.updatedAt != updatedAt {
		self.updatedAt = updatedAt
	}
}
// sourcery:end




