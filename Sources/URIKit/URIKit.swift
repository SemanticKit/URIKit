import Foundation

public enum URINormalizationError: Error, Equatable {
    case emptyInput
    case invalidURI(String)
    case strictComplianceViolation(String)
}

public struct URINormalizer: Sendable {
    public init() {}

    public func normalize(uri: String, strict: Bool = true) throws -> String {
        let raw = uri.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else {
            throw URINormalizationError.emptyInput
        }
        if strict, raw.contains(where: \.isWhitespace) {
            throw URINormalizationError.strictComplianceViolation("Whitespace is not allowed in strict mode.")
        }

        guard let parsedURL = URL(string: raw),
              var components = URLComponents(url: parsedURL, resolvingAgainstBaseURL: false),
              let scheme = components.scheme,
              !scheme.isEmpty else {
            throw URINormalizationError.invalidURI(uri)
        }

        let normalizedScheme = scheme.lowercased()
        components.scheme = normalizedScheme

        if let host = components.host, !host.isEmpty {
            components.host = host.lowercased()
        } else if strict, Self.authoritySchemes.contains(normalizedScheme) {
            throw URINormalizationError.strictComplianceViolation(
                "Host component is required for \(normalizedScheme) URIs in strict mode."
            )
        }

        if let port = components.port, isDefaultPort(port, scheme: normalizedScheme) {
            components.port = nil
        }

        let percentEncodedPath = components.percentEncodedPath
        if !percentEncodedPath.isEmpty {
            components.percentEncodedPath = removeDotSegments(from: percentEncodedPath)
        } else if Self.authoritySchemes.contains(normalizedScheme), components.host != nil {
            components.percentEncodedPath = "/"
        }

        guard let normalized = components.string else {
            throw URINormalizationError.invalidURI(uri)
        }
        return normalized
    }

    private static let authoritySchemes: Set<String> = ["http", "https", "ftp", "ws", "wss"]

    private func isDefaultPort(_ port: Int, scheme: String) -> Bool {
        switch scheme.lowercased() {
        case "http":
            return port == 80
        case "https":
            return port == 443
        default:
            return false
        }
    }

    private func removeDotSegments(from path: String) -> String {
        let hasLeadingSlash = path.hasPrefix("/")
        let hasTrailingSlash = path.count > 1 && path.hasSuffix("/")
        var segments: [String] = []

        for segment in path.split(separator: "/", omittingEmptySubsequences: false).map(String.init) {
            if segment.isEmpty || segment == "." {
                continue
            }
            if segment == ".." {
                if !segments.isEmpty {
                    _ = segments.removeLast()
                }
                continue
            }
            segments.append(segment)
        }

        var normalized = segments.joined(separator: "/")
        if hasLeadingSlash {
            normalized = "/" + normalized
        }
        if normalized.isEmpty {
            normalized = hasLeadingSlash ? "/" : ""
        }
        if hasTrailingSlash, normalized != "/" {
            normalized += "/"
        }
        return normalized
    }
}

public struct LegacyXMLIRICompatibility: Sendable {
    private let normalizer: URINormalizer

    public init(normalizer: URINormalizer = .init()) {
        self.normalizer = normalizer
    }

    public func normalize(resourceIdentifier: String) throws -> String {
        let trimmed = resourceIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw URINormalizationError.emptyInput
        }

        let withoutControl = trimmed.filter { !$0.isASCIIControl }
        let unescaped = decodeXMLPredefinedEntities(in: withoutControl)
        let slashNormalized = unescaped.replacingOccurrences(of: "\\", with: "/")
        let collapsedWhitespace = slashNormalized.replacingOccurrences(
            of: #"\s+"#,
            with: "%20",
            options: .regularExpression
        )

        return try normalizer.normalize(uri: collapsedWhitespace, strict: false)
    }

    private func decodeXMLPredefinedEntities(in value: String) -> String {
        value
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&apos;", with: "'")
    }
}

private extension Character {
    var isASCIIControl: Bool {
        unicodeScalars.allSatisfy { $0.value < 0x20 || $0.value == 0x7F }
    }
}
