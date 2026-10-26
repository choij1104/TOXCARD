import UIKit
import Capacitor

/// Small native touches the web layer cannot do itself.
/// JS: Capacitor.registerPlugin('NativeUI')
///   haptic({ style: "selection" | "light" | "medium" | "success" | "warning" }) -> {}
///   appearance({ style: "system" | "light" | "dark" })  window appearance, so the status bar,
///                                                       keyboard and system sheets match the theme
///   share({ title, text })            -> { completed: Bool }   iOS share sheet with the card as text
///   printCard({ title, html })          -> { completed: Bool }   AirPrint of one card (UIPrintInteractionController)
@objc(NativeUIPlugin)
public class NativeUIPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "NativeUIPlugin"
    public let jsName = "NativeUI"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "haptic", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "appearance", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "share", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "printCard", returnType: CAPPluginReturnPromise)
    ]

    @objc func haptic(_ call: CAPPluginCall) {
        let style = call.getString("style") ?? "selection"
        DispatchQueue.main.async {
            switch style {
            case "light": UIImpactFeedbackGenerator(style: .light).impactOccurred()
            case "medium": UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            case "success": UINotificationFeedbackGenerator().notificationOccurred(.success)
            case "warning": UINotificationFeedbackGenerator().notificationOccurred(.warning)
            default: UISelectionFeedbackGenerator().selectionChanged()
            }
            call.resolve()
        }
    }

    @objc func appearance(_ call: CAPPluginCall) {
        let style = call.getString("style") ?? "system"
        DispatchQueue.main.async {
            let s: UIUserInterfaceStyle = style == "dark" ? .dark : (style == "light" ? .light : .unspecified)
            self.bridge?.viewController?.view.window?.overrideUserInterfaceStyle = s
            call.resolve()
        }
    }

    private func anchor(_ vc: UIViewController) -> CGRect {
        CGRect(x: vc.view.bounds.midX, y: vc.view.bounds.maxY - 90, width: 1, height: 1)
    }

    @objc func share(_ call: CAPPluginCall) {
        let text = call.getString("text") ?? ""
        guard !text.isEmpty else { call.reject("Nothing to share."); return }
        DispatchQueue.main.async {
            guard let vc = self.bridge?.viewController else { call.reject("No view controller."); return }
            let sheet = UIActivityViewController(activityItems: [text], applicationActivities: nil)
            if let pop = sheet.popoverPresentationController {
                pop.sourceView = vc.view
                pop.sourceRect = self.anchor(vc)
            }
            sheet.completionWithItemsHandler = { _, completed, _, _ in call.resolve(["completed": completed]) }
            vc.present(sheet, animated: true)
        }
    }

    @objc func printCard(_ call: CAPPluginCall) {
        let html = call.getString("html") ?? ""
        guard !html.isEmpty else { call.reject("Nothing to print."); return }
        let title = call.getString("title") ?? "TOXCARD"
        DispatchQueue.main.async {
            guard UIPrintInteractionController.isPrintingAvailable else {
                call.resolve(["completed": false])
                return
            }
            let info = UIPrintInfo(dictionary: nil)
            info.outputType = .general
            info.jobName = title
            let pc = UIPrintInteractionController.shared
            pc.printInfo = info
            let f = UIMarkupTextPrintFormatter(markupText: html)
            f.perPageContentInsets = UIEdgeInsets(top: 48, left: 48, bottom: 48, right: 48)
            pc.printFormatter = f
            pc.present(animated: true) { _, completed, _ in call.resolve(["completed": completed]) }
        }
    }
}
