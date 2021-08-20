// Generated using Sourcery 1.5.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT




// sourcery:inline:TwitterUser.AutoGenerateProperty

// Generated using Sourcery
// DO NOT EDIT
public struct Property {
	public let  id: ID
	public let  name: String
	public let  username: String
	public let  bioDescription: String?
	public let  createdAt: Date?
	public let  location: String?
	public let  pinnedTweetID: Tweet.ID?
	public let  profileBannerURL: String?
	public let  profileImageURL: String?
	public let  protected: Bool
	public let  url: String?
	public let  verified: Bool
	public let  updatedAt: Date

	public init(
		id: ID,
		name: String,
		username: String,
		bioDescription: String?,
		createdAt: Date?,
		location: String?,
		pinnedTweetID: Tweet.ID?,
		profileBannerURL: String?,
		profileImageURL: String?,
		protected: Bool,
		url: String?,
		verified: Bool,
		updatedAt: Date
	) {
		self.id = id
		self.name = name
		self.username = username
		self.bioDescription = bioDescription
		self.createdAt = createdAt
		self.location = location
		self.pinnedTweetID = pinnedTweetID
		self.profileBannerURL = profileBannerURL
		self.profileImageURL = profileImageURL
		self.protected = protected
		self.url = url
		self.verified = verified
		self.updatedAt = updatedAt
	}
}

public func configure(property: Property) {
	self.id = property.id
	self.name = property.name
	self.username = property.username
	self.bioDescription = property.bioDescription
	self.createdAt = property.createdAt
	self.location = property.location
	self.pinnedTweetID = property.pinnedTweetID
	self.profileBannerURL = property.profileBannerURL
	self.profileImageURL = property.profileImageURL
	self.protected = property.protected
	self.url = property.url
	self.verified = property.verified
	self.updatedAt = property.updatedAt
}

public func update(property: Property) {
	update(name: property.name)
	update(username: property.username)
	update(bioDescription: property.bioDescription)
	update(createdAt: property.createdAt)
	update(location: property.location)
	update(pinnedTweetID: property.pinnedTweetID)
	update(profileBannerURL: property.profileBannerURL)
	update(profileImageURL: property.profileImageURL)
	update(protected: property.protected)
	update(url: property.url)
	update(verified: property.verified)
	update(updatedAt: property.updatedAt)
}
// sourcery:end
