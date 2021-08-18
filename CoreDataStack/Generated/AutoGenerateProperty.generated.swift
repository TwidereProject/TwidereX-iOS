// Generated using Sourcery 1.5.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// sourcery:inline:MastodonAuthentication.AutoGenerateProperty

// Generated using Sourcery
// DO NOT EDIT
public struct Property {
	public let  identifier: ID
	public let  domain: String
	public let  userID: String
	public let  username: String
	public let  appAccessToken: String
	public let  userAccessToken: String
	public let  clientID: String
	public let  clientSecret: String
	public let  createdAt: Date
	public let  updatedAt: Date
	public let  authenticationIndex: AuthenticationIndex
	public let  mastodonUser: MastodonUser

	public init(
		identifier: ID,
		domain: String,
		userID: String,
		username: String,
		appAccessToken: String,
		userAccessToken: String,
		clientID: String,
		clientSecret: String,
		createdAt: Date,
		updatedAt: Date,
		authenticationIndex: AuthenticationIndex,
		mastodonUser: MastodonUser
	) {
		self.identifier = identifier
		self.domain = domain
		self.userID = userID
		self.username = username
		self.appAccessToken = appAccessToken
		self.userAccessToken = userAccessToken
		self.clientID = clientID
		self.clientSecret = clientSecret
		self.createdAt = createdAt
		self.updatedAt = updatedAt
		self.authenticationIndex = authenticationIndex
		self.mastodonUser = mastodonUser
	}
}

func configure(property: Property) {
	self.identifier = identifier
	self.domain = domain
	self.userID = userID
	self.username = username
	self.appAccessToken = appAccessToken
	self.userAccessToken = userAccessToken
	self.clientID = clientID
	self.clientSecret = clientSecret
	self.createdAt = createdAt
	self.updatedAt = updatedAt
	self.authenticationIndex = authenticationIndex
	self.mastodonUser = mastodonUser
}

public func update(property: Property) {
	update(identifier: property.identifier)
	update(domain: property.domain)
	update(userID: property.userID)
	update(username: property.username)
	update(appAccessToken: property.appAccessToken)
	update(userAccessToken: property.userAccessToken)
	update(clientID: property.clientID)
	update(clientSecret: property.clientSecret)
	update(createdAt: property.createdAt)
	update(updatedAt: property.updatedAt)
	update(authenticationIndex: property.authenticationIndex)
	update(mastodonUser: property.mastodonUser)
}
// sourcery:end

