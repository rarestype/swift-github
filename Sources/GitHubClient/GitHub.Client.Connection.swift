public import GitHubAPI
public import HTTPClient
public import JSON
public import NIOCore
public import NIOHPACK
public import UnixTime

extension GitHub.Client {
    @frozen public struct Connection {
        @usableFromInline let http2: HTTP.Client2.Connection
        @usableFromInline let agent: String
        @usableFromInline let app: Application

        @inlinable internal init(
            http2: HTTP.Client2.Connection,
            agent: String,
            app: Application
        ) {
            self.http2 = http2
            self.agent = agent
            self.app = app
        }
    }
}
extension GitHub.Client.Connection {
    @inlinable func fetch(
        from endpoint: String,
        with authorization: GitHub.ClientAuthorization,
        method: String,
        body: ByteBuffer?
    ) async throws -> JSON {
        var endpoint: String = endpoint
        var status: UInt? = nil

        following:
        for _: Int in 0 ... 1 {
            let request: HTTP.Client2.Request = .init(
                headers: [
                    ":method": method,
                    ":scheme": "https",
                    ":authority": self.http2.remote,
                    ":path": endpoint,

                    "authorization": authorization.header,
                    //  GitHub will reject the API request if the user-agent is not set.
                    "user-agent": self.agent,
                    "accept": "application/vnd.github+json"
                ],
                body: body
            )

            let response: HTTP.Client2.Facet = try await self.http2.fetch(request)
            status = response.status

            //  TODO: support If-None-Match
            switch response.status {
            case 200?:
                return JSON.init(utf8: response.body[...])

            case 301?:
                if let location: String = response.headers?["location"].first {
                    endpoint = .init(location.trimmingPrefix("https://\(self.http2.remote)"))
                    continue following
                }

            case 403?:
                if  let second: String = response.headers?["x-ratelimit-reset"].first,
                    let second: Int64 = .init(second) {
                    throw GitHub.Client<Application>.RateLimitError.init(
                        until: .second(second)
                    )
                }

            case _:
                break
            }

            break following
        }

        throw HTTP.StatusError.init(code: status)
    }
}
extension GitHub.Client.Connection {
    /// Run a REST API request with the given credentials, following up to one redirect.
    @inlinable public func get<Response>(
        expecting _: Response.Type = Response.self,
        from endpoint: String,
        with authorization: GitHub.ClientAuthorization
    ) async throws -> Response where Response: JSONDecodable {
        let json: JSON = try await self.fetch(
            from: endpoint,
            with: authorization,
            method: "GET",
            body: nil
        )
        return try json.decode()
    }

    @discardableResult
    @inlinable public func post(
        to endpoint: String,
        with authorization: GitHub.ClientAuthorization
    ) async throws -> UInt {
        try await self.post(expecting: Never.self, from: endpoint, with: authorization).0
    }

    @inlinable public func post<Response>(
        expecting _: Response.Type = Response.self,
        from endpoint: String,
        with authorization: GitHub.ClientAuthorization
    ) async throws -> Response
        where Response: JSONDecodable {
        let (status, response): (UInt, Response?) = try await self.post(
            expecting: Response.self,
            from: endpoint,
            with: authorization
        )

        if  let response: Response {
            return response
        } else {
            throw HTTP.StatusError.init(code: status)
        }
    }

    @inlinable func post<Response>(
        expecting _: Response.Type,
        from endpoint: String,
        with authorization: GitHub.ClientAuthorization
    ) async throws -> (UInt, Response?)
        where Response: JSONDecodable {
        let response: HTTP.Client2.Facet = try await self.http2.fetch(
            [
                ":method": "POST",
                ":scheme": "https",
                ":authority": self.http2.remote,
                ":path": endpoint,

                "authorization": authorization.header,
                //  GitHub will reject the API request if the user-agent is not set.
                "user-agent": self.agent,
                "accept": "application/vnd.github+json",
                "x-github-api-version": "2022-11-28",
            ]
        )

        guard
        let status: UInt = response.status,
        case 200 ... 299 = status else {
            throw HTTP.StatusError.init(
                code: response.status,
                message: String.init(decoding: response.body, as: Unicode.UTF8.self)
            )
        }

        if  response.body.isEmpty {
            return (status, nil)
        } else {
            let json: JSON = .init(utf8: response.body[...])
            return (status, try json.decode())
        }
    }
}
extension GitHub.Client<()>.Connection {
    /// Run a GraphQL API request.
    ///
    /// The request will be charged to the user associated with the stored token. It is not
    /// possible to run a GraphQL API request without a token.
    @inlinable public func post<T>(
        query: String,
        expecting _: T.Type = T.self,
        with authorization: GitHub.ClientAuthorization
    ) async throws -> GraphQL.Response<T> where T: JSONDecodable {
        let json: JSON = try await self.fetch(
            from: "/graphql",
            with: authorization,
            method: "POST",
            body: self.http2.buffer(string: query),
        )
        return try json.decode()
    }
}
extension GitHub.Client<GitHub.OAuth>.Connection {
    /// Run a REST API request.
    @inlinable public func get<Response>(
        expecting _: Response.Type = Response.self,
        from endpoint: String
    ) async throws -> Response where Response: JSONDecodable {
        try await self.get(from: endpoint, with: .basic(self.app))
    }
}
