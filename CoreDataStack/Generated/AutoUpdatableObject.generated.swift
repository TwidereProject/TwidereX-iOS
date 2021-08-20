// Generated using Sourcery 1.5.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT




// sourcery:inline:TwitterUser.AutoUpdatableObject

// Generated using Sourcery
// DO NOT EDIT
public func update(name: String) {
	if self.name != name {
		self.name = name
	}
}
public func update(username: String) {
	if self.username != username {
		self.username = username
	}
}
public func update(bioDescription: String?) {
	if self.bioDescription != bioDescription {
		self.bioDescription = bioDescription
	}
}
public func update(createdAt: Date?) {
	if self.createdAt != createdAt {
		self.createdAt = createdAt
	}
}
public func update(location: String?) {
	if self.location != location {
		self.location = location
	}
}
public func update(pinnedTweetID: Tweet.ID?) {
	if self.pinnedTweetID != pinnedTweetID {
		self.pinnedTweetID = pinnedTweetID
	}
}
public func update(profileBannerURL: String?) {
	if self.profileBannerURL != profileBannerURL {
		self.profileBannerURL = profileBannerURL
	}
}
public func update(profileImageURL: String?) {
	if self.profileImageURL != profileImageURL {
		self.profileImageURL = profileImageURL
	}
}
public func update(protected: Bool) {
	if self.protected != protected {
		self.protected = protected
	}
}
public func update(url: String?) {
	if self.url != url {
		self.url = url
	}
}
public func update(verified: Bool) {
	if self.verified != verified {
		self.verified = verified
	}
}
public func update(updatedAt: Date) {
	if self.updatedAt != updatedAt {
		self.updatedAt = updatedAt
	}
}
// sourcery:end
