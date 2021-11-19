// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
public enum L10n {

  public enum Accessibility {
    public enum Common {
      /// Back
      public static let back = L10n.tr("Localizable", "Accessibility.Common.Back")
      /// Close
      public static let close = L10n.tr("Localizable", "Accessibility.Common.Close")
      /// Done
      public static let done = L10n.tr("Localizable", "Accessibility.Common.Done")
      /// More
      public static let more = L10n.tr("Localizable", "Accessibility.Common.More")
      /// Network Image
      public static let networkImage = L10n.tr("Localizable", "Accessibility.Common.NetworkImage")
      public enum Logo {
        /// Github Logo
        public static let github = L10n.tr("Localizable", "Accessibility.Common.Logo.Github")
        /// Mastodon Logo
        public static let mastodon = L10n.tr("Localizable", "Accessibility.Common.Logo.Mastodon")
        /// Telegram Logo
        public static let telegram = L10n.tr("Localizable", "Accessibility.Common.Logo.Telegram")
        /// Twidere X logo
        public static let twidere = L10n.tr("Localizable", "Accessibility.Common.Logo.Twidere")
        /// Twitter Logo
        public static let twitter = L10n.tr("Localizable", "Accessibility.Common.Logo.Twitter")
      }
      public enum Status {
        /// Location
        public static let location = L10n.tr("Localizable", "Accessibility.Common.Status.Location")
        /// Media
        public static let media = L10n.tr("Localizable", "Accessibility.Common.Status.Media")
        /// Retweeted
        public static let retweeted = L10n.tr("Localizable", "Accessibility.Common.Status.Retweeted")
        public enum Actions {
          /// Like
          public static let like = L10n.tr("Localizable", "Accessibility.Common.Status.Actions.Like")
          /// Reply
          public static let reply = L10n.tr("Localizable", "Accessibility.Common.Status.Actions.Reply")
          /// Retweet
          public static let retweet = L10n.tr("Localizable", "Accessibility.Common.Status.Actions.Retweet")
        }
      }
      public enum Video {
        /// Play video
        public static let play = L10n.tr("Localizable", "Accessibility.Common.Video.Play")
      }
    }
    public enum Scene {
      public enum Compose {
        /// Add mention
        public static let addMention = L10n.tr("Localizable", "Accessibility.Scene.Compose.AddMention")
        /// Open draft
        public static let draft = L10n.tr("Localizable", "Accessibility.Scene.Compose.Draft")
        /// Add image
        public static let image = L10n.tr("Localizable", "Accessibility.Scene.Compose.Image")
        /// Send
        public static let send = L10n.tr("Localizable", "Accessibility.Scene.Compose.Send")
        /// Thread mode
        public static let thread = L10n.tr("Localizable", "Accessibility.Scene.Compose.Thread")
        public enum Location {
          /// Disable location
          public static let disable = L10n.tr("Localizable", "Accessibility.Scene.Compose.Location.Disable")
          /// Enable location
          public static let enable = L10n.tr("Localizable", "Accessibility.Scene.Compose.Location.Enable")
        }
        public enum MediaInsert {
          /// Take Photo
          public static let camera = L10n.tr("Localizable", "Accessibility.Scene.Compose.MediaInsert.Camera")
          /// Add GIF
          public static let gif = L10n.tr("Localizable", "Accessibility.Scene.Compose.MediaInsert.Gif")
          /// Browse Library
          public static let library = L10n.tr("Localizable", "Accessibility.Scene.Compose.MediaInsert.Library")
          /// Record Video
          public static let recordVideo = L10n.tr("Localizable", "Accessibility.Scene.Compose.MediaInsert.RecordVideo")
        }
      }
      public enum Gif {
        /// Search GIF
        public static let search = L10n.tr("Localizable", "Accessibility.Scene.Gif.Search")
        /// GIPHY
        public static let title = L10n.tr("Localizable", "Accessibility.Scene.Gif.Title")
      }
      public enum Home {
        /// Compose
        public static let compose = L10n.tr("Localizable", "Accessibility.Scene.Home.Compose")
        /// Menu
        public static let menu = L10n.tr("Localizable", "Accessibility.Scene.Home.Menu")
        public enum Drawer {
          /// Account DropDown
          public static let accountDropdown = L10n.tr("Localizable", "Accessibility.Scene.Home.Drawer.AccountDropdown")
        }
      }
      public enum ManageAccounts {
        /// Add
        public static let add = L10n.tr("Localizable", "Accessibility.Scene.ManageAccounts.Add")
      }
      public enum Search {
        /// History
        public static let history = L10n.tr("Localizable", "Accessibility.Scene.Search.History")
        /// Save
        public static let save = L10n.tr("Localizable", "Accessibility.Scene.Search.Save")
      }
      public enum Settings {
        public enum Display {
          /// Font Size
          public static let fontSize = L10n.tr("Localizable", "Accessibility.Scene.Settings.Display.FontSize")
        }
      }
      public enum Timeline {
        /// Load
        public static let loadGap = L10n.tr("Localizable", "Accessibility.Scene.Timeline.LoadGap")
      }
      public enum User {
        /// Location
        public static let location = L10n.tr("Localizable", "Accessibility.Scene.User.Location")
        /// Website
        public static let website = L10n.tr("Localizable", "Accessibility.Scene.User.Website")
        public enum Tab {
          /// Favourite
          public static let favourite = L10n.tr("Localizable", "Accessibility.Scene.User.Tab.Favourite")
          /// Media
          public static let media = L10n.tr("Localizable", "Accessibility.Scene.User.Tab.Media")
          /// Statuses
          public static let status = L10n.tr("Localizable", "Accessibility.Scene.User.Tab.Status")
        }
      }
    }
  }

