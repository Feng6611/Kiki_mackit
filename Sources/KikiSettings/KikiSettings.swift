import AppKit
import SwiftUI

@MainActor
public final class KikiSettingsNavigationModel<Tab: Hashable>: ObservableObject {
    @Published public var selectedTab: Tab

    public init(selectedTab: Tab) {
        self.selectedTab = selectedTab
    }
}

public enum KikiSettingsUI {
    public struct FormPane<Content: View>: View {
        private let content: Content

        public init(@ViewBuilder content: () -> Content) {
            self.content = content()
        }

        public var body: some View {
            Form {
                content
            }
            .formStyle(.grouped)
        }
    }

    public struct LinkButton: View {
        private let title: String
        private let urlString: String
        private let systemImage: String?

        public init(title: String, urlString: String, systemImage: String? = nil) {
            self.title = title
            self.urlString = urlString
            self.systemImage = systemImage
        }

        public var body: some View {
            Button {
                KikiSettingsUI.openURL(urlString)
            } label: {
                if let systemImage {
                    Label(title, systemImage: systemImage)
                } else {
                    Text(title)
                }
            }
            .buttonStyle(.link)
        }
    }

    public struct CopyRow: View {
        private let title: String
        private let value: String
        private let systemImage: String?

        public init(title: String, value: String, systemImage: String? = nil) {
            self.title = title
            self.value = value
            self.systemImage = systemImage
        }

        public var body: some View {
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(value, forType: .string)
            } label: {
                HStack(spacing: 8) {
                    if let systemImage {
                        Label(title, systemImage: systemImage)
                    } else {
                        Text(title)
                    }
                    Spacer(minLength: 0)
                    Text(value)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
    }

    public struct AppIdentityView: View {
        private let appName: String
        private let versionText: String
        private let icon: NSImage
        private let iconSize: CGFloat

        public init(
            appName: String,
            versionText: String,
            icon: NSImage = NSApp.applicationIconImage,
            iconSize: CGFloat = 76
        ) {
            self.appName = appName
            self.versionText = versionText
            self.icon = icon
            self.iconSize = iconSize
        }

        public var body: some View {
            VStack(spacing: 8) {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: iconSize, height: iconSize)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: .black.opacity(0.10), radius: 8, y: 4)

                Text(appName)
                    .font(.system(size: 20, weight: .semibold))

                Text(versionText)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    public struct ApplicationRow: View {
        private let bundleID: String
        private let removeAction: (String) -> Void

        public init(bundleID: String, removeAction: @escaping (String) -> Void) {
            self.bundleID = bundleID
            self.removeAction = removeAction
        }

        private var applicationURL: URL? {
            NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)
        }

        private var displayName: String {
            guard let applicationURL else {
                return bundleID
            }

            return FileManager.default.displayName(atPath: applicationURL.path)
        }

        public var body: some View {
            HStack(spacing: 8) {
                icon

                Text(displayName)
                    .font(.caption)
                    .lineLimit(1)
                    .help(bundleID)

                Spacer(minLength: 0)

                Button {
                    removeAction(bundleID)
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .help("Remove \(displayName)")
                .accessibilityLabel("Remove \(displayName)")
            }
        }

        @ViewBuilder
        private var icon: some View {
            if let applicationURL {
                Image(nsImage: NSWorkspace.shared.icon(forFile: applicationURL.path))
                    .resizable()
                    .frame(width: 16, height: 16)
            } else {
                Image(systemName: "app")
                    .frame(width: 16, height: 16)
                    .foregroundStyle(.secondary)
            }
        }
    }

    public struct ApplicationPicker<Applications: RandomAccessCollection>: View where Applications.Element == NSRunningApplication {
        private let applications: Applications
        @Binding private var selection: String?
        private let isDisabled: Bool
        private let addAction: (String) -> Void

        public init(
            applications: Applications,
            selection: Binding<String?>,
            isDisabled: Bool,
            addAction: @escaping (String) -> Void
        ) {
            self.applications = applications
            self._selection = selection
            self.isDisabled = isDisabled
            self.addAction = addAction
        }

        public var body: some View {
            HStack {
                Picker(selection: $selection) {
                    Text("Select an app...").tag(String?.none)
                    ForEach(pickerApplications) { application in
                        Text(application.displayName)
                            .tag(Optional(application.bundleID))
                    }
                } label: {
                    EmptyView()
                }
                .labelsHidden()
                .disabled(isDisabled)

                Button("Add") {
                    guard let selection else {
                        return
                    }

                    addAction(selection)
                    self.selection = nil
                }
                .disabled(selection == nil || isDisabled)
            }
        }

        private var pickerApplications: [KikiApplicationPickerItem] {
            var seenBundleIDs = Set<String>()
            return applications.compactMap { application -> KikiApplicationPickerItem? in
                guard let bundleID = application.bundleIdentifier else {
                    return nil
                }

                guard seenBundleIDs.insert(bundleID).inserted else {
                    return nil
                }

                return KikiApplicationPickerItem(
                    bundleID: bundleID,
                    displayName: application.localizedName ?? bundleID
                )
            }
        }
    }

    public static func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            return
        }

        NSWorkspace.shared.open(url)
    }
}

public extension View {
    func kikiSettingDescription() -> some View {
        font(.caption)
            .foregroundStyle(.secondary)
    }
}

@MainActor
public final class KikiSettingsWindowController {
    private let frameAutosaveName: NSWindow.FrameAutosaveName
    private let minimumContentSize: CGSize
    private let windowTitle: String

