// URIKit has folded into IRIKit. This module holds no identifier
// implementation of its own: importing URIKit imports IRIKit, so existing
// `import URIKit` lines keep compiling while callers move to `import IRIKit`.
@_exported import IRIKit