  public enum Common {
    public enum Alerts {
      public enum AccountSuspended {
        /// Twitter suspends accounts which violate the %@
        public static func message(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.AccountSuspended.Message", String(describing: p1))
        }
        /// Account Suspended
        public static let title = L10n.tr("Localizable", "Common.Alerts.AccountSuspended.Title")
        /// Twitter Rules
        public static let twitterRules = L10n.tr("Localizable", "Common.Alerts.AccountSuspended.TwitterRules")
      }
      public enum AccountTemporarilyLocked {
        /// Open Twitter to unlock
        public static let message = L10n.tr("Localizable", "Common.Alerts.AccountTemporarilyLocked.Message")
        /// Account Temporarily Locked
        public static let title = L10n.tr("Localizable", "Common.Alerts.AccountTemporarilyLocked.Title")
      }
      public enum BlockUserConfirm {
        /// Do you want to block %@?
        public static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.BlockUserConfirm.Title", String(describing: p1))
        }
      }
      public enum BlockUserSuccess {
        /// %@ has been blocked
        public static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.BlockUserSuccess.Title", String(describing: p1))
        }
      }
      public enum CancelFollowRequest {
        /// Cancel follow request for %@?
        public static func message(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.CancelFollowRequest.Message", String(describing: p1))
        }
      }
      public enum FailedToBlockUser {
        /// Please try again
        public static let message = L10n.tr("Localizable", "Common.Alerts.FailedToBlockUser.Message")
        /// Failed to block %@
        public static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.FailedToBlockUser.Title", String(describing: p1))
        }
      }
      public enum FailedToDeleteTweet {
        /// Please try again
        public static let message = L10n.tr("Localizable", "Common.Alerts.FailedToDeleteTweet.Message")
        /// Failed to Delete Tweet
        public static let title = L10n.tr("Localizable", "Common.Alerts.FailedToDeleteTweet.Title")
      }
      public enum FailedToFollowing {
        /// Please try again
        public static let message = L10n.tr("Localizable", "Common.Alerts.FailedToFollowing.Message")
        /// Failed to Following
        public static let title = L10n.tr("Localizable", "Common.Alerts.FailedToFollowing.Title")
      }
      public enum FailedToLoad {
        /// Please try again
        public static let message = L10n.tr("Localizable", "Common.Alerts.FailedToLoad.Message")
        /// Failed to Load
        public static let title = L10n.tr("Localizable", "Common.Alerts.FailedToLoad.Title")
      }
      public enum FailedToLoginMastodonServer {
        /// Server URL is incorrect.
        public static let message = L10n.tr("Localizable", "Common.Alerts.FailedToLoginMastodonServer.Message")
        /// Failed to Login
        public static let title = L10n.tr("Localizable", "Common.Alerts.FailedToLoginMastodonServer.Title")
      }
      public enum FailedToLoginTimeout {
        /// Connection timeout.
        public static let message = L10n.tr("Localizable", "Common.Alerts.FailedToLoginTimeout.Message")
        /// Failed to Login
        public static let title = L10n.tr("Localizable", "Common.Alerts.FailedToLoginTimeout.Title")
      }
      public enum FailedToMuteUser {
        /// Please try again
        public static let message = L10n.tr("Localizable", "Common.Alerts.FailedToMuteUser.Message")
        /// Failed to mute %@
        public static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.FailedToMuteUser.Title", String(describing: p1))
        }
      }
      public enum FailedToReportAndBlockUser {
        /// Please try again
        public static let message = L10n.tr("Localizable", "Common.Alerts.FailedToReportAndBlockUser.Message")
        /// Failed to report and block %@
        public static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.FailedToReportAndBlockUser.Title", String(describing: p1))
        }
      }
      public enum FailedToReportUser {
        /// Please try again
        public static let message = L10n.tr("Localizable", "Common.Alerts.FailedToReportUser.Message")
        /// Failed to report %@
        public static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.FailedToReportUser.Title", String(describing: p1))
        }
      }
      public enum FailedToSendMessage {
        /// Failed to send message
        public static let message = L10n.tr("Localizable", "Common.Alerts.FailedToSendMessage.Message")
        /// Sending message
        public static let title = L10n.tr("Localizable", "Common.Alerts.FailedToSendMessage.Title")
      }
      public enum FailedToUnblockUser {
        /// Please try again
        public static let message = L10n.tr("Localizable", "Common.Alerts.FailedToUnblockUser.Message")
        /// Failed to unblock %@
        public static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.FailedToUnblockUser.Title", String(describing: p1))
        }
      }
      public enum FailedToUnfollowing {
        /// Please try again
        public static let message = L10n.tr("Localizable", "Common.Alerts.FailedToUnfollowing.Message")
        /// Failed to Unfollowing
        public static let title = L10n.tr("Localizable", "Common.Alerts.FailedToUnfollowing.Title")
      }
      public enum FailedToUnmuteUser {
        /// Please try again
        public static let message = L10n.tr("Localizable", "Common.Alerts.FailedToUnmuteUser.Message")
        /// Failed to unmute %@
        public static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.FailedToUnmuteUser.Title", String(describing: p1))
        }
      }
      public enum FollowingRequestSent {
        /// Following Request Sent
        public static let title = L10n.tr("Localizable", "Common.Alerts.FollowingRequestSent.Title")
      }
      public enum FollowingSuccess {
        /// Following Succeeded
        public static let title = L10n.tr("Localizable", "Common.Alerts.FollowingSuccess.Title")
      }
      public enum MediaSaveFail {
        /// Please try again
        public static let message = L10n.tr("Localizable", "Common.Alerts.MediaSaveFail.Message")
        /// Failed to save media
        public static let title = L10n.tr("Localizable", "Common.Alerts.MediaSaveFail.Title")
      }
      public enum MediaSaved {
        /// Media saved
        public static let title = L10n.tr("Localizable", "Common.Alerts.MediaSaved.Title")
      }
      public enum MediaSaving {
        /// Saving media
        public static let title = L10n.tr("Localizable", "Common.Alerts.MediaSaving.Title")
      }
      public enum MediaSharing {
        /// Media will be shared after download is completed
        public static let title = L10n.tr("Localizable", "Common.Alerts.MediaSharing.Title")
      }
      public enum MuteUserConfirm {
        /// Do you want to mute %@?
        public static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.MuteUserConfirm.Title", String(describing: p1))
        }
      }
      public enum MuteUserSuccess {
        /// %@ has been muted
        public static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.MuteUserSuccess.Title", String(describing: p1))
        }
      }
      public enum NoTweetsFound {
        /// No Tweets Found
        public static let title = L10n.tr("Localizable", "Common.Alerts.NoTweetsFound.Title")
      }
      public enum PermissionDeniedFriendshipBlocked {
        /// You have been blocked from following this account at the request of the user
        public static let message = L10n.tr("Localizable", "Common.Alerts.PermissionDeniedFriendshipBlocked.Message")
        /// Permission Denied
        public static let title = L10n.tr("Localizable", "Common.Alerts.PermissionDeniedFriendshipBlocked.Title")
      }
      public enum PermissionDeniedNotAuthorized {
        /// Sorry, you are not authorized
        public static let message = L10n.tr("Localizable", "Common.Alerts.PermissionDeniedNotAuthorized.Message")
        /// Permission Denied
        public static let title = L10n.tr("Localizable", "Common.Alerts.PermissionDeniedNotAuthorized.Title")
      }
      public enum PhotoSaveFail {
        /// Please try again
        public static let message = L10n.tr("Localizable", "Common.Alerts.PhotoSaveFail.Message")
        /// Failed to Save Photo
        public static let title = L10n.tr("Localizable", "Common.Alerts.PhotoSaveFail.Title")
      }
      public enum PhotoSaved {
        /// Photo Saved
        public static let title = L10n.tr("Localizable", "Common.Alerts.PhotoSaved.Title")
      }
      public enum RateLimitExceeded {
        /// Reached Twitter API usage limit
        public static let message = L10n.tr("Localizable", "Common.Alerts.RateLimitExceeded.Message")
        /// Rate Limit Exceeded
        public static let title = L10n.tr("Localizable", "Common.Alerts.RateLimitExceeded.Title")
      }
      public enum ReportAndBlockUserSuccess {
        /// %@ has been reported for spam and blocked
        public static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.ReportAndBlockUserSuccess.Title", String(describing: p1))
        }
      }
      public enum ReportUserSuccess {
        /// %@ has been reported for spam
        public static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.ReportUserSuccess.Title", String(describing: p1))
        }
      }
      public enum TooManyRequests {
        /// Too Many Requests
        public static let title = L10n.tr("Localizable", "Common.Alerts.TooManyRequests.Title")
      }
      public enum TweetDeleted {
        /// Tweet Deleted
        public static let title = L10n.tr("Localizable", "Common.Alerts.TweetDeleted.Title")
      }
      public enum TweetFail {
        /// Please try again
        public static let message = L10n.tr("Localizable", "Common.Alerts.TweetFail.Message")
        /// Failed to Tweet
        public static let title = L10n.tr("Localizable", "Common.Alerts.TweetFail.Title")
      }
      public enum TweetSending {
        /// Sending tweet
        public static let title = L10n.tr("Localizable", "Common.Alerts.TweetSending.Title")
      }
      public enum TweetSent {
        /// Tweet Sent
        public static let title = L10n.tr("Localizable", "Common.Alerts.TweetSent.Title")
      }
      public enum UnblockUserConfirm {
        /// Do you want to unblock %@?
        public static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.UnblockUserConfirm.Title", String(describing: p1))
        }
      }
      public enum UnblockUserSuccess {
        /// %@ has been unblocked
        public static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.UnblockUserSuccess.Title", String(describing: p1))
        }
      }
      public enum UnfollowUser {
        /// Unfollow user %@?
        public static func message(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.UnfollowUser.Message", String(describing: p1))
        }
      }
      public enum UnfollowingSuccess {
        /// Unfollowing Succeeded
        public static let title = L10n.tr("Localizable", "Common.Alerts.UnfollowingSuccess.Title")
      }
      public enum UnmuteUserConfirm {
        /// Do you want to unmute %@?
        public static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.UnmuteUserConfirm.Title", String(describing: p1))
        }
      }
      public enum UnmuteUserSuccess {
        /// %@ has been unmuted
        public static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.UnmuteUserSuccess.Title", String(describing: p1))
        }
      }
    }
    public enum Controls {
      public enum Actions {
        /// Add
        public static let add = L10n.tr("Localizable", "Common.Controls.Actions.Add")
        /// Cancel
        public static let cancel = L10n.tr("Localizable", "Common.Controls.Actions.Cancel")
        /// Confirm
        public static let confirm = L10n.tr("Localizable", "Common.Controls.Actions.Confirm")
        /// Edit
        public static let edit = L10n.tr("Localizable", "Common.Controls.Actions.Edit")
        /// OK
        public static let ok = L10n.tr("Localizable", "Common.Controls.Actions.Ok")
        /// Open in Safari
        public static let openInSafari = L10n.tr("Localizable", "Common.Controls.Actions.OpenInSafari")
        /// Preview
        public static let preview = L10n.tr("Localizable", "Common.Controls.Actions.Preview")
        /// Remove
        public static let remove = L10n.tr("Localizable", "Common.Controls.Actions.Remove")
        /// Save
        public static let save = L10n.tr("Localizable", "Common.Controls.Actions.Save")
        /// Save photo
        public static let savePhoto = L10n.tr("Localizable", "Common.Controls.Actions.SavePhoto")
        /// Share media
        public static let shareMedia = L10n.tr("Localizable", "Common.Controls.Actions.ShareMedia")
        /// Sign in
        public static let signIn = L10n.tr("Localizable", "Common.Controls.Actions.SignIn")
        /// Take photo
        public static let takePhoto = L10n.tr("Localizable", "Common.Controls.Actions.TakePhoto")
        /// Yes
        public static let yes = L10n.tr("Localizable", "Common.Controls.Actions.Yes")
      }
      public enum Friendship {
        /// Block %@
        public static func blockUser(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Friendship.BlockUser", String(describing: p1))
        }
        /// follower
        public static let follower = L10n.tr("Localizable", "Common.Controls.Friendship.Follower")
        /// followers
        public static let followers = L10n.tr("Localizable", "Common.Controls.Friendship.Followers")
        /// Follows you
        public static let followsYou = L10n.tr("Localizable", "Common.Controls.Friendship.FollowsYou")
        /// Mute %@
        public static func muteUser(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Friendship.MuteUser", String(describing: p1))
        }
        /// %@ is following you
        public static func userIsFollowingYou(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Friendship.UserIsFollowingYou", String(describing: p1))
        }
        /// %@ is not following you
        public static func userIsNotFollowingYou(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Friendship.UserIsNotFollowingYou", String(describing: p1))
        }
        public enum Actions {
          /// Block
          public static let block = L10n.tr("Localizable", "Common.Controls.Friendship.Actions.Block")
          /// Blocked
          public static let blocked = L10n.tr("Localizable", "Common.Controls.Friendship.Actions.Blocked")
          /// Follow
          public static let follow = L10n.tr("Localizable", "Common.Controls.Friendship.Actions.Follow")
          /// Following
          public static let following = L10n.tr("Localizable", "Common.Controls.Friendship.Actions.Following")
          /// Mute
          public static let mute = L10n.tr("Localizable", "Common.Controls.Friendship.Actions.Mute")
          /// Pending
          public static let pending = L10n.tr("Localizable", "Common.Controls.Friendship.Actions.Pending")
          /// Report
          public static let report = L10n.tr("Localizable", "Common.Controls.Friendship.Actions.Report")
          /// Report and Block
          public static let reportAndBlock = L10n.tr("Localizable", "Common.Controls.Friendship.Actions.ReportAndBlock")
          /// Request
          public static let request = L10n.tr("Localizable", "Common.Controls.Friendship.Actions.Request")
          /// Unblock
          public static let unblock = L10n.tr("Localizable", "Common.Controls.Friendship.Actions.Unblock")
          /// Unfollow
          public static let unfollow = L10n.tr("Localizable", "Common.Controls.Friendship.Actions.Unfollow")
          /// Unmute
          public static let unmute = L10n.tr("Localizable", "Common.Controls.Friendship.Actions.Unmute")
        }
      }
      public enum Ios {
        /// Photo Library
        public static let photoLibrary = L10n.tr("Localizable", "Common.Controls.Ios.PhotoLibrary")
      }
      public enum ProfileDashboard {
        /// Followers
        public static let followers = L10n.tr("Localizable", "Common.Controls.ProfileDashboard.Followers")
        /// Following
        public static let following = L10n.tr("Localizable", "Common.Controls.ProfileDashboard.Following")
        /// Listed
        public static let listed = L10n.tr("Localizable", "Common.Controls.ProfileDashboard.Listed")
      }
      public enum Status {
        /// Media
        public static let media = L10n.tr("Localizable", "Common.Controls.Status.Media")
        /// %@ boosted
        public static func userBoosted(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Status.UserBoosted", String(describing: p1))
        }
        /// %@ retweeted
        public static func userRetweeted(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Status.UserRetweeted", String(describing: p1))
        }
        /// You boosted
        public static let youBoosted = L10n.tr("Localizable", "Common.Controls.Status.YouBoosted")
        /// You retweeted
        public static let youRetweeted = L10n.tr("Localizable", "Common.Controls.Status.YouRetweeted")
        public enum Actions {
          /// Bookmark
          public static let bookmark = L10n.tr("Localizable", "Common.Controls.Status.Actions.Bookmark")
          /// Copy link
          public static let copyLink = L10n.tr("Localizable", "Common.Controls.Status.Actions.CopyLink")
          /// Copy text
          public static let copyText = L10n.tr("Localizable", "Common.Controls.Status.Actions.CopyText")
          /// Delete tweet
          public static let deleteTweet = L10n.tr("Localizable", "Common.Controls.Status.Actions.DeleteTweet")
          /// Pin on Profile
          public static let pinOnProfile = L10n.tr("Localizable", "Common.Controls.Status.Actions.PinOnProfile")
          /// Quote
          public static let quote = L10n.tr("Localizable", "Common.Controls.Status.Actions.Quote")
          /// Retweet
          public static let retweet = L10n.tr("Localizable", "Common.Controls.Status.Actions.Retweet")
          /// Share
          public static let share = L10n.tr("Localizable", "Common.Controls.Status.Actions.Share")
          /// Share link
          public static let shareLink = L10n.tr("Localizable", "Common.Controls.Status.Actions.ShareLink")
          /// Translate
          public static let translate = L10n.tr("Localizable", "Common.Controls.Status.Actions.Translate")
          /// Unpin from Profile
          public static let unpinFromProfile = L10n.tr("Localizable", "Common.Controls.Status.Actions.UnpinFromProfile")
          /// Vote
          public static let vote = L10n.tr("Localizable", "Common.Controls.Status.Actions.Vote")
        }
        public enum Poll {
          /// Closed
          public static let expired = L10n.tr("Localizable", "Common.Controls.Status.Poll.Expired")
          /// %@ people
          public static func totalPeople(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Common.Controls.Status.Poll.TotalPeople", String(describing: p1))
          }
          /// %@ person
          public static func totalPerson(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Common.Controls.Status.Poll.TotalPerson", String(describing: p1))
          }
          /// %@ vote
          public static func totalVote(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Common.Controls.Status.Poll.TotalVote", String(describing: p1))
          }
          /// %@ votes
          public static func totalVotes(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Common.Controls.Status.Poll.TotalVotes", String(describing: p1))
          }
        }
        public enum Thread {
          /// Show this thread
          public static let show = L10n.tr("Localizable", "Common.Controls.Status.Thread.Show")
        }
      }
      public enum Timeline {
        /// Load More
        public static let loadMore = L10n.tr("Localizable", "Common.Controls.Timeline.LoadMore")
      }
    }
    public enum Countable {
      public enum Like {
        /// %@ likes
        public static func multiple(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Countable.Like.Multiple", String(describing: p1))
        }
        /// %@ like
        public static func single(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Countable.Like.Single", String(describing: p1))
        }
      }
      public enum List {
        /// %@ lists
        public static func multiple(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Countable.List.Multiple", String(describing: p1))
        }
        /// %@ list
        public static func single(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Countable.List.Single", String(describing: p1))
        }
      }
      public enum Member {
        /// %@ members
        public static func multiple(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Countable.Member.Multiple", String(describing: p1))
        }
        /// %@ member
        public static func single(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Countable.Member.Single", String(describing: p1))
        }
      }
      public enum Photo {
        /// %@ photos
        public static func multiple(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Countable.Photo.Multiple", String(describing: p1))
        }
        /// %@ photo
        public static func single(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Countable.Photo.Single", String(describing: p1))
        }
      }
      public enum Quote {
        /// %@ quotes
        public static func mutiple(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Countable.Quote.Mutiple", String(describing: p1))
        }
        /// %@ quote
        public static func single(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Countable.Quote.Single", String(describing: p1))
        }
      }
      public enum Reply {
        /// %@ replies
        public static func mutiple(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Countable.Reply.Mutiple", String(describing: p1))
        }
        /// %@ reply
        public static func single(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Countable.Reply.Single", String(describing: p1))
        }
      }
      public enum Retweet {
        /// %@ retweets
        public static func mutiple(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Countable.Retweet.Mutiple", String(describing: p1))
        }
        /// %@ retweet
        public static func single(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Countable.Retweet.Single", String(describing: p1))
        }
      }
      public enum Tweet {
        /// %@ tweets
        public static func multiple(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Countable.Tweet.Multiple", String(describing: p1))
        }
        /// %@ tweet
        public static func single(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Countable.Tweet.Single", String(describing: p1))
        }
      }
    }
    public enum Notification {
      /// %@ favourited your toot
      public static func favourite(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Common.Notification.Favourite", String(describing: p1))
      }
      /// %@ followed you
      public static func follow(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Common.Notification.Follow", String(describing: p1))
      }
      /// %@ has requested to follow you
      public static func followRequest(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Common.Notification.FollowRequest", String(describing: p1))
      }
      /// %@ mentions you
      public static func mentions(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Common.Notification.Mentions", String(describing: p1))
      }
      /// Your poll has ended
      public static let ownPoll = L10n.tr("Localizable", "Common.Notification.OwnPoll")
      /// A poll you have voted in has ended
      public static let poll = L10n.tr("Localizable", "Common.Notification.Poll")
      /// %@ boosted your toot
      public static func reblog(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Common.Notification.Reblog", String(describing: p1))
      }
      /// %@ just posted
      public static func status(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Common.Notification.Status", String(describing: p1))
      }
      public enum Messages {
        /// %@ sent you a message
        public static func content(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Notification.Messages.Content", String(describing: p1))
        }
        /// New direct message
        public static let title = L10n.tr("Localizable", "Common.Notification.Messages.Title")
      }
    }
    public enum NotificationChannel {
      public enum BackgroundProgresses {
        /// Background progresses
        public static let name = L10n.tr("Localizable", "Common.NotificationChannel.BackgroundProgresses.Name")
      }
      public enum ContentInteractions {
        /// Interactions like mentions and retweets
        public static let description = L10n.tr("Localizable", "Common.NotificationChannel.ContentInteractions.Description")
        /// Interactions
        public static let name = L10n.tr("Localizable", "Common.NotificationChannel.ContentInteractions.Name")
      }
      public enum ContentMessages {
        /// Direct messages
        public static let description = L10n.tr("Localizable", "Common.NotificationChannel.ContentMessages.Description")
        /// Messages
        public static let name = L10n.tr("Localizable", "Common.NotificationChannel.ContentMessages.Name")
      }
    }
  }

  public enum Scene {
    public enum Authentication {
      /// Authentication
      public static let title = L10n.tr("Localizable", "Scene.Authentication.Title")
    }
    public enum Bookmark {
      /// Bookmark
      public static let title = L10n.tr("Localizable", "Scene.Bookmark.Title")
    }
    public enum Compose {
      /// , 
      public static let and = L10n.tr("Localizable", "Scene.Compose.And")
      /// Write your warning here
      public static let cwPlaceholder = L10n.tr("Localizable", "Scene.Compose.CwPlaceholder")
      ///  and 
      public static let lastEnd = L10n.tr("Localizable", "Scene.Compose.LastEnd")
      /// Others in this conversation:
      public static let othersInThisConversation = L10n.tr("Localizable", "Scene.Compose.OthersInThisConversation")
      /// What’s happening?
      public static let placeholder = L10n.tr("Localizable", "Scene.Compose.Placeholder")
      /// Replying to
      public static let replyingTo = L10n.tr("Localizable", "Scene.Compose.ReplyingTo")
      /// Reply to …
      public static let replyTo = L10n.tr("Localizable", "Scene.Compose.ReplyTo")
      public enum SaveDraft {
        /// Save draft
        public static let action = L10n.tr("Localizable", "Scene.Compose.SaveDraft.Action")
        /// Save draft?
        public static let message = L10n.tr("Localizable", "Scene.Compose.SaveDraft.Message")
      }
      public enum Title {
        /// Compose
        public static let compose = L10n.tr("Localizable", "Scene.Compose.Title.Compose")
        /// Quote
        public static let quote = L10n.tr("Localizable", "Scene.Compose.Title.Quote")
        /// Reply
        public static let reply = L10n.tr("Localizable", "Scene.Compose.Title.Reply")
      }
      public enum Visibility {
        /// Direct
        public static let direct = L10n.tr("Localizable", "Scene.Compose.Visibility.Direct")
        /// Private
        public static let `private` = L10n.tr("Localizable", "Scene.Compose.Visibility.Private")
        /// Public
        public static let `public` = L10n.tr("Localizable", "Scene.Compose.Visibility.Public")
        /// Unlisted
        public static let unlisted = L10n.tr("Localizable", "Scene.Compose.Visibility.Unlisted")
      }
      public enum Vote {
        /// Multiple choice
        public static let multiple = L10n.tr("Localizable", "Scene.Compose.Vote.Multiple")
        public enum Expiration {
          /// 1 day
          public static let _1Day = L10n.tr("Localizable", "Scene.Compose.Vote.Expiration.1Day")
          /// 1 hour
          public static let _1Hour = L10n.tr("Localizable", "Scene.Compose.Vote.Expiration.1Hour")
          /// 30 minutes
          public static let _30Min = L10n.tr("Localizable", "Scene.Compose.Vote.Expiration.30Min")
          /// 3 days
          public static let _3Day = L10n.tr("Localizable", "Scene.Compose.Vote.Expiration.3Day")
          /// 5 minutes
          public static let _5Min = L10n.tr("Localizable", "Scene.Compose.Vote.Expiration.5Min")
          /// 6 hours
          public static let _6Hour = L10n.tr("Localizable", "Scene.Compose.Vote.Expiration.6Hour")
          /// 7 days
          public static let _7Day = L10n.tr("Localizable", "Scene.Compose.Vote.Expiration.7Day")
        }
      }
    }
    public enum ComposeHashtagSearch {
      /// Search hashtag
      public static let searchPlaceholder = L10n.tr("Localizable", "Scene.ComposeHashtagSearch.SearchPlaceholder")
    }
    public enum ComposeUserSearch {
      /// Search users
      public static let searchPlaceholder = L10n.tr("Localizable", "Scene.ComposeUserSearch.SearchPlaceholder")
    }
    public enum Drafts {
      /// Drafts
      public static let title = L10n.tr("Localizable", "Scene.Drafts.Title")
      public enum Actions {
        /// Delete draft
        public static let deleteDraft = L10n.tr("Localizable", "Scene.Drafts.Actions.DeleteDraft")
        /// Edit draft
        public static let editDraft = L10n.tr("Localizable", "Scene.Drafts.Actions.EditDraft")
      }
    }
    public enum Drawer {
      /// Manage accounts
      public static let manageAccounts = L10n.tr("Localizable", "Scene.Drawer.ManageAccounts")
      /// Sign in
      public static let signIn = L10n.tr("Localizable", "Scene.Drawer.SignIn")
    }
    public enum Federated {
      /// Federated
      public static let title = L10n.tr("Localizable", "Scene.Federated.Title")
    }
    public enum Followers {
      /// Followers
      public static let title = L10n.tr("Localizable", "Scene.Followers.Title")
    }
    public enum Following {
      /// Following
      public static let title = L10n.tr("Localizable", "Scene.Following.Title")
    }
    public enum Likes {
      /// Likes
      public static let title = L10n.tr("Localizable", "Scene.Likes.Title")
    }
    public enum Listed {
      /// Listed
      public static let title = L10n.tr("Localizable", "Scene.Listed.Title")
    }
    public enum Lists {
      /// Lists
      public static let title = L10n.tr("Localizable", "Scene.Lists.Title")
      public enum Icons {
        /// Create list
        public static let create = L10n.tr("Localizable", "Scene.Lists.Icons.Create")
        /// Private visibility
        public static let `private` = L10n.tr("Localizable", "Scene.Lists.Icons.Private")
      }
      public enum Tabs {
        /// MY LISTS
        public static let created = L10n.tr("Localizable", "Scene.Lists.Tabs.Created")
        /// SUBSCRIBED
        public static let subscribed = L10n.tr("Localizable", "Scene.Lists.Tabs.Subscribed")
      }
    }
    public enum ListsDetails {
      /// Add Members
      public static let addMembers = L10n.tr("Localizable", "Scene.ListsDetails.AddMembers")
      /// Delete this list: %@
      public static func deleteListConfirm(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Scene.ListsDetails.DeleteListConfirm", String(describing: p1))
      }
      /// Delete this list
      public static let deleteListTitle = L10n.tr("Localizable", "Scene.ListsDetails.DeleteListTitle")
      /// No Members Found.
      public static let noMembersFound = L10n.tr("Localizable", "Scene.ListsDetails.NoMembersFound")
      /// Lists Details
      public static let title = L10n.tr("Localizable", "Scene.ListsDetails.Title")
      public enum Descriptions {
        /// %d Members
        public static func multipleMembers(_ p1: Int) -> String {
          return L10n.tr("Localizable", "Scene.ListsDetails.Descriptions.MultipleMembers", p1)
        }
        /// %d Subscribers
        public static func multipleSubscribers(_ p1: Int) -> String {
          return L10n.tr("Localizable", "Scene.ListsDetails.Descriptions.MultipleSubscribers", p1)
        }
        /// 1 Member
        public static let singleMember = L10n.tr("Localizable", "Scene.ListsDetails.Descriptions.SingleMember")
        /// 1 Subscriber
        public static let singleSubscriber = L10n.tr("Localizable", "Scene.ListsDetails.Descriptions.SingleSubscriber")
      }
      public enum MenuActions {
        /// Add Member
        public static let addMember = L10n.tr("Localizable", "Scene.ListsDetails.MenuActions.AddMember")
        /// Delete List
        public static let deleteList = L10n.tr("Localizable", "Scene.ListsDetails.MenuActions.DeleteList")
        /// Edit List
        public static let editList = L10n.tr("Localizable", "Scene.ListsDetails.MenuActions.EditList")
        /// Follow
        public static let follow = L10n.tr("Localizable", "Scene.ListsDetails.MenuActions.Follow")
        /// Rename List
        public static let renameList = L10n.tr("Localizable", "Scene.ListsDetails.MenuActions.RenameList")
        /// Unfollow
        public static let unfollow = L10n.tr("Localizable", "Scene.ListsDetails.MenuActions.Unfollow")
      }
      public enum Tabs {
        /// List Members
        public static let members = L10n.tr("Localizable", "Scene.ListsDetails.Tabs.Members")
        /// Subscribers
        public static let subscriber = L10n.tr("Localizable", "Scene.ListsDetails.Tabs.Subscriber")
      }
    }
    public enum ListsModify {
      /// Description
      public static let description = L10n.tr("Localizable", "Scene.ListsModify.Description")
      /// Name
      public static let name = L10n.tr("Localizable", "Scene.ListsModify.Name")
      /// Private
      public static let `private` = L10n.tr("Localizable", "Scene.ListsModify.Private")
      public enum Create {
        /// New List
        public static let title = L10n.tr("Localizable", "Scene.ListsModify.Create.Title")
      }
      public enum Dialog {
        /// Create a list
        public static let create = L10n.tr("Localizable", "Scene.ListsModify.Dialog.Create")
        /// Rename the list
        public static let edit = L10n.tr("Localizable", "Scene.ListsModify.Dialog.Edit")
      }
      public enum Edit {
        /// Edit List
        public static let title = L10n.tr("Localizable", "Scene.ListsModify.Edit.Title")
      }
    }
    public enum ListsUsers {
      public enum Add {
        /// Search people
        public static let search = L10n.tr("Localizable", "Scene.ListsUsers.Add.Search")
        /// Add Member
        public static let title = L10n.tr("Localizable", "Scene.ListsUsers.Add.Title")
      }
      public enum MenuActions {
        /// Add
        public static let add = L10n.tr("Localizable", "Scene.ListsUsers.MenuActions.Add")
        /// Remove
        public static let remove = L10n.tr("Localizable", "Scene.ListsUsers.MenuActions.Remove")
      }
    }
    public enum Local {
      /// Local
      public static let title = L10n.tr("Localizable", "Scene.Local.Title")
    }
    public enum ManageAccounts {
      /// Delete account
      public static let deleteAccount = L10n.tr("Localizable", "Scene.ManageAccounts.DeleteAccount")
      /// Accounts
      public static let title = L10n.tr("Localizable", "Scene.ManageAccounts.Title")
    }
    public enum Mentions {
      /// Mentions
      public static let title = L10n.tr("Localizable", "Scene.Mentions.Title")
    }
    public enum Messages {
      /// Messages
      public static let title = L10n.tr("Localizable", "Scene.Messages.Title")
      public enum Action {
        /// Copy message text
        public static let copyText = L10n.tr("Localizable", "Scene.Messages.Action.CopyText")
        /// Delete message for you
        public static let delete = L10n.tr("Localizable", "Scene.Messages.Action.Delete")
      }
      public enum Error {
        /// The Current account does not support direct messages
        public static let notSupported = L10n.tr("Localizable", "Scene.Messages.Error.NotSupported")
      }
      public enum Expanded {
        /// [Photo]
        public static let photo = L10n.tr("Localizable", "Scene.Messages.Expanded.Photo")
      }
      public enum Icon {
        /// Send message failed
        public static let failed = L10n.tr("Localizable", "Scene.Messages.Icon.Failed")
      }
      public enum NewConversation {
        /// Search people
        public static let search = L10n.tr("Localizable", "Scene.Messages.NewConversation.Search")
        /// Find people
        public static let title = L10n.tr("Localizable", "Scene.Messages.NewConversation.Title")
      }
    }
    public enum Notification {
      /// Notification
      public static let title = L10n.tr("Localizable", "Scene.Notification.Title")
      public enum Tabs {
        /// All
        public static let all = L10n.tr("Localizable", "Scene.Notification.Tabs.All")
      }
    }
    public enum Profile {
      /// Hide reply
      public static let hideReply = L10n.tr("Localizable", "Scene.Profile.HideReply")
      /// Me
      public static let title = L10n.tr("Localizable", "Scene.Profile.Title")
      public enum Filter {
        /// All tweets
        public static let all = L10n.tr("Localizable", "Scene.Profile.Filter.All")
        /// Exclude replies
        public static let excludeReplies = L10n.tr("Localizable", "Scene.Profile.Filter.ExcludeReplies")
      }
      public enum PermissionDeniedProfileBlocked {
        /// You have been blocked from viewing this user’s profile.
        public static let message = L10n.tr("Localizable", "Scene.Profile.PermissionDeniedProfileBlocked.Message")
        /// Permission Denied
        public static let title = L10n.tr("Localizable", "Scene.Profile.PermissionDeniedProfileBlocked.Title")
      }
    }
    public enum Search {
      /// Saved Search
      public static let savedSearch = L10n.tr("Localizable", "Scene.Search.SavedSearch")
      /// Show less
      public static let showLess = L10n.tr("Localizable", "Scene.Search.ShowLess")
      /// Show more
      public static let showMore = L10n.tr("Localizable", "Scene.Search.ShowMore")
      /// Search
      public static let title = L10n.tr("Localizable", "Scene.Search.Title")
      public enum SearchBar {
        /// Search tweets or users
        public static let placeholder = L10n.tr("Localizable", "Scene.Search.SearchBar.Placeholder")
      }
      public enum Tabs {
        /// Hashtag
        public static let hashtag = L10n.tr("Localizable", "Scene.Search.Tabs.Hashtag")
        /// Media
        public static let media = L10n.tr("Localizable", "Scene.Search.Tabs.Media")
        /// People
        public static let people = L10n.tr("Localizable", "Scene.Search.Tabs.People")
        /// Toots
        public static let toots = L10n.tr("Localizable", "Scene.Search.Tabs.Toots")
        /// Tweets
        public static let tweets = L10n.tr("Localizable", "Scene.Search.Tabs.Tweets")
        /// Users
        public static let users = L10n.tr("Localizable", "Scene.Search.Tabs.Users")
      }
    }
    public enum Settings {
      /// Settings
      public static let title = L10n.tr("Localizable", "Scene.Settings.Title")
      public enum About {
        /// Next generation of Twidere for Android 5.0+. \nStill in early stage.
        public static let description = L10n.tr("Localizable", "Scene.Settings.About.Description")
        /// License
        public static let license = L10n.tr("Localizable", "Scene.Settings.About.License")
        /// About
        public static let title = L10n.tr("Localizable", "Scene.Settings.About.Title")
        /// Ver %@
        public static func version(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Scene.Settings.About.Version", String(describing: p1))
        }
        public enum Logo {
          /// About page background logo
          public static let background = L10n.tr("Localizable", "Scene.Settings.About.Logo.Background")
          /// About page background logo shadow
          public static let backgroundShadow = L10n.tr("Localizable", "Scene.Settings.About.Logo.BackgroundShadow")
        }
      }
      public enum Appearance {
        /// AMOLED optimized mode
        public static let amoledOptimizedMode = L10n.tr("Localizable", "Scene.Settings.Appearance.AmoledOptimizedMode")
        /// Highlight color
        public static let highlightColor = L10n.tr("Localizable", "Scene.Settings.Appearance.HighlightColor")
        /// Pick color
        public static let pickColor = L10n.tr("Localizable", "Scene.Settings.Appearance.PickColor")
        /// Appearance
        public static let title = L10n.tr("Localizable", "Scene.Settings.Appearance.Title")
        public enum ScrollingTimeline {
          /// Hide app bar when scrolling
          public static let appBar = L10n.tr("Localizable", "Scene.Settings.Appearance.ScrollingTimeline.AppBar")
          /// Hide FAB when scrolling
          public static let fab = L10n.tr("Localizable", "Scene.Settings.Appearance.ScrollingTimeline.Fab")
          /// Hide tab bar when scrolling
          public static let tabBar = L10n.tr("Localizable", "Scene.Settings.Appearance.ScrollingTimeline.TabBar")
        }
        public enum SectionHeader {
          /// Scrolling timeline
          public static let scrollingTimeline = L10n.tr("Localizable", "Scene.Settings.Appearance.SectionHeader.ScrollingTimeline")
          /// Tab position
          public static let tabPosition = L10n.tr("Localizable", "Scene.Settings.Appearance.SectionHeader.TabPosition")
          /// Theme
          public static let theme = L10n.tr("Localizable", "Scene.Settings.Appearance.SectionHeader.Theme")
        }
        public enum TabPosition {
          /// Bottom
          public static let bottom = L10n.tr("Localizable", "Scene.Settings.Appearance.TabPosition.Bottom")
          /// Top
          public static let top = L10n.tr("Localizable", "Scene.Settings.Appearance.TabPosition.Top")
        }
        public enum Theme {
          /// Auto
          public static let auto = L10n.tr("Localizable", "Scene.Settings.Appearance.Theme.Auto")
          /// Dark
          public static let dark = L10n.tr("Localizable", "Scene.Settings.Appearance.Theme.Dark")
          /// Light
          public static let light = L10n.tr("Localizable", "Scene.Settings.Appearance.Theme.Light")
        }
      }
      public enum Display {
        /// Display
        public static let title = L10n.tr("Localizable", "Scene.Settings.Display.Title")
        /// Url previews
        public static let urlPreview = L10n.tr("Localizable", "Scene.Settings.Display.UrlPreview")
        public enum DateFormat {
          /// Absolute
          public static let absolute = L10n.tr("Localizable", "Scene.Settings.Display.DateFormat.Absolute")
          /// Relative
          public static let relative = L10n.tr("Localizable", "Scene.Settings.Display.DateFormat.Relative")
        }
        public enum Media {
          /// Always
          public static let always = L10n.tr("Localizable", "Scene.Settings.Display.Media.Always")
          /// Automatic
          public static let automatic = L10n.tr("Localizable", "Scene.Settings.Display.Media.Automatic")
          /// Auto playback
          public static let autoPlayback = L10n.tr("Localizable", "Scene.Settings.Display.Media.AutoPlayback")
          /// Media previews
          public static let mediaPreviews = L10n.tr("Localizable", "Scene.Settings.Display.Media.MediaPreviews")
          /// Mute by default
          public static let muteByDefault = L10n.tr("Localizable", "Scene.Settings.Display.Media.MuteByDefault")
          /// Off
          public static let off = L10n.tr("Localizable", "Scene.Settings.Display.Media.Off")
        }
        public enum Preview {
          /// Thanks for using @TwidereProject!
          public static let thankForUsingTwidereX = L10n.tr("Localizable", "Scene.Settings.Display.Preview.ThankForUsingTwidereX")
        }
        public enum SectionHeader {
          /// Date Format
          public static let dateFormat = L10n.tr("Localizable", "Scene.Settings.Display.SectionHeader.DateFormat")
          /// Media
          public static let media = L10n.tr("Localizable", "Scene.Settings.Display.SectionHeader.Media")
          /// Preview
          public static let preview = L10n.tr("Localizable", "Scene.Settings.Display.SectionHeader.Preview")
          /// Text
          public static let text = L10n.tr("Localizable", "Scene.Settings.Display.SectionHeader.Text")
        }
        public enum Text {
          /// Avatar Style
          public static let avatarStyle = L10n.tr("Localizable", "Scene.Settings.Display.Text.AvatarStyle")
          /// Circle
          public static let circle = L10n.tr("Localizable", "Scene.Settings.Display.Text.Circle")
          /// Rounded Square
          public static let roundedSquare = L10n.tr("Localizable", "Scene.Settings.Display.Text.RoundedSquare")
          /// Use the system font size
          public static let useTheSystemFontSize = L10n.tr("Localizable", "Scene.Settings.Display.Text.UseTheSystemFontSize")
        }
      }
      public enum Layout {
        /// Layout
        public static let title = L10n.tr("Localizable", "Scene.Settings.Layout.Title")
        public enum Actions {
          /// Drawer actions
          public static let drawer = L10n.tr("Localizable", "Scene.Settings.Layout.Actions.Drawer")
          /// Tabbar actions
          public static let tabbar = L10n.tr("Localizable", "Scene.Settings.Layout.Actions.Tabbar")
        }
        public enum Desc {
          /// Choose and arrange up to 5 actions that will appear on the tabbar (The local and federal timelines will only be displayed in Mastodon.)
          public static let content = L10n.tr("Localizable", "Scene.Settings.Layout.Desc.Content")
          /// Custom Layout
          public static let title = L10n.tr("Localizable", "Scene.Settings.Layout.Desc.Title")
        }
      }
      public enum Misc {
        /// Misc
        public static let title = L10n.tr("Localizable", "Scene.Settings.Misc.Title")
        public enum Nitter {
          /// Third-party Twitter data provider
          public static let title = L10n.tr("Localizable", "Scene.Settings.Misc.Nitter.Title")
          public enum Dialog {
            public enum Information {
              /// Due to the limitation of Twitter API, some data might not be able to fetch from Twitter, you can use a third-party data provider to provide these data. Twidere does not take any responsibility for them.
              public static let content = L10n.tr("Localizable", "Scene.Settings.Misc.Nitter.Dialog.Information.Content")
              /// Third party Twitter data provider
              public static let title = L10n.tr("Localizable", "Scene.Settings.Misc.Nitter.Dialog.Information.Title")
            }
            public enum Usage {
              /// - Twitter status threading
              public static let content = L10n.tr("Localizable", "Scene.Settings.Misc.Nitter.Dialog.Usage.Content")
              /// Project URL
              public static let projectButton = L10n.tr("Localizable", "Scene.Settings.Misc.Nitter.Dialog.Usage.ProjectButton")
              /// Using Third-party data provider in
              public static let title = L10n.tr("Localizable", "Scene.Settings.Misc.Nitter.Dialog.Usage.Title")
            }
          }
          public enum Input {
            /// Alternative Twitter front-end focused on privacy.
            public static let description = L10n.tr("Localizable", "Scene.Settings.Misc.Nitter.Input.Description")
            /// Nitter Instance
            public static let placeholder = L10n.tr("Localizable", "Scene.Settings.Misc.Nitter.Input.Placeholder")
          }
        }
        public enum Proxy {
          /// Password
          public static let password = L10n.tr("Localizable", "Scene.Settings.Misc.Proxy.Password")
          /// Server
          public static let server = L10n.tr("Localizable", "Scene.Settings.Misc.Proxy.Server")
          /// Proxy settings
          public static let title = L10n.tr("Localizable", "Scene.Settings.Misc.Proxy.Title")
          /// Username
          public static let username = L10n.tr("Localizable", "Scene.Settings.Misc.Proxy.Username")
          public enum Enable {
            /// Use proxy for all network requests
            public static let description = L10n.tr("Localizable", "Scene.Settings.Misc.Proxy.Enable.Description")
            /// Proxy
            public static let title = L10n.tr("Localizable", "Scene.Settings.Misc.Proxy.Enable.Title")
          }
          public enum Port {
            /// Proxy server port must be numbers
            public static let error = L10n.tr("Localizable", "Scene.Settings.Misc.Proxy.Port.Error")
            /// Port
            public static let title = L10n.tr("Localizable", "Scene.Settings.Misc.Proxy.Port.Title")
          }
          public enum `Type` {
            /// HTTP
            public static let http = L10n.tr("Localizable", "Scene.Settings.Misc.Proxy.Type.Http")
            /// Reverse
            public static let reverse = L10n.tr("Localizable", "Scene.Settings.Misc.Proxy.Type.Reverse")
            /// Proxy type
            public static let title = L10n.tr("Localizable", "Scene.Settings.Misc.Proxy.Type.Title")
          }
        }
      }
      public enum Notification {
        /// Accounts
        public static let accounts = L10n.tr("Localizable", "Scene.Settings.Notification.Accounts")
        /// Show Notification
        public static let notificationSwitch = L10n.tr("Localizable", "Scene.Settings.Notification.NotificationSwitch")
        /// Notification
        public static let title = L10n.tr("Localizable", "Scene.Settings.Notification.Title")
      }
      public enum SectionHeader {
        /// About
        public static let about = L10n.tr("Localizable", "Scene.Settings.SectionHeader.About")
        /// General
        public static let general = L10n.tr("Localizable", "Scene.Settings.SectionHeader.General")
      }
      public enum Storage {
        /// Storage
        public static let title = L10n.tr("Localizable", "Scene.Settings.Storage.Title")
        public enum All {
          /// Delete all Twidere X cache. Your account credentials will not be lost.
          public static let subTitle = L10n.tr("Localizable", "Scene.Settings.Storage.All.SubTitle")
          /// Clear all cache
          public static let title = L10n.tr("Localizable", "Scene.Settings.Storage.All.Title")
        }
        public enum Media {
          /// Clear stored media cache.
          public static let subTitle = L10n.tr("Localizable", "Scene.Settings.Storage.Media.SubTitle")
          /// Clear media cache
          public static let title = L10n.tr("Localizable", "Scene.Settings.Storage.Media.Title")
        }
        public enum Search {
          /// Clear search history
          public static let title = L10n.tr("Localizable", "Scene.Settings.Storage.Search.Title")
        }
      }
    }
    public enum SignIn {
      /// Hello!\nSign in to Get Started.
      public static let helloSignInToGetStarted = L10n.tr("Localizable", "Scene.SignIn.HelloSignInToGetStarted")
      /// Sign in with Mastodon
      public static let signInWithMastodon = L10n.tr("Localizable", "Scene.SignIn.SignInWithMastodon")
      /// Sign in with Twitter
      public static let signInWithTwitter = L10n.tr("Localizable", "Scene.SignIn.SignInWithTwitter")
      public enum TwitterOptions {
        /// Sign in with Custom Twitter Key
        public static let signInWithCustomTwitterKey = L10n.tr("Localizable", "Scene.SignIn.TwitterOptions.SignInWithCustomTwitterKey")
        /// Twitter API v2 access is required.
        public static let twitterApiV2AccessIsRequired = L10n.tr("Localizable", "Scene.SignIn.TwitterOptions.TwitterApiV2AccessIsRequired")
      }
    }
    public enum Status {
      /// Tweet
      public static let title = L10n.tr("Localizable", "Scene.Status.Title")
      /// Toot
      public static let titleMastodon = L10n.tr("Localizable", "Scene.Status.TitleMastodon")
      public enum Like {
        /// %d Likes
        public static func multiple(_ p1: Int) -> String {
          return L10n.tr("Localizable", "Scene.Status.Like.Multiple", p1)
        }
        /// 1 Like
        public static let single = L10n.tr("Localizable", "Scene.Status.Like.Single")
      }
      public enum Quote {
        /// %d Quotes
        public static func mutiple(_ p1: Int) -> String {
          return L10n.tr("Localizable", "Scene.Status.Quote.Mutiple", p1)
        }
        /// 1 Quote
        public static let single = L10n.tr("Localizable", "Scene.Status.Quote.Single")
      }
      public enum Reply {
        /// %d Replies
        public static func mutiple(_ p1: Int) -> String {
          return L10n.tr("Localizable", "Scene.Status.Reply.Mutiple", p1)
        }
        /// 1 Reply
        public static let single = L10n.tr("Localizable", "Scene.Status.Reply.Single")
      }
      public enum Retweet {
        /// %d Retweets
        public static func mutiple(_ p1: Int) -> String {
          return L10n.tr("Localizable", "Scene.Status.Retweet.Mutiple", p1)
        }
        /// 1 Retweet
        public static let single = L10n.tr("Localizable", "Scene.Status.Retweet.Single")
      }
    }
    public enum Timeline {
      /// Timeline
      public static let title = L10n.tr("Localizable", "Scene.Timeline.Title")
    }
    public enum Trends {
      /// %d people talking
      public static func accounts(_ p1: Int) -> String {
        return L10n.tr("Localizable", "Scene.Trends.Accounts", p1)
      }
      /// Trending Now
      public static let now = L10n.tr("Localizable", "Scene.Trends.Now")
      /// Trends
      public static let title = L10n.tr("Localizable", "Scene.Trends.Title")
      /// Trends - Worldwide
      public static let worldWide = L10n.tr("Localizable", "Scene.Trends.WorldWide")
    }
  }

  public enum Count {
    public enum People {
      /// Plural format key: "%#@count_people_talking@"
      public static func talking(_ p1: Int) -> String {
        return L10n.tr("Localizable", "count.people.talking", p1)
      }
    }
  }

  public enum Date {
    public enum Day {
      /// Plural format key: "%#@count_day_left@"
      public static func `left`(_ p1: Int) -> String {
        return L10n.tr("Localizable", "date.day.left", p1)
      }
    }
    public enum Hour {
      /// Plural format key: "%#@count_hour_left@"
      public static func `left`(_ p1: Int) -> String {
        return L10n.tr("Localizable", "date.hour.left", p1)
      }
    }
    public enum Minute {
      /// Plural format key: "%#@count_minute_left@"
      public static func `left`(_ p1: Int) -> String {
        return L10n.tr("Localizable", "date.minute.left", p1)
      }
    }
    public enum Month {
      /// Plural format key: "%#@count_month_left@"
      public static func `left`(_ p1: Int) -> String {
        return L10n.tr("Localizable", "date.month.left", p1)
      }
    }
    public enum Second {
      /// Plural format key: "%#@count_second_left@"
      public static func `left`(_ p1: Int) -> String {
        return L10n.tr("Localizable", "date.second.left", p1)
      }
    }
    public enum Year {
      /// Plural format key: "%#@count_year_left@"
      public static func `left`(_ p1: Int) -> String {
        return L10n.tr("Localizable", "date.year.left", p1)
      }
    }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    let format = Bundle.module.localizedString(forKey: key, value: nil, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}
