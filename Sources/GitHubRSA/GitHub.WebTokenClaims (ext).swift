public import GitHubAPI
public import JSON
public import JWT

extension GitHub.WebTokenClaims {
    /// Always returns ``iat`` advanced by ten minutes.
    @inlinable public var exp: Int64 { self.iat + 600 }

    /// Always returns ``JSON.WebTokenHeader.Alg/rs256``.
    @inlinable public var alg: JSON.WebTokenHeader.Alg { .rs256 }
}
extension GitHub.WebTokenClaims {
    @frozen public enum CodingKey: String, Sendable {
        case alg
        case exp
        case iat
        case iss
    }
}
extension GitHub.WebTokenClaims: JSONObjectEncodable {
    public func encode(to json: inout JSON.ObjectEncoder<CodingKey>) {
        json[.alg] = self.alg
        json[.exp] = self.exp
        json[.iat] = self.iat
        json[.iss] = self.iss
    }
}
