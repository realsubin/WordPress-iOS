import UIKit

class WPSplitViewController: UISplitViewController {
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return viewControllers.first?.preferredStatusBarStyle() ?? .LightContent
    }
}
