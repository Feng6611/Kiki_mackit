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
    public let systemImage: String?
    public let kind: KikiStandardAboutLinkKind

    public init(
        id: String,
        title: String,
        url: URL,
        systemImage: String? = nil
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.kind = .link
        self.value = Self.deriveValue(from: url, kind: .link)
        self.systemImage = systemImage
    }

    public init(
        id: String,
        title: String,
        url: URL,
        value: String?,
        systemImage: String? = nil,
        kind: KikiStandardAboutLinkKind = .link
    ) {
        self.id = id
        self.title = title
        self.url = url
        let resolvedKind = (kind == .link && url.scheme == "mailto") ? .copy : kind
        self.kind = resolvedKind
        self.value = value ?? Self.deriveValue(from: url, kind: resolvedKind)
        self.systemImage = systemImage ?? Self.deriveSystemImage(from: url, kind: resolvedKind)
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

    private static func deriveSystemImage(from url: URL, kind: KikiStandardAboutLinkKind) -> String {
        if kind == .copy, url.scheme == "mailto" {
            return "envelope"
        }
        return "link"
    }
}

public struct KikiStandardAboutLinks: Equatable, Sendable {
    public let terms: URL?
    public let privacy: URL?
    public let support: URL?
    public let website: URL?
    public let feedback: URL?
    public let github: URL?

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
        self.website = website
        self.feedback = feedback
        self.github = nil
    }

    public init(
        website: URL? = nil,
        feedback: URL? = nil,
        github: URL?
    ) {
        self.terms = nil
        self.privacy = nil
        self.support = nil
        self.website = website
        self.feedback = feedback
        self.github = github
    }

    public var orderedLinks: [KikiStandardAboutLink] {
        var result: [KikiStandardAboutLink] = []
        if let website {
            result.append(KikiStandardAboutLink(
                id: "website",
                title: "Official",
                url: website,
                value: nil,
                systemImage: "globe"
            ))
        }
        if let feedback {
            result.append(KikiStandardAboutLink(
                id: "feedback",
                title: "Email",
                url: feedback,
                value: nil
            ))
        }
        if let support {
            result.append(KikiStandardAboutLink(
                id: "support",
                title: "Support",
                url: support,
                value: nil,
                systemImage: "lifepreserver"
            ))
        }
        if let github {
            result.append(KikiStandardAboutLink(
                id: "github",
                title: "GitHub",
                url: github,
                value: nil,
                systemImage: "chevron.left.forwardslash.chevron.right"
            ))
        }
        if let terms {
            result.append(KikiStandardAboutLink(
                id: "terms",
                title: "Terms of use",
                url: terms,
                value: nil,
                systemImage: "doc.text"
            ))
        }
        if let privacy {
            result.append(KikiStandardAboutLink(
                id: "privacy",
                title: "Privacy policy",
                url: privacy,
                value: nil,
                systemImage: "lock.shield"
            ))
        }
        return result
    }
}
