// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {

  internal enum Common {
    internal enum Alerts {
      internal enum AccountTemporarilyLocked {
        /// Open Twitter to unlock
        internal static let message = L10n.tr("Localizable", "Common.Alerts.AccountTemporarilyLocked.Message")
        /// Account Temporarily Locked
        internal static let title = L10n.tr("Localizable", "Common.Alerts.AccountTemporarilyLocked.Title")
      }
      internal enum CancelFollowRequest {
        /// Cancel follow request for %@?
        internal static func message(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.CancelFollowRequest.Message", String(describing: p1))
        }
      }
      internal enum PhotoSaveFail {
        /// Please try again
        internal static let message = L10n.tr("Localizable", "Common.Alerts.PhotoSaveFail.Message")
        /// Failed to Save Photo
        internal static let title = L10n.tr("Localizable", "Common.Alerts.PhotoSaveFail.Title")
      }
      internal enum PhotoSaved {
        /// Photo Saved
        internal static let title = L10n.tr("Localizable", "Common.Alerts.PhotoSaved.Title")
      }
      internal enum RateLimitExceeded {
        /// Reached Twitter API usage limit
        internal static let message = L10n.tr("Localizable", "Common.Alerts.RateLimitExceeded.Message")
        /// Rate Limit Exceeded
        internal static let title = L10n.tr("Localizable", "Common.Alerts.RateLimitExceeded.Title")
      }
      internal enum TweetFail {
        /// Please try again
        internal static let message = L10n.tr("Localizable", "Common.Alerts.TweetFail.Message")
        /// Failed to Tweet
        internal static let title = L10n.tr("Localizable", "Common.Alerts.TweetFail.Title")
      }
      internal enum TweetSent {
        /// Tweet Sent
        internal static let title = L10n.tr("Localizable", "Common.Alerts.TweetSent.Title")
      }
      internal enum UnfollowUser {
        /// Unfollow user %@?
        internal static func message(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.UnfollowUser.Message", String(describing: p1))
        }
      }
    }
    internal enum Controls {
      internal enum Actions {
        /// Add
        internal static let add = L10n.tr("Localizable", "Common.Controls.Actions.Add")
        /// Cancel
        internal static let cancel = L10n.tr("Localizable", "Common.Controls.Actions.Cancel")
        /// Confirm
        internal static let confirm = L10n.tr("Localizable", "Common.Controls.Actions.Confirm")
        /// Edit
        internal static let edit = L10n.tr("Localizable", "Common.Controls.Actions.Edit")
        /// OK
        internal static let ok = L10n.tr("Localizable", "Common.Controls.Actions.Ok")
        /// Open in Safari
        internal static let openInSafari = L10n.tr("Localizable", "Common.Controls.Actions.OpenInSafari")
        /// Preview
        internal static let preview = L10n.tr("Localizable", "Common.Controls.Actions.Preview")
        /// Remove
        internal static let remove = L10n.tr("Localizable", "Common.Controls.Actions.Remove")
        /// Save
        internal static let save = L10n.tr("Localizable", "Common.Controls.Actions.Save")
        /// Save photo
        internal static let savePhoto = L10n.tr("Localizable", "Common.Controls.Actions.SavePhoto")
        /// Take photo
        internal static let takePhoto = L10n.tr("Localizable", "Common.Controls.Actions.TakePhoto")
      }
      internal enum Friendship {
        /// follower
        internal static let follower = L10n.tr("Localizable", "Common.Controls.Friendship.Follower")
        /// followers
        internal static let followers = L10n.tr("Localizable", "Common.Controls.Friendship.Followers")
        /// Follows you
        internal static let followsYou = L10n.tr("Localizable", "Common.Controls.Friendship.FollowsYou")
        /// %@ is following you
        internal static func userIsFollowingYou(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Friendship.UserIsFollowingYou", String(describing: p1))
        }
        /// %@ is not following you
        internal static func userIsNotFollowingYou(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Friendship.UserIsNotFollowingYou", String(describing: p1))
        }
        internal enum Actions {
          /// Follow
          internal static let follow = L10n.tr("Localizable", "Common.Controls.Friendship.Actions.Follow")
          /// Following
          internal static let following = L10n.tr("Localizable", "Common.Controls.Friendship.Actions.Following")
          /// Pending
          internal static let pending = L10n.tr("Localizable", "Common.Controls.Friendship.Actions.Pending")
          /// Unfollow
          internal static let unfollow = L10n.tr("Localizable", "Common.Controls.Friendship.Actions.Unfollow")
        }
      }
      internal enum Ios {
        /// Photo Library
        internal static let photoLibrary = L10n.tr("Localizable", "Common.Controls.Ios.PhotoLibrary")
      }
      internal enum ProfileDashboard {
        /// Followers
        internal static let followers = L10n.tr("Localizable", "Common.Controls.ProfileDashboard.Followers")
        /// Following
        internal static let following = L10n.tr("Localizable", "Common.Controls.ProfileDashboard.Following")
        /// Listed
        internal static let listed = L10n.tr("Localizable", "Common.Controls.ProfileDashboard.Listed")
      }
      internal enum Status {
        /// %@ retweeted
        internal static func userRetweeted(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Status.UserRetweeted", String(describing: p1))
        }
      }
      internal enum Timeline {
        /// Load More
        internal static let loadMore = L10n.tr("Localizable", "Common.Controls.Timeline.LoadMore")
      }
    }
    internal enum Countable {
      internal enum Like {
        /// likes
        internal static let multiple = L10n.tr("Localizable", "Common.Countable.Like.Multiple")
        /// like
        internal static let single = L10n.tr("Localizable", "Common.Countable.Like.Single")
      }
      internal enum List {
        /// lists
        internal static let multiple = L10n.tr("Localizable", "Common.Countable.List.Multiple")
        /// list
        internal static let single = L10n.tr("Localizable", "Common.Countable.List.Single")
      }
      internal enum Member {
        /// members
        internal static let multiple = L10n.tr("Localizable", "Common.Countable.Member.Multiple")
        /// member
        internal static let single = L10n.tr("Localizable", "Common.Countable.Member.Single")
      }
      internal enum Photo {
        /// photos
        internal static let multiple = L10n.tr("Localizable", "Common.Countable.Photo.Multiple")
        /// photo
        internal static let single = L10n.tr("Localizable", "Common.Countable.Photo.Single")
      }
      internal enum Quote {
        /// quotes
        internal static let mutiple = L10n.tr("Localizable", "Common.Countable.Quote.Mutiple")
        /// quote
        internal static let single = L10n.tr("Localizable", "Common.Countable.Quote.Single")
      }
      internal enum Reply {
        /// replies
        internal static let mutiple = L10n.tr("Localizable", "Common.Countable.Reply.Mutiple")
        /// reply
        internal static let single = L10n.tr("Localizable", "Common.Countable.Reply.Single")
      }
      internal enum Retweet {
        /// retweets
        internal static let mutiple = L10n.tr("Localizable", "Common.Countable.Retweet.Mutiple")
        /// retweet
        internal static let single = L10n.tr("Localizable", "Common.Countable.Retweet.Single")
      }
      internal enum Tweet {
        /// tweets
        internal static let multiple = L10n.tr("Localizable", "Common.Countable.Tweet.Multiple")
        /// tweet
        internal static let single = L10n.tr("Localizable", "Common.Countable.Tweet.Single")
      }
    }
  }

  internal enum Scene {
    internal enum Authentication {
      /// Authentication
      internal static let title = L10n.tr("Localizable", "Scene.Authentication.Title")
    }
    internal enum Bookmark {
      /// Bookmark
      internal static let title = L10n.tr("Localizable", "Scene.Bookmark.Title")
    }
    internal enum Compose {
      /// , 
      internal static let and = L10n.tr("Localizable", "Scene.Compose.And")
      ///  and 
      internal static let lastEnd = L10n.tr("Localizable", "Scene.Compose.LastEnd")
      /// Others in this conversation:
      internal static let othersInThisConversation = L10n.tr("Localizable", "Scene.Compose.OthersInThisConversation")
      /// What’s happening?
      internal static let placeholder = L10n.tr("Localizable", "Scene.Compose.Placeholder")
      /// Replying to
      internal static let replyingTo = L10n.tr("Localizable", "Scene.Compose.ReplyingTo")
      /// Reply to …
      internal static let replyTo = L10n.tr("Localizable", "Scene.Compose.ReplyTo")
      internal enum SaveDraft {
        /// Save draft
        internal static let action = L10n.tr("Localizable", "Scene.Compose.SaveDraft.Action")
        /// Save draft?
        internal static let message = L10n.tr("Localizable", "Scene.Compose.SaveDraft.Message")
      }
      internal enum Title {
        /// Compose
        internal static let compose = L10n.tr("Localizable", "Scene.Compose.Title.Compose")
        /// Quote
        internal static let quote = L10n.tr("Localizable", "Scene.Compose.Title.Quote")
        /// Reply
        internal static let reply = L10n.tr("Localizable", "Scene.Compose.Title.Reply")
      }
    }
    internal enum Drafts {
      /// Drafts
      internal static let title = L10n.tr("Localizable", "Scene.Drafts.Title")
      internal enum Actions {
        /// Delete draft
        internal static let deleteDraft = L10n.tr("Localizable", "Scene.Drafts.Actions.DeleteDraft")
        /// Edit draft
        internal static let editDraft = L10n.tr("Localizable", "Scene.Drafts.Actions.EditDraft")
      }
    }
    internal enum Drawer {
      /// Manage accounts
      internal static let manageAccounts = L10n.tr("Localizable", "Scene.Drawer.ManageAccounts")
      /// Sign in
      internal static let signIn = L10n.tr("Localizable", "Scene.Drawer.SignIn")
    }
    internal enum Followers {
      /// Followers
      internal static let title = L10n.tr("Localizable", "Scene.Followers.Title")
    }
    internal enum Following {
      /// Following
      internal static let title = L10n.tr("Localizable", "Scene.Following.Title")
    }
    internal enum Likes {
      /// Likes
      internal static let title = L10n.tr("Localizable", "Scene.Likes.Title")
    }
    internal enum Listed {
      /// Listed
      internal static let title = L10n.tr("Localizable", "Scene.Listed.Title")
    }
    internal enum Lists {
      /// Lists
      internal static let title = L10n.tr("Localizable", "Scene.Lists.Title")
      internal enum Tabs {
        /// Created
        internal static let created = L10n.tr("Localizable", "Scene.Lists.Tabs.Created")
        /// Subscribed
        internal static let subscribed = L10n.tr("Localizable", "Scene.Lists.Tabs.Subscribed")
      }
    }
    internal enum ListsDetails {
      /// Add Members
      internal static let addMembers = L10n.tr("Localizable", "Scene.ListsDetails.AddMembers")
      /// No Members Found.
      internal static let noMembersFound = L10n.tr("Localizable", "Scene.ListsDetails.NoMembersFound")
      /// Lists Details
      internal static let title = L10n.tr("Localizable", "Scene.ListsDetails.Title")
      internal enum Descriptions {
        /// %d Members
        internal static func multipleMembers(_ p1: Int) -> String {
          return L10n.tr("Localizable", "Scene.ListsDetails.Descriptions.MultipleMembers", p1)
        }
        /// %d Subscribers
        internal static func multipleSubscribers(_ p1: Int) -> String {
          return L10n.tr("Localizable", "Scene.ListsDetails.Descriptions.MultipleSubscribers", p1)
        }
        /// 1 Member
        internal static let singleMember = L10n.tr("Localizable", "Scene.ListsDetails.Descriptions.SingleMember")
        /// 1 Subscriber
        internal static let singleSubscriber = L10n.tr("Localizable", "Scene.ListsDetails.Descriptions.SingleSubscriber")
      }
      internal enum MenuActions {
        /// Add Member
        internal static let addMember = L10n.tr("Localizable", "Scene.ListsDetails.MenuActions.AddMember")
        /// Edit List
        internal static let editList = L10n.tr("Localizable", "Scene.ListsDetails.MenuActions.EditList")
      }
      internal enum Tabs {
        /// Members
        internal static let members = L10n.tr("Localizable", "Scene.ListsDetails.Tabs.Members")
        /// Subscriber
        internal static let subscriber = L10n.tr("Localizable", "Scene.ListsDetails.Tabs.Subscriber")
      }
    }
    internal enum ManageAccounts {
      /// Delete account
      internal static let deleteAccount = L10n.tr("Localizable", "Scene.ManageAccounts.DeleteAccount")
      /// Accounts
      internal static let title = L10n.tr("Localizable", "Scene.ManageAccounts.Title")
    }
    internal enum Mentions {
      /// Mentions
      internal static let title = L10n.tr("Localizable", "Scene.Mentions.Title")
    }
    internal enum Messages {
      /// Messages
      internal static let title = L10n.tr("Localizable", "Scene.Messages.Title")
    }
    internal enum Profile {
      /// Hide reply
      internal static let hideReply = L10n.tr("Localizable", "Scene.Profile.HideReply")
      /// Me
      internal static let title = L10n.tr("Localizable", "Scene.Profile.Title")
      internal enum PermissionDenied {
        /// You have been blocked from viewing this user’s profile.
        internal static let message = L10n.tr("Localizable", "Scene.Profile.PermissionDenied.Message")
        /// Permission Denied
        internal static let title = L10n.tr("Localizable", "Scene.Profile.PermissionDenied.Title")
      }
    }
    internal enum Search {
      /// Saved Search
      internal static let savedSearch = L10n.tr("Localizable", "Scene.Search.SavedSearch")
      /// Search
      internal static let title = L10n.tr("Localizable", "Scene.Search.Title")
      internal enum SearchBar {
        /// Search tweets or users
        internal static let placeholder = L10n.tr("Localizable", "Scene.Search.SearchBar.Placeholder")
      }
      internal enum Tabs {
        /// Media
        internal static let media = L10n.tr("Localizable", "Scene.Search.Tabs.Media")
        /// Tweets
        internal static let tweets = L10n.tr("Localizable", "Scene.Search.Tabs.Tweets")
        /// Users
        internal static let users = L10n.tr("Localizable", "Scene.Search.Tabs.Users")
      }
    }
    internal enum Settings {
      /// Settings
      internal static let title = L10n.tr("Localizable", "Scene.Settings.Title")
      internal enum About {
        /// License
        internal static let license = L10n.tr("Localizable", "Scene.Settings.About.License")
        /// About
        internal static let title = L10n.tr("Localizable", "Scene.Settings.About.Title")
      }
      internal enum Appearance {
        /// Highlight color
        internal static let highlightColor = L10n.tr("Localizable", "Scene.Settings.Appearance.HighlightColor")
        /// Pick color
        internal static let pickColor = L10n.tr("Localizable", "Scene.Settings.Appearance.PickColor")
        /// Appearance
        internal static let title = L10n.tr("Localizable", "Scene.Settings.Appearance.Title")
        internal enum SectionHeader {
          /// Tab position
          internal static let tabPosition = L10n.tr("Localizable", "Scene.Settings.Appearance.SectionHeader.TabPosition")
          /// Theme
          internal static let theme = L10n.tr("Localizable", "Scene.Settings.Appearance.SectionHeader.Theme")
        }
        internal enum TabPosition {
          /// Bottom
          internal static let bottom = L10n.tr("Localizable", "Scene.Settings.Appearance.TabPosition.Bottom")
          /// Top
          internal static let top = L10n.tr("Localizable", "Scene.Settings.Appearance.TabPosition.Top")
        }
        internal enum Theme {
          /// Auto
          internal static let auto = L10n.tr("Localizable", "Scene.Settings.Appearance.Theme.Auto")
          /// dark
          internal static let dark = L10n.tr("Localizable", "Scene.Settings.Appearance.Theme.Dark")
          /// light
          internal static let light = L10n.tr("Localizable", "Scene.Settings.Appearance.Theme.Light")
        }
      }
      internal enum Display {
        /// Display
        internal static let title = L10n.tr("Localizable", "Scene.Settings.Display.Title")
        internal enum DateFormat {
          /// Absolute
          internal static let absolute = L10n.tr("Localizable", "Scene.Settings.Display.DateFormat.Absolute")
          /// Relative
          internal static let relative = L10n.tr("Localizable", "Scene.Settings.Display.DateFormat.Relative")
        }
        internal enum Media {
          /// Always
          internal static let always = L10n.tr("Localizable", "Scene.Settings.Display.Media.Always")
          /// Automatic
          internal static let automatic = L10n.tr("Localizable", "Scene.Settings.Display.Media.Automatic")
          /// Auto playback
          internal static let autoPlayback = L10n.tr("Localizable", "Scene.Settings.Display.Media.AutoPlayback")
          /// Media previews
          internal static let mediaPreviews = L10n.tr("Localizable", "Scene.Settings.Display.Media.MediaPreviews")
          /// Off
          internal static let off = L10n.tr("Localizable", "Scene.Settings.Display.Media.Off")
        }
        internal enum Preview {
          /// Thanks for using @TwidereProject!
          internal static let thankForUsingTwidereX = L10n.tr("Localizable", "Scene.Settings.Display.Preview.ThankForUsingTwidereX")
        }
        internal enum SectionHeader {
          /// Date Format
          internal static let dateFormat = L10n.tr("Localizable", "Scene.Settings.Display.SectionHeader.DateFormat")
          /// Media
          internal static let media = L10n.tr("Localizable", "Scene.Settings.Display.SectionHeader.Media")
          /// Preview
          internal static let preview = L10n.tr("Localizable", "Scene.Settings.Display.SectionHeader.Preview")
          /// Text
          internal static let text = L10n.tr("Localizable", "Scene.Settings.Display.SectionHeader.Text")
        }
        internal enum Text {
          /// Avatar Style
          internal static let avatarStyle = L10n.tr("Localizable", "Scene.Settings.Display.Text.AvatarStyle")
          /// Circle
          internal static let circle = L10n.tr("Localizable", "Scene.Settings.Display.Text.Circle")
          /// Rounded Square
          internal static let roundedSquare = L10n.tr("Localizable", "Scene.Settings.Display.Text.RoundedSquare")
          /// Use the system font size
          internal static let useTheSystemFontSize = L10n.tr("Localizable", "Scene.Settings.Display.Text.UseTheSystemFontSize")
        }
      }
      internal enum SectionHeader {
        /// About
        internal static let about = L10n.tr("Localizable", "Scene.Settings.SectionHeader.About")
        /// General
        internal static let general = L10n.tr("Localizable", "Scene.Settings.SectionHeader.General")
      }
    }
    internal enum SignIn {
      /// Sign in with Twitter
      internal static let signInWithTwitter = L10n.tr("Localizable", "Scene.SignIn.SignInWithTwitter")
    }
    internal enum Status {
      /// Tweet
      internal static let title = L10n.tr("Localizable", "Scene.Status.Title")
      internal enum Like {
        /// %d Likes
        internal static func multiple(_ p1: Int) -> String {
          return L10n.tr("Localizable", "Scene.Status.Like.Multiple", p1)
        }
        /// 1 Like
        internal static let single = L10n.tr("Localizable", "Scene.Status.Like.Single")
      }
      internal enum Quote {
        /// %d Quotes
        internal static func mutiple(_ p1: Int) -> String {
          return L10n.tr("Localizable", "Scene.Status.Quote.Mutiple", p1)
        }
        /// 1 Quote
        internal static let single = L10n.tr("Localizable", "Scene.Status.Quote.Single")
      }
      internal enum Reply {
        /// %d Replies
        internal static func mutiple(_ p1: Int) -> String {
          return L10n.tr("Localizable", "Scene.Status.Reply.Mutiple", p1)
        }
        /// 1 Reply
        internal static let single = L10n.tr("Localizable", "Scene.Status.Reply.Single")
      }
      internal enum Retweet {
        /// %d Retweets
        internal static func mutiple(_ p1: Int) -> String {
          return L10n.tr("Localizable", "Scene.Status.Retweet.Mutiple", p1)
        }
        /// 1 Retweet
        internal static let single = L10n.tr("Localizable", "Scene.Status.Retweet.Single")
      }
    }
    internal enum Timeline {
      /// Timeline
      internal static let title = L10n.tr("Localizable", "Scene.Timeline.Title")
    }
    internal enum Trends {
      /// Trends
      internal static let title = L10n.tr("Localizable", "Scene.Trends.Title")
    }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: nil, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle = Bundle(for: BundleToken.self)
}
// swiftlint:enable convenience_type
