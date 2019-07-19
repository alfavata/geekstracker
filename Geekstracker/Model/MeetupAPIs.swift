//

import Foundation

protocol MeetupAPIsDelegate: class {
    func meetupAPIs(_: MeetupAPIs, didUpdateEvents result: Result<[MeetupModel.Event], Error>)
    func meetupAPIs(_: MeetupAPIs, didFetchAttendance result: Result<[MeetupModel.Attendance], Error>, for event: MeetupModel.Event)
}

class MeetupAPIs {
    
    enum Endpoint: String {
        case events
    }
    
    enum Error: Swift.Error {
        case connection(errorMessage: String)
        case response(statusCode: Int, errorMessage: String)
        
        var userFacingMessage: String {
            switch self {
            case let .connection(errorMessage):
                return "Connection error:\n\(errorMessage)"
            case let .response(errorCode, errorMessage):
                return "Response error (status code \(errorCode)):\n\(errorMessage)"
            }
        }
    }

    private let timestampFormatter = DateFormatter("yyyy-MM-dd")
    private let session = URLSession(configuration: .default)
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .millisecondsSince1970
        return decoder
    }()
    
    weak private var delegate: MeetupAPIsDelegate!
    
    init(delegate: MeetupAPIsDelegate) {
        self.delegate = delegate
    }
    
    // MARK: Events
    
    @objc
    func fetchEvents() {
        let interval = TimeInterval(60 * 60 * 24 * 180)
        
        func timestamp(for interval: TimeInterval) -> String {
            let date = Calendar.current.startOfDay(for: Date(timeIntervalSinceNow: interval))
            return timestampFormatter.string(from: date) + "T00:00:00.000"
        }
        
        let query: [String: LosslessStringConvertible] = [
            "desc": true,
            "status": "\(MeetupModel.Event.Status.upcoming),\(MeetupModel.Event.Status.past)",
            "no_earlier_than": timestamp(for: -interval),
            "no_later_than": timestamp(for: interval)
        ]
        session.dataTask(with: URLRequest(endpoint: .events, query: query)) {
            do {
                let events = try self.extract([MeetupModel.Event].self, from: ($0, $1, $2)).filter { $0.name.contains("Geekstraveganza") }
                self.delegate.meetupAPIs(self, didUpdateEvents: .success(events))
            } catch {
                self.delegate.meetupAPIs(self, didUpdateEvents: .failure(error))
            }
        }.resume()
    }
    
    // MARK: Members
    
    func fetchAttendance(_ event: MeetupModel.Event) {
        session.dataTask(with: URLRequest(endpoint: .events, path: "/\(event.id)/attendance")) {
            do {
                let attendance = try self.extract([MeetupModel.Attendance].self, from: ($0, $1, $2))
                self.delegate.meetupAPIs(self, didFetchAttendance: .success(attendance), for: event)
            } catch {
                self.delegate.meetupAPIs(self, didFetchAttendance: .failure(error), for: event)
            }
        }.resume()
    }
    
    // MARK: Private
    
    private func extract<T>(_ type: T.Type, from result: URLSessionDataTask.Result) throws -> T where T: Decodable {
        guard result.error == nil else { throw Error.connection(errorMessage: result.error!.localizedDescription) }
        guard let response = result.response as? HTTPURLResponse else { throw Error.connection(errorMessage: "Invalid or missing response") }
        guard let data = result.data else { throw Error.connection(errorMessage: "No data received") }
        guard response.statusCode / 100 == 2 else {
            if let error = try self.decoder.decode(MeetupModel.Errors.self, from: data).errors.first {
                throw Error.response(statusCode: response.statusCode, errorMessage: error.message)
            } else {
                throw Error.response(statusCode: response.statusCode, errorMessage: "Unknown error")
            }
        }
        return try self.decoder.decode(T.self, from: data)
    }
}

private extension URLRequest {
    
    init(endpoint: MeetupAPIs.Endpoint,
         includeUrlName: Bool = true,
         path: String = "",
         query queryParams: [String: LosslessStringConvertible] = [:]) {
        var url = URLComponents()
        url.scheme = "https"
        url.host = "api.meetup.com"
        url.path = (includeUrlName ? "/londonvegan/" : "/") + endpoint.rawValue + path
        
        // we may need to switch to OAuth one day, but an API key is good enough for now
        let queryItems = [URLQueryItem(name: "sign", value: "true"), URLQueryItem(name: "key", value: "yourKeyHere")]
        url.queryItems = queryItems + queryParams.map { URLQueryItem(name: $0, value: String(describing: $1)) }
        
        self.init(url: url.url!)
    }
}

private extension URLSessionDataTask {
    typealias Result = (data: Data?, response: URLResponse?, error: Error?)
}
