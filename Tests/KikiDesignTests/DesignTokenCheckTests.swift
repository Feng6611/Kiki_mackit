import Foundation
import Testing

struct DesignTokenCheckTests {
    private var packageRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private var script: URL {
        packageRoot.appendingPathComponent("script/check_design_tokens.sh")
    }

    private func check(_ files: [URL] = []) throws -> (status: Int32, report: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = [script.path] + files.map(\.path)

        let standardOutput = Pipe()
        let standardError = Pipe()
        process.standardOutput = standardOutput
        process.standardError = standardError
        try process.run()
        process.waitUntilExit()

        let output = standardOutput.fileHandleForReading.readDataToEndOfFile()
        let error = standardError.fileHandleForReading.readDataToEndOfFile()
        let report = String(decoding: output + error, as: UTF8.self)
        return (process.terminationStatus, report)
    }

    private func fixture(_ contents: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("kiki-design-tokens-\(UUID().uuidString).swift")
        try contents.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    @Test("Kiki source chrome uses design tokens")
    func packageSourcesPass() throws {
        let result = try check()
        #expect(result.status == 0)
        #expect(result.report.contains("Design tokens: OK ("))
    }

    @Test("The check catches tab-spaced numbers and hex colors")
    func rawValuesFailWithFileAndLine() throws {
        let file = try fixture("""
        .padding(.horizontal,\t18)
        let color = Color(hex: "#FF00AA")
        """)
        defer { try? FileManager.default.removeItem(at: file) }

        let result = try check([file])
        #expect(result.status == 1)
        #expect(result.report.contains("\(file.path):1:"))
        #expect(result.report.contains("\(file.path):2:"))
    }

    @Test("An unreadable path exits with status 2")
    func unreadablePathFails() throws {
        let missing = FileManager.default.temporaryDirectory
            .appendingPathComponent("kiki-design-tokens-missing-\(UUID().uuidString).swift")
        let result = try check([missing])
        #expect(result.status == 2)
        #expect(result.report.contains("cannot read \(missing.path)"))
    }

    @Test("Tokens and a reasoned exemption pass")
    func tokenizedAndExemptValuesPass() throws {
        let file = try fixture("""
        .padding(.horizontal, KikiDesignTokens.Spacing.xl)
        .opacity(KikiDesignTokens.Opacity.subtleFill)
        let brand = Color(red: 0.2, green: 0.3, blue: 0.4) // token-exempt: fixture brand color
        """)
        defer { try? FileManager.default.removeItem(at: file) }

        let result = try check([file])
        #expect(result.status == 0)
    }
}
