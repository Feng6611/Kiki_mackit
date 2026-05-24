import AppKit
import ApplicationServices
import CoreGraphics
import Foundation

public enum KikiAuthorizationStatus: Equatable, Sendable {
    case authorized
    case notAuthorized
}

public enum KikiAuthorizationPanel: String, CaseIterable, Sendable {
    case accessibility = "Privacy_Accessibility"
    case screenRecording = "Privacy_ScreenCapture"

    public var title: String {
        switch self {
        case .accessibility:
            return "Accessibility"
        case .screenRecording:
            return "Screen Recording"
        }
    }

    public var systemImage: String {
        switch self {
        case .accessibility:
            return "accessibility"
        case .screenRecording:
            return "rectangle.on.rectangle"
        }
    }

    public var settingsURL: URL {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?\(rawValue)"
        ) else {
            preconditionFailure("Invalid System Settings URL for \(rawValue)")
        }

        return url
    }

    @MainActor
    public var status: KikiAuthorizationStatus {
        isAuthorized ? .authorized : .notAuthorized
    }

    @MainActor
    public var isAuthorized: Bool {
        switch self {
        case .accessibility:
            return AXIsProcessTrusted()
        case .screenRecording:
            return CGPreflightScreenCaptureAccess()
        }
    }

    @discardableResult
    @MainActor
    public func requestSystemPrompt() -> Bool {
        switch self {
        case .accessibility:
            let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
            return AXIsProcessTrustedWithOptions([promptKey: true] as CFDictionary)
        case .screenRecording:
            return CGRequestScreenCaptureAccess()
        }
    }
}