    public init(
        frameAutosaveName: String,
        minimumContentSize: CGSize,
        windowTitle: String = "Settings"
    ) {
        self.frameAutosaveName = NSWindow.FrameAutosaveName(frameAutosaveName)
        self.minimumContentSize = minimumContentSize
        self.windowTitle = windowTitle
    }

    public var isVisible: Bool {
        visibleSettingsWindows.isEmpty == false
    }

    public func prepareForSettingsScene() {
        activateApp()
        DispatchQueue.main.async { [weak self] in
            self?.restoreSettingsWindowFrame()
        }
    }

    private func activateApp() {
        NSRunningApplication.current.activate(options: [.activateIgnoringOtherApps])

        if #available(macOS 14.0, *) {
            NSApplication.shared.activate()
        } else {
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }

    private var visibleSettingsWindows: [NSWindow] {
        NSApp.windows.filter { window in
            window.isVisible && window.title == windowTitle
        }
    }

    private func restoreSettingsWindowFrame() {
        for window in visibleSettingsWindows {
            window.contentMinSize = minimumContentSize
            window.center()
            window.setFrameUsingName(frameAutosaveName)
            window.setFrameAutosaveName(frameAutosaveName)
            enforceMinimumContentSize(for: window)
        }
    }

    private func enforceMinimumContentSize(for window: NSWindow) {
        let currentContentSize = window.contentLayoutRect.size
        guard currentContentSize.width < minimumContentSize.width
                || currentContentSize.height < minimumContentSize.height else {
            return
        }

        var frame = window.frame
        let targetContentSize = CGSize(
            width: max(currentContentSize.width, minimumContentSize.width),
            height: max(currentContentSize.height, minimumContentSize.height)
        )
        let targetFrame = window.frameRect(forContentRect: CGRect(origin: .zero, size: targetContentSize))
        frame.size.width = targetFrame.size.width
        frame.size.height = targetFrame.size.height
        window.setFrame(frame, display: true)
    }
}

@MainActor
public final class KikiSettingsOpener {
    private let windowController: KikiSettingsWindowController?

    public init(windowController: KikiSettingsWindowController? = nil) {
        self.windowController = windowController
    }

    public func prepare() {
        windowController?.prepareForSettingsScene()
    }

    public func open(preparesWindow: Bool = true) {
        if preparesWindow {
            prepare()
        }

        if performMainMenuSettingsItem() {
            return
        }

        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    private func performMainMenuSettingsItem() -> Bool {
        guard let mainMenu = NSApp.mainMenu else {
            return false
        }

        return performSettingsItem(in: mainMenu)
    }

    private func performSettingsItem(in menu: NSMenu) -> Bool {
        for (index, item) in menu.items.enumerated() {
            if isSettingsItem(item), item.isEnabled {
                menu.performActionForItem(at: index)
                return true
            }

            if let submenu = item.submenu,
               performSettingsItem(in: submenu) {
                return true
            }
        }

        return false
    }

    private func isSettingsItem(_ item: NSMenuItem) -> Bool {
        if item.keyEquivalent == "," {
            return true
        }

        let normalizedTitle = item.title
            .replacingOccurrences(of: "…", with: "...")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        return normalizedTitle == "settings..."
            || normalizedTitle == "preferences..."
    }
}

private struct KikiApplicationPickerItem: Identifiable {
    let bundleID: String
    let displayName: String

    var id: String {
        bundleID
    }
}
