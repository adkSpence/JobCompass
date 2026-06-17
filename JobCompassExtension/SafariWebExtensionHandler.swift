import SafariServices
import os.log

class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {
    func beginRequest(with context: NSExtensionContext) {
        let item = context.inputItems.first as? NSExtensionItem
        let message = item?.userInfo?[SFExtensionMessageKey]

        os_log(.default, "JobCompass extension received message: %@", "\(String(describing: message))")

        // The extension communicates with the app via the jobcompass:// URL scheme
        // directly from background.js — no native messaging needed.
        // This handler is required by the extension target but is otherwise unused.
        context.completeRequest(returningItems: nil, completionHandler: nil)
    }
}
