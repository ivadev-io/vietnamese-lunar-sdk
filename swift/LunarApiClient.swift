import Foundation

public struct LunarApiResponse {
    public let data: Data
    public let status: Int
    public let dailyLimit: Int?
    public let dailyRemaining: Int?
    public let dailyResetEpochSeconds: Int?
}

public struct LunarApiError: Error {
    public let status: Int
    public let data: Data
}

/// Transport-only Apple-platform client. It contains no calendar algorithm.
public actor LunarApiClient {
    private let apiKey: String
    private let baseURL: URL
    private let session: URLSession

    public init(apiKey: String, baseURL: URL = URL(string: "https://lunar.ivadev.workers.dev")!, session: URLSession = .shared) {
        precondition(!apiKey.isEmpty, "apiKey is required")
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.session = session
    }

    public func toLunar(date: String, profile: String? = nil) async throws -> LunarApiResponse {
        try await get(path: "/v1/lunar", query: [URLQueryItem(name: "date", value: date), URLQueryItem(name: "profile", value: profile)].filter { $0.value != nil })
    }

    public func toSolar(day: Int, month: Int, year: Int, isLeapMonth: Bool = false, profile: String? = nil) async throws -> LunarApiResponse {
        try await get(path: "/v1/solar", query: [URLQueryItem(name: "day", value: String(day)), URLQueryItem(name: "month", value: String(month)), URLQueryItem(name: "year", value: String(year)), URLQueryItem(name: "leap", value: String(isLeapMonth)), URLQueryItem(name: "profile", value: profile)].filter { $0.value != nil })
    }

    public func solarTerms(year: Int, profile: String? = nil) async throws -> LunarApiResponse {
        try await get(path: "/v1/solar-terms", query: [URLQueryItem(name: "year", value: String(year)), URLQueryItem(name: "profile", value: profile)].filter { $0.value != nil })
    }

    public func toLunarBatch(dates: [String], profile: String? = nil) async throws -> LunarApiResponse {
        precondition((1...31).contains(dates.count), "dates must contain 1 to 31 values")
        var body: [String: Any] = ["dates": dates]
        if let profile { body["profile"] = profile }
        var request = URLRequest(url: URL(string: "/v1/lunar/batch", relativeTo: baseURL)!.absoluteURL, timeoutInterval: 10)
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return try await perform(request)
    }

    private func get(path: String, query: [URLQueryItem]) async throws -> LunarApiResponse {
        var components = URLComponents(url: URL(string: path, relativeTo: baseURL)!.absoluteURL, resolvingAgainstBaseURL: false)!
        components.queryItems = query
        let request = URLRequest(url: components.url!, timeoutInterval: 10)
        return try await perform(request)
    }

    private func perform(_ original: URLRequest) async throws -> LunarApiResponse {
        var request = original
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue("swift/1.0.0", forHTTPHeaderField: "X-Client-Version")
        let (data, rawResponse) = try await session.data(for: request)
        let response = rawResponse as! HTTPURLResponse
        if !(200...299).contains(response.statusCode) { throw LunarApiError(status: response.statusCode, data: data) }
        return LunarApiResponse(data: data, status: response.statusCode, dailyLimit: response.value(forHTTPHeaderField: "X-RateLimit-Daily-Limit").flatMap(Int.init), dailyRemaining: response.value(forHTTPHeaderField: "X-RateLimit-Daily-Remaining").flatMap(Int.init), dailyResetEpochSeconds: response.value(forHTTPHeaderField: "X-RateLimit-Daily-Reset").flatMap(Int.init))
    }
}
