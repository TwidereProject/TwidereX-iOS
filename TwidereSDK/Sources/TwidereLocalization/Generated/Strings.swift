// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
public enum L10n {
  public enum Accessibility {
    public enum Common {
      /// Back
      public static let back = L10n.tr("Localizable", "Accessibility.Common.Back", fallback: "Back")
      /// Close
      public static let close = L10n.tr("Localizable", "Accessibility.Common.Close", fallback: "Close")
      /// Done
      public static let done = L10n.tr("Localizable", "Accessibility.Common.Done", fallback: "Done")
      /// More
      public static let more = L10n.tr("Localizable", "Accessibility.Common.More", fallback: "More")
      /// Network Image
      public static let networkImage = L10n.tr("Localizable", "Accessibility.Common.NetworkImage", fallback: "Network Image")
      public enum Logo {
        /// Github Logo
        public static let github = L10n.tr("Localizable", "Accessibility.Common.Logo.Github", fallback: "Github Logo")
        /// Mastodon Logo
        public static let mastodon = L10n.tr("Localizable", "Accessibility.Common.Logo.Mastodon", fallback: "Mastodon Logo")
        /// Telegram Logo
        public static let telegram = L10n.tr("Localizable", "Accessibility.Common.Logo.Telegram", fallback: "Telegram Logo")
        /// Twidere X logo
        public static let twidere = L10n.tr("Localizable", "Accessibility.Common.Logo.Twidere", fallback: "Twidere X logo")
        /// Twitter Logo
        public static let twitter = L10n.tr("Localizable", "Accessibility.Common.Logo.Twitter", fallback: "Twitter Logo")
      }
      public enum Status {
        /// Author avatar
        public static let authorAvatar = L10n.tr("Localizable", "Accessibility.Common.Status.AuthorAvatar", fallback: "Author avatar")
        /// Boosted
        public static let boosted = L10n.tr("Localizable", "Accessibility.Common.Status.Boosted", fallback: "Boosted")
        /// Content Warning
        public static let contentWarning = L10n.tr("Localizable", "Accessibility.Common.Status.ContentWarning", fallback: "Content Warning")
        /// Liked
        public static let liked = L10n.tr("Localizable", "Accessibility.Common.Status.Liked", fallback: "Liked")
        /// Location
        public static let location = L10n.tr("Localizable", "Accessibility.Common.Status.Location", fallback: "Location")
        /// Media
        public static let media = L10n.tr("Localizable", "Accessibility.Common.Status.Media", fallback: "Media")
        /// Poll option
        public static let pollOptionOrdinalPrefix = L10n.tr("Localizable", "Accessibility.Common.Status.PollOptionOrdinalPrefix", fallback: "Poll option")
        /// Retweeted
        public static let retweeted = L10n.tr("Localizable", "Accessibility.Common.Status.Retweeted", fallback: "Retweeted")
        public enum Actions {
          /// Hide content
          public static let hideContent = L10n.tr("Localizable", "Accessibility.Common.Status.Actions.HideContent", fallback: "Hide content")
          /// Hide media
          public static let hideMedia = L10n.tr("Localizable", "Accessibility.Common.Status.Actions.HideMedia", fallback: "Hide media")
          /// Like
          public static let like = L10n.tr("Localizable", "Accessibility.Common.Status.Actions.Like", fallback: "Like")
          /// Menu
          public static let menu = L10n.tr("Localizable", "Accessibility.Common.Status.Actions.Menu", fallback: "Menu")
          /// Reply
          public static let reply = L10n.tr("Localizable", "Accessibility.Common.Status.Actions.Reply", fallback: "Reply")
          /// Retweet
          public static let retweet = L10n.tr("Localizable", "Accessibility.Common.Status.Actions.Retweet", fallback: "Retweet")
          /// Reveal content
          public static let revealContent = L10n.tr("Localizable", "Accessibility.Common.Status.Actions.RevealContent", fallback: "Reveal content")
          /// Reveal media
          public static let revealMedia = L10n.tr("Localizable", "Accessibility.Common.Status.Actions.RevealMedia", fallback: "Reveal media")
        }
      }
      public enum Video {
        /// Play video
        public static let play = L10n.tr("Localizable", "Accessibility.Common.Video.Play", fallback: "Play video")
      }
    }
    public enum Scene {
      public enum Compose {
        /// Add mention
        public static let addMention = L10n.tr("Localizable", "Accessibility.Scene.Compose.AddMention", fallback: "Add mention")
        /// Open draft
        public static let draft = L10n.tr("Localizable", "Accessibility.Scene.Compose.Draft", fallback: "Open draft")
        /// Add image
        public static let image = L10n.tr("Localizable", "Accessibility.Scene.Compose.Image", fallback: "Add image")
        /// Send
        public static let send = L10n.tr("Localizable", "Accessibility.Scene.Compose.Send", fallback: "Send")
        /// Thread mode
        public static let thread = L10n.tr("Localizable", "Accessibility.Scene.Compose.Thread", fallback: "Thread mode")
        public enum Location {
          /// Disable location
          public static let disable = L10n.tr("Localizable", "Accessibility.Scene.Compose.Location.Disable", fallback: "Disable location")
          /// Enable location
          public static let enable = L10n.tr("Localizable", "Accessibility.Scene.Compose.Location.Enable", fallback: "Enable location")
        }
        public enum MediaInsert {
          /// Take Photo
          public static let camera = L10n.tr("Localizable", "Accessibility.Scene.Compose.MediaInsert.Camera", fallback: "Take Photo")
          /// Add GIF
          public static let gif = L10n.tr("Localizable", "Accessibility.Scene.Compose.MediaInsert.Gif", fallback: "Add GIF")
          /// Browse Library
          public static let library = L10n.tr("Localizable", "Accessibility.Scene.Compose.MediaInsert.Library", fallback: "Browse Library")
          /// Record Video
          public static let recordVideo = L10n.tr("Localizable", "Accessibility.Scene.Compose.MediaInsert.RecordVideo", fallback: "Record Video")
        }
      }
      public enum Gif {
        /// Search GIF
        public static let search = L10n.tr("Localizable", "Accessibility.Scene.Gif.Search", fallback: "Search GIF")
        /// GIPHY
        public static let title = L10n.tr("Localizable", "Accessibility.Scene.Gif.Title", fallback: "GIPHY")
      }
      public enum Home {
        /// Compose
        public static let compose = L10n.tr("Localizable", "Accessibility.Scene.Home.Compose", fallback: "Compose")
        /// Menu
        public static let menu = L10n.tr("Localizable", "Accessibility.Scene.Home.Menu", fallback: "Menu")
        public enum Drawer {
          /// Account DropDown
          public static let accountDropdown = L10n.tr("Localizable", "Accessibility.Scene.Home.Drawer.AccountDropdown", fallback: "Account DropDown")
        }
      }
      public enum ManageAccounts {
        /// Add
        public static let add = L10n.tr("Localizable", "Accessibility.Scene.ManageAccounts.Add", fallback: "Add")
        /// Current sign-in user: %@
        public static func currentSignInUser(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Accessibility.Scene.ManageAccounts.CurrentSignInUser", String(describing: p1), fallback: "Current sign-in user: %@")
        }
      }
      public enum Search {
        /// History
        public static let history = L10n.tr("Localizable", "Accessibility.Scene.Search.History", fallback: "History")
        /// Save
        public static let save = L10n.tr("Localizable", "Accessibility.Scene.Search.Save", fallback: "Save")
      }
      public enum Settings {
        public enum Display {
          /// Font Size
          public static let fontSize = L10n.tr("Localizable", "Accessibility.Scene.Settings.Display.FontSize", fallback: "Font Size")
        }
      }
      public enum SignIn {
        /// Please enter Mastodon domain to sign-in
        public static let pleaseEnterMastodonDomainToSignIn = L10n.tr("Localizable", "Accessibility.Scene.SignIn.PleaseEnterMastodonDomainToSignIn", fallback: "Please enter Mastodon domain to sign-in")
        /// Twitter client authentication key setting
        public static let twitterClientAuthenticationKeySetting = L10n.tr("Localizable", "Accessibility.Scene.SignIn.TwitterClientAuthenticationKeySetting", fallback: "Twitter client authentication key setting")
      }
      public enum Timeline {
        /// Load
        public static let loadGap = L10n.tr("Localizable", "Accessibility.Scene.Timeline.LoadGap", fallback: "Load")
      }
      public enum User {
        /// Location
        public static let location = L10n.tr("Localizable", "Accessibility.Scene.User.Location", fallback: "Location")
        /// Website
        public static let website = L10n.tr("Localizable", "Accessibility.Scene.User.Website", fallback: "Website")
        public enum Tab {
          /// Favourite
          public static let favourite = L10n.tr("Localizable", "Accessibility.Scene.User.Tab.Favourite", fallback: "Favourite")
          /// Media
          public static let media = L10n.tr("Localizable", "Accessibility.Scene.User.Tab.Media", fallback: "Media")
          /// Statuses
          public static let status = L10n.tr("Localizable", "Accessibility.Scene.User.Tab.Status", fallback: "Statuses")
        }
      }
    }
    public enum VoiceOver {
      /// Double tap and hold to display menu
      public static let doubleTapAndHoldToDisplayMenu = L10n.tr("Localizable", "Accessibility.VoiceOver.DoubleTapAndHoldToDisplayMenu", fallback: "Double tap and hold to display menu")
      /// Double tap and hold to open the accounts panel
      public static let doubleTapAndHoldToOpenTheAccountsPanel = L10n.tr("Localizable", "Accessibility.VoiceOver.DoubleTapAndHoldToOpenTheAccountsPanel", fallback: "Double tap and hold to open the accounts panel")
      /// Double tap to open profile
      public static let doubleTapToOpenProfile = L10n.tr("Localizable", "Accessibility.VoiceOver.DoubleTapToOpenProfile", fallback: "Double tap to open profile")
      /// Selected
      public static let selected = L10n.tr("Localizable", "Accessibility.VoiceOver.Selected", fallback: "Selected")
    }
  }
  public enum Common {
    public enum Alerts {
      public enum AccountSuspended {
        /// Twitter suspends accounts which violate the %@
        public static func message(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.AccountSuspended.Message", String(describing: p1), fallback: "Twitter suspends accounts which violate the %@")
        }
        /// Account Suspended
        public static let title = L10n.tr("Localizable", "Common.Alerts.AccountSuspended.Title", fallback: "Account Suspended")
        /// Twitter Rules
        public static let twitterRules = L10n.tr("Localizable", "Common.Alerts.AccountSuspended.TwitterRules", fallback: "Twitter Rules")
      }
      public enum AccountTemporarilyLocked {
        /// Open Twitter to unlock
        public static let message = L10n.tr("Localizable", "Common.Alerts.AccountTemporarilyLocked.Message", fallback: "Open Twitter to unlock")
        /// Account Temporarily Locked
        public static let title = L10n.tr("Localizable", "Common.Alerts.AccountTemporarilyLocked.Title", fallback: "Account Temporarily Locked")
      }
      public enum BlockUserConfirm {
        /// Do you want to block %@?
        public static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.BlockUserConfirm.Title", String(describing: p1), fallback: "Do you want to block %@?")
        }
      }
      public enum BlockUserSuccess {
        /// %@ has been blocked
        public static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.BlockUserSuccess.Title", String(describing: p1), fallback: "%@ has been blocked")
        }
      }
      public enum CancelFollowRequest {
        /// Cancel follow request for %@?
        public static func message(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.CancelFollowRequest.Message", String(describing: p1), fallback: "Cancel follow request for %@?")
        }
      }
      public enum DeleteTootConfirm {
        /// Do you want to delete this toot?
        public static let message = L10n.tr("Localizable", "Common.Alerts.DeleteTootConfirm.Message", fallback: "Do you want to delete this toot?")
        /// Delete Toot
        public static let title = L10n.tr("Localizable", "Common.Alerts.DeleteTootConfirm.Title", fallback: "Delete Toot")
      }
      public enum DeleteTweetConfirm {
        /// Do you want to delete this tweet?
        public static let message = L10n.tr("Localizable", "Common.Alerts.DeleteTweetConfirm.Message", fallback: "Do you want to delete this tweet?")
        /// Delete Tweet
        public static let title = L10n.tr("Localizable", "Common.Alerts.DeleteTweetConfirm.Title", fallback: "Delete Tweet")
      }
      public enum FailedToAddListMember {
        /// Please try again
        public static let message = L10n.tr("Localizable", "Common.Alerts.FailedToAddListMember.Message", fallback: "Please try again")
        /// Failed to Add List Member
        public static let title = L10n.tr("Localizable", "Common.Alerts.FailedToAddListMember.Title", fallback: "Failed to Add List Member")
      }
      public enum FailedToBlockUser {
        /// Please try again
        public static let message = L10n.tr("Localizable", "Common.Alerts.FailedToBlockUser.Message", fallback: "Please try again")
        /// Failed to block %@
        public static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.FailedToBlockUser.Title", String(describing: p1), fallback: "Failed to block %@")
        }
      }
      public enum FailedToDeleteList {
        /// Please try again
        public static let message = L10n.tr("Localizable", "Common.Alerts.FailedToDeleteList.Message", fallback: "Please try again")
        /// Failed to Delete List
        public static let title = L10n.tr("Localizable", "Common.Alerts.FailedToDeleteList.Title", fallback: "Failed to Delete List")
      }
      public enum FailedToDeleteToot {
        /// Please try again
        public static let message = L10n.tr("Localizable", "Common.Alerts.FailedToDeleteToot.Message", fallback: "Please try again")
        /// Failed to Delete Toot
        public static let title = L10n.tr("Localizable", "Common.Alerts.FailedToDeleteToot.Title", fallback: "Failed to Delete Toot")
      }
      public enum FailedToDeleteTweet {
        /// Please try again
        public static let message = L10n.tr("Localizable", "Common.Alerts.FailedToDeleteTweet.Message", fallback: "Please try again")
        /// Failed to Delete Tweet
        public static let title = L10n.tr("Localizable", "Common.Alerts.FailedToDeleteTweet.Title", fallback: "Failed to Delete Tweet")
      }
      public enum FailedToFollowing {
        /// Please try again
        public static let message = L10n.tr("Localizable", "Common.Alerts.FailedToFollowing.Message", fallback: "Please try again")
        /// Failed to Following
        public static let title = L10n.tr("Localizable", "Common.Alerts.FailedToFollowing.Title", fallback: "Failed to Following")
      }
      public enum FailedToLoad {
        /// Please try again
        public static let message = L10n.tr("Localizable", "Common.Alerts.FailedToLoad.Message", fallback: "Please try again")
        /// Failed to Load
        public static let title = L10n.tr("Localizable", "Common.Alerts.FailedToLoad.Title", fallback: "Failed to Load")
      }
      public enum FailedToLoginMastodonServer {
        /// Server URL is incorrect.
        public static let message = L10n.tr("Localizable", "Common.Alerts.FailedToLoginMastodonServer.Message", fallback: "Server URL is incorrect.")
        /// Failed to Login
        public static let title = L10n.tr("Localizable", "Common.Alerts.FailedToLoginMastodonServer.Title", fallback: "Failed to Login")
      }
      public enum FailedToLoginTimeout {
        /// Connection timeout.
        public static let message = L10n.tr("Localizable", "Common.Alerts.FailedToLoginTimeout.Message", fallback: "Connection timeout.")
        /// Failed to Login
        public static let title = L10n.tr("Localizable", "Common.Alerts.FailedToLoginTimeout.Title", fallback: "Failed to Login")
      }
      public enum FailedToMuteUser {
        /// Please try again
        public static let message = L10n.tr("Localizable", "Common.Alerts.FailedToMuteUser.Message", fallback: "Please try again")
        /// Failed to mute %@
        public static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.FailedToMuteUser.Title", String(describing: p1), fallback: "Failed to mute %@")
        }
      }
      public enum FailedToRemoveListMember {
        /// Please try again
        public static let message = L10n.tr("Localizable", "Common.Alerts.FailedToRemoveListMember.Message", fallback: "Please try again")
        /// Failed to Remove List Member
        public static let title = L10n.tr("Localizable", "Common.Alerts.FailedToRemoveListMember.Title", fallback: "Failed to Remove List Member")
      }
      public enum FailedToReportAndBlockUser {
        /// Please try again
        public static let message = L10n.tr("Localizable", "Common.Alerts.FailedToReportAndBlockUser.Message", fallback: "Please try again")
        /// Failed to report and block %@
        public static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.FailedToReportAndBlockUser.Title", String(describing: p1), fallback: "Failed to report and block %@")
        }
      }
      public enum FailedToReportUser {
        /// Please try again
        public static let message = L10n.tr("Localizable", "Common.Alerts.FailedToReportUser.Message", fallback: "Please try again")
        /// Failed to report %@
        public static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.FailedToReportUser.Title", String(describing: p1), fallback: "Failed to report %@")
        }
      }
      public enum FailedToSendMessage {
        /// Failed to send message
        public static let message = L10n.tr("Localizable", "Common.Alerts.FailedToSendMessage.Message", fallback: "Failed to send message")
        /// Sending message
        public static let title = L10n.tr("Localizable", "Common.Alerts.FailedToSendMessage.Title", fallback: "Sending message")
      }
      public enum FailedToUnblockUser {
        /// Please try again
        public static let message = L10n.tr("Localizable", "Common.Alerts.FailedToUnblockUser.Message", fallback: "Please try again")
        /// Failed to unblock %@
        public static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.FailedToUnblockUser.Title", String(describing: p1), fallback: "Failed to unblock %@")
        }
      }
      public enum FailedToUnfollowing {
        /// Please try again
        public static let message = L10n.tr("Localizable", "Common.Alerts.FailedToUnfollowing.Message", fallback: "Please try again")
        /// Failed to Unfollowing
        public static let title = L10n.tr("Localizable", "Common.Alerts.FailedToUnfollowing.Title", fallback: "Failed to Unfollowing")
      }
      public enum FailedToUnmuteUser {
        /// Please try again
        public static let message = L10n.tr("Localizable", "Common.Alerts.FailedToUnmuteUser.Message", fallback: "Please try again")
        /// Failed to unmute %@
        public static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.FailedToUnmuteUser.Title", String(describing: p1), fallback: "Failed to unmute %@")
        }
      }
      public enum FollowingRequestSent {
        /// Following Request Sent
        public static let title = L10n.tr("Localizable", "Common.Alerts.FollowingRequestSent.Title", fallback: "Following Request Sent")
      }
      public enum FollowingSuccess {
        /// Following Succeeded
        public static let title = L10n.tr("Localizable", "Common.Alerts.FollowingSuccess.Title", fallback: "Following Succeeded")
      }
      public enum ListDeleted {
        /// Please try again
        public static let message = L10n.tr("Localizable", "Common.Alerts.ListDeleted.Message", fallback: "Please try again")
        /// List Deleted
        public static let title = L10n.tr("Localizable", "Common.Alerts.ListDeleted.Title", fallback: "List Deleted")
      }
      public enum ListMemberRemoved {
        /// List Member Removed
        public static let title = L10n.tr("Localizable", "Common.Alerts.ListMemberRemoved.Title", fallback: "List Member Removed")
      }
      public enum MediaSaveFail {
        /// Please try again
        public static let message = L10n.tr("Localizable", "Common.Alerts.MediaSaveFail.Message", fallback: "Please try again")
        /// Failed to save media
        public static let title = L10n.tr("Localizable", "Common.Alerts.MediaSaveFail.Title", fallback: "Failed to save media")
      }
      public enum MediaSaved {
        /// Media saved
        public static let title = L10n.tr("Localizable", "Common.Alerts.MediaSaved.Title", fallback: "Media saved")
      }
      public enum MediaSaving {
        /// Saving media
        public static let title = L10n.tr("Localizable", "Common.Alerts.MediaSaving.Title", fallback: "Saving media")
      }
      public enum MediaSharing {
        /// Media will be shared after download is completed
        public static let title = L10n.tr("Localizable", "Common.Alerts.MediaSharing.Title", fallback: "Media will be shared after download is completed")
      }
      public enum MuteUserConfirm {
        /// Do you want to mute %@?
        public static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.MuteUserConfirm.Title", String(describing: p1), fallback: "Do you want to mute %@?")
        }
      }
      public enum MuteUserSuccess {
        /// %@ has been muted
        public static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.MuteUserSuccess.Title", String(describing: p1), fallback: "%@ has been muted")
        }
      }
      public enum NoTweetsFound {
        /// No Tweets Found
        public static let title = L10n.tr("Localizable", "Common.Alerts.NoTweetsFound.Title", fallback: "No Tweets Found")
      }
      public enum PermissionDeniedFriendshipBlocked {
        /// You have been blocked from following this account at the request of the user
        public static let message = L10n.tr("Localizable", "Common.Alerts.PermissionDeniedFriendshipBlocked.Message", fallback: "You have been blocked from following this account at the request of the user")
        /// Permission Denied
        public static let title = L10n.tr("Localizable", "Common.Alerts.PermissionDeniedFriendshipBlocked.Title", fallback: "Permission Denied")
      }
      public enum PermissionDeniedNotAuthorized {
        /// Sorry, you are not authorized
        public static let message = L10n.tr("Localizable", "Common.Alerts.PermissionDeniedNotAuthorized.Message", fallback: "Sorry, you are not authorized")
        /// Permission Denied
        public static let title = L10n.tr("Localizable", "Common.Alerts.PermissionDeniedNotAuthorized.Title", fallback: "Permission Denied")
      }
      public enum PhotoCopied {
        /// Photo Copied
        public static let title = L10n.tr("Localizable", "Common.Alerts.PhotoCopied.Title", fallback: "Photo Copied")
      }
      public enum PhotoCopyFail {
        /// Please try again
        public static let message = L10n.tr("Localizable", "Common.Alerts.PhotoCopyFail.Message", fallback: "Please try again")
        /// Failed to Copy Photo
        public static let title = L10n.tr("Localizable", "Common.Alerts.PhotoCopyFail.Title", fallback: "Failed to Copy Photo")
      }
      public enum PhotoSaveFail {
        /// Please try again
        public static let message = L10n.tr("Localizable", "Common.Alerts.PhotoSaveFail.Message", fallback: "Please try again")
        /// Failed to Save Photo
        public static let title = L10n.tr("Localizable", "Common.Alerts.PhotoSaveFail.Title", fallback: "Failed to Save Photo")
      }
      public enum PhotoSaved {
        /// Photo Saved
        public static let title = L10n.tr("Localizable", "Common.Alerts.PhotoSaved.Title", fallback: "Photo Saved")
      }
      public enum PostFailInvalidPoll {
        /// Poll has empty field. Please fulfill the field then try again
        public static let message = L10n.tr("Localizable", "Common.Alerts.PostFailInvalidPoll.Message", fallback: "Poll has empty field. Please fulfill the field then try again")
        /// Failed to Publish
        public static let title = L10n.tr("Localizable", "Common.Alerts.PostFailInvalidPoll.Title", fallback: "Failed to Publish")
      }
      public enum RateLimitExceeded {
        /// Reached Twitter API usage limit
        public static let message = L10n.tr("Localizable", "Common.Alerts.RateLimitExceeded.Message", fallback: "Reached Twitter API usage limit")
        /// Rate Limit Exceeded
        public static let title = L10n.tr("Localizable", "Common.Alerts.RateLimitExceeded.Title", fallback: "Rate Limit Exceeded")
      }
      public enum ReportAndBlockUserSuccess {
        /// %@ has been reported for spam and blocked
        public static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.ReportAndBlockUserSuccess.Title", String(describing: p1), fallback: "%@ has been reported for spam and blocked")
        }
      }
      public enum ReportUserSuccess {
        /// %@ has been reported for spam
        public static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.ReportUserSuccess.Title", String(describing: p1), fallback: "%@ has been reported for spam")
        }
      }
      public enum RequestThrottle {
        /// Operation too frequent. Please try again later
        public static let message = L10n.tr("Localizable", "Common.Alerts.RequestThrottle.Message", fallback: "Operation too frequent. Please try again later")
        /// Request Throttle
        public static let title = L10n.tr("Localizable", "Common.Alerts.RequestThrottle.Title", fallback: "Request Throttle")
      }
      public enum SignOutUserConfirm {
        /// Do you want to sign out?
        public static let message = L10n.tr("Localizable", "Common.Alerts.SignOutUserConfirm.Message", fallback: "Do you want to sign out?")
        /// Sign out
        public static let title = L10n.tr("Localizable", "Common.Alerts.SignOutUserConfirm.Title", fallback: "Sign out")
      }
      public enum TooManyRequests {
        /// Too Many Requests
        public static let title = L10n.tr("Localizable", "Common.Alerts.TooManyRequests.Title", fallback: "Too Many Requests")
      }
      public enum TootDeleted {
        /// Toot Deleted
        public static let title = L10n.tr("Localizable", "Common.Alerts.TootDeleted.Title", fallback: "Toot Deleted")
      }
      public enum TootFail {
        /// Your toot has been saved to Drafts.
        public static let draftSavedMessage = L10n.tr("Localizable", "Common.Alerts.TootFail.DraftSavedMessage", fallback: "Your toot has been saved to Drafts.")
        /// Please try again
        public static let message = L10n.tr("Localizable", "Common.Alerts.TootFail.Message", fallback: "Please try again")
        /// Failed to Toot
        public static let title = L10n.tr("Localizable", "Common.Alerts.TootFail.Title", fallback: "Failed to Toot")
      }
      public enum TootPosted {
        /// Toot Posted
        public static let title = L10n.tr("Localizable", "Common.Alerts.TootPosted.Title", fallback: "Toot Posted")
      }
      public enum TootSending {
        /// Sending toot
        public static let title = L10n.tr("Localizable", "Common.Alerts.TootSending.Title", fallback: "Sending toot")
      }
      public enum TweetDeleted {
        /// Tweet Deleted
        public static let title = L10n.tr("Localizable", "Common.Alerts.TweetDeleted.Title", fallback: "Tweet Deleted")
      }
      public enum TweetFail {
        /// Your tweet has been saved to Drafts.
        public static let draftSavedMessage = L10n.tr("Localizable", "Common.Alerts.TweetFail.DraftSavedMessage", fallback: "Your tweet has been saved to Drafts.")
        /// Please try again
        public static let message = L10n.tr("Localizable", "Common.Alerts.TweetFail.Message", fallback: "Please try again")
        /// Failed to Tweet
        public static let title = L10n.tr("Localizable", "Common.Alerts.TweetFail.Title", fallback: "Failed to Tweet")
      }
      public enum TweetPosted {
        /// Tweet Posted
        public static let title = L10n.tr("Localizable", "Common.Alerts.TweetPosted.Title", fallback: "Tweet Posted")
      }
      public enum TweetSending {
        /// Sending tweet
        public static let title = L10n.tr("Localizable", "Common.Alerts.TweetSending.Title", fallback: "Sending tweet")
      }
      public enum TweetSent {
        /// Tweet Sent
        public static let title = L10n.tr("Localizable", "Common.Alerts.TweetSent.Title", fallback: "Tweet Sent")
      }
      public enum UnblockUserConfirm {
        /// Do you want to unblock %@?
        public static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.UnblockUserConfirm.Title", String(describing: p1), fallback: "Do you want to unblock %@?")
        }
      }
      public enum UnblockUserSuccess {
        /// %@ has been unblocked
        public static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.UnblockUserSuccess.Title", String(describing: p1), fallback: "%@ has been unblocked")
        }
      }
      public enum UnfollowUser {
        /// Unfollow user %@?
        public static func message(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.UnfollowUser.Message", String(describing: p1), fallback: "Unfollow user %@?")
        }
      }
      public enum UnfollowingSuccess {
        /// Unfollowing Succeeded
        public static let title = L10n.tr("Localizable", "Common.Alerts.UnfollowingSuccess.Title", fallback: "Unfollowing Succeeded")
      }
      public enum UnmuteUserConfirm {
        /// Do you want to unmute %@?
        public static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.UnmuteUserConfirm.Title", String(describing: p1), fallback: "Do you want to unmute %@?")
        }
      }
      public enum UnmuteUserSuccess {
        /// %@ has been unmuted
        public static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.UnmuteUserSuccess.Title", String(describing: p1), fallback: "%@ has been unmuted")
        }
      }
    }
    public enum Controls {
      public enum Actions {
        /// Add
        public static let add = L10n.tr("Localizable", "Common.Controls.Actions.Add", fallback: "Add")
        /// Browse
        public static let browse = L10n.tr("Localizable", "Common.Controls.Actions.Browse", fallback: "Browse")
        /// Cancel
        public static let cancel = L10n.tr("Localizable", "Common.Controls.Actions.Cancel", fallback: "Cancel")
        /// Clear
        public static let clear = L10n.tr("Localizable", "Common.Controls.Actions.Clear", fallback: "Clear")
        /// Confirm
        public static let confirm = L10n.tr("Localizable", "Common.Controls.Actions.Confirm", fallback: "Confirm")
        /// Copy
        public static let copy = L10n.tr("Localizable", "Common.Controls.Actions.Copy", fallback: "Copy")
        /// Delete
        public static let delete = L10n.tr("Localizable", "Common.Controls.Actions.Delete", fallback: "Delete")
        /// Done
        public static let done = L10n.tr("Localizable", "Common.Controls.Actions.Done", fallback: "Done")
        /// Edit
        public static let edit = L10n.tr("Localizable", "Common.Controls.Actions.Edit", fallback: "Edit")
        /// OK
        public static let ok = L10n.tr("Localizable", "Common.Controls.Actions.Ok", fallback: "OK")
        /// Open in Safari
        public static let openInSafari = L10n.tr("Localizable", "Common.Controls.Actions.OpenInSafari", fallback: "Open in Safari")
        /// Preview
        public static let preview = L10n.tr("Localizable", "Common.Controls.Actions.Preview", fallback: "Preview")
        /// Remove
        public static let remove = L10n.tr("Localizable", "Common.Controls.Actions.Remove", fallback: "Remove")
        /// Save
        public static let save = L10n.tr("Localizable", "Common.Controls.Actions.Save", fallback: "Save")
        /// Save photo
        public static let savePhoto = L10n.tr("Localizable", "Common.Controls.Actions.SavePhoto", fallback: "Save photo")
        /// Share
        public static let share = L10n.tr("Localizable", "Common.Controls.Actions.Share", fallback: "Share")
        /// Share link
        public static let shareLink = L10n.tr("Localizable", "Common.Controls.Actions.ShareLink", fallback: "Share link")
        /// Share media
        public static let shareMedia = L10n.tr("Localizable", "Common.Controls.Actions.ShareMedia", fallback: "Share media")
        /// Sign in
        public static let signIn = L10n.tr("Localizable", "Common.Controls.Actions.SignIn", fallback: "Sign in")
        /// Sign out
        public static let signOut = L10n.tr("Localizable", "Common.Controls.Actions.SignOut", fallback: "Sign out")
        /// Take photo
        public static let takePhoto = L10n.tr("Localizable", "Common.Controls.Actions.TakePhoto", fallback: "Take photo")
        /// Yes
        public static let yes = L10n.tr("Localizable", "Common.Controls.Actions.Yes", fallback: "Yes")
        public enum ShareMediaMenu {
          /// Link
          public static let link = L10n.tr("Localizable", "Common.Controls.Actions.ShareMediaMenu.Link", fallback: "Link")
          /// Media
          public static let media = L10n.tr("Localizable", "Common.Controls.Actions.ShareMediaMenu.Media", fallback: "Media")
        }
      }
      public enum Friendship {
        /// Block %@
        public static func blockUser(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Friendship.BlockUser", String(describing: p1), fallback: "Block %@")
        }
        /// Do you want to report and block %@
        public static func doYouWantToReportAndBlockUser(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Friendship.DoYouWantToReportAndBlockUser", String(describing: p1), fallback: "Do you want to report and block %@")
        }
        /// Do you want to report %@
        public static func doYouWantToReportUser(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Friendship.DoYouWantToReportUser", String(describing: p1), fallback: "Do you want to report %@")
        }
        /// follower
        public static let follower = L10n.tr("Localizable", "Common.Controls.Friendship.Follower", fallback: "follower")
        /// followers
        public static let followers = L10n.tr("Localizable", "Common.Controls.Friendship.Followers", fallback: "followers")
        /// Follows you
        public static let followsYou = L10n.tr("Localizable", "Common.Controls.Friendship.FollowsYou", fallback: "Follows you")
        /// Mute %@
        public static func muteUser(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Friendship.MuteUser", String(describing: p1), fallback: "Mute %@")
        }
        /// %@ is following you
        public static func userIsFollowingYou(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Friendship.UserIsFollowingYou", String(describing: p1), fallback: "%@ is following you")
        }
        /// %@ is not following you
        public static func userIsNotFollowingYou(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Friendship.UserIsNotFollowingYou", String(describing: p1), fallback: "%@ is not following you")
        }
        public enum Actions {
          /// Block
          public static let block = L10n.tr("Localizable", "Common.Controls.Friendship.Actions.Block", fallback: "Block")
          /// Blocked
          public static let blocked = L10n.tr("Localizable", "Common.Controls.Friendship.Actions.Blocked", fallback: "Blocked")
          /// Follow
          public static let follow = L10n.tr("Localizable", "Common.Controls.Friendship.Actions.Follow", fallback: "Follow")
          /// Following
          public static let following = L10n.tr("Localizable", "Common.Controls.Friendship.Actions.Following", fallback: "Following")
          /// Mute
          public static let mute = L10n.tr("Localizable", "Common.Controls.Friendship.Actions.Mute", fallback: "Mute")
          /// Pending
          public static let pending = L10n.tr("Localizable", "Common.Controls.Friendship.Actions.Pending", fallback: "Pending")
          /// Report
          public static let report = L10n.tr("Localizable", "Common.Controls.Friendship.Actions.Report", fallback: "Report")
          /// Report and Block
          public static let reportAndBlock = L10n.tr("Localizable", "Common.Controls.Friendship.Actions.ReportAndBlock", fallback: "Report and Block")
          /// Request
          public static let request = L10n.tr("Localizable", "Common.Controls.Friendship.Actions.Request", fallback: "Request")
          /// Unblock
          public static let unblock = L10n.tr("Localizable", "Common.Controls.Friendship.Actions.Unblock", fallback: "Unblock")
          /// Unfollow
          public static let unfollow = L10n.tr("Localizable", "Common.Controls.Friendship.Actions.Unfollow", fallback: "Unfollow")
          /// Unmute
          public static let unmute = L10n.tr("Localizable", "Common.Controls.Friendship.Actions.Unmute", fallback: "Unmute")
        }
      }
      public enum Ios {
        /// Photo Library
        public static let photoLibrary = L10n.tr("Localizable", "Common.Controls.Ios.PhotoLibrary", fallback: "Photo Library")
      }
      public enum List {
        /// No results
        public static let noResults = L10n.tr("Localizable", "Common.Controls.List.NoResults", fallback: "No results")
      }
      public enum ProfileDashboard {
        /// Followers
        public static let followers = L10n.tr("Localizable", "Common.Controls.ProfileDashboard.Followers", fallback: "Followers")
        /// Following
        public static let following = L10n.tr("Localizable", "Common.Controls.ProfileDashboard.Following", fallback: "Following")
        /// Listed
        public static let listed = L10n.tr("Localizable", "Common.Controls.ProfileDashboard.Listed", fallback: "Listed")
      }
      public enum Status {
        /// Media
        public static let media = L10n.tr("Localizable", "Common.Controls.Status.Media", fallback: "Media")
        /// %@ boosted
        public static func userBoosted(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Status.UserBoosted", String(describing: p1), fallback: "%@ boosted")
        }
        /// %@ retweeted
        public static func userRetweeted(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Status.UserRetweeted", String(describing: p1), fallback: "%@ retweeted")
        }
        /// You boosted
        public static let youBoosted = L10n.tr("Localizable", "Common.Controls.Status.YouBoosted", fallback: "You boosted")
        /// You retweeted
        public static let youRetweeted = L10n.tr("Localizable", "Common.Controls.Status.YouRetweeted", fallback: "You retweeted")
        public enum Actions {
          /// Bookmark
          public static let bookmark = L10n.tr("Localizable", "Common.Controls.Status.Actions.Bookmark", fallback: "Bookmark")
          /// Boost
          public static let boost = L10n.tr("Localizable", "Common.Controls.Status.Actions.Boost", fallback: "Boost")
          /// Copy link
          public static let copyLink = L10n.tr("Localizable", "Common.Controls.Status.Actions.CopyLink", fallback: "Copy link")
          /// Copy text
          public static let copyText = L10n.tr("Localizable", "Common.Controls.Status.Actions.CopyText", fallback: "Copy text")
          /// Delete tweet
          public static let deleteTweet = L10n.tr("Localizable", "Common.Controls.Status.Actions.DeleteTweet", fallback: "Delete tweet")
          /// Like
          public static let like = L10n.tr("Localizable", "Common.Controls.Status.Actions.Like", fallback: "Like")
          /// Pin on Profile
          public static let pinOnProfile = L10n.tr("Localizable", "Common.Controls.Status.Actions.PinOnProfile", fallback: "Pin on Profile")
          /// Quote
          public static let quote = L10n.tr("Localizable", "Common.Controls.Status.Actions.Quote", fallback: "Quote")
          /// Reply
          public static let reply = L10n.tr("Localizable", "Common.Controls.Status.Actions.Reply", fallback: "Reply")
          /// Repost
          public static let repost = L10n.tr("Localizable", "Common.Controls.Status.Actions.Repost", fallback: "Repost")
          /// Retweet
          public static let retweet = L10n.tr("Localizable", "Common.Controls.Status.Actions.Retweet", fallback: "Retweet")
          /// Save media
          public static let saveMedia = L10n.tr("Localizable", "Common.Controls.Status.Actions.SaveMedia", fallback: "Save media")
          /// Share
          public static let share = L10n.tr("Localizable", "Common.Controls.Status.Actions.Share", fallback: "Share")
          /// Share content
          public static let shareContent = L10n.tr("Localizable", "Common.Controls.Status.Actions.ShareContent", fallback: "Share content")
          /// Share link
          public static let shareLink = L10n.tr("Localizable", "Common.Controls.Status.Actions.ShareLink", fallback: "Share link")
          /// Translate
          public static let translate = L10n.tr("Localizable", "Common.Controls.Status.Actions.Translate", fallback: "Translate")
          /// Undo Boost
          public static let undoBoost = L10n.tr("Localizable", "Common.Controls.Status.Actions.UndoBoost", fallback: "Undo Boost")
          /// Undo Repost
          public static let undoRepost = L10n.tr("Localizable", "Common.Controls.Status.Actions.UndoRepost", fallback: "Undo Repost")
          /// Undo Retweet
          public static let undoRetweet = L10n.tr("Localizable", "Common.Controls.Status.Actions.UndoRetweet", fallback: "Undo Retweet")
          /// Unpin from Profile
          public static let unpinFromProfile = L10n.tr("Localizable", "Common.Controls.Status.Actions.UnpinFromProfile", fallback: "Unpin from Profile")
          /// Vote
          public static let vote = L10n.tr("Localizable", "Common.Controls.Status.Actions.Vote", fallback: "Vote")
        }
        public enum Poll {
          /// Closed
          public static let expired = L10n.tr("Localizable", "Common.Controls.Status.Poll.Expired", fallback: "Closed")
          /// %@ people
          public static func totalPeople(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Common.Controls.Status.Poll.TotalPeople", String(describing: p1), fallback: "%@ people")
          }
          /// %@ person
          public static func totalPerson(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Common.Controls.Status.Poll.TotalPerson", String(describing: p1), fallback: "%@ person")
          }
          /// %@ vote
          public static func totalVote(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Common.Controls.Status.Poll.TotalVote", String(describing: p1), fallback: "%@ vote")
          }
          /// %@ votes
          public static func totalVotes(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Common.Controls.Status.Poll.TotalVotes", String(describing: p1), fallback: "%@ votes")
          }
        }
        public enum ReplySettings {
          /// People %@ follows or mentioned can reply.
          public static func peopleUserFollowsOrMentionedCanReply(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Common.Controls.Status.ReplySettings.PeopleUserFollowsOrMentionedCanReply", String(describing: p1), fallback: "People %@ follows or mentioned can reply.")
          }
          /// People %@ mentioned can reply.
          public static func peopleUserMentionedCanReply(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Common.Controls.Status.ReplySettings.PeopleUserMentionedCanReply", String(describing: p1), fallback: "People %@ mentioned can reply.")
          }
        }
        public enum Thread {
          /// Show this thread
          public static let show = L10n.tr("Localizable", "Common.Controls.Status.Thread.Show", fallback: "Show this thread")
        }
      }
      public enum Timeline {
        /// Load More
        public static let loadMore = L10n.tr("Localizable", "Common.Controls.Timeline.LoadMore", fallback: "Load More")
      }
      public enum User {
        public enum Actions {
          /// Add/remove from Lists
          public static let addRemoveFromLists = L10n.tr("Localizable", "Common.Controls.User.Actions.AddRemoveFromLists", fallback: "Add/remove from Lists")
          /// View Listed
          public static let viewListed = L10n.tr("Localizable", "Common.Controls.User.Actions.ViewListed", fallback: "View Listed")
          /// View Lists
          public static let viewLists = L10n.tr("Localizable", "Common.Controls.User.Actions.ViewLists", fallback: "View Lists")
        }
      }
    }
    public enum Countable {
      public enum Like {
        /// %@ likes
        public static func multiple(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Countable.Like.Multiple", String(describing: p1), fallback: "%@ likes")
        }
        /// %@ like
        public static func single(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Countable.Like.Single", String(describing: p1), fallback: "%@ like")
        }
      }
      public enum List {
        /// %@ lists
        public static func multiple(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Countable.List.Multiple", String(describing: p1), fallback: "%@ lists")
        }
        /// %@ list
        public static func single(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Countable.List.Single", String(describing: p1), fallback: "%@ list")
        }
      }
      public enum Member {
        /// %@ members
        public static func multiple(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Countable.Member.Multiple", String(describing: p1), fallback: "%@ members")
        }
        /// %@ member
        public static func single(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Countable.Member.Single", String(describing: p1), fallback: "%@ member")
        }
      }
      public enum Photo {
        /// %@ photos
        public static func multiple(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Countable.Photo.Multiple", String(describing: p1), fallback: "%@ photos")
        }
        /// %@ photo
        public static func single(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Countable.Photo.Single", String(describing: p1), fallback: "%@ photo")
        }
      }
      public enum Quote {
        /// %@ quotes
        public static func mutiple(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Countable.Quote.Mutiple", String(describing: p1), fallback: "%@ quotes")
        }
        /// %@ quote
        public static func single(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Countable.Quote.Single", String(describing: p1), fallback: "%@ quote")
        }
      }
      public enum Reply {
        /// %@ replies
        public static func mutiple(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Countable.Reply.Mutiple", String(describing: p1), fallback: "%@ replies")
        }
        /// %@ reply
        public static func single(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Countable.Reply.Single", String(describing: p1), fallback: "%@ reply")
        }
      }
      public enum Retweet {
        /// %@ retweets
        public static func mutiple(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Countable.Retweet.Mutiple", String(describing: p1), fallback: "%@ retweets")
        }
        /// %@ retweet
        public static func single(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Countable.Retweet.Single", String(describing: p1), fallback: "%@ retweet")
        }
      }
      public enum Tweet {
        /// %@ tweets
        public static func multiple(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Countable.Tweet.Multiple", String(describing: p1), fallback: "%@ tweets")
        }
        /// %@ tweet
        public static func single(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Countable.Tweet.Single", String(describing: p1), fallback: "%@ tweet")
        }
      }
    }
    public enum Notification {
      /// %@ favourited your toot
      public static func favourite(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Common.Notification.Favourite", String(describing: p1), fallback: "%@ favourited your toot")
      }
      /// %@ followed you
      public static func follow(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Common.Notification.Follow", String(describing: p1), fallback: "%@ followed you")
      }
      /// %@ has requested to follow you
      public static func followRequest(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Common.Notification.FollowRequest", String(describing: p1), fallback: "%@ has requested to follow you")
      }
      /// %@ mentions you
      public static func mentions(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Common.Notification.Mentions", String(describing: p1), fallback: "%@ mentions you")
      }
      /// Your poll has ended
      public static let ownPoll = L10n.tr("Localizable", "Common.Notification.OwnPoll", fallback: "Your poll has ended")
      /// A poll you have voted in has ended
      public static let poll = L10n.tr("Localizable", "Common.Notification.Poll", fallback: "A poll you have voted in has ended")
      /// %@ boosted your toot
      public static func reblog(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Common.Notification.Reblog", String(describing: p1), fallback: "%@ boosted your toot")
      }
      /// %@ just posted
      public static func status(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Common.Notification.Status", String(describing: p1), fallback: "%@ just posted")
      }
      public enum FollowRequestAction {
        /// Approve
        public static let approve = L10n.tr("Localizable", "Common.Notification.FollowRequestAction.Approve", fallback: "Approve")
        /// Deny
        public static let deny = L10n.tr("Localizable", "Common.Notification.FollowRequestAction.Deny", fallback: "Deny")
      }
      public enum FollowRequestResponse {
        /// Follow Request Approved
        public static let followRequestApproved = L10n.tr("Localizable", "Common.Notification.FollowRequestResponse.FollowRequestApproved", fallback: "Follow Request Approved")
        /// Follow Request Denied
        public static let followRequestDenied = L10n.tr("Localizable", "Common.Notification.FollowRequestResponse.FollowRequestDenied", fallback: "Follow Request Denied")
      }
      public enum Messages {
        /// %@ sent you a message
        public static func content(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Notification.Messages.Content", String(describing: p1), fallback: "%@ sent you a message")
        }
        /// New direct message
        public static let title = L10n.tr("Localizable", "Common.Notification.Messages.Title", fallback: "New direct message")
      }
    }
    public enum NotificationChannel {
      public enum BackgroundProgresses {
        /// Background progresses
        public static let name = L10n.tr("Localizable", "Common.NotificationChannel.BackgroundProgresses.Name", fallback: "Background progresses")
      }
      public enum ContentInteractions {
        /// Interactions like mentions and retweets
        public static let description = L10n.tr("Localizable", "Common.NotificationChannel.ContentInteractions.Description", fallback: "Interactions like mentions and retweets")
        /// Interactions
        public static let name = L10n.tr("Localizable", "Common.NotificationChannel.ContentInteractions.Name", fallback: "Interactions")
      }
      public enum ContentMessages {
        /// Direct messages
        public static let description = L10n.tr("Localizable", "Common.NotificationChannel.ContentMessages.Description", fallback: "Direct messages")
        /// Messages
        public static let name = L10n.tr("Localizable", "Common.NotificationChannel.ContentMessages.Name", fallback: "Messages")
      }
    }
  }
  public enum Scene {
    public enum Authentication {
      /// Authentication
      public static let title = L10n.tr("Localizable", "Scene.Authentication.Title", fallback: "Authentication")
    }
    public enum Bookmark {
      /// Bookmark
      public static let title = L10n.tr("Localizable", "Scene.Bookmark.Title", fallback: "Bookmark")
    }
    public enum Compose {
      /// , 
      public static let and = L10n.tr("Localizable", "Scene.Compose.And", fallback: ", ")
      /// Write your warning here
      public static let cwPlaceholder = L10n.tr("Localizable", "Scene.Compose.CwPlaceholder", fallback: "Write your warning here")
      ///  and 
      public static let lastEnd = L10n.tr("Localizable", "Scene.Compose.LastEnd", fallback: " and ")
      /// Others in this conversation:
      public static let othersInThisConversation = L10n.tr("Localizable", "Scene.Compose.OthersInThisConversation", fallback: "Others in this conversation:")
      /// What’s happening?
      public static let placeholder = L10n.tr("Localizable", "Scene.Compose.Placeholder", fallback: "What’s happening?")
      /// Replying to
      public static let replyingTo = L10n.tr("Localizable", "Scene.Compose.ReplyingTo", fallback: "Replying to")
      /// Reply to …
      public static let replyTo = L10n.tr("Localizable", "Scene.Compose.ReplyTo", fallback: "Reply to …")
      public enum Media {
        /// Preview
        public static let preview = L10n.tr("Localizable", "Scene.Compose.Media.Preview", fallback: "Preview")
        /// Remove
        public static let remove = L10n.tr("Localizable", "Scene.Compose.Media.Remove", fallback: "Remove")
        public enum Caption {
          /// Add Caption
          public static let add = L10n.tr("Localizable", "Scene.Compose.Media.Caption.Add", fallback: "Add Caption")
          /// Add a description for this image
          public static let addADescriptionForThisImage = L10n.tr("Localizable", "Scene.Compose.Media.Caption.AddADescriptionForThisImage", fallback: "Add a description for this image")
          /// Remove Caption
          public static let remove = L10n.tr("Localizable", "Scene.Compose.Media.Caption.Remove", fallback: "Remove Caption")
          /// Update Caption
          public static let update = L10n.tr("Localizable", "Scene.Compose.Media.Caption.Update", fallback: "Update Caption")
        }
      }
      public enum ReplySettings {
        /// Everyone can reply
        public static let everyoneCanReply = L10n.tr("Localizable", "Scene.Compose.ReplySettings.EveryoneCanReply", fallback: "Everyone can reply")
        /// Only people you mention can reply
        public static let onlyPeopleYouMentionCanReply = L10n.tr("Localizable", "Scene.Compose.ReplySettings.OnlyPeopleYouMentionCanReply", fallback: "Only people you mention can reply")
        /// People you follow can reply
        public static let peopleYouFollowCanReply = L10n.tr("Localizable", "Scene.Compose.ReplySettings.PeopleYouFollowCanReply", fallback: "People you follow can reply")
      }
      public enum SaveDraft {
        /// Save draft
        public static let action = L10n.tr("Localizable", "Scene.Compose.SaveDraft.Action", fallback: "Save draft")
        /// Save draft?
        public static let message = L10n.tr("Localizable", "Scene.Compose.SaveDraft.Message", fallback: "Save draft?")
      }
      public enum Title {
        /// Compose
        public static let compose = L10n.tr("Localizable", "Scene.Compose.Title.Compose", fallback: "Compose")
        /// Quote
        public static let quote = L10n.tr("Localizable", "Scene.Compose.Title.Quote", fallback: "Quote")
        /// Reply
        public static let reply = L10n.tr("Localizable", "Scene.Compose.Title.Reply", fallback: "Reply")
      }
      public enum Visibility {
        /// Direct
        public static let direct = L10n.tr("Localizable", "Scene.Compose.Visibility.Direct", fallback: "Direct")
        /// Private
        public static let `private` = L10n.tr("Localizable", "Scene.Compose.Visibility.Private", fallback: "Private")
        /// Public
        public static let `public` = L10n.tr("Localizable", "Scene.Compose.Visibility.Public", fallback: "Public")
        /// Unlisted
        public static let unlisted = L10n.tr("Localizable", "Scene.Compose.Visibility.Unlisted", fallback: "Unlisted")
      }
      public enum VisibilityDescription {
        /// Visible for mentioned users only
        public static let direct = L10n.tr("Localizable", "Scene.Compose.VisibilityDescription.Direct", fallback: "Visible for mentioned users only")
        /// Visible for followers only
        public static let `private` = L10n.tr("Localizable", "Scene.Compose.VisibilityDescription.Private", fallback: "Visible for followers only")
        /// Visible for all, shown in public timelines
        public static let `public` = L10n.tr("Localizable", "Scene.Compose.VisibilityDescription.Public", fallback: "Visible for all, shown in public timelines")
        /// Visible for all, but not in public timelines
        public static let unlisted = L10n.tr("Localizable", "Scene.Compose.VisibilityDescription.Unlisted", fallback: "Visible for all, but not in public timelines")
      }
      public enum Vote {
        /// Multiple choice
        public static let multiple = L10n.tr("Localizable", "Scene.Compose.Vote.Multiple", fallback: "Multiple choice")
        /// Choice %d
        public static func placeholderIndex(_ p1: Int) -> String {
          return L10n.tr("Localizable", "Scene.Compose.Vote.PlaceholderIndex", p1, fallback: "Choice %d")
        }
        public enum Expiration {
          /// 1 day
          public static let _1Day = L10n.tr("Localizable", "Scene.Compose.Vote.Expiration.1Day", fallback: "1 day")
          /// 1 hour
          public static let _1Hour = L10n.tr("Localizable", "Scene.Compose.Vote.Expiration.1Hour", fallback: "1 hour")
          /// 30 minutes
          public static let _30Min = L10n.tr("Localizable", "Scene.Compose.Vote.Expiration.30Min", fallback: "30 minutes")
          /// 3 days
          public static let _3Day = L10n.tr("Localizable", "Scene.Compose.Vote.Expiration.3Day", fallback: "3 days")
          /// 5 minutes
          public static let _5Min = L10n.tr("Localizable", "Scene.Compose.Vote.Expiration.5Min", fallback: "5 minutes")
          /// 6 hours
          public static let _6Hour = L10n.tr("Localizable", "Scene.Compose.Vote.Expiration.6Hour", fallback: "6 hours")
          /// 7 days
          public static let _7Day = L10n.tr("Localizable", "Scene.Compose.Vote.Expiration.7Day", fallback: "7 days")
        }
      }
    }
    public enum ComposeHashtagSearch {
      /// Search hashtag
      public static let searchPlaceholder = L10n.tr("Localizable", "Scene.ComposeHashtagSearch.SearchPlaceholder", fallback: "Search hashtag")
    }
    public enum ComposeUserSearch {
      /// Search users
      public static let searchPlaceholder = L10n.tr("Localizable", "Scene.ComposeUserSearch.SearchPlaceholder", fallback: "Search users")
    }
    public enum Detail {
      /// Detail
      public static let title = L10n.tr("Localizable", "Scene.Detail.Title", fallback: "Detail")
    }
    public enum Drafts {
      /// Drafts
      public static let title = L10n.tr("Localizable", "Scene.Drafts.Title", fallback: "Drafts")
      public enum Actions {
        /// Delete draft
        public static let deleteDraft = L10n.tr("Localizable", "Scene.Drafts.Actions.DeleteDraft", fallback: "Delete draft")
        /// Edit draft
        public static let editDraft = L10n.tr("Localizable", "Scene.Drafts.Actions.EditDraft", fallback: "Edit draft")
      }
    }
    public enum Drawer {
      /// Manage accounts
      public static let manageAccounts = L10n.tr("Localizable", "Scene.Drawer.ManageAccounts", fallback: "Manage accounts")
      /// Sign in
      public static let signIn = L10n.tr("Localizable", "Scene.Drawer.SignIn", fallback: "Sign in")
    }
    public enum Federated {
      /// Federated
      public static let title = L10n.tr("Localizable", "Scene.Federated.Title", fallback: "Federated")
    }
    public enum Followers {
      /// Followers
      public static let title = L10n.tr("Localizable", "Scene.Followers.Title", fallback: "Followers")
    }
    public enum Following {
      /// Following
      public static let title = L10n.tr("Localizable", "Scene.Following.Title", fallback: "Following")
    }
    public enum History {
      /// Clear
      public static let clear = L10n.tr("Localizable", "Scene.History.Clear", fallback: "Clear")
      /// History
      public static let title = L10n.tr("Localizable", "Scene.History.Title", fallback: "History")
      public enum Scope {
        /// Toot
        public static let toot = L10n.tr("Localizable", "Scene.History.Scope.Toot", fallback: "Toot")
        /// Tweet
        public static let tweet = L10n.tr("Localizable", "Scene.History.Scope.Tweet", fallback: "Tweet")
        /// User
        public static let user = L10n.tr("Localizable", "Scene.History.Scope.User", fallback: "User")
      }
    }
    public enum Likes {
      /// Likes
      public static let title = L10n.tr("Localizable", "Scene.Likes.Title", fallback: "Likes")
    }
    public enum Listed {
      /// Listed
      public static let title = L10n.tr("Localizable", "Scene.Listed.Title", fallback: "Listed")
    }
    public enum Lists {
      /// Lists
      public static let title = L10n.tr("Localizable", "Scene.Lists.Title", fallback: "Lists")
      public enum Icons {
        /// Create list
        public static let create = L10n.tr("Localizable", "Scene.Lists.Icons.Create", fallback: "Create list")
        /// Private visibility
        public static let `private` = L10n.tr("Localizable", "Scene.Lists.Icons.Private", fallback: "Private visibility")
      }
      public enum Tabs {
        /// MY LISTS
        public static let created = L10n.tr("Localizable", "Scene.Lists.Tabs.Created", fallback: "MY LISTS")
        /// SUBSCRIBED
        public static let subscribed = L10n.tr("Localizable", "Scene.Lists.Tabs.Subscribed", fallback: "SUBSCRIBED")
      }
    }
    public enum ListsDetails {
      /// Add Members
      public static let addMembers = L10n.tr("Localizable", "Scene.ListsDetails.AddMembers", fallback: "Add Members")
      /// Delete this list: %@
      public static func deleteListConfirm(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Scene.ListsDetails.DeleteListConfirm", String(describing: p1), fallback: "Delete this list: %@")
      }
      /// Delete this list
      public static let deleteListTitle = L10n.tr("Localizable", "Scene.ListsDetails.DeleteListTitle", fallback: "Delete this list")
      /// No Members Found.
      public static let noMembersFound = L10n.tr("Localizable", "Scene.ListsDetails.NoMembersFound", fallback: "No Members Found.")
      /// Lists Details
      public static let title = L10n.tr("Localizable", "Scene.ListsDetails.Title", fallback: "Lists Details")
      public enum Descriptions {
        /// %d Members
        public static func multipleMembers(_ p1: Int) -> String {
          return L10n.tr("Localizable", "Scene.ListsDetails.Descriptions.MultipleMembers", p1, fallback: "%d Members")
        }
        /// %d Subscribers
        public static func multipleSubscribers(_ p1: Int) -> String {
          return L10n.tr("Localizable", "Scene.ListsDetails.Descriptions.MultipleSubscribers", p1, fallback: "%d Subscribers")
        }
        /// 1 Member
        public static let singleMember = L10n.tr("Localizable", "Scene.ListsDetails.Descriptions.SingleMember", fallback: "1 Member")
        /// 1 Subscriber
        public static let singleSubscriber = L10n.tr("Localizable", "Scene.ListsDetails.Descriptions.SingleSubscriber", fallback: "1 Subscriber")
      }
      public enum MenuActions {
        /// Add Member
        public static let addMember = L10n.tr("Localizable", "Scene.ListsDetails.MenuActions.AddMember", fallback: "Add Member")
        /// Delete List
        public static let deleteList = L10n.tr("Localizable", "Scene.ListsDetails.MenuActions.DeleteList", fallback: "Delete List")
        /// Edit List
        public static let editList = L10n.tr("Localizable", "Scene.ListsDetails.MenuActions.EditList", fallback: "Edit List")
        /// Follow
        public static let follow = L10n.tr("Localizable", "Scene.ListsDetails.MenuActions.Follow", fallback: "Follow")
        /// Rename List
        public static let renameList = L10n.tr("Localizable", "Scene.ListsDetails.MenuActions.RenameList", fallback: "Rename List")
        /// Unfollow
        public static let unfollow = L10n.tr("Localizable", "Scene.ListsDetails.MenuActions.Unfollow", fallback: "Unfollow")
      }
      public enum Tabs {
        /// List Members
        public static let members = L10n.tr("Localizable", "Scene.ListsDetails.Tabs.Members", fallback: "List Members")
        /// Subscribers
        public static let subscriber = L10n.tr("Localizable", "Scene.ListsDetails.Tabs.Subscriber", fallback: "Subscribers")
      }
    }
    public enum ListsModify {
      /// Description
      public static let description = L10n.tr("Localizable", "Scene.ListsModify.Description", fallback: "Description")
      /// Name
      public static let name = L10n.tr("Localizable", "Scene.ListsModify.Name", fallback: "Name")
      /// Private
      public static let `private` = L10n.tr("Localizable", "Scene.ListsModify.Private", fallback: "Private")
      public enum Create {
        /// New List
        public static let title = L10n.tr("Localizable", "Scene.ListsModify.Create.Title", fallback: "New List")
      }
      public enum Dialog {
        /// Create a list
        public static let create = L10n.tr("Localizable", "Scene.ListsModify.Dialog.Create", fallback: "Create a list")
        /// Rename the list
        public static let edit = L10n.tr("Localizable", "Scene.ListsModify.Dialog.Edit", fallback: "Rename the list")
      }
      public enum Edit {
        /// Edit List
        public static let title = L10n.tr("Localizable", "Scene.ListsModify.Edit.Title", fallback: "Edit List")
      }
    }
    public enum ListsUsers {
      public enum Add {
        /// Search people
        public static let search = L10n.tr("Localizable", "Scene.ListsUsers.Add.Search", fallback: "Search people")
        /// Search within people you follow
        public static let searchWithinPeopleYouFollow = L10n.tr("Localizable", "Scene.ListsUsers.Add.SearchWithinPeopleYouFollow", fallback: "Search within people you follow")
        /// Add Member
        public static let title = L10n.tr("Localizable", "Scene.ListsUsers.Add.Title", fallback: "Add Member")
      }
      public enum MenuActions {
        /// Add
        public static let add = L10n.tr("Localizable", "Scene.ListsUsers.MenuActions.Add", fallback: "Add")
        /// Remove
        public static let remove = L10n.tr("Localizable", "Scene.ListsUsers.MenuActions.Remove", fallback: "Remove")
      }
    }
    public enum Local {
      /// Local
      public static let title = L10n.tr("Localizable", "Scene.Local.Title", fallback: "Local")
    }
    public enum ManageAccounts {
      /// Delete account
      public static let deleteAccount = L10n.tr("Localizable", "Scene.ManageAccounts.DeleteAccount", fallback: "Delete account")
      /// Accounts
      public static let title = L10n.tr("Localizable", "Scene.ManageAccounts.Title", fallback: "Accounts")
    }
    public enum Mentions {
      /// Mentions
      public static let title = L10n.tr("Localizable", "Scene.Mentions.Title", fallback: "Mentions")
    }
    public enum Messages {
      /// Messages
      public static let title = L10n.tr("Localizable", "Scene.Messages.Title", fallback: "Messages")
      public enum Action {
        /// Copy message text
        public static let copyText = L10n.tr("Localizable", "Scene.Messages.Action.CopyText", fallback: "Copy message text")
        /// Delete message for you
        public static let delete = L10n.tr("Localizable", "Scene.Messages.Action.Delete", fallback: "Delete message for you")
      }
      public enum Error {
        /// The Current account does not support direct messages
        public static let notSupported = L10n.tr("Localizable", "Scene.Messages.Error.NotSupported", fallback: "The Current account does not support direct messages")
      }
      public enum Expanded {
        /// [Photo]
        public static let photo = L10n.tr("Localizable", "Scene.Messages.Expanded.Photo", fallback: "[Photo]")
      }
      public enum Icon {
        /// Send message failed
        public static let failed = L10n.tr("Localizable", "Scene.Messages.Icon.Failed", fallback: "Send message failed")
      }
      public enum NewConversation {
        /// Search people
        public static let search = L10n.tr("Localizable", "Scene.Messages.NewConversation.Search", fallback: "Search people")
        /// Find people
        public static let title = L10n.tr("Localizable", "Scene.Messages.NewConversation.Title", fallback: "Find people")
      }
    }
    public enum Notification {
      /// Notification
      public static let title = L10n.tr("Localizable", "Scene.Notification.Title", fallback: "Notification")
      public enum Tabs {
        /// All
        public static let all = L10n.tr("Localizable", "Scene.Notification.Tabs.All", fallback: "All")
        /// Mentions
        public static let mentions = L10n.tr("Localizable", "Scene.Notification.Tabs.Mentions", fallback: "Mentions")
      }
    }
    public enum Profile {
      /// Hide reply
      public static let hideReply = L10n.tr("Localizable", "Scene.Profile.HideReply", fallback: "Hide reply")
      /// Me
      public static let title = L10n.tr("Localizable", "Scene.Profile.Title", fallback: "Me")
      public enum Fields {
        /// Joined in %@
        public static func joinedInDate(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Scene.Profile.Fields.JoinedInDate", String(describing: p1), fallback: "Joined in %@")
        }
      }
      public enum Filter {
        /// All tweets
        public static let all = L10n.tr("Localizable", "Scene.Profile.Filter.All", fallback: "All tweets")
        /// Exclude replies
        public static let excludeReplies = L10n.tr("Localizable", "Scene.Profile.Filter.ExcludeReplies", fallback: "Exclude replies")
      }
      public enum PermissionDeniedProfileBlocked {
        /// You have been blocked from viewing this user’s profile.
        public static let message = L10n.tr("Localizable", "Scene.Profile.PermissionDeniedProfileBlocked.Message", fallback: "You have been blocked from viewing this user’s profile.")
        /// Permission Denied
        public static let title = L10n.tr("Localizable", "Scene.Profile.PermissionDeniedProfileBlocked.Title", fallback: "Permission Denied")
      }
    }
    public enum Search {
      /// Saved Search
      public static let savedSearch = L10n.tr("Localizable", "Scene.Search.SavedSearch", fallback: "Saved Search")
      /// Show less
      public static let showLess = L10n.tr("Localizable", "Scene.Search.ShowLess", fallback: "Show less")
      /// Show more
      public static let showMore = L10n.tr("Localizable", "Scene.Search.ShowMore", fallback: "Show more")
      /// Search
      public static let title = L10n.tr("Localizable", "Scene.Search.Title", fallback: "Search")
      public enum SearchBar {
        /// Search tweets or users
        public static let placeholder = L10n.tr("Localizable", "Scene.Search.SearchBar.Placeholder", fallback: "Search tweets or users")
      }
      public enum Tabs {
        /// Hashtag
        public static let hashtag = L10n.tr("Localizable", "Scene.Search.Tabs.Hashtag", fallback: "Hashtag")
        /// Media
        public static let media = L10n.tr("Localizable", "Scene.Search.Tabs.Media", fallback: "Media")
        /// People
        public static let people = L10n.tr("Localizable", "Scene.Search.Tabs.People", fallback: "People")
        /// Toots
        public static let toots = L10n.tr("Localizable", "Scene.Search.Tabs.Toots", fallback: "Toots")
        /// Tweets
        public static let tweets = L10n.tr("Localizable", "Scene.Search.Tabs.Tweets", fallback: "Tweets")
        /// Users
        public static let users = L10n.tr("Localizable", "Scene.Search.Tabs.Users", fallback: "Users")
      }
    }
    public enum Settings {
      /// Settings
      public static let title = L10n.tr("Localizable", "Scene.Settings.Title", fallback: "Settings")
      public enum About {
        /// Next generation of Twidere for Android 5.0+. 
        /// Still in early stage.
        public static let description = L10n.tr("Localizable", "Scene.Settings.About.Description", fallback: "Next generation of Twidere for Android 5.0+. \nStill in early stage.")
        /// License
        public static let license = L10n.tr("Localizable", "Scene.Settings.About.License", fallback: "License")
        /// About
        public static let title = L10n.tr("Localizable", "Scene.Settings.About.Title", fallback: "About")
        /// Ver %@
        public static func version(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Scene.Settings.About.Version", String(describing: p1), fallback: "Ver %@")
        }
        public enum Logo {
          /// About page background logo
          public static let background = L10n.tr("Localizable", "Scene.Settings.About.Logo.Background", fallback: "About page background logo")
          /// About page background logo shadow
          public static let backgroundShadow = L10n.tr("Localizable", "Scene.Settings.About.Logo.BackgroundShadow", fallback: "About page background logo shadow")
        }
      }
      public enum Account {
        /// Blocked People
        public static let blockedPeople = L10n.tr("Localizable", "Scene.Settings.Account.BlockedPeople", fallback: "Blocked People")
        /// Mute and Block
        public static let muteAndBlock = L10n.tr("Localizable", "Scene.Settings.Account.MuteAndBlock", fallback: "Mute and Block")
        /// Muted People
        public static let mutedPeople = L10n.tr("Localizable", "Scene.Settings.Account.MutedPeople", fallback: "Muted People")
        /// Account
        public static let title = L10n.tr("Localizable", "Scene.Settings.Account.Title", fallback: "Account")
      }
      public enum Appearance {
        /// AMOLED optimized mode
        public static let amoledOptimizedMode = L10n.tr("Localizable", "Scene.Settings.Appearance.AmoledOptimizedMode", fallback: "AMOLED optimized mode")
        /// App Icon
        public static let appIcon = L10n.tr("Localizable", "Scene.Settings.Appearance.AppIcon", fallback: "App Icon")
        /// Highlight color
        public static let highlightColor = L10n.tr("Localizable", "Scene.Settings.Appearance.HighlightColor", fallback: "Highlight color")
        /// Pick color
        public static let pickColor = L10n.tr("Localizable", "Scene.Settings.Appearance.PickColor", fallback: "Pick color")
        /// Appearance
        public static let title = L10n.tr("Localizable", "Scene.Settings.Appearance.Title", fallback: "Appearance")
        public enum ScrollingTimeline {
          /// Hide app bar when scrolling
          public static let appBar = L10n.tr("Localizable", "Scene.Settings.Appearance.ScrollingTimeline.AppBar", fallback: "Hide app bar when scrolling")
          /// Hide FAB when scrolling
          public static let fab = L10n.tr("Localizable", "Scene.Settings.Appearance.ScrollingTimeline.Fab", fallback: "Hide FAB when scrolling")
          /// Hide tab bar when scrolling
          public static let tabBar = L10n.tr("Localizable", "Scene.Settings.Appearance.ScrollingTimeline.TabBar", fallback: "Hide tab bar when scrolling")
        }
        public enum SectionHeader {
          /// Scrolling timeline
          public static let scrollingTimeline = L10n.tr("Localizable", "Scene.Settings.Appearance.SectionHeader.ScrollingTimeline", fallback: "Scrolling timeline")
          /// Tab position
          public static let tabPosition = L10n.tr("Localizable", "Scene.Settings.Appearance.SectionHeader.TabPosition", fallback: "Tab position")
          /// Theme
          public static let theme = L10n.tr("Localizable", "Scene.Settings.Appearance.SectionHeader.Theme", fallback: "Theme")
          /// Translation
          public static let translation = L10n.tr("Localizable", "Scene.Settings.Appearance.SectionHeader.Translation", fallback: "Translation")
        }
        public enum TabPosition {
          /// Bottom
          public static let bottom = L10n.tr("Localizable", "Scene.Settings.Appearance.TabPosition.Bottom", fallback: "Bottom")
          /// Top
          public static let top = L10n.tr("Localizable", "Scene.Settings.Appearance.TabPosition.Top", fallback: "Top")
        }
        public enum Theme {
          /// Auto
          public static let auto = L10n.tr("Localizable", "Scene.Settings.Appearance.Theme.Auto", fallback: "Auto")
          /// Dark
          public static let dark = L10n.tr("Localizable", "Scene.Settings.Appearance.Theme.Dark", fallback: "Dark")
          /// Light
          public static let light = L10n.tr("Localizable", "Scene.Settings.Appearance.Theme.Light", fallback: "Light")
        }
        public enum Translation {
          /// Always
          public static let always = L10n.tr("Localizable", "Scene.Settings.Appearance.Translation.Always", fallback: "Always")
          /// Auto
          public static let auto = L10n.tr("Localizable", "Scene.Settings.Appearance.Translation.Auto", fallback: "Auto")
          /// Off
          public static let off = L10n.tr("Localizable", "Scene.Settings.Appearance.Translation.Off", fallback: "Off")
          /// Service
          public static let service = L10n.tr("Localizable", "Scene.Settings.Appearance.Translation.Service", fallback: "Service")
          /// Translate button
          public static let translateButton = L10n.tr("Localizable", "Scene.Settings.Appearance.Translation.TranslateButton", fallback: "Translate button")
        }
      }
      public enum Behaviors {
        /// Behaviors
        public static let title = L10n.tr("Localizable", "Scene.Settings.Behaviors.Title", fallback: "Behaviors")
        public enum HistorySection {
          /// Enable History Record
          public static let enableHistoryRecord = L10n.tr("Localizable", "Scene.Settings.Behaviors.HistorySection.EnableHistoryRecord", fallback: "Enable History Record")
          /// History
          public static let history = L10n.tr("Localizable", "Scene.Settings.Behaviors.HistorySection.History", fallback: "History")
        }
        public enum TabBarSection {
          /// Show tab bar labels
          public static let showTabBarLabels = L10n.tr("Localizable", "Scene.Settings.Behaviors.TabBarSection.ShowTabBarLabels", fallback: "Show tab bar labels")
          /// Tab Bar
          public static let tabBar = L10n.tr("Localizable", "Scene.Settings.Behaviors.TabBarSection.TabBar", fallback: "Tab Bar")
          /// Tap tab bar scroll to top
          public static let tapTabBarScrollToTop = L10n.tr("Localizable", "Scene.Settings.Behaviors.TabBarSection.TapTabBarScrollToTop", fallback: "Tap tab bar scroll to top")
        }
        public enum TimelineRefreshingSection {
          /// Automatically refresh timeline
          public static let automaticallyRefreshTimeline = L10n.tr("Localizable", "Scene.Settings.Behaviors.TimelineRefreshingSection.AutomaticallyRefreshTimeline", fallback: "Automatically refresh timeline")
          /// Refresh interval
          public static let refreshInterval = L10n.tr("Localizable", "Scene.Settings.Behaviors.TimelineRefreshingSection.RefreshInterval", fallback: "Refresh interval")
          /// Reset to top
          public static let resetToTop = L10n.tr("Localizable", "Scene.Settings.Behaviors.TimelineRefreshingSection.ResetToTop", fallback: "Reset to top")
          /// Timeline Refreshing
          public static let timelineRefreshing = L10n.tr("Localizable", "Scene.Settings.Behaviors.TimelineRefreshingSection.TimelineRefreshing", fallback: "Timeline Refreshing")
          public enum RefreshIntervalOption {
            /// 120 seconds
            public static let _120Seconds = L10n.tr("Localizable", "Scene.Settings.Behaviors.TimelineRefreshingSection.RefreshIntervalOption.120Seconds", fallback: "120 seconds")
            /// 300 seconds
            public static let _300Seconds = L10n.tr("Localizable", "Scene.Settings.Behaviors.TimelineRefreshingSection.RefreshIntervalOption.300Seconds", fallback: "300 seconds")
            /// 30 seconds
            public static let _30Seconds = L10n.tr("Localizable", "Scene.Settings.Behaviors.TimelineRefreshingSection.RefreshIntervalOption.30Seconds", fallback: "30 seconds")
            /// 60 seconds
            public static let _60Seconds = L10n.tr("Localizable", "Scene.Settings.Behaviors.TimelineRefreshingSection.RefreshIntervalOption.60Seconds", fallback: "60 seconds")
          }
          public enum ResetToTopOption {
            /// Double Tap
            public static let doubleTap = L10n.tr("Localizable", "Scene.Settings.Behaviors.TimelineRefreshingSection.ResetToTopOption.DoubleTap", fallback: "Double Tap")
            /// Single Tap
            public static let singleTap = L10n.tr("Localizable", "Scene.Settings.Behaviors.TimelineRefreshingSection.ResetToTopOption.SingleTap", fallback: "Single Tap")
          }
        }
      }
      public enum Display {
        /// Display
        public static let title = L10n.tr("Localizable", "Scene.Settings.Display.Title", fallback: "Display")
        /// Url previews
        public static let urlPreview = L10n.tr("Localizable", "Scene.Settings.Display.UrlPreview", fallback: "Url previews")
        public enum DateFormat {
          /// Absolute
          public static let absolute = L10n.tr("Localizable", "Scene.Settings.Display.DateFormat.Absolute", fallback: "Absolute")
          /// Relative
          public static let relative = L10n.tr("Localizable", "Scene.Settings.Display.DateFormat.Relative", fallback: "Relative")
        }
        public enum Media {
          /// Always
          public static let always = L10n.tr("Localizable", "Scene.Settings.Display.Media.Always", fallback: "Always")
          /// Automatic
          public static let automatic = L10n.tr("Localizable", "Scene.Settings.Display.Media.Automatic", fallback: "Automatic")
          /// Auto playback
          public static let autoPlayback = L10n.tr("Localizable", "Scene.Settings.Display.Media.AutoPlayback", fallback: "Auto playback")
          /// Media previews
          public static let mediaPreviews = L10n.tr("Localizable", "Scene.Settings.Display.Media.MediaPreviews", fallback: "Media previews")
          /// Mute by default
          public static let muteByDefault = L10n.tr("Localizable", "Scene.Settings.Display.Media.MuteByDefault", fallback: "Mute by default")
          /// Off
          public static let off = L10n.tr("Localizable", "Scene.Settings.Display.Media.Off", fallback: "Off")
        }
        public enum Preview {
          /// Thanks for using @TwidereProject!
          public static let thankForUsingTwidereX = L10n.tr("Localizable", "Scene.Settings.Display.Preview.ThankForUsingTwidereX", fallback: "Thanks for using @TwidereProject!")
        }
        public enum SectionHeader {
          /// Avatar
          public static let avatar = L10n.tr("Localizable", "Scene.Settings.Display.SectionHeader.Avatar", fallback: "Avatar")
          /// Date Format
          public static let dateFormat = L10n.tr("Localizable", "Scene.Settings.Display.SectionHeader.DateFormat", fallback: "Date Format")
          /// Media
          public static let media = L10n.tr("Localizable", "Scene.Settings.Display.SectionHeader.Media", fallback: "Media")
          /// Preview
          public static let preview = L10n.tr("Localizable", "Scene.Settings.Display.SectionHeader.Preview", fallback: "Preview")
          /// Text
          public static let text = L10n.tr("Localizable", "Scene.Settings.Display.SectionHeader.Text", fallback: "Text")
        }
        public enum Text {
          /// Avatar Style
          public static let avatarStyle = L10n.tr("Localizable", "Scene.Settings.Display.Text.AvatarStyle", fallback: "Avatar Style")
          /// Circle
          public static let circle = L10n.tr("Localizable", "Scene.Settings.Display.Text.Circle", fallback: "Circle")
          /// Rounded Square
          public static let roundedSquare = L10n.tr("Localizable", "Scene.Settings.Display.Text.RoundedSquare", fallback: "Rounded Square")
          /// Use the system font size
          public static let useTheSystemFontSize = L10n.tr("Localizable", "Scene.Settings.Display.Text.UseTheSystemFontSize", fallback: "Use the system font size")
        }
      }
      public enum Layout {
        /// Layout
        public static let title = L10n.tr("Localizable", "Scene.Settings.Layout.Title", fallback: "Layout")
        public enum Actions {
          /// Drawer actions
          public static let drawer = L10n.tr("Localizable", "Scene.Settings.Layout.Actions.Drawer", fallback: "Drawer actions")
          /// Tabbar actions
          public static let tabbar = L10n.tr("Localizable", "Scene.Settings.Layout.Actions.Tabbar", fallback: "Tabbar actions")
        }
        public enum Desc {
          /// Choose and arrange up to 5 actions that will appear on the tabbar (The local and federal timelines will only be displayed in Mastodon.)
          public static let content = L10n.tr("Localizable", "Scene.Settings.Layout.Desc.Content", fallback: "Choose and arrange up to 5 actions that will appear on the tabbar (The local and federal timelines will only be displayed in Mastodon.)")
          /// Custom Layout
          public static let title = L10n.tr("Localizable", "Scene.Settings.Layout.Desc.Title", fallback: "Custom Layout")
        }
      }
      public enum Misc {
        /// Misc
        public static let title = L10n.tr("Localizable", "Scene.Settings.Misc.Title", fallback: "Misc")
        public enum Nitter {
          /// Third-party Twitter data provider
          public static let title = L10n.tr("Localizable", "Scene.Settings.Misc.Nitter.Title", fallback: "Third-party Twitter data provider")
          public enum Dialog {
            public enum Information {
              /// Due to the limitation of Twitter API, some data might not be able to fetch from Twitter, you can use a third-party data provider to provide these data. Twidere does not take any responsibility for them.
              public static let content = L10n.tr("Localizable", "Scene.Settings.Misc.Nitter.Dialog.Information.Content", fallback: "Due to the limitation of Twitter API, some data might not be able to fetch from Twitter, you can use a third-party data provider to provide these data. Twidere does not take any responsibility for them.")
              /// Third party Twitter data provider
              public static let title = L10n.tr("Localizable", "Scene.Settings.Misc.Nitter.Dialog.Information.Title", fallback: "Third party Twitter data provider")
            }
            public enum Usage {
              /// - Twitter status threading
              public static let content = L10n.tr("Localizable", "Scene.Settings.Misc.Nitter.Dialog.Usage.Content", fallback: "- Twitter status threading")
              /// Project URL
              public static let projectButton = L10n.tr("Localizable", "Scene.Settings.Misc.Nitter.Dialog.Usage.ProjectButton", fallback: "Project URL")
              /// Using Third-party data provider in
              public static let title = L10n.tr("Localizable", "Scene.Settings.Misc.Nitter.Dialog.Usage.Title", fallback: "Using Third-party data provider in")
            }
          }
          public enum Input {
            /// Alternative Twitter front-end focused on privacy.
            public static let description = L10n.tr("Localizable", "Scene.Settings.Misc.Nitter.Input.Description", fallback: "Alternative Twitter front-end focused on privacy.")
            /// Nitter instance URL is invalid, e.g. https://nitter.net
            public static let invalid = L10n.tr("Localizable", "Scene.Settings.Misc.Nitter.Input.Invalid", fallback: "Nitter instance URL is invalid, e.g. https://nitter.net")
            /// Nitter Instance
            public static let placeholder = L10n.tr("Localizable", "Scene.Settings.Misc.Nitter.Input.Placeholder", fallback: "Nitter Instance")
            /// Instance URL
            public static let value = L10n.tr("Localizable", "Scene.Settings.Misc.Nitter.Input.Value", fallback: "Instance URL")
          }
        }
        public enum Proxy {
          /// Password
          public static let password = L10n.tr("Localizable", "Scene.Settings.Misc.Proxy.Password", fallback: "Password")
          /// Server
          public static let server = L10n.tr("Localizable", "Scene.Settings.Misc.Proxy.Server", fallback: "Server")
          /// Proxy settings
          public static let title = L10n.tr("Localizable", "Scene.Settings.Misc.Proxy.Title", fallback: "Proxy settings")
          /// Username
          public static let username = L10n.tr("Localizable", "Scene.Settings.Misc.Proxy.Username", fallback: "Username")
          public enum Enable {
            /// Use proxy for all network requests
            public static let description = L10n.tr("Localizable", "Scene.Settings.Misc.Proxy.Enable.Description", fallback: "Use proxy for all network requests")
            /// Proxy
            public static let title = L10n.tr("Localizable", "Scene.Settings.Misc.Proxy.Enable.Title", fallback: "Proxy")
          }
          public enum Port {
            /// Proxy server port must be numbers
            public static let error = L10n.tr("Localizable", "Scene.Settings.Misc.Proxy.Port.Error", fallback: "Proxy server port must be numbers")
            /// Port
            public static let title = L10n.tr("Localizable", "Scene.Settings.Misc.Proxy.Port.Title", fallback: "Port")
          }
          public enum `Type` {
            /// HTTP
            public static let http = L10n.tr("Localizable", "Scene.Settings.Misc.Proxy.Type.Http", fallback: "HTTP")
            /// Reverse
            public static let reverse = L10n.tr("Localizable", "Scene.Settings.Misc.Proxy.Type.Reverse", fallback: "Reverse")
            /// SOCKS
            public static let socks = L10n.tr("Localizable", "Scene.Settings.Misc.Proxy.Type.Socks", fallback: "SOCKS")
            /// Proxy type
            public static let title = L10n.tr("Localizable", "Scene.Settings.Misc.Proxy.Type.Title", fallback: "Proxy type")
          }
        }
      }
      public enum Notification {
        /// Accounts
        public static let accounts = L10n.tr("Localizable", "Scene.Settings.Notification.Accounts", fallback: "Accounts")
        /// Show Notification
        public static let notificationSwitch = L10n.tr("Localizable", "Scene.Settings.Notification.NotificationSwitch", fallback: "Show Notification")
        /// Push Notification
        public static let pushNotification = L10n.tr("Localizable", "Scene.Settings.Notification.PushNotification", fallback: "Push Notification")
        /// Notification
        public static let title = L10n.tr("Localizable", "Scene.Settings.Notification.Title", fallback: "Notification")
        public enum Mastodon {
          /// Favorite
          public static let favorite = L10n.tr("Localizable", "Scene.Settings.Notification.Mastodon.Favorite", fallback: "Favorite")
          /// Mention
          public static let mention = L10n.tr("Localizable", "Scene.Settings.Notification.Mastodon.Mention", fallback: "Mention")
          /// New Follow
          public static let newFollow = L10n.tr("Localizable", "Scene.Settings.Notification.Mastodon.NewFollow", fallback: "New Follow")
          /// poll
          public static let poll = L10n.tr("Localizable", "Scene.Settings.Notification.Mastodon.Poll", fallback: "poll")
          /// Reblog
          public static let reblog = L10n.tr("Localizable", "Scene.Settings.Notification.Mastodon.Reblog", fallback: "Reblog")
        }
      }
      public enum PrivacyAndSafety {
        /// Always show sensitive media
        public static let alwaysShowSensitiveMedia = L10n.tr("Localizable", "Scene.Settings.PrivacyAndSafety.AlwaysShowSensitiveMedia", fallback: "Always show sensitive media")
        /// Privacy and safety
        public static let title = L10n.tr("Localizable", "Scene.Settings.PrivacyAndSafety.Title", fallback: "Privacy and safety")
        public enum SectionHeader {
          /// Mute and Block
          public static let muteAndBlock = L10n.tr("Localizable", "Scene.Settings.PrivacyAndSafety.SectionHeader.MuteAndBlock", fallback: "Mute and Block")
          /// Sensitive Info
          public static let sensitive = L10n.tr("Localizable", "Scene.Settings.PrivacyAndSafety.SectionHeader.Sensitive", fallback: "Sensitive Info")
        }
      }
      public enum SectionHeader {
        /// About
        public static let about = L10n.tr("Localizable", "Scene.Settings.SectionHeader.About", fallback: "About")
        /// Account
        public static let account = L10n.tr("Localizable", "Scene.Settings.SectionHeader.Account", fallback: "Account")
        /// General
        public static let general = L10n.tr("Localizable", "Scene.Settings.SectionHeader.General", fallback: "General")
      }
      public enum Storage {
        /// Storage
        public static let title = L10n.tr("Localizable", "Scene.Settings.Storage.Title", fallback: "Storage")
        public enum All {
          /// Delete all Twidere X cache. Your account credentials will not be lost.
          public static let subTitle = L10n.tr("Localizable", "Scene.Settings.Storage.All.SubTitle", fallback: "Delete all Twidere X cache. Your account credentials will not be lost.")
          /// Clear all cache
          public static let title = L10n.tr("Localizable", "Scene.Settings.Storage.All.Title", fallback: "Clear all cache")
        }
        public enum Media {
          /// Clear stored media cache.
          public static let subTitle = L10n.tr("Localizable", "Scene.Settings.Storage.Media.SubTitle", fallback: "Clear stored media cache.")
          /// Clear media cache
          public static let title = L10n.tr("Localizable", "Scene.Settings.Storage.Media.Title", fallback: "Clear media cache")
        }
        public enum Search {
          /// Clear search history
          public static let title = L10n.tr("Localizable", "Scene.Settings.Storage.Search.Title", fallback: "Clear search history")
        }
      }
    }
    public enum SignIn {
      /// Hello!
      /// Sign in to Get Started.
      public static let helloSignInToGetStarted = L10n.tr("Localizable", "Scene.SignIn.HelloSignInToGetStarted", fallback: "Hello!\nSign in to Get Started.")
      /// Sign in with Mastodon
      public static let signInWithMastodon = L10n.tr("Localizable", "Scene.SignIn.SignInWithMastodon", fallback: "Sign in with Mastodon")
      /// Sign in with Twitter
      public static let signInWithTwitter = L10n.tr("Localizable", "Scene.SignIn.SignInWithTwitter", fallback: "Sign in with Twitter")
      public enum TwitterOptions {
        /// Sign in with Custom Twitter Key
        public static let signInWithCustomTwitterKey = L10n.tr("Localizable", "Scene.SignIn.TwitterOptions.SignInWithCustomTwitterKey", fallback: "Sign in with Custom Twitter Key")
        /// Twitter API v2 access is required.
        public static let twitterApiV2AccessIsRequired = L10n.tr("Localizable", "Scene.SignIn.TwitterOptions.TwitterApiV2AccessIsRequired", fallback: "Twitter API v2 access is required.")
      }
    }
    public enum Status {
      /// Tweet
      public static let title = L10n.tr("Localizable", "Scene.Status.Title", fallback: "Tweet")
      /// Toot
      public static let titleMastodon = L10n.tr("Localizable", "Scene.Status.TitleMastodon", fallback: "Toot")
      public enum Like {
        /// %d Likes
        public static func multiple(_ p1: Int) -> String {
          return L10n.tr("Localizable", "Scene.Status.Like.Multiple", p1, fallback: "%d Likes")
        }
        /// 1 Like
        public static let single = L10n.tr("Localizable", "Scene.Status.Like.Single", fallback: "1 Like")
      }
      public enum Quote {
        /// %d Quotes
        public static func mutiple(_ p1: Int) -> String {
          return L10n.tr("Localizable", "Scene.Status.Quote.Mutiple", p1, fallback: "%d Quotes")
        }
        /// 1 Quote
        public static let single = L10n.tr("Localizable", "Scene.Status.Quote.Single", fallback: "1 Quote")
      }
      public enum Reply {
        /// %d Replies
        public static func mutiple(_ p1: Int) -> String {
          return L10n.tr("Localizable", "Scene.Status.Reply.Mutiple", p1, fallback: "%d Replies")
        }
        /// 1 Reply
        public static let single = L10n.tr("Localizable", "Scene.Status.Reply.Single", fallback: "1 Reply")
      }
      public enum Retweet {
        /// %d Retweets
        public static func mutiple(_ p1: Int) -> String {
          return L10n.tr("Localizable", "Scene.Status.Retweet.Mutiple", p1, fallback: "%d Retweets")
        }
        /// 1 Retweet
        public static let single = L10n.tr("Localizable", "Scene.Status.Retweet.Single", fallback: "1 Retweet")
      }
    }
    public enum Timeline {
      /// Timeline
      public static let title = L10n.tr("Localizable", "Scene.Timeline.Title", fallback: "Timeline")
    }
    public enum Trends {
      /// %d people talking
      public static func accounts(_ p1: Int) -> String {
        return L10n.tr("Localizable", "Scene.Trends.Accounts", p1, fallback: "%d people talking")
      }
      /// Trending Now
      public static let now = L10n.tr("Localizable", "Scene.Trends.Now", fallback: "Trending Now")
      /// Trends
      public static let title = L10n.tr("Localizable", "Scene.Trends.Title", fallback: "Trends")
      /// Trends Location
      public static let trendsLocation = L10n.tr("Localizable", "Scene.Trends.TrendsLocation", fallback: "Trends Location")
      /// Trends - Worldwide
      public static let worldWide = L10n.tr("Localizable", "Scene.Trends.WorldWide", fallback: "Trends - Worldwide")
      /// Worldwide
      public static let worldWideWithoutPrefix = L10n.tr("Localizable", "Scene.Trends.WorldWideWithoutPrefix", fallback: "Worldwide")
    }
  }
  public enum Count {
    /// Plural format key: "Input limit remains %#@character_count@"
    public static func inputLimitRemains(_ p1: Int) -> String {
      return L10n.tr("Localizable", "count.input_limit_remains", p1, fallback: "Plural format key: \"Input limit remains %#@character_count@\"")
    }
    /// Plural format key: "%#@like_count@"
    public static func like(_ p1: Int) -> String {
      return L10n.tr("Localizable", "count.like", p1, fallback: "Plural format key: \"%#@like_count@\"")
    }
    /// Plural format key: "%#@count_media@"
    public static func media(_ p1: Int) -> String {
      return L10n.tr("Localizable", "count.media", p1, fallback: "Plural format key: \"%#@count_media@\"")
    }
    /// Plural format key: "%#@count_notification@"
    public static func notification(_ p1: Int) -> String {
      return L10n.tr("Localizable", "count.notification", p1, fallback: "Plural format key: \"%#@count_notification@\"")
    }
    /// Plural format key: "%#@count_people@"
    public static func people(_ p1: Int) -> String {
      return L10n.tr("Localizable", "count.people", p1, fallback: "Plural format key: \"%#@count_people@\"")
    }
    /// Plural format key: "%#@post_count@"
    public static func post(_ p1: Int) -> String {
      return L10n.tr("Localizable", "count.post", p1, fallback: "Plural format key: \"%#@post_count@\"")
    }
    /// Plural format key: "%#@quote_count@"
    public static func quote(_ p1: Int) -> String {
      return L10n.tr("Localizable", "count.quote", p1, fallback: "Plural format key: \"%#@quote_count@\"")
    }
    /// Plural format key: "%#@reblog_count@"
    public static func reblog(_ p1: Int) -> String {
      return L10n.tr("Localizable", "count.reblog", p1, fallback: "Plural format key: \"%#@reblog_count@\"")
    }
    /// Plural format key: "%#@reply_count@"
    public static func reply(_ p1: Int) -> String {
      return L10n.tr("Localizable", "count.reply", p1, fallback: "Plural format key: \"%#@reply_count@\"")
    }
    /// Plural format key: "%#@retweet_count@"
    public static func retweet(_ p1: Int) -> String {
      return L10n.tr("Localizable", "count.retweet", p1, fallback: "Plural format key: \"%#@retweet_count@\"")
    }
    /// Plural format key: "%#@count_vote@"
    public static func vote(_ p1: Int) -> String {
      return L10n.tr("Localizable", "count.vote", p1, fallback: "Plural format key: \"%#@count_vote@\"")
    }
    public enum MetricFormatted {
      /// Plural format key: "%@ %#@post_count@"
      public static func post(_ p1: Any, _ p2: Int) -> String {
        return L10n.tr("Localizable", "count.metric_formatted.post", String(describing: p1), p2, fallback: "Plural format key: \"%@ %#@post_count@\"")
      }
    }
    public enum People {
      /// Plural format key: "%#@count_people_talking@"
      public static func talking(_ p1: Int) -> String {
        return L10n.tr("Localizable", "count.people.talking", p1, fallback: "Plural format key: \"%#@count_people_talking@\"")
      }
    }
  }
  public enum Date {
    public enum Day {
      /// Plural format key: "%#@count_day_left@"
      public static func `left`(_ p1: Int) -> String {
        return L10n.tr("Localizable", "date.day.left", p1, fallback: "Plural format key: \"%#@count_day_left@\"")
      }
    }
    public enum Hour {
      /// Plural format key: "%#@count_hour_left@"
      public static func `left`(_ p1: Int) -> String {
        return L10n.tr("Localizable", "date.hour.left", p1, fallback: "Plural format key: \"%#@count_hour_left@\"")
      }
    }
    public enum Minute {
      /// Plural format key: "%#@count_minute_left@"
      public static func `left`(_ p1: Int) -> String {
        return L10n.tr("Localizable", "date.minute.left", p1, fallback: "Plural format key: \"%#@count_minute_left@\"")
      }
    }
    public enum Month {
      /// Plural format key: "%#@count_month_left@"
      public static func `left`(_ p1: Int) -> String {
        return L10n.tr("Localizable", "date.month.left", p1, fallback: "Plural format key: \"%#@count_month_left@\"")
      }
    }
    public enum Second {
      /// Plural format key: "%#@count_second_left@"
      public static func `left`(_ p1: Int) -> String {
        return L10n.tr("Localizable", "date.second.left", p1, fallback: "Plural format key: \"%#@count_second_left@\"")
      }
    }
    public enum Year {
      /// Plural format key: "%#@count_year_left@"
      public static func `left`(_ p1: Int) -> String {
        return L10n.tr("Localizable", "date.year.left", p1, fallback: "Plural format key: \"%#@count_year_left@\"")
      }
    }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg..., fallback value: String) -> String {
    let format = Bundle.module.localizedString(forKey: key, value: value, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}
