public import JSON

extension GitHub {
    @frozen public struct AppInstallationAccessTokenResponse: Sendable {
        public let token: InstallationAccessToken
        public let expires: String

        @inlinable public init(token: InstallationAccessToken, expires: String) {
            self.token = token
            self.expires = expires
        }
    }
}
extension GitHub.AppInstallationAccessTokenResponse {
    @frozen public enum CodingKey: String, Sendable {
        case token
        case expires_at
        case permissions
        case repository_selection
    }
}
extension GitHub.AppInstallationAccessTokenResponse: JSONObjectDecodable {
    public init(json: JSON.ObjectDecoder<CodingKey>) throws {
        self.init(token: try json[.token].decode(), expires: try json[.expires_at].decode())
    }
}
