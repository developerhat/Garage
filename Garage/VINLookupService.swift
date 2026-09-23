import Foundation

struct VINDetails: Sendable {
    let year: Int?
    let make: String
    let model: String
    let trim: String
}

enum VINLookupError: LocalizedError {
    case invalidVIN
    case invalidResponse
    case notFound(String)

    var errorDescription: String? {
        switch self {
        case .invalidVIN:
            "Enter a complete 17-character VIN."
        case .invalidResponse:
            "The VIN service returned an unreadable response."
        case .notFound(let message):
            message.isEmpty ? "No vehicle information was found for that VIN." : message
        }
    }
}

struct VINLookupService {
    private struct Response: Decodable {
        let Results: [Result]
    }

    private struct Result: Decodable {
        let Make: String?
        let Model: String?
        let ModelYear: String?
        let Trim: String?
        let ErrorCode: String?
        let ErrorText: String?
    }

    func decode(_ vin: String) async throws -> VINDetails {
        let normalizedVIN = vin.uppercased()
        guard normalizedVIN.count == 17 else { throw VINLookupError.invalidVIN }

        let baseURL = URL(string: "https://vpic.nhtsa.dot.gov/api/vehicles/DecodeVinValues/")!
        let url = baseURL
            .appendingPathComponent(normalizedVIN)
            .appending(queryItems: [URLQueryItem(name: "format", value: "json")])
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw VINLookupError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(Response.self, from: data)
        guard let result = decoded.Results.first else { throw VINLookupError.invalidResponse }

        let errors = result.ErrorCode?
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) } ?? []
        guard errors.isEmpty || errors.allSatisfy({ $0 == "0" }) else {
            throw VINLookupError.notFound(result.ErrorText ?? "")
        }

        let make = result.Make?.trimmed ?? ""
        let model = result.Model?.trimmed ?? ""
        guard !make.isEmpty || !model.isEmpty else {
            throw VINLookupError.notFound(result.ErrorText ?? "")
        }

        return VINDetails(
            year: result.ModelYear.flatMap(Int.init),
            make: make,
            model: model,
            trim: result.Trim?.trimmed ?? ""
        )
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
