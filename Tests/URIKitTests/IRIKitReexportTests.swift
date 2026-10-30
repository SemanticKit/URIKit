import Foundation
import Testing
import URIKit

/// These tests import only URIKit and check that what it exposes is IRIKit:
/// RFC 3987 validation and section 5 normalization, with repair of boundary
/// text left to the decoder that read it.
@Suite("import URIKit re-exports IRIKit", .tags(.reexport))
struct IRIKitReexportTests {
    @Test("The IRI type seen through URIKit is IRIKit's IRI.")
    func iriIsIRIKitsType() throws {
        let viaURIKit: URIKit.IRI = try IRI(validating: "https://example.org/a")
        let viaIRIKit: IRIKit.IRI = viaURIKit

        #expect(viaIRIKit.rawValue == "https://example.org/a")
    }

    @Test("Scheme-based normalization follows RFC 3987 section 5.")
    func normalizesSchemeHostPathAndDefaultPort() throws {
        let iri = try IRI(validating: "HTTPS://BÜCHER.Example:443/a/./b/../c")

        // The legible IDN is kept, and the ACE spelling is equivalent.
        #expect(try iri.normalized(.syntaxAndSchemeBased).rawValue == "https://bücher.example/a/c")
        #expect(try iri.isEquivalent(
            to: IRI(validating: "https://xn--bcher-kva.example/a/c"),
            under: .syntaxAndSchemeBased
        ))
    }

    @Test("Authority-free URNs keep their case-sensitive parts.")
    func normalizesURN() throws {
        let iri = try IRI(validating: "URN:example:Animal:ferret:nose")

        #expect(try iri.normalized(.syntaxAndSchemeBased).rawValue == "urn:example:Animal:ferret:nose")
    }

    @Test(
        "Text that still carries boundary noise is rejected, not repaired; the decoder that read it fixes it first.",
        arguments: [
            "  https://example.org/a  ",
            "https://example.org/with space",
            "https://example.org\\folder\\file",
        ]
    )
    func boundaryTextIsNotAnIRI(_ text: String) {
        #expect(throws: IRIError.invalidIRI(text)) {
            _ = try IRI(validating: text)
        }
    }

    @Test("IRIKit does not decode XML entities; an undecoded entity stays in the IRI as literal text.")
    func xmlEntitiesAreNotDecoded() throws {
        let iri = try IRI(validating: "https://example.org/q?a=1&amp;b=2")

        #expect(iri.rawValue == "https://example.org/q?a=1&amp;b=2")
        #expect(try iri.normalized(.syntaxAndSchemeBased).rawValue == "https://example.org/q?a=1&amp;b=2")
    }

    @Test("HTTP-family IRIs without a host fail scheme-based normalization.")
    func requiresHostForHTTPFamily() throws {
        let iri = try IRI(validating: "https:/relative")

        #expect(throws: IRIError.invalidIRI("https:/relative")) {
            _ = try iri.normalized(.syntaxAndSchemeBased)
        }
    }

    @Test("Empty or all-whitespace text is not an IRI.", arguments: ["", "  \n \t  "])
    func rejectsEmptyInput(_ text: String) {
        #expect(throws: IRIError.invalidIRI(text)) {
            _ = try IRI(validating: text)
        }
    }

    @Test("Percent-encoded spaces and query ampersands survive scheme-based normalization.")
    func percentEncodingAndQuerySurviveNormalization() throws {
        let iri = try IRI(validating: "HTTPS://Example.org/folder/file%20name?a=1&b=2")

        #expect(try iri.normalized(.syntaxAndSchemeBased).rawValue == "https://example.org/folder/file%20name?a=1&b=2")
    }

    @Test("A boundary that needs an ASCII host gets the ACE form from Foundation.")
    func aceHostComesFromFoundationAtTheBoundary() throws {
        let iri = try IRI(validating: "https://Bücher.example/private/card").normalized(.syntaxAndSchemeBased)

        #expect(URLComponents(string: iri.rawValue)?.encodedHost == "xn--bcher-kva.example")
        #expect(URL(string: iri.rawValue)?.absoluteString == "https://xn--bcher-kva.example/private/card")
    }
}
