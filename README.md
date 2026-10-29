# URIKit

URIKit has folded into [IRIKit](https://github.com/SemanticKit/IRIKit).
IRIKit is the one type for identifiers that enter or leave the SemanticKit
runtime, and it owns RFC 3987 section 5 comparison and normalization.

The `URIKit` product now contains no identifier code of its own. It
re-exports IRIKit, so `import URIKit` still compiles and gives you IRIKit's
`IRI`, `IRIReference`, `AbsoluteIRI` and `IRINormalization`. Replace
`import URIKit` with `import IRIKit`, and depend on IRIKit directly. Do not
add new code here.

## Moving from URIKit to IRIKit

| URIKit | IRIKit |
| --- | --- |
| `URINormalizer().normalize(uri: s)` | `try IRI(validating: s).normalized(.syntaxAndSchemeBased)` |
| `URINormalizer().normalize(uri: s, strict: false)` | `try IRI(validating: s).normalized(.syntaxBased)` |
| comparing two normalized strings | `try lhs.isEquivalent(to: rhs, under: .syntaxAndSchemeBased)` |
| `URINormalizationError` | `IRIError` |
| `LegacyXMLIRICompatibility` | the XML decoder, then `IRI(validating:)` (see below) |

## Behaviours that move to the boundary

IRIKit validates the text it is given and does not repair it. Three things
URIKit did belong to the step that reads or writes the text, not to the
identifier type:

- **Whitespace trimming.** URIKit trimmed surrounding whitespace before it
  validated. An IRI cannot contain whitespace, so the decoder that read the
  text (a Turtle or RDF/XML reader, an HTTP header parser) trims it and then
  calls `IRI(validating:)`.
- **XML repair.** `LegacyXMLIRICompatibility` decoded XML entities, turned
  backslashes into slashes and percent-encoded inner whitespace. Entity
  decoding is the XML format's job (RFC 3987 section 5.2) and happens in the
  RDF/XML decoder. Backslashes and raw spaces are not IRI characters, so an
  identifier that still has them after decoding is rejected, not repaired.
- **ACE output.** URIKit printed internationalized hosts in their ASCII
  Compatible Encoding (`xn--bcher-kva.example`). IRIKit keeps the legible
  form (`bücher.example`) and treats both spellings as equivalent under
  `.syntaxAndSchemeBased`. Code that needs an ASCII host, such as a DNS
  lookup, produces the ACE form at that boundary.
