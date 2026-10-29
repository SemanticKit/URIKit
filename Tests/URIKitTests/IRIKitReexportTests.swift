import Testing
import URIKit

/// URIKit has folded into IRIKit. These tests import only URIKit and check
/// that its former behaviours now come from IRIKit's types, and that the
/// behaviours IRIKit deliberately changed are left to the boundary step.
@Suite("import URIKit re-exports IRIKit", .tags(.reexport))
struct IRIKitReexportTests {
    @Test("The IRI type seen through URIKit is IRIKit's IRI.")
    func iriIsIRIKitsType() throws {
        let viaURIKit: URIKit.IRI = try IRI(validating: "https://example.org/a")
        let viaIRIKit: IRIKit.IRI = viaURIKit

        #expect(viaIRIKit.rawValue == "https://example.org/a")
    }

    @Test("Former strict normalization is RFC 3987 section 5 normalization in IRIKit.")
    func normalizesSchemeHostPathAndDefaultPort() throws {
        let iri = try IRI(validating: "HTTPS://BÜCHER.Example:443/a/./b/../c")

        // URIKit printed the ACE host "xn--bcher-kva.example". IRIKit keeps
        // the legible IDN and treats the ACE spelling as equivalent.
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
        "Surrounding whitespace and XML escaping are not IRI text; the decoder that read the text removes them first.",
        arguments: [
            "  https://example.org/a  ",
            "HTTPS://Example.org\\folder\\file name?a=1&amp;b=2",
        ]
    )
    func boundaryTextIsNotAnIRI(_ text: String) {
        #expect(throws: IRIError.invalidIRI(text)) {
            _ = try IRI(validating: text)
        }
    }
}
