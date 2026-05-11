import Testing
@testable import URIKit

@Test func strictNormalizationCanonicalizesSchemeHostPathAndDefaultPort() throws {
    let normalizer = URINormalizer()
    let normalized = try normalizer.normalize(uri: "HTTPS://BÜCHER.Example:443/a/./b/../c")
    #expect(normalized == "https://xn--bcher-kva.example/a/c")
}

@Test func strictNormalizationRejectsWhitespace() throws {
    let normalizer = URINormalizer()

    #expect(throws: URINormalizationError.self) {
        _ = try normalizer.normalize(uri: "https://example.org/with space")
    }
}

@Test func strictNormalizationRequiresAuthorityForHTTPFamily() throws {
    let normalizer = URINormalizer()

    #expect(throws: URINormalizationError.self) {
        _ = try normalizer.normalize(uri: "https:/relative")
    }
}

@Test func strictNormalizationAllowsAuthorityFreeURN() throws {
    let normalizer = URINormalizer()
    let normalized = try normalizer.normalize(uri: "URN:example:Animal:ferret:nose")

    #expect(normalized == "urn:example:Animal:ferret:nose")
}

@Test func legacyCompatibilityNormalizesXMLIdentifiers() throws {
    let compatibility = LegacyXMLIRICompatibility()
    let normalized = try compatibility.normalize(
        resourceIdentifier: "  HTTPS://Example.org\\folder\\file name?a=1&amp;b=2  "
    )

    #expect(normalized == "https://example.org/folder/file%20name?a=1&b=2")
}

@Test func legacyCompatibilityRejectsEmptyInput() throws {
    let compatibility = LegacyXMLIRICompatibility()

    #expect(throws: URINormalizationError.emptyInput) {
        _ = try compatibility.normalize(resourceIdentifier: "  \n \t  ")
    }
}
