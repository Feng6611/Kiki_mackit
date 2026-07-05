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
            website: URL(string: "https://example.com"),
            feedback: nil,
            github: URL(string: "https://github.com/foo/bar")
        )
        let ordered = links.orderedLinks
        #expect(ordered.map(\.id) == ["website", "github"])
    }

    @Test("Standard about links produces empty list when none provided")
    func standardLinksReturnsEmptyWhenNoneProvided() {
        let links = KikiStandardAboutLinks()
        #expect(links.orderedLinks.isEmpty)
    }

    @Test("mailto feedback link resolves to copy kind with email value")
    func mailtoFeedbackResolvesToCopy() {
        let links = KikiStandardAboutLinks(
            feedback: URL(string: "mailto:hello@example.com")
        )
        let link = links.orderedLinks.first
        #expect(link?.kind == .copy)
        #expect(link?.value == "hello@example.com")
        #expect(link?.systemImage == "envelope")
    }

    @Test("https link resolves to link kind with host value")
    func httpsLinkResolvesToLinkWithHost() {
        let links = KikiStandardAboutLinks(
            website: URL(string: "https://www.example.com/path")
        )
        let link = links.orderedLinks.first
        #expect(link?.kind == .link)
        #expect(link?.value == "example.com")
        #expect(link?.systemImage == "globe")
    }

    @Test("Explicit value and kind override derivation")
    func explicitValueAndKindOverride() {
        let link = KikiStandardAboutLink(
            id: "repo",
            title: "GitHub",
            url: URL(string: "https://github.com/foo/bar")!,
            value: "foo/bar",
            systemImage: "chevron.left.forwardslash.chevron.right"
        )
        #expect(link.kind == .link)
        #expect(link.value == "foo/bar")
        #expect(link.systemImage == "chevron.left.forwardslash.chevron.right")
    }
}
