import Foundation
import KikiSettings
import Testing

struct KikiAppMetadataTests {
    @Test("Display version includes build number when distinct")
    func displayVersionIncludesBuildNumberWhenDistinct() {
        let metadata = KikiAppMetadata(
            appName: "Kiki",
            bundleIdentifier: "com.example.kiki",
            shortVersion: "1.0",
            buildNumber: "42"
        )
        #expect(metadata.displayVersion == "Version 1.0 (42)")
    }

    @Test("Display version omits build number when matching short version")
    func displayVersionOmitsBuildWhenSameAsShortVersion() {
        let matching = KikiAppMetadata(
            appName: "Kiki",
            bundleIdentifier: "com.example.kiki",
            shortVersion: "1.0",
            buildNumber: "1.0"
        )
        let empty = KikiAppMetadata(
            appName: "Kiki",
            bundleIdentifier: "com.example.kiki",
            shortVersion: "1.0",
            buildNumber: ""
        )
        #expect(matching.displayVersion == "Version 1.0")
        #expect(empty.displayVersion == "Version 1.0")
    }

    @Test("Standard about links emits ordered entries for provided URLs only")
    func standardLinksReturnOnlyProvidedURLs() throws {
        let links = KikiStandardAboutLinks(
            terms: URL(string: "https://example.com/terms"),
            privacy: nil,
            support: URL(string: "https://example.com/support"),
            feedback: nil,
            website: URL(string: "https://example.com")
        )
        let ordered = links.orderedLinks
        #expect(ordered.map(\.id) == ["website", "support", "terms"])
    }

    @Test("Standard about links produces empty list when none provided")
    func standardLinksReturnsEmptyWhenNoneProvided() {
        let links = KikiStandardAboutLinks()
        #expect(links.orderedLinks.isEmpty)
    }
}
