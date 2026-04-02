extension GitHub {
    @frozen public struct WebTokenClaims: Sendable {
        /// The Unix second at which the token was issued.
        public let iat: Int64
        /// The ``App/client`` ID of the relevant GitHub App. This is not the ``App.id``!
        public let iss: String

        @inlinable public init(iat: Int64, iss: String) {
            self.iat = iat
            self.iss = iss
        }
    }
}
