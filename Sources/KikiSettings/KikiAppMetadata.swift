import Foundation

public struct KikiAppMetadata: Equatable, Sendable {
    public let appName: String
    public let bundleIdentifier: String
    public let shortVersion: String
    public let buildNumber: String
    public let copyright: String?

    public init(
        appName: String,
        bundleIdentifier: String,
        shortVersion: String,
        buildNumber: String,
        copyright: String? = nil
    ) {
        self.appName = appName
        self.bundleIdentifier = bundleIdentifier
        self.shortVersion = shortVersion
        self.buildNumber = buildNumber
        self.copyright = copyright
    }

    public var displayVersion: String {
        if buildNumber.isEmpty || buildNumber == shortVersion {
            return "Version \(shortVersion)"
        }
        return "Version \(shortVersion) (\(buildNumber))"
    }

    public static func bundle(_ bundle: Bundle = .main) -> KikiAppMetadata {
        let info = bundle.infoDictionary ?? [:]
        let appName = (info["CFBundleDisplayName"] as? String)
            ?? (info["CFBundleName"] as? String)
            ?? bundle.bundleURL.deletingPathExtension().lastPathComponent
        let bundleIdentifier = (info["CFBundleIdentifier"] as? String) ?? bundle.bundleIdentifier ?? ""
        let shortVersion = (info["CFBundleShortVersionString"] as? String) ?? "0.0"
        let buildNumber = (info["CFBundleVersion"] as? String) ?? ""
        let copyright = info["NSHumanReadableCopyright"] as? String
        return KikiAppMetadata(
            appName: appName,
            bundleIdentifier: bundleIdentifier,
            shortVersion: shortVersion,
            buildNumber: buildNumber,
            copyright: copyright
        )
    }
}

public enum KikiStandardAboutLinkKind: Sendable {
    case link
    case copy
}

public struct KikiStandardAboutLink: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let url: URL
    public let value: String
    public let systemImage: String
    public let kind: KikiStandardAboutLinkKind

    public init(
        id: String,
        title: String,
        url: URL,
        value: String? = nil,
        systemImage: String? = nil,
        kind: KikiStandardAboutLinkKind = .link
    ) {
        self.id = id
        self.title = title
        self.url = url
        let resolvedKind = (kind == .link && url.scheme == "mailto") ? .copy : kind
        self.kind = resolvedKind
        self.value = value ?? Self.deriveValue(from: url, kind: resolvedKind)
        self.systemImage = systemImage ?? (resolvedKind == .copy ? "doc" : "link")
    }

    private static func deriveValue(from url: URL, kind: KikiStandardAboutLinkKind) -> String {
        if kind == .copy, url.scheme == "mailto" {
            return url.absoluteString.replacingOccurrences(of: "mailto:", with: "")
        }
        if let host = url.host {
            return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
        }
        return url.absoluteString
    }
}

public struct KikiStandardAboutLinks: Equatable, Sendable {
    public let terms: URL?
    public let privacy: URL?
    public let support: URL?
    public let feedback: URL?
    public let website: URL?

    public init(
        terms: URL? = nil,
        privacy: URL? = nil,
        support: URL? = nil,
        feedback: URL? = nil,
        website: URL? = nil
    ) {
        self.terms = terms
        self.privacy = privacy
        self.support = support
        self.feedback = feedback
        self.website = website
    }

    public var orderedLinks: [KikiStandardAboutLink] {
        var result: [KikiStandardAboutLink] = []
        if let website {
            result.append(KikiStandardAboutLink(
                id: "website",
                title: "Website",
                url: website,
                systemImage: "globe"
            ))
        }
        if let support {
            result.append(KikiStandardAboutLink(
                id: "support",
                title: "Support",
                url: support,
                systemImage: "lifepreserver"
            ))
        }
        if let feedback {
            result.append(KikiStandardAboutLink(
                id: "feedback",
                title: "Send feedback",
                url: feedback,
                systemImage: "envelope"
            ))
        }
        if let terms {
            result.append(KikiStandardAboutLink(
                id: "terms",
                title: "Terms of use",
                url: terms,
                systemImage: "doc.text"
            ))
        }
        if let privacy {
            result.append(KikiStandardAboutLink(
                id: "privacy",
                title: "Privacy policy",
                url: privacy,
                systemImage: "lock.shield"
            ))
        }
        return result
    }
}
