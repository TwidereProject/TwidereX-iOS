// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {

  internal enum Accessibility {
    internal enum Common {
      /// Back
      internal static let back = L10n.tr("Localizable", "Accessibility.Common.Back")
      /// Close
      internal static let close = L10n.tr("Localizable", "Accessibility.Common.Close")
      /// Done
      internal static let done = L10n.tr("Localizable", "Accessibility.Common.Done")
      /// More
      internal static let more = L10n.tr("Localizable", "Accessibility.Common.More")
      /// Network Image
      internal static let networkImage = L10n.tr("Localizable", "Accessibility.Common.NetworkImage")
      internal enum Logo {
        /// Github Logo
        internal static let github = L10n.tr("Localizable", "Accessibility.Common.Logo.Github")
        /// Mastodon Logo
        internal static let mastodon = L10n.tr("Localizable", "Accessibility.Common.Logo.Mastodon")
        /// Telegram Logo
        internal static let telegram = L10n.tr("Localizable", "Accessibility.Common.Logo.Telegram")
        /// Twidere X logo
        internal static let twidere = L10n.tr("Localizable", "Accessibility.Common.Logo.Twidere")
        /// Twitter Logo
        internal static let twitter = L10n.tr("Localizable", "Accessibility.Common.Logo.Twitter")
      }
      internal enum Status {
        /// Location
        internal static let location = L10n.tr("Localizable", "Accessibility.Common.Status.Location")
        /// Media
        internal static let media = L10n.tr("Localizable", "Accessibility.Common.Status.Media")
        /// Retweeted
        internal static let retweeted = L10n.tr("Localizable", "Accessibility.Common.Status.Retweeted")
        internal enum Actions {
          /// Like
          internal static let like = L10n.tr("Localizable", "Accessibility.Common.Status.Actions.Like")
          /// Reply
          internal static let reply = L10n.tr("Localizable", "Accessibility.Common.Status.Actions.Reply")
          /// Retweet
          internal static let retweet = L10n.tr("Localizable", "Accessibility.Common.Status.Actions.Retweet")
        }
      }
      internal enum Video {
        /// Play video
        internal static let play = L10n.tr("Localizable", "Accessibility.Common.Video.Play")
      }
    }
    internal enum Scene {
      internal enum Compose {
        /// Add mention
        internal static let addMention = L10n.tr("Localizable", "Accessibility.Scene.Compose.AddMention")
        /// Open draft
        internal static let draft = L10n.tr("Localizable", "Accessibility.Scene.Compose.Draft")
        /// Add image
        internal static let image = L10n.tr("Localizable", "Accessibility.Scene.Compose.Image")
        /// Send
        internal static let send = L10n.tr("Localizable", "Accessibility.Scene.Compose.Send")
        /// Thread mode
        internal static let thread = L10n.tr("Localizable", "Accessibility.Scene.Compose.Thread")
        internal enum Location {
          /// Disable location
          internal static let disable = L10n.tr("Localizable", "Accessibility.Scene.Compose.Location.Disable")
          /// Enable location
          internal static let enable = L10n.tr("Localizable", "Accessibility.Scene.Compose.Location.Enable")
        }
      }
      internal enum Home {
        /// Compose
        internal static let compose = L10n.tr("Localizable", "Accessibility.Scene.Home.Compose")
        /// Menu
        internal static let menu = L10n.tr("Localizable", "Accessibility.Scene.Home.Menu")
        internal enum Drawer {
          /// Account DropDown
          internal static let accountDropdown = L10n.tr("Localizable", "Accessibility.Scene.Home.Drawer.AccountDropdown")
        }
      }
      internal enum ManageAccounts {
        /// Add
        internal static let add = L10n.tr("Localizable", "Accessibility.Scene.ManageAccounts.Add")
      }
      internal enum Search {
        /// History
        internal static let history = L10n.tr("Localizable", "Accessibility.Scene.Search.History")
        /// Save
        internal static let save = L10n.tr("Localizable", "Accessibility.Scene.Search.Save")
      }
      internal enum Settings {
        internal enum Display {
          /// Font Size
          internal static let fontSize = L10n.tr("Localizable", "Accessibility.Scene.Settings.Display.FontSize")
        }
      }
      internal enum Timeline {
        /// Load
        internal static let loadGap = L10n.tr("Localizable", "Accessibility.Scene.Timeline.LoadGap")
      }
      internal enum User {
        /// Location
        internal static let location = L10n.tr("Localizable", "Accessibility.Scene.User.Location")
        /// Website
        internal static let website = L10n.tr("Localizable", "Accessibility.Scene.User.Website")
        internal enum Tab {
          /// Favourite
          internal static let favourite = L10n.tr("Localizable", "Accessibility.Scene.User.Tab.Favourite")
          /// Media
          internal static let media = L10n.tr("Localizable", "Accessibility.Scene.User.Tab.Media")
          /// Statuses
          internal static let status = L10n.tr("Localizable", "Accessibility.Scene.User.Tab.Status")
        }
      }
    }
  }

  internal enum Common {
    internal enum Alerts {
      internal enum AccountSuspended {
        /// Twitter suspends accounts which violate the %@
        internal static func message(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.AccountSuspended.Message", String(describing: p1))
        }
        /// Account Suspended
        internal static let title = L10n.tr("Localizable", "Common.Alerts.AccountSuspended.Title")
        /// Twitter Rules
        internal static let twitterRules = L10n.tr("Localizable", "Common.Alerts.AccountSuspended.TwitterRules")
      }
      internal enum AccountTemporarilyLocked {
        /// Open Twitter to unlock
        internal static let message = L10n.tr("Localizable", "Common.Alerts.AccountTemporarilyLocked.Message")
        /// Account Temporarily Locked
        internal static let title = L10n.tr("Localizable", "Common.Alerts.AccountTemporarilyLocked.Title")
      }
      internal enum BlockUserSuccess {
        /// %@ has been blocked
        internal static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.BlockUserSuccess.Title", String(describing: p1))
        }
      }
      internal enum CancelFollowRequest {
        /// Cancel follow request for %@?
        internal static func message(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.CancelFollowRequest.Message", String(describing: p1))
        }
      }
      internal enum FailedToBlockUser {
        /// Please try again
        internal static let message = L10n.tr("Localizable", "Common.Alerts.FailedToBlockUser.Message")
        /// Failed to block %@
        internal static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.FailedToBlockUser.Title", String(describing: p1))
        }
      }
      internal enum FailedToDeleteTweet {
        /// Please try again
        internal static let message = L10n.tr("Localizable", "Common.Alerts.FailedToDeleteTweet.Message")
        /// Failed to Delete Tweet
        internal static let title = L10n.tr("Localizable", "Common.Alerts.FailedToDeleteTweet.Title")
      }
      internal enum FailedToFollowing {
        /// Please try again
        internal static let message = L10n.tr("Localizable", "Common.Alerts.FailedToFollowing.Message")
        /// Failed to Following
        internal static let title = L10n.tr("Localizable", "Common.Alerts.FailedToFollowing.Title")
      }
      internal enum FailedToLoad {
        /// Please try again
        internal static let message = L10n.tr("Localizable", "Common.Alerts.FailedToLoad.Message")
        /// Failed to Load
        internal static let title = L10n.tr("Localizable", "Common.Alerts.FailedToLoad.Title")
      }
      internal enum FailedToLoginMastodonServer {
        /// Server URL is incorrect.
        internal static let message = L10n.tr("Localizable", "Common.Alerts.FailedToLoginMastodonServer.Message")
        /// Failed to Login
        internal static let title = L10n.tr("Localizable", "Common.Alerts.FailedToLoginMastodonServer.Title")
      }
      internal enum FailedToLoginTimeout {
        /// Connection timeout.
        internal static let message = L10n.tr("Localizable", "Common.Alerts.FailedToLoginTimeout.Message")
        /// Failed to Login
        internal static let title = L10n.tr("Localizable", "Common.Alerts.FailedToLoginTimeout.Title")
      }
      internal enum FailedToMuteUser {
        /// Please try again
        internal static let message = L10n.tr("Localizable", "Common.Alerts.FailedToMuteUser.Message")
        /// Failed to mute %@
        internal static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.FailedToMuteUser.Title", String(describing: p1))
        }
      }
      internal enum FailedToReportAndBlockUser {
        /// Please try again
        internal static let message = L10n.tr("Localizable", "Common.Alerts.FailedToReportAndBlockUser.Message")
        /// Failed to report and block %@
        internal static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.FailedToReportAndBlockUser.Title", String(describing: p1))
        }
      }
      internal enum FailedToReportUser {
        /// Please try again
        internal static let message = L10n.tr("Localizable", "Common.Alerts.FailedToReportUser.Message")
        /// Failed to report %@
        internal static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.FailedToReportUser.Title", String(describing: p1))
        }
      }
      internal enum FailedToSendMessage {
        /// Failed to send message
        internal static let message = L10n.tr("Localizable", "Common.Alerts.FailedToSendMessage.Message")
        /// Sending message
        internal static let title = L10n.tr("Localizable", "Common.Alerts.FailedToSendMessage.Title")
      }
      internal enum FailedToUnblockUser {
        /// Please try again
        internal static let message = L10n.tr("Localizable", "Common.Alerts.FailedToUnblockUser.Message")
        /// Failed to unblock %@
        internal static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.FailedToUnblockUser.Title", String(describing: p1))
        }
      }
      internal enum FailedToUnfollowing {
        /// Please try again
        internal static let message = L10n.tr("Localizable", "Common.Alerts.FailedToUnfollowing.Message")
        /// Failed to Unfollowing
        internal static let title = L10n.tr("Localizable", "Common.Alerts.FailedToUnfollowing.Title")
      }
      internal enum FailedToUnmuteUser {
        /// Please try again
        internal static let message = L10n.tr("Localizable", "Common.Alerts.FailedToUnmuteUser.Message")
        /// Failed to unmute %@
        internal static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.FailedToUnmuteUser.Title", String(describing: p1))
        }
      }
      internal enum FollowingRequestSent {
        /// Following Request Sent
        internal static let title = L10n.tr("Localizable", "Common.Alerts.FollowingRequestSent.Title")
      }
      internal enum FollowingSuccess {
        /// Following Succeeded
        internal static let title = L10n.tr("Localizable", "Common.Alerts.FollowingSuccess.Title")
      }
      internal enum MediaSaveFail {
        /// Please try again
        internal static let message = L10n.tr("Localizable", "Common.Alerts.MediaSaveFail.Message")
        /// Failed to save media
        internal static let title = L10n.tr("Localizable", "Common.Alerts.MediaSaveFail.Title")
      }
      internal enum MediaSaved {
        /// Media saved
        internal static let title = L10n.tr("Localizable", "Common.Alerts.MediaSaved.Title")
      }
      internal enum MediaSaving {
        /// Saving media
        internal static let title = L10n.tr("Localizable", "Common.Alerts.MediaSaving.Title")
      }
      internal enum MediaSharing {
        /// Media will be shared after download is completed
        internal static let title = L10n.tr("Localizable", "Common.Alerts.MediaSharing.Title")
      }
      internal enum MuteUserSuccess {
        /// %@ has been muted
        internal static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.MuteUserSuccess.Title", String(describing: p1))
        }
      }
      internal enum NoTweetsFound {
        /// No Tweets Found
        internal static let title = L10n.tr("Localizable", "Common.Alerts.NoTweetsFound.Title")
      }
      internal enum PermissionDeniedFriendshipBlocked {
        /// You have been blocked from following this account at the request of the user
        internal static let message = L10n.tr("Localizable", "Common.Alerts.PermissionDeniedFriendshipBlocked.Message")
        /// Permission Denied
        internal static let title = L10n.tr("Localizable", "Common.Alerts.PermissionDeniedFriendshipBlocked.Title")
      }
      internal enum PermissionDeniedNotAuthorized {
        /// Sorry, you are not authorized
        internal static let message = L10n.tr("Localizable", "Common.Alerts.PermissionDeniedNotAuthorized.Message")
        /// Permission Denied
        internal static let title = L10n.tr("Localizable", "Common.Alerts.PermissionDeniedNotAuthorized.Title")
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
      internal enum ReportAndBlockUserSuccess {
        /// %@ has been reported for spam and blocked
        internal static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.ReportAndBlockUserSuccess.Title", String(describing: p1))
        }
      }
      internal enum ReportUserSuccess {
        /// %@ has been reported for spam
        internal static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.ReportUserSuccess.Title", String(describing: p1))
        }
      }
      internal enum TooManyRequests {
        /// Too Many Requests
        internal static let title = L10n.tr("Localizable", "Common.Alerts.TooManyRequests.Title")
      }
      internal enum TweetDeleted {
        /// Tweet Deleted
        internal static let title = L10n.tr("Localizable", "Common.Alerts.TweetDeleted.Title")
      }
      internal enum TweetFail {
        /// Please try again
        internal static let message = L10n.tr("Localizable", "Common.Alerts.TweetFail.Message")
        /// Failed to Tweet
        internal static let title = L10n.tr("Localizable", "Common.Alerts.TweetFail.Title")
      }
      internal enum TweetSending {
        /// Sending tweet
        internal static let title = L10n.tr("Localizable", "Common.Alerts.TweetSending.Title")
      }
      internal enum TweetSent {
        /// Tweet Sent
        internal static let title = L10n.tr("Localizable", "Common.Alerts.TweetSent.Title")
      }
      internal enum UnblockUserSuccess {
        /// %@ has been unblocked
        internal static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.UnblockUserSuccess.Title", String(describing: p1))
        }
      }
      internal enum UnfollowUser {
        /// Unfollow user %@?
        internal static func message(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.UnfollowUser.Message", String(describing: p1))
        }
      }
      internal enum UnfollowingSuccess {
        /// Unfollowing Succeeded
        internal static let title = L10n.tr("Localizable", "Common.Alerts.UnfollowingSuccess.Title")
      }
      internal enum UnmuteUserSuccess {
        /// %@ has been unmuted
        internal static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.UnmuteUserSuccess.Title", String(describing: p1))
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
        /// Share media
        internal static let shareMedia = L10n.tr("Localizable", "Common.Controls.Actions.ShareMedia")
        /// Sign in
        internal static let signIn = L10n.tr("Localizable", "Common.Controls.Actions.SignIn")
        /// Take photo
        internal static let takePhoto = L10n.tr("Localizable", "Common.Controls.Actions.TakePhoto")
        /// Yes
        internal static let yes = L10n.tr("Localizable", "Common.Controls.Actions.Yes")
      }
      internal enum Friendship {
        /// Block %@
        internal static func blockUser(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Friendship.BlockUser", String(describing: p1))
        }
        /// follower
        internal static let follower = L10n.tr("Localizable", "Common.Controls.Friendship.Follower")
        /// followers
        internal static let followers = L10n.tr("Localizable", "Common.Controls.Friendship.Followers")
        /// Follows you
        internal static let followsYou = L10n.tr("Localizable", "Common.Controls.Friendship.FollowsYou")
        /// Mute %@
        internal static func muteUser(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Friendship.MuteUser", String(describing: p1))
        }
        /// %@ is following you
        internal static func userIsFollowingYou(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Friendship.UserIsFollowingYou", String(describing: p1))
        }
        /// %@ is not following you
        internal static func userIsNotFollowingYou(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Friendship.UserIsNotFollowingYou", String(describing: p1))
        }
        internal enum Actions {
          /// Block
          internal static let block = L10n.tr("Localizable", "Common.Controls.Friendship.Actions.Block")
          /// Follow
          internal static let follow = L10n.tr("Localizable", "Common.Controls.Friendship.Actions.Follow")
          /// Following
          internal static let following = L10n.tr("Localizable", "Common.Controls.Friendship.Actions.Following")
          /// Mute
          internal static let mute = L10n.tr("Localizable", "Common.Controls.Friendship.Actions.Mute")
          /// Pending
          internal static let pending = L10n.tr("Localizable", "Common.Controls.Friendship.Actions.Pending")
          /// Report
          internal static let report = L10n.tr("Localizable", "Common.Controls.Friendship.Actions.Report")
          /// Report and Block
          internal static let reportAndBlock = L10n.tr("Localizable", "Common.Controls.Friendship.Actions.ReportAndBlock")
          /// Unblock
          internal static let unblock = L10n.tr("Localizable", "Common.Controls.Friendship.Actions.Unblock")
          /// Unfollow
          internal static let unfollow = L10n.tr("Localizable", "Common.Controls.Friendship.Actions.Unfollow")
          /// Unmute
          internal static let unmute = L10n.tr("Localizable", "Common.Controls.Friendship.Actions.Unmute")
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
        /// Media
        internal static let media = L10n.tr("Localizable", "Common.Controls.Status.Media")
        /// %@ boosted
        internal static func userBoosted(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Status.UserBoosted", String(describing: p1))
        }
        /// %@ retweeted
        internal static func userRetweeted(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Status.UserRetweeted", String(describing: p1))
        }
        /// You boosted
        internal static let youBoosted = L10n.tr("Localizable", "Common.Controls.Status.YouBoosted")
        /// You retweeted
        internal static let youRetweeted = L10n.tr("Localizable", "Common.Controls.Status.YouRetweeted")
        internal enum Actions {
          /// Bookmark
          internal static let bookmark = L10n.tr("Localizable", "Common.Controls.Status.Actions.Bookmark")
          /// Copy link
          internal static let copyLink = L10n.tr("Localizable", "Common.Controls.Status.Actions.CopyLink")
          /// Copy text
          internal static let copyText = L10n.tr("Localizable", "Common.Controls.Status.Actions.CopyText")
          /// Delete tweet
          internal static let deleteTweet = L10n.tr("Localizable", "Common.Controls.Status.Actions.DeleteTweet")
          /// Pin on Profile
          internal static let pinOnProfile = L10n.tr("Localizable", "Common.Controls.Status.Actions.PinOnProfile")
          /// Quote
          internal static let quote = L10n.tr("Localizable", "Common.Controls.Status.Actions.Quote")
          /// Retweet
          internal static let retweet = L10n.tr("Localizable", "Common.Controls.Status.Actions.Retweet")
          /// Share
          internal static let share = L10n.tr("Localizable", "Common.Controls.Status.Actions.Share")
          /// Share link
          internal static let shareLink = L10n.tr("Localizable", "Common.Controls.Status.Actions.ShareLink")
          /// Translate
          internal static let translate = L10n.tr("Localizable", "Common.Controls.Status.Actions.Translate")
          /// Unpin from Profile
          internal static let unpinFromProfile = L10n.tr("Localizable", "Common.Controls.Status.Actions.UnpinFromProfile")
          /// Vote
          internal static let vote = L10n.tr("Localizable", "Common.Controls.Status.Actions.Vote")
        }
        internal enum Poll {
          /// Closed
          internal static let expired = L10n.tr("Localizable", "Common.Controls.Status.Poll.Expired")
          /// %@ people
          internal static func totalPeople(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Common.Controls.Status.Poll.TotalPeople", String(describing: p1))
          }
          /// %@ person
          internal static func totalPerson(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Common.Controls.Status.Poll.TotalPerson", String(describing: p1))
          }
          /// %@ vote
          internal static func totalVote(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Common.Controls.Status.Poll.TotalVote", String(describing: p1))
          }
          /// %@ votes
          internal static func totalVotes(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Common.Controls.Status.Poll.TotalVotes", String(describing: p1))
          }
        }
        internal enum Thread {
          /// Show this thread
          internal static let show = L10n.tr("Localizable", "Common.Controls.Status.Thread.Show")
        }
      }
      internal enum Timeline {
        /// Load More
        internal static let loadMore = L10n.tr("Localizable", "Common.Controls.Timeline.LoadMore")
      }
    }
    internal enum Countable {
      internal enum Like {
        /// %@ likes
        internal static func multiple(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Countable.Like.Multiple", String(describing: p1))
        }
        /// %@ like
        internal static func single(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Countable.Like.Single", String(describing: p1))
        }
      }
      internal enum List {
        /// %@ lists
        internal static func multiple(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Countable.List.Multiple", String(describing: p1))
        }
        /// %@ list
        internal static func single(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Countable.List.Single", String(describing: p1))
        }
      }
      internal enum Member {
        /// %@ members
        internal static func multiple(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Countable.Member.Multiple", String(describing: p1))
        }
        /// %@ member
        internal static func single(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Countable.Member.Single", String(describing: p1))
        }
      }
      internal enum Photo {
        /// %@ photos
        internal static func multiple(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Countable.Photo.Multiple", String(describing: p1))
        }
        /// %@ photo
        internal static func single(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Countable.Photo.Single", String(describing: p1))
        }
      }
      internal enum Quote {
        /// %@ quotes
        internal static func mutiple(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Countable.Quote.Mutiple", String(describing: p1))
        }
        /// %@ quote
        internal static func single(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Countable.Quote.Single", String(describing: p1))
        }
      }
      internal enum Reply {
        /// %@ replies
        internal static func mutiple(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Countable.Reply.Mutiple", String(describing: p1))
        }
        /// %@ reply
        internal static func single(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Countable.Reply.Single", String(describing: p1))
        }
      }
      internal enum Retweet {
        /// %@ retweets
        internal static func mutiple(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Countable.Retweet.Mutiple", String(describing: p1))
        }
        /// %@ retweet
        internal static func single(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Countable.Retweet.Single", String(describing: p1))
        }
      }
      internal enum Tweet {
        /// %@ tweets
        internal static func multiple(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Countable.Tweet.Multiple", String(describing: p1))
        }
        /// %@ tweet
        internal static func single(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Countable.Tweet.Single", String(describing: p1))
        }
      }
    }
    internal enum Notification {
      /// %@ favourited your toot
      internal static func favourite(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Common.Notification.Favourite", String(describing: p1))
      }
      /// %@ followed you
      internal static func follow(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Common.Notification.Follow", String(describing: p1))
      }
      /// %@ has requested to follow you
      internal static func followRequest(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Common.Notification.FollowRequest", String(describing: p1))
      }
      /// %@ mentions you
      internal static func mentions(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Common.Notification.Mentions", String(describing: p1))
      }
      /// Your poll has ended
      internal static let ownPoll = L10n.tr("Localizable", "Common.Notification.OwnPoll")
      /// A poll you have voted in has ended
      internal static let poll = L10n.tr("Localizable", "Common.Notification.Poll")
      /// %@ boosted your toot
      internal static func reblog(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Common.Notification.Reblog", String(describing: p1))
      }
      /// %@ just posted
      internal static func status(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Common.Notification.Status", String(describing: p1))
      }
      internal enum Messages {
        /// %@ sent you a message
        internal static func content(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Notification.Messages.Content", String(describing: p1))
        }
        /// New direct message
        internal static let title = L10n.tr("Localizable", "Common.Notification.Messages.Title")
      }
    }
    internal enum NotificationChannel {
      internal enum BackgroundProgresses {
        /// Background progresses
        internal static let name = L10n.tr("Localizable", "Common.NotificationChannel.BackgroundProgresses.Name")
      }
      internal enum ContentInteractions {
        /// Interactions like mentions and retweets
        internal static let description = L10n.tr("Localizable", "Common.NotificationChannel.ContentInteractions.Description")
        /// Interactions
        internal static let name = L10n.tr("Localizable", "Common.NotificationChannel.ContentInteractions.Name")
      }
      internal enum ContentMessages {
        /// Direct messages
        internal static let description = L10n.tr("Localizable", "Common.NotificationChannel.ContentMessages.Description")
        /// Messages
        internal static let name = L10n.tr("Localizable", "Common.NotificationChannel.ContentMessages.Name")
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
      /// Write your warning here
      internal static let cwPlaceholder = L10n.tr("Localizable", "Scene.Compose.CwPlaceholder")
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
      internal enum Visibility {
        /// Direct
        internal static let direct = L10n.tr("Localizable", "Scene.Compose.Visibility.Direct")
        /// Private
        internal static let `private` = L10n.tr("Localizable", "Scene.Compose.Visibility.Private")
        /// Public
        internal static let `public` = L10n.tr("Localizable", "Scene.Compose.Visibility.Public")
        /// Unlisted
        internal static let unlisted = L10n.tr("Localizable", "Scene.Compose.Visibility.Unlisted")
      }
      internal enum Vote {
        /// Multiple choice
        internal static let multiple = L10n.tr("Localizable", "Scene.Compose.Vote.Multiple")
        internal enum Expiration {
          /// 1 day
          internal static let _1Day = L10n.tr("Localizable", "Scene.Compose.Vote.Expiration.1Day")
          /// 1 hour
          internal static let _1Hour = L10n.tr("Localizable", "Scene.Compose.Vote.Expiration.1Hour")
          /// 30 minutes
          internal static let _30Min = L10n.tr("Localizable", "Scene.Compose.Vote.Expiration.30Min")
          /// 3 days
          internal static let _3Day = L10n.tr("Localizable", "Scene.Compose.Vote.Expiration.3Day")
          /// 5 minutes
          internal static let _5Min = L10n.tr("Localizable", "Scene.Compose.Vote.Expiration.5Min")
          /// 6 hours
          internal static let _6Hour = L10n.tr("Localizable", "Scene.Compose.Vote.Expiration.6Hour")
          /// 7 days
          internal static let _7Day = L10n.tr("Localizable", "Scene.Compose.Vote.Expiration.7Day")
        }
      }
    }
    internal enum ComposeHashtagSearch {
      /// Search hashtag
      internal static let searchPlaceholder = L10n.tr("Localizable", "Scene.ComposeHashtagSearch.SearchPlaceholder")
    }
    internal enum ComposeUserSearch {
      /// Search users
      internal static let searchPlaceholder = L10n.tr("Localizable", "Scene.ComposeUserSearch.SearchPlaceholder")
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
    internal enum Federated {
      /// Federated
      internal static let title = L10n.tr("Localizable", "Scene.Federated.Title")
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
      internal enum Icons {
        /// Create list
        internal static let create = L10n.tr("Localizable", "Scene.Lists.Icons.Create")
        /// Private visibility
        internal static let `private` = L10n.tr("Localizable", "Scene.Lists.Icons.Private")
      }
      internal enum Tabs {
        /// MY LISTS
        internal static let created = L10n.tr("Localizable", "Scene.Lists.Tabs.Created")
        /// SUBSCRIBED
        internal static let subscribed = L10n.tr("Localizable", "Scene.Lists.Tabs.Subscribed")
      }
    }
    internal enum ListsDetails {
      /// Add Members
      internal static let addMembers = L10n.tr("Localizable", "Scene.ListsDetails.AddMembers")
      /// Delete this list: %@
      internal static func deleteListConfirm(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Scene.ListsDetails.DeleteListConfirm", String(describing: p1))
      }
      /// Delete this list
      internal static let deleteListTitle = L10n.tr("Localizable", "Scene.ListsDetails.DeleteListTitle")
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
        /// Delete List
        internal static let deleteList = L10n.tr("Localizable", "Scene.ListsDetails.MenuActions.DeleteList")
        /// Edit List
        internal static let editList = L10n.tr("Localizable", "Scene.ListsDetails.MenuActions.EditList")
        /// Follow
        internal static let follow = L10n.tr("Localizable", "Scene.ListsDetails.MenuActions.Follow")
        /// Rename List
        internal static let renameList = L10n.tr("Localizable", "Scene.ListsDetails.MenuActions.RenameList")
        /// Unfollow
        internal static let unfollow = L10n.tr("Localizable", "Scene.ListsDetails.MenuActions.Unfollow")
      }
      internal enum Tabs {
        /// List Members
        internal static let members = L10n.tr("Localizable", "Scene.ListsDetails.Tabs.Members")
        /// Subscribers
        internal static let subscriber = L10n.tr("Localizable", "Scene.ListsDetails.Tabs.Subscriber")
      }
    }
    internal enum ListsModify {
      /// Description
      internal static let description = L10n.tr("Localizable", "Scene.ListsModify.Description")
      /// Name
      internal static let name = L10n.tr("Localizable", "Scene.ListsModify.Name")
      /// Private
      internal static let `private` = L10n.tr("Localizable", "Scene.ListsModify.Private")
      internal enum Create {
        /// New List
        internal static let title = L10n.tr("Localizable", "Scene.ListsModify.Create.Title")
      }
      internal enum Dialog {
        /// Create a list
        internal static let create = L10n.tr("Localizable", "Scene.ListsModify.Dialog.Create")
        /// Rename the list
        internal static let edit = L10n.tr("Localizable", "Scene.ListsModify.Dialog.Edit")
      }
      internal enum Edit {
        /// Edit List
        internal static let title = L10n.tr("Localizable", "Scene.ListsModify.Edit.Title")
      }
    }
    internal enum ListsUsers {
      internal enum Add {
        /// Search people
        internal static let search = L10n.tr("Localizable", "Scene.ListsUsers.Add.Search")
        /// Add Member
        internal static let title = L10n.tr("Localizable", "Scene.ListsUsers.Add.Title")
      }
      internal enum MenuActions {
        /// Add
        internal static let add = L10n.tr("Localizable", "Scene.ListsUsers.MenuActions.Add")
        /// Remove
        internal static let remove = L10n.tr("Localizable", "Scene.ListsUsers.MenuActions.Remove")
      }
    }
    internal enum Local {
      /// Local
      internal static let title = L10n.tr("Localizable", "Scene.Local.Title")
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
      internal enum Action {
        /// Copy message text
        internal static let copyText = L10n.tr("Localizable", "Scene.Messages.Action.CopyText")
        /// Delete message for you
        internal static let delete = L10n.tr("Localizable", "Scene.Messages.Action.Delete")
      }
      internal enum Error {
        /// The Current account does not support direct messages
        internal static let notSupported = L10n.tr("Localizable", "Scene.Messages.Error.NotSupported")
      }
      internal enum Expanded {
        /// [Photo]
        internal static let photo = L10n.tr("Localizable", "Scene.Messages.Expanded.Photo")
      }
      internal enum Icon {
        /// Send message failed
        internal static let failed = L10n.tr("Localizable", "Scene.Messages.Icon.Failed")
      }
      internal enum NewConversation {
        /// Search people
        internal static let search = L10n.tr("Localizable", "Scene.Messages.NewConversation.Search")
        /// Find people
        internal static let title = L10n.tr("Localizable", "Scene.Messages.NewConversation.Title")
      }
    }
    internal enum Notification {
      /// Notification
      internal static let title = L10n.tr("Localizable", "Scene.Notification.Title")
      internal enum Tabs {
        /// All
        internal static let all = L10n.tr("Localizable", "Scene.Notification.Tabs.All")
      }
    }
    internal enum Profile {
      /// Hide reply
      internal static let hideReply = L10n.tr("Localizable", "Scene.Profile.HideReply")
      /// Me
      internal static let title = L10n.tr("Localizable", "Scene.Profile.Title")
      internal enum Filter {
        /// All tweets
        internal static let all = L10n.tr("Localizable", "Scene.Profile.Filter.All")
        /// Exclude replies
        internal static let excludeReplies = L10n.tr("Localizable", "Scene.Profile.Filter.ExcludeReplies")
      }
      internal enum PermissionDeniedProfileBlocked {
        /// You have been blocked from viewing this user’s profile.
        internal static let message = L10n.tr("Localizable", "Scene.Profile.PermissionDeniedProfileBlocked.Message")
        /// Permission Denied
        internal static let title = L10n.tr("Localizable", "Scene.Profile.PermissionDeniedProfileBlocked.Title")
      }
    }
    internal enum Search {
      /// Saved Search
      internal static let savedSearch = L10n.tr("Localizable", "Scene.Search.SavedSearch")
      /// Show less
      internal static let showLess = L10n.tr("Localizable", "Scene.Search.ShowLess")
      /// Show more
      internal static let showMore = L10n.tr("Localizable", "Scene.Search.ShowMore")
      /// Search
      internal static let title = L10n.tr("Localizable", "Scene.Search.Title")
      internal enum SearchBar {
        /// Search tweets or users
        internal static let placeholder = L10n.tr("Localizable", "Scene.Search.SearchBar.Placeholder")
      }
      internal enum Tabs {
        /// Hashtag
        internal static let hashtag = L10n.tr("Localizable", "Scene.Search.Tabs.Hashtag")
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
        /// Next generation of Twidere for Android 5.0+. \nStill in early stage.
        internal static let description = L10n.tr("Localizable", "Scene.Settings.About.Description")
        /// License
        internal static let license = L10n.tr("Localizable", "Scene.Settings.About.License")
        /// About
        internal static let title = L10n.tr("Localizable", "Scene.Settings.About.Title")
        /// Ver %@
        internal static func version(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Scene.Settings.About.Version", String(describing: p1))
        }
        internal enum Logo {
          /// About page background logo
          internal static let background = L10n.tr("Localizable", "Scene.Settings.About.Logo.Background")
          /// About page background logo shadow
          internal static let backgroundShadow = L10n.tr("Localizable", "Scene.Settings.About.Logo.BackgroundShadow")
        }
      }
      internal enum Appearance {
        /// AMOLED optimized mode
        internal static let amoledOptimizedMode = L10n.tr("Localizable", "Scene.Settings.Appearance.AmoledOptimizedMode")
        /// Highlight color
        internal static let highlightColor = L10n.tr("Localizable", "Scene.Settings.Appearance.HighlightColor")
        /// Pick color
        internal static let pickColor = L10n.tr("Localizable", "Scene.Settings.Appearance.PickColor")
        /// Appearance
        internal static let title = L10n.tr("Localizable", "Scene.Settings.Appearance.Title")
        internal enum ScrollingTimeline {
          /// Hide app bar when scrolling
          internal static let appBar = L10n.tr("Localizable", "Scene.Settings.Appearance.ScrollingTimeline.AppBar")
          /// Hide FAB when scrolling
          internal static let fab = L10n.tr("Localizable", "Scene.Settings.Appearance.ScrollingTimeline.Fab")
          /// Hide tab bar when scrolling
          internal static let tabBar = L10n.tr("Localizable", "Scene.Settings.Appearance.ScrollingTimeline.TabBar")
        }
        internal enum SectionHeader {
          /// Scrolling timeline
          internal static let scrollingTimeline = L10n.tr("Localizable", "Scene.Settings.Appearance.SectionHeader.ScrollingTimeline")
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
          /// Dark
          internal static let dark = L10n.tr("Localizable", "Scene.Settings.Appearance.Theme.Dark")
          /// Light
          internal static let light = L10n.tr("Localizable", "Scene.Settings.Appearance.Theme.Light")
        }
      }
      internal enum Display {
        /// Display
        internal static let title = L10n.tr("Localizable", "Scene.Settings.Display.Title")
        /// Url previews
        internal static let urlPreview = L10n.tr("Localizable", "Scene.Settings.Display.UrlPreview")
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
      internal enum Layout {
        /// Layout
        internal static let title = L10n.tr("Localizable", "Scene.Settings.Layout.Title")
        internal enum Actions {
          /// Drawer actions
          internal static let drawer = L10n.tr("Localizable", "Scene.Settings.Layout.Actions.Drawer")
          /// Tabbar actions
          internal static let tabbar = L10n.tr("Localizable", "Scene.Settings.Layout.Actions.Tabbar")
        }
        internal enum Desc {
          /// Choose and arrange up to 5 actions that will appear on the tabbar (The local and federal timelines will only be displayed in Mastodon.)
          internal static let content = L10n.tr("Localizable", "Scene.Settings.Layout.Desc.Content")
          /// Custom Layout
          internal static let title = L10n.tr("Localizable", "Scene.Settings.Layout.Desc.Title")
        }
      }
      internal enum Misc {
        /// Misc
        internal static let title = L10n.tr("Localizable", "Scene.Settings.Misc.Title")
        internal enum Nitter {
          /// Third-party Twitter data provider
          internal static let title = L10n.tr("Localizable", "Scene.Settings.Misc.Nitter.Title")
          internal enum Dialog {
            internal enum Information {
              /// Due to the limitation of Twitter API, some data might not be able to fetch from Twitter, you can use a third-party data provider to provide these data. Twidere does not take any responsibility for them.
              internal static let content = L10n.tr("Localizable", "Scene.Settings.Misc.Nitter.Dialog.Information.Content")
              /// Third party Twitter data provider
              internal static let title = L10n.tr("Localizable", "Scene.Settings.Misc.Nitter.Dialog.Information.Title")
            }
            internal enum Usage {
              /// - Twitter status threading
              internal static let content = L10n.tr("Localizable", "Scene.Settings.Misc.Nitter.Dialog.Usage.Content")
              /// Project URL
              internal static let projectButton = L10n.tr("Localizable", "Scene.Settings.Misc.Nitter.Dialog.Usage.ProjectButton")
              /// Using Third-party data provider in
              internal static let title = L10n.tr("Localizable", "Scene.Settings.Misc.Nitter.Dialog.Usage.Title")
            }
          }
          internal enum Input {
            /// Alternative Twitter front-end focused on privacy.
            internal static let description = L10n.tr("Localizable", "Scene.Settings.Misc.Nitter.Input.Description")
            /// Nitter Instance
            internal static let placeholder = L10n.tr("Localizable", "Scene.Settings.Misc.Nitter.Input.Placeholder")
          }
        }
        internal enum Proxy {
          /// Password
          internal static let password = L10n.tr("Localizable", "Scene.Settings.Misc.Proxy.Password")
          /// Server
          internal static let server = L10n.tr("Localizable", "Scene.Settings.Misc.Proxy.Server")
          /// Proxy settings
          internal static let title = L10n.tr("Localizable", "Scene.Settings.Misc.Proxy.Title")
          /// Username
          internal static let username = L10n.tr("Localizable", "Scene.Settings.Misc.Proxy.Username")
          internal enum Enable {
            /// Use proxy for all network requests
            internal static let description = L10n.tr("Localizable", "Scene.Settings.Misc.Proxy.Enable.Description")
            /// Proxy
            internal static let title = L10n.tr("Localizable", "Scene.Settings.Misc.Proxy.Enable.Title")
          }
          internal enum Port {
            /// Proxy server port must be numbers
            internal static let error = L10n.tr("Localizable", "Scene.Settings.Misc.Proxy.Port.Error")
            /// Port
            internal static let title = L10n.tr("Localizable", "Scene.Settings.Misc.Proxy.Port.Title")
          }
          internal enum `Type` {
            /// HTTP
            internal static let http = L10n.tr("Localizable", "Scene.Settings.Misc.Proxy.Type.Http")
            /// Reverse
            internal static let reverse = L10n.tr("Localizable", "Scene.Settings.Misc.Proxy.Type.Reverse")
            /// Proxy type
            internal static let title = L10n.tr("Localizable", "Scene.Settings.Misc.Proxy.Type.Title")
          }
        }
      }
      internal enum Notification {
        /// Accounts
        internal static let accounts = L10n.tr("Localizable", "Scene.Settings.Notification.Accounts")
        /// Show Notification
        internal static let notificationSwitch = L10n.tr("Localizable", "Scene.Settings.Notification.NotificationSwitch")
        /// Notification
        internal static let title = L10n.tr("Localizable", "Scene.Settings.Notification.Title")
      }
      internal enum SectionHeader {
        /// About
        internal static let about = L10n.tr("Localizable", "Scene.Settings.SectionHeader.About")
        /// General
        internal static let general = L10n.tr("Localizable", "Scene.Settings.SectionHeader.General")
      }
      internal enum Storage {
        /// Storage
        internal static let title = L10n.tr("Localizable", "Scene.Settings.Storage.Title")
        internal enum All {
          /// Delete all Twidere X cache. Your account credentials will not be lost.
          internal static let subTitle = L10n.tr("Localizable", "Scene.Settings.Storage.All.SubTitle")
          /// Clear all cache
          internal static let title = L10n.tr("Localizable", "Scene.Settings.Storage.All.Title")
        }
        internal enum Media {
          /// Clear stored media cache.
          internal static let subTitle = L10n.tr("Localizable", "Scene.Settings.Storage.Media.SubTitle")
          /// Clear media cache
          internal static let title = L10n.tr("Localizable", "Scene.Settings.Storage.Media.Title")
        }
        internal enum Search {
          /// Clear search history
          internal static let title = L10n.tr("Localizable", "Scene.Settings.Storage.Search.Title")
        }
      }
    }
    internal enum SignIn {
      /// Hello!\nSign in to Get Started.
      internal static let helloSignInToGetStarted = L10n.tr("Localizable", "Scene.SignIn.HelloSignInToGetStarted")
      /// Sign in with Mastodon
      internal static let signInWithMastodon = L10n.tr("Localizable", "Scene.SignIn.SignInWithMastodon")
      /// Sign in with Twitter
      internal static let signInWithTwitter = L10n.tr("Localizable", "Scene.SignIn.SignInWithTwitter")
      internal enum TwitterOptions {
        /// Sign in with Custom Twitter Key
        internal static let signInWithCustomTwitterKey = L10n.tr("Localizable", "Scene.SignIn.TwitterOptions.SignInWithCustomTwitterKey")
        /// Twitter API v2 access is required.
        internal static let twitterApiV2AccessIsRequired = L10n.tr("Localizable", "Scene.SignIn.TwitterOptions.TwitterApiV2AccessIsRequired")
      }
    }
    internal enum Status {
      /// Tweet
      internal static let title = L10n.tr("Localizable", "Scene.Status.Title")
      /// Toot
      internal static let titleMastodon = L10n.tr("Localizable", "Scene.Status.TitleMastodon")
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
      /// %d people talking
      internal static func accounts(_ p1: Int) -> String {
        return L10n.tr("Localizable", "Scene.Trends.Accounts", p1)
      }
      /// Trending Now
      internal static let now = L10n.tr("Localizable", "Scene.Trends.Now")
      /// Trends
      internal static let title = L10n.tr("Localizable", "Scene.Trends.Title")
      /// Trends - Worldwide
      internal static let worldWide = L10n.tr("Localizable", "Scene.Trends.WorldWide")
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
