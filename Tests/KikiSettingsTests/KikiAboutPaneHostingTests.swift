import AppKit
import SwiftUI
import Testing
@testable import KikiSettings

@MainActor
@Suite(.serialized)
struct KikiAboutPaneHostingTests {
    private let metadata = KikiAppMetadata(appName: "Fixture", bundleIdentifier: "test.fixture",
                                           shortVersion: "1", buildNumber: "1")

    @Test("Copy rows bypass the URL callback; links invoke it once with their URL")
    func copyRouting() {
        var opened: [URL] = []
        let pane = KikiStandardAboutPane(metadata: metadata, tint: .red, onOpenLink: { opened.append($0) })
        let mail = KikiStandardAboutLinks(feedback: URL(string: "mailto:test@example.com")!).orderedLinks[0]
        let explicitCopy = KikiStandardAboutLink(id: "copy", title: "Copy", url: URL(string: "https://example.com")!,
                                                 value: "copy value", kind: .copy)
        #expect(pane.customLinkAction(for: mail) == nil)
        #expect(pane.customLinkAction(for: explicitCopy) == nil)
        #expect(opened.isEmpty)
        let link = KikiStandardAboutLinks(website: URL(string: "https://example.com")!).orderedLinks[0]
        let action = pane.customLinkAction(for: link)
        #expect(action != nil)
        action?()
        #expect(opened == [link.url])
        #expect(KikiStandardAboutPane(metadata: metadata).customLinkAction(for: link) == nil)
    }

    private final class Probe {
        var counts: [String: Int] = [:]
        var positions: [String: CGFloat] = [:]
    }

    private func marker(_ name: String, _ probe: Probe) -> some View {
        Text(name).frame(height: 24)
            .onAppear { probe.counts[name, default: 0] += 1 }
            .background(GeometryReader { proxy in
                Color.clear.onAppear { probe.positions[name] = proxy.frame(in: .global).minY }
                    .onChange(of: proxy.frame(in: .global).minY) { probe.positions[name] = $0 }
            })
    }

    private func settle<V: View>(_ host: NSHostingView<V>) async {
        for _ in 0..<30 {
            host.layoutSubtreeIfNeeded()
            try? await Task.sleep(for: .milliseconds(10))
        }
    }

    @Test("Standard About mounts replacement status, extra links and sections in order")
    func standardExtensions() async throws {
        let probe = Probe()
        // Repeated slot modifiers replace the prior value and preserve the concrete pane type.
        let pane: KikiStandardAboutPane = KikiStandardAboutPane(metadata: metadata)
            .statusContent { marker("discarded", probe) }
            .statusContent { marker("status", probe) }
            .additionalLinks { marker("discardedLinks", probe) }
            .additionalLinks { marker("links", probe) }
            .additionalSections { Section { marker("discardedSection", probe) } }
            .additionalSections { Section { marker("section", probe) } }
        let host = NSHostingView(rootView: pane)
        host.frame = CGRect(x: 0, y: 0, width: 600, height: 1000)
        await settle(host)
        #expect(probe.counts == ["status": 1, "links": 1, "section": 1])
        let status = try #require(probe.positions["status"])
        let links = try #require(probe.positions["links"])
        let section = try #require(probe.positions["section"])
        #expect(status < links && links < section)
        host.frame.size.width = 700
        await settle(host)
        #expect(probe.counts == ["status": 1, "links": 1, "section": 1])
    }

    @Test("Base About keeps original status and links when appending sections")
    func baseExtensions() async throws {
        let probe = Probe()
        let pane = KikiAboutPane(appName: "Fixture", versionText: "1", status: {
            marker("status", probe)
        }, links: {
            marker("links", probe)
        }).additionalSections { Section { marker("discardedSection", probe) } }
            .additionalSections { Section { marker("section", probe) } }
        let host = NSHostingView(rootView: pane)
        host.frame = CGRect(x: 0, y: 0, width: 600, height: 1000)
        await settle(host)
        #expect(probe.counts == ["status": 1, "links": 1, "section": 1])
        #expect(try #require(probe.positions["links"]) < #require(probe.positions["section"]))
    }
}
