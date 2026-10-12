import AppKit
import SwiftUI
import Testing
@testable import KikiSettings

@MainActor
@Suite(.serialized)
struct KikiSettingsFittingHostingTests {
    private enum Tab: Hashable {
        case short
        case tall
    }

    @MainActor
    private final class Probe: ObservableObject {
        @Published var showsExtraRows = false
        private(set) var taskRuns: [Tab: Int] = [:]

        func recordTask(for tab: Tab) {
            taskRuns[tab, default: 0] += 1
        }
    }

    private struct Root: View {
        let coordinator: KikiSettingsCoordinator<Tab>
        @ObservedObject var probe: Probe

        var body: some View {
            KikiSettingsCoordinatorView(coordinator: coordinator) { tab in
                KikiSettingsPane {
                    Section {
                        if tab == .short {
                            Text("Short pane")
                            if probe.showsExtraRows {
                                ForEach(0..<40, id: \.self) { index in
                                    Text("Additional row \(index)")
                                }
                            }
                        } else {
                            ForEach(0..<80, id: \.self) { index in
                                Text("Tall row \(index)")
                            }
                        }
                    }
                }
                .task {
                    probe.recordTask(for: tab)
                }
            }
        }
    }

    private struct WindowFixture {
        let host: NSHostingView<Root>
        let coordinator: KikiSettingsCoordinator<Tab>
        let probe: Probe
        let layout: KikiSettingsWindowLayout
        let window: FakeSettingsWindow
    }

    @MainActor
    private final class FakeSettingsWindow: KikiSettingsWindowManaging {
        var isVisible = true
        var contentHeight: CGFloat = 0
        private var minimumHeight: CGFloat = 0
        private var maximumHeight: CGFloat = .greatestFiniteMagnitude
        var onContentHeightChange: ((CGFloat) -> Void)?

        func configure(
            frameAutosaveName: NSWindow.FrameAutosaveName,
            idealContentSize: CGSize,
            minimumContentSize: CGSize,
            maximumContentSize: CGSize,
            heightPolicy: KikiSettingsWindowHeightPolicy
        ) {
            contentHeight = idealContentSize.height
            minimumHeight = minimumContentSize.height
            maximumHeight = maximumContentSize.height
        }

        func fitContentHeight(_ height: CGFloat) {
            contentHeight = min(max(height, minimumHeight), maximumHeight)
            onContentHeightChange?(contentHeight)
        }

        func close() {
            isVisible = false
        }
    }

    private func makeWindow(initialTab: Tab) -> WindowFixture {
        let layout = KikiSettingsWindowLayout(
            ideal: CGSize(width: 500, height: 620),
            minimum: CGSize(width: 500, height: 480),
            maximum: CGSize(width: 500, height: 780),
            heightPolicy: .fitsContent
        )
        let controller = KikiSettingsWindowController(
            frameAutosaveName: "KikiSettingsFittingHostingTests",
            layout: layout
        )
        let window = FakeSettingsWindow()
        controller.register(managedWindow: window)
        let coordinator = KikiSettingsCoordinator(
            tabs: [
                KikiSettingsTabSpec(.short, title: "Short", systemImage: "circle"),
                KikiSettingsTabSpec(.tall, title: "Tall", systemImage: "circle.fill")
            ],
            initialTab: initialTab,
            windowController: controller
        )
        let probe = Probe()
        let host = NSHostingView(rootView: Root(coordinator: coordinator, probe: probe))
        host.frame = CGRect(origin: .zero, size: layout.ideal)
        window.onContentHeightChange = { [weak host] height in
            host?.frame.size = CGSize(width: layout.ideal.width, height: height)
            host?.layoutSubtreeIfNeeded()
        }

        return WindowFixture(
            host: host,
            coordinator: coordinator,
            probe: probe,
            layout: layout,
            window: window
        )
    }

    private func settle(_ fixture: WindowFixture) async {
        for _ in 0..<45 {
            fixture.host.layoutSubtreeIfNeeded()
            try? await Task.sleep(for: .milliseconds(10))
        }
    }

    @Test("fitsContent refits short and tall panes without restarting pane tasks")
    func fitsPaneHeightsAndPreservesPaneTask() async throws {
        let fixture = makeWindow(initialTab: .short)
        defer { fixture.window.onContentHeightChange = nil }

        await settle(fixture)

        let shortHeight = fixture.window.contentHeight
        #expect(shortHeight >= fixture.layout.minimum.height)
        #expect(shortHeight < fixture.layout.ideal.height)
        #expect(fixture.host.frame.height == shortHeight)
        #expect(fixture.host.frame.width == fixture.layout.ideal.width)
        #expect(fixture.probe.taskRuns[.short] == 1)

        fixture.probe.showsExtraRows = true
        await settle(fixture)
        #expect(fixture.window.contentHeight > shortHeight)
        #expect(fixture.host.frame.width == fixture.layout.ideal.width)
        #expect(fixture.probe.taskRuns[.short] == 1)

        fixture.coordinator.select(.tall)
        await settle(fixture)

        #expect(abs(fixture.window.contentHeight - fixture.layout.maximum.height) < 1)
        #expect(fixture.host.frame.height == fixture.layout.maximum.height)
        #expect(fixture.host.frame.width == fixture.layout.ideal.width)
        #expect(fixture.probe.taskRuns[.tall] == 1)
    }
}
