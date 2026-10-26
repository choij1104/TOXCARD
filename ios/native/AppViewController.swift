import UIKit
import WebKit
import Capacitor

/// Registers TOXCARD's own native plugins with the Capacitor bridge and gives the web view the
/// app's ground colour in light and dark appearance, so nothing flashes behind it.
class AppViewController: CAPBridgeViewController {
    override open func capacitorDidLoad() {
        bridge?.registerPluginInstance(LaunchRoutePlugin())
        bridge?.registerPluginInstance(SpotlightPlugin())
        bridge?.registerPluginInstance(QuickActionsPlugin())
        bridge?.registerPluginInstance(NativeUIPlugin())

        let ground = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.039, green: 0.043, blue: 0.043, alpha: 1)   // #0A0B0B
                : UIColor(red: 0.937, green: 0.941, blue: 0.929, alpha: 1)   // #EFF0ED
        }
        view.backgroundColor = ground
        webView?.isOpaque = false
        webView?.backgroundColor = ground
        webView?.scrollView.backgroundColor = ground
    }
}
