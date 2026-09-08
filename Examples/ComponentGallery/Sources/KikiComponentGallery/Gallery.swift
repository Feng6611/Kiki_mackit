import SwiftUI
import KikiSettings
import KikiReview
import KikiOnboarding

@main
struct GalleryApp: App {
    var body: some Scene {
        WindowGroup("Kiki Component Gallery") { Gallery() }
            .defaultSize(width: 640, height: 720)
    }
}

struct Gallery: View {
    @State private var longCopy = false
    @State private var loading = false
    @State private var disabled = false
    @State private var dark = false
    @State private var reduceMotion = false
    @State private var option = 0
    @State private var step = 0
    @State private var review = false
    @State private var result = "No action yet"
    @State private var reviewController = KikiReviewPromptController()

    private var configuration: KikiReviewPromptConfiguration {
        .init(windowTitle: "Review preview",
              title: longCopy ? "Vielen Dank, dass Sie unsere Anwendung verwenden" : "Enjoying the app?",
              message: longCopy
                ? String(repeating: "Ihre Rückmeldung hilft uns, die Anwendung verständlicher und zugänglicher zu gestalten. ", count: 6)
                : "A short review helps other people discover the app.",
              primaryActionTitle: longCopy ? "Eine Bewertung im App Store schreiben" : "Review on App Store",
              secondaryActionTitle: longCopy ? "Vielleicht zu einem späteren Zeitpunkt" : "Not Now")
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Toggle("Long copy", isOn: $longCopy)
                Toggle("Loading", isOn: $loading)
                Toggle("Disabled", isOn: $disabled)
                Toggle("Dark", isOn: $dark)
            }.padding()
            Toggle("Disable animations (system Reduce Motion is also respected)", isOn: $reduceMotion).padding(.horizontal)
            TabView {
                KikiSettingsPane {
                    Section("Rows") {
                        KikiSettingsCopyRow(title: "Email", value: "hello@example.com", systemImage: "envelope")
                        KikiSettingsLinkRow(title: "Intercepted link", value: "example.com",
                                            urlString: "https://example.com", systemImage: "link",
                                            action: { result = "Link callback received" })
                        KikiSettingsSegmentedPickerRow("Aggregation", selection: $option,
                            options: [0, 1, 2], optionTitle: { index in
                                longCopy ? ["Nach Kalendertagen", "Nach Kalenderwochen", "Nach Kalendermonaten"][index]
                                         : ["Day", "Week", "Month"][index]
                            })
                    }.disabled(disabled)
                    Section("Presentation") {
                        Button("Review sheet") { review = true }
                        Button("Review window") {
                            reviewController.show(configuration: configuration) { result = String(describing: $0) }
                        }
                        Text(result).foregroundStyle(.secondary)
                        KikiOnboardingProgressDots(count: 3, currentIndex: step)
                        Button("Next step") { step = (step + 1) % 3 }
                    }
                }.tabItem { Label("Rows", systemImage: "list.bullet") }
                KikiStandardAboutPane(
                    metadata: .init(appName: "Gallery", bundleIdentifier: "dev.kiki.gallery",
                                    shortVersion: "0.10.0", buildNumber: "1"),
                    accessStatus: .init(tone: .neutral, title: "Account status",
                                        subtitle: longCopy ? String(repeating: "Additional detail. ", count: 20) : "Caller-owned status detail",
                                        actionTitle: "Refresh", isActionLoading: loading),
                    onAccessAction: { result = "Refresh requested" },
                    links: .init(website: URL(string: "https://example.com")!),
                    tint: .purple,
                    onOpenLink: { result = $0.absoluteString }
                ).tabItem { Label("About", systemImage: "info.circle") }
            }
        }
        .frame(minWidth: 420, minHeight: 500)
        .preferredColorScheme(dark ? .dark : .light)
        .transaction { if reduceMotion { $0.disablesAnimations = true } }
        .sheet(isPresented: $review) {
            KikiReviewPromptView(configuration: configuration,
                onReview: { result = "Review action"; review = false },
                onNotNow: { result = "Not now"; review = false },
                onClose: { result = "Closed"; review = false })
        }
    }
}
