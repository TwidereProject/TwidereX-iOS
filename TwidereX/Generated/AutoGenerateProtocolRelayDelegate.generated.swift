// Generated using Sourcery 1.6.1 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// sourcery:inline:UserViewContainerTableViewCell.AutoGenerateProtocolRelayDelegate
func statusView(_ statusView: StatusView, headerDidPressed header: UIView) {
    delegate?.tableViewCell(self, statusView: statusView, headerDidPressed: header)
}

func statusView(_ statusView: StatusView, authorAvatarButtonDidPressed button: AvatarButton) {
    delegate?.tableViewCell(self, statusView: statusView, authorAvatarButtonDidPressed: button)
}

func statusView(_ statusView: StatusView, quoteStatusView: StatusView, authorAvatarButtonDidPressed button: AvatarButton) {
    delegate?.tableViewCell(self, statusView: statusView, quoteStatusView: quoteStatusView, authorAvatarButtonDidPressed: button)
}

func statusView(_ statusView: StatusView, expandContentButtonDidPressed button: UIButton) {
    delegate?.tableViewCell(self, statusView: statusView, expandContentButtonDidPressed: button)
}

func statusView(_ statusView: StatusView, metaTextAreaView: MetaTextAreaView, didSelectMeta meta: Meta) {
    delegate?.tableViewCell(self, statusView: statusView, metaTextAreaView: metaTextAreaView, didSelectMeta: meta)
}

func statusView(_ statusView: StatusView, quoteStatusView: StatusView, metaTextAreaView: MetaTextAreaView, didSelectMeta meta: Meta) {
    delegate?.tableViewCell(self, statusView: statusView, quoteStatusView: quoteStatusView, metaTextAreaView: metaTextAreaView, didSelectMeta: meta)
}

func statusView(_ statusView: StatusView, mediaGridContainerView containerView: MediaGridContainerView, didTapMediaView mediaView: MediaView, at index: Int) {
    delegate?.tableViewCell(self, statusView: statusView, mediaGridContainerView: containerView, didTapMediaView: mediaView, at: index)
}

func statusView(_ statusView: StatusView, mediaGridContainerView containerView: MediaGridContainerView, toggleContentWarningOverlayViewDisplay contentWarningOverlayView: ContentWarningOverlayView) {
    delegate?.tableViewCell(self, statusView: statusView, mediaGridContainerView: containerView, toggleContentWarningOverlayViewDisplay: contentWarningOverlayView)
}

func statusView(_ statusView: StatusView, quoteStatusView: StatusView, mediaGridContainerView containerView: MediaGridContainerView, didTapMediaView mediaView: MediaView, at index: Int) {
    delegate?.tableViewCell(self, statusView: statusView, quoteStatusView: quoteStatusView, mediaGridContainerView: containerView, didTapMediaView: mediaView, at: index)
}

func statusView(_ statusView: StatusView, pollTableView tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    delegate?.tableViewCell(self, statusView: statusView, pollTableView: tableView, didSelectRowAt: indexPath)
}

func statusView(_ statusView: StatusView, pollVoteButtonDidPressed button: UIButton) {
    delegate?.tableViewCell(self, statusView: statusView, pollVoteButtonDidPressed: button)
}

func statusView(_ statusView: StatusView, quoteStatusViewDidPressed quoteStatusView: StatusView) {
    delegate?.tableViewCell(self, statusView: statusView, quoteStatusViewDidPressed: quoteStatusView)
}

func statusView(_ statusView: StatusView, statusToolbar: StatusToolbar, actionDidPressed action: StatusToolbar.Action, button: UIButton) {
    delegate?.tableViewCell(self, statusView: statusView, statusToolbar: statusToolbar, actionDidPressed: action, button: button)
}

func statusView(_ statusView: StatusView, statusToolbar: StatusToolbar, menuActionDidPressed action: StatusToolbar.MenuAction, menuButton button: UIButton) {
    delegate?.tableViewCell(self, statusView: statusView, statusToolbar: statusToolbar, menuActionDidPressed: action, menuButton: button)
}

func statusView(_ statusView: StatusView, accessibilityActivate: Void) {
    delegate?.tableViewCell(self, statusView: statusView, accessibilityActivate: accessibilityActivate)
}

// sourcery:end

