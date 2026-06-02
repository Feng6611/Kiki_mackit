import AppKit

@MainActor
package enum KikiAppActivation {
    package static func activate() {
        if #available(macOS 14.0, *) {
            if let frontmostApplication = NSWorkspace.shared.frontmostApplication,
               frontmostApplication.processIdentifier != ProcessInfo.processInfo.processIdentifier,
               NSRunningApplication.current.activate(from: frontmostApplication) {
                return
            }

            NSApplication.shared.activate()
        } else {
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }
}

package enum KikiURLActions {
    package static func open(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            return
        }

        NSWorkspace.shared.open(url)
    }
}
