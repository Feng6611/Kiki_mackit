import AppKit
import SwiftUI

public struct KikiSettingsApplicationRow: View {
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
        HStack(spacing: KikiSettingsSpacing.sm) {
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

public struct KikiSettingsApplicationPicker<Applications: RandomAccessCollection>: View where Applications.Element == NSRunningApplication {
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

private struct KikiApplicationPickerItem: Identifiable {
    let bundleID: String
    let displayName: String

    var id: String {
        bundleID
    }
}
