#if canImport(Cryptography)
public import GitHubAPI
public import Cryptography
import JSON

extension RSA.PrivateKey {
    public func jwt(signing claims: GitHub.WebTokenClaims) throws -> String {
        let header: JSON.WebTokenHeader = .init(alg: .rs256)
        return try header.sign(encoding: claims) {
            try self.sign(hashing: $0[...], padding: .pkcs1_legacy, algorithm: .sha256)
        }
    }
}
#endif
