import Foundation
import WordPressShared
import WordPressComAnalytics
import WordPress_AppbotX

class AboutViewController: ImmuTableViewController {
    required convenience init() {
        self.init(style: .Grouped)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCustomCells()
        setupTableModel()
        setupNavigationItem()
        setupDismissButtonIfNeeded()
        setupTableHeader()
        setupTableFooter()
        customizeAppearance()
    }

    // MARK: - View Controller Setup

    private func setupCustomCells() {
        registerRows([
            TextRow.self,
            LinkRow.self,
            LinkWithValueRow.self
            ])
    }

    private func setupTableModel() {
        let versionRow = TextRow(
            title: NSLocalizedString("Version", comment: "Displays the version of the App"),
            value: NSBundle.mainBundle().shortVersionString())
        let tosRow = LinkRow(
            title: NSLocalizedString("Terms of Service", comment: "Opens the Terms of Service Web"),
            action: openURL(NSURL(string: WPAutomatticTermsOfServiceURL)!)
            )
        let privacyRow = LinkRow(
            title: NSLocalizedString("Privacy Policy", comment: "Opens the Privacy Policy Web"),
            action: openURL(NSURL(string: WPAutomatticPrivacyURL)!)
            )

        let twitterRow = LinkWithValueRow(
            title: NSLocalizedString("Twitter", comment: "Launches the Twitter App"),
            value: WPTwitterWordPressHandle,
            action: openExternalURL(NSURL(string: WPTwitterWordPressMobileURL)!)
        )

        let blogRow = LinkWithValueRow(
            title: NSLocalizedString("Blog", comment: "Opens the WordPress Mobile Blog"),
            value: appsBlogHostname(),
            action: openURL(NSURL(string: WPAutomatticAppsBlogURL)!)
        )

        let ratingsRow = LinkRow(
            title: NSLocalizedString("Rate us on the App Store", comment: "Prompts the user to rate us on the store"),
            action: displayRatingPrompt()
        )

        let sourceRow = LinkRow(
            title: NSLocalizedString("Source Code", comment: "Opens the Github Repository Web"),
            action: openURL(NSURL(string: WPGithubMainURL)!)
        )

        viewModel = ImmuTable(sections: [
            ImmuTableSection(rows: [
                versionRow,
                tosRow,
                privacyRow
                ]),
            ImmuTableSection(rows: [
                twitterRow,
                blogRow,
                ratingsRow,
                sourceRow
                ])
            ])
    }

    private func setupNavigationItem() {
        title = NSLocalizedString("About", comment: "About this app (information page title)")

        // Don't show 'About' in the next-view back button
        navigationItem.backBarButtonItem = UIBarButtonItem(title: String(), style: .Plain, target: nil, action: nil)
    }

    private func setupTableHeader() {
        let iconBottomPadding = CGFloat(30)
        // Load and Tint the Logo
        let color = WPStyleGuide.wordPressBlue()
        let tintedImage = UIImage(named: "icon-wp")?.imageTintedWithColor(color)
        let imageView = UIImageView(image: tintedImage)
        imageView.autoresizingMask = [.FlexibleLeftMargin, .FlexibleRightMargin]
        imageView.contentMode = .Top

        // Let's add a bottom padding!
        imageView.frame.size.height += iconBottomPadding

        // Finally, setup the TableView
        tableView.tableHeaderView = imageView
    }

    private func setupTableFooter() {
        let calendar                = NSCalendar.currentCalendar()
        let year                    = calendar.components(.Year, fromDate: NSDate()).year

        let footerView              = WPTableViewSectionHeaderFooterView(reuseIdentifier: nil, style: .Footer)
        footerView.title            = NSLocalizedString("© \(year) Automattic, Inc.", comment: "About View's Footer Text")
        footerView.titleAlignment   = .Center
        tableView.tableFooterView             = footerView
    }

    private func customizeAppearance() {
        tableView.contentInset      = WPTableViewContentInsets

        WPStyleGuide.resetReadableMarginsForTableView(tableView)
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
    }

    private func setupDismissButtonIfNeeded() {
        // Don't display a dismiss button, unless this is the only view in the stack!
        if navigationController?.viewControllers.count > 1 {
            return
        }

        let title = NSLocalizedString("Close", comment: "Dismiss the current view")
        let style = WPStyleGuide.barButtonStyleForBordered()
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: title, style: style, target: self, action: "dismissWasPressed:")
    }

    // MARK: - Helpers

    private func appsBlogHostname() -> String {
        return NSURL(string: WPAutomatticAppsBlogURL)!.host ?? ""
    }

    // MARK: - Cell actions

    private func openURL(url: NSURL) -> (ImmuTableRow) -> Void {
        return { [unowned self] _ in

            let webViewController = WPWebViewController(URL: url)
            if self.presentingViewController != nil {
                self.navigationController?.pushViewController(webViewController, animated: true)
            } else {
                let navController = UINavigationController(rootViewController: webViewController)
                self.presentViewController(navController, animated: true, completion: nil)
            }
        }
    }

    private func openExternalURL(url: NSURL) -> (ImmuTableRow) -> Void {
        return { _ in
            UIApplication.sharedApplication().openURL(url)
        }
    }
    
    private func displayRatingPrompt() -> (ImmuTableRow) -> Void {
        return { _ in
            // Note:
            // Let's follow the same procedure executed as in NotificationsViewController, so that if the user
            // manually decides to rate the app, we don't render the prompt!
            //
            WPAnalytics.track(.AppReviewsRatedApp)
            AppRatingUtility.ratedCurrentVersion()
            ABXAppStore.openAppStoreForApp(WPiTunesAppId)
        }
    }
}
