import Foundation

struct MeetupModel {

    struct Error: Codable {
        let code: String
        let message: String
        let field: String?
    }

    struct Errors: Codable {
        let errors: [Error]
    }
    
    struct Event: Codable, Equatable {
        
        enum Status: String, Codable {
            case cancelled
            case draft
            case past
            case proposed
            case suggested
            case upcoming
        }
        
        let id: String
        let name: String
        let status: Status
        let time: Date
        let waitlistCount: Int
        let yesRsvpCount: Int
//        let link: URL
    }

    struct Member: Codable, Hashable {

        struct Context: Codable {
            let host: Bool
        }

        let name: String
    }

    struct Attendance: Codable {
        let member: Member
        let rsvp: RSVP

        struct RSVP: Codable {
            enum Response: String, Codable {
                case yes
                case no
                case waitlist
            }
            let response: Response
            let guests: Int
        }
    }
}
