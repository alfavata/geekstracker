//

import UIKit

class MainController: UITabBarController, MeetupAPIsDelegate {
    
    private func allChildren<T>(ofType type: T.Type, perform action: (T) -> Void) {
        viewControllers?.compactMap { $0 as? UINavigationController }.compactMap { $0.viewControllers.first as? T }.forEach { action($0) }
    }

    private lazy var client = MeetupAPIs(delegate: self)
    private var members = Set<MeetupModel.Member>()
    private let serialQueue = DispatchQueue(label: "com.meetup.londonvegan.Geekstracker")

    override func viewDidLoad() {
        super.viewDidLoad()
        allChildren(ofType: UITableViewController.self) {
            $0.tableView.refreshControl?.addTarget(client, action: #selector(MeetupAPIs.fetchEvents), for: .valueChanged)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        client.fetchEvents()
    }
    
    // MARK: MeetupAPIsDelegate
    
    private func evaluate<T>(_ result: Result<T, Error>, success successHandler: (T) -> Void) {
        switch result {
        case let .success(payload):
            successHandler(payload)
        case let .failure(error):
            DispatchQueue.main.async {
                let errorMessage = (error as? MeetupAPIs.Error)?.userFacingMessage ?? error.localizedDescription
                let alert = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
                alert.addAction(.init(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true)
            }
        }
    }
    
    func meetupAPIs(_ client: MeetupAPIs, didUpdateEvents result: Result<[MeetupModel.Event], Error>) {
        guard client === self.client else { preconditionFailure() }
        
        DispatchQueue.main.async {
            self.allChildren(ofType: UITableViewController.self) { $0.tableView.refreshControl?.endRefreshing() }
        }

        evaluate(result) { events in
            serialQueue.async { self.members.removeAll() }
            events.filter { $0.status == .past }.forEach(self.client.fetchAttendance)
            allChildren(ofType: EventListViewController.self) { $0.eventsUpdated(events) }
            if let currentEvent = events.first(where: { $0.time < Date() && $0.status == .upcoming }) {
                allChildren(ofType: CurrentEventViewController.self) { $0.event = currentEvent }
                self.client.fetchAttendance(currentEvent)
            }
        }
    }

    func meetupAPIs(_ client: MeetupAPIs, didFetchAttendance result: Result<[MeetupModel.Attendance], Error>, for event: MeetupModel.Event) {
        guard client === self.client else { preconditionFailure() }

        evaluate(result) { attendance in

            self.allChildren(ofType: CurrentEventViewController.self) {
                if $0.event == event {
                    $0.attendance = attendance
                }
            }

            let members = attendance.map { $0.member }
            serialQueue.async {
                self.allChildren(ofType: MembersViewController.self) { $0.members.formUnion(members) }
            }
        }
    }
}
