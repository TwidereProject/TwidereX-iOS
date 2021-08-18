// Generated using Sourcery 1.5.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// sourcery:inline:MastodonUser.AutoUpdatableObject

// Generated using Sourcery
// DO NOT EDIT
public func update(acct: String) {
	if self.acct != acct {
		self.acct = acct
	}
}
public func update(username: String) {
	if self.username != username {
		self.username = username
	}
}
public func update(displayName: String) {
	if self.displayName != displayName {
		self.displayName = displayName
	}
}
public func update(note: String?) {
	if self.note != note {
		self.note = note
	}
}
public func update(url: String?) {
	if self.url != url {
		self.url = url
	}
}
public func update(avatar: String?) {
	if self.avatar != avatar {
		self.avatar = avatar
	}
}
public func update(avatarStatic: String?) {
	if self.avatarStatic != avatarStatic {
		self.avatarStatic = avatarStatic
	}
}
public func update(header: String?) {
	if self.header != header {
		self.header = header
	}
}
public func update(headerStatic: String?) {
	if self.headerStatic != headerStatic {
		self.headerStatic = headerStatic
	}
}
public func update(emojisData: Data?) {
	if self.emojisData != emojisData {
		self.emojisData = emojisData
	}
}
public func update(fieldsData: Data?) {
	if self.fieldsData != fieldsData {
		self.fieldsData = fieldsData
	}
}
public func update(statusesCount: NSNumber) {
	if self.statusesCount != statusesCount {
		self.statusesCount = statusesCount
	}
}
public func update(followingCount: NSNumber) {
	if self.followingCount != followingCount {
		self.followingCount = followingCount
	}
}
public func update(followersCount: NSNumber) {
	if self.followersCount != followersCount {
		self.followersCount = followersCount
	}
}
public func update(locked: Bool) {
	if self.locked != locked {
		self.locked = locked
	}
}
public func update(bot: Bool) {
	if self.bot != bot {
		self.bot = bot
	}
}
public func update(suspended: Bool) {
	if self.suspended != suspended {
		self.suspended = suspended
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
