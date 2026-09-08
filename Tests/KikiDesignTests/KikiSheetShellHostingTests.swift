import AppKit
import SwiftUI
import Testing
@testable import KikiDesign

@MainActor
@Suite(.serialized)
struct KikiSheetShellHostingTests {
    private final class Model: ObservableObject {
        @Published var contentHeight: CGFloat = 80
        @Published var footerHeight: CGFloat = 40
        var contentAppears = 0
        var footerAppears = 0
        var contentTasks = 0
        var footerTasks = 0
        var shellSize = CGSize.zero
        var footerFrame = CGRect.zero
        var contentFrame = CGRect.zero
    }

    private struct Fixture: View {
        @ObservedObject var model: Model
        var fixed = false
        var body: some View {
            KikiSheetShell(width: 300, minimumHeight: fixed ? 300 : 160,
                           idealHeight: 220, maximumHeight: 300) {
                Color.red.frame(height: model.contentHeight)
                    .background(GeometryReader { proxy in
                        Color.clear.onAppear { model.contentFrame = proxy.frame(in: .global) }
                            .onChange(of: proxy.frame(in: .global)) { model.contentFrame = $0 }
                    })
                    .onAppear { model.contentAppears += 1 }
                    .task { model.contentTasks += 1 }
            } footer: {
                Color.blue.frame(height: model.footerHeight)
                    .background(GeometryReader { proxy in
                        Color.clear.onAppear { model.footerFrame = proxy.frame(in: .global) }
                            .onChange(of: proxy.frame(in: .global)) { model.footerFrame = $0 }
                    })
                    .onAppear { model.footerAppears += 1 }
                    .task { model.footerTasks += 1 }
            }
            .background(GeometryReader { proxy in
                Color.clear.onAppear { model.shellSize = proxy.size }
                    .onChange(of: proxy.size) { model.shellSize = $0 }
            })
        }
    }

    private func settle<V: View>(_ host: NSHostingView<V>) async {
        for _ in 0..<20 {
            host.layoutSubtreeIfNeeded()
            try? await Task.sleep(for: .milliseconds(10))
        }
    }

    @Test("Mounted documents resize within bounds without remounting or duplicate tasks")
    func adaptiveLayout() async throws {
        let model = Model()
        let host = NSHostingView(rootView: Fixture(model: model))
        host.frame = CGRect(x: 0, y: 0, width: 300, height: 300)
        await settle(host)
        #expect(abs(model.shellSize.height - 160) < 1)
        #expect(abs(model.footerFrame.height - 40) < 1)

        model.contentHeight = 210
        await settle(host)
        #expect(abs(model.shellSize.height - 250) < 1)

        model.contentHeight = 900
        await settle(host)
        #expect(abs(model.shellSize.height - 300) < 1)
        let pinnedFooterY = model.footerFrame.minY
        let contentScroll = try #require(descendants(host).compactMap { $0 as? NSScrollView }
            .first { abs($0.contentView.bounds.height - 260) < 1 })
        #expect(abs(model.contentFrame.height - 900) < 1)
        let contentY = model.contentFrame.minY
        let footerScroll = try #require(descendants(host).compactMap { $0 as? NSScrollView }
            .first { abs($0.contentView.bounds.height - 40) < 1 })
        contentScroll.contentView.scroll(to: NSPoint(x: 0, y: 100))
        contentScroll.reflectScrolledClipView(contentScroll.contentView)
        await settle(host)
        #expect(contentScroll.contentView.bounds.minY > 0)
        #expect(model.contentFrame.minY < contentY)
        #expect(abs(model.footerFrame.minY - pinnedFooterY) < 1)
        model.contentHeight = 1200
        host.frame.size = CGSize(width: 500, height: 500)
        await settle(host)
        #expect(abs(model.shellSize.width - 300) < 1)
        #expect(abs(model.shellSize.height - 300) < 1)
        #expect(abs(model.footerFrame.height - 40) < 1)
        // Resizing the host may center the whole shell; compare again at the same host size.
        model.contentHeight = 900
        await settle(host)
        let resizedFooterY = model.footerFrame.minY
        model.contentHeight = 1000
        await settle(host)
        #expect(abs(model.footerFrame.minY - resizedFooterY) < 1)

        model.footerHeight = 500
        await settle(host)
        #expect(abs(model.shellSize.height - 300) < 1)
        #expect(abs(model.footerFrame.height - 500) < 1)
        // Scroll viewports reserve half for an oversized footer, not its document height.
        let scrolls = descendants(host).compactMap { $0 as? NSScrollView }
        #expect(scrolls.count == 2)
        #expect(scrolls.allSatisfy { abs($0.contentView.bounds.height - 150) < 1 })

        let footerY = model.footerFrame.minY
        footerScroll.contentView.scroll(to: NSPoint(x: 0, y: 100))
        footerScroll.reflectScrolledClipView(footerScroll.contentView)
        await settle(host)
        #expect(footerScroll.contentView.bounds.minY > 0)
        #expect(model.footerFrame.minY < footerY)

        model.contentHeight = 30
        model.footerHeight = 40
        await settle(host)
        #expect(abs(model.shellSize.height - 160) < 1)
        #expect(model.contentAppears == 1)
        #expect(model.footerAppears == 1)
        #expect(model.contentTasks == 1)
        #expect(model.footerTasks == 1)
    }

    @Test("Equal minimum and maximum keep a fixed shell with pinned footer")
    func fixedLayout() async {
        let model = Model()
        let host = NSHostingView(rootView: Fixture(model: model, fixed: true))
        host.frame = CGRect(x: 0, y: 0, width: 300, height: 300)
        await settle(host)
        let footerY = model.footerFrame.minY
        model.contentHeight = 1500
        await settle(host)
        #expect(abs(model.shellSize.height - 300) < 1)
        #expect(abs(model.footerFrame.minY - footerY) < 1)
        let scrolls = descendants(host).compactMap { $0 as? NSScrollView }
        #expect(scrolls.count == 2)
        #expect(scrolls.contains { abs($0.contentView.bounds.height - 260) < 1 })
        #expect(scrolls.contains { abs($0.contentView.bounds.height - 40) < 1 })
        #expect(model.contentAppears == 1 && model.footerAppears == 1)
        #expect(model.contentTasks == 1 && model.footerTasks == 1)
    }

    @Test("Content-only initializer measures its single document without footer space")
    func contentOnly() async {
        let model = Model()
        let shell = KikiSheetShell(width: 300, minimumHeight: 100, idealHeight: 200, maximumHeight: 300) {
            Color.red.frame(height: 180)
                .onAppear { model.contentAppears += 1 }
                .task { model.contentTasks += 1 }
        }.background(GeometryReader { proxy in
            Color.clear.onAppear { model.shellSize = proxy.size }
                .onChange(of: proxy.size) { model.shellSize = $0 }
        })
        let host = NSHostingView(rootView: shell)
        host.frame = CGRect(x: 0, y: 0, width: 300, height: 300)
        await settle(host)
        #expect(abs(model.shellSize.height - 180) < 1)
        let scrolls = descendants(host).compactMap { $0 as? NSScrollView }
        #expect(scrolls.contains { abs($0.contentView.bounds.height - 180) < 1 })
        #expect(model.contentAppears == 1 && model.contentTasks == 1)
    }

    private func descendants(_ view: NSView) -> [NSView] {
        view.subviews.flatMap { [$0] + descendants($0) }
    }
}
