import UIKit

class EventListViewController: UITableViewController {
    
    private let calendar = Calendar.current
    private let dayFormatter = DateFormatter("EEEE d")
    private let monthFormatter = DateFormatter("MMMM yyyy")

    fileprivate typealias EventGroup = [MeetupModel.Event]
    private var events = [EventGroup]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.refreshControl = UIRefreshControl()
    }
    
    func eventsUpdated(_ events: [MeetupModel.Event]) {
        let filteredEvents = events.filter { $0.status == self.status }
        let buckets: [Date: EventGroup] = filteredEvents.reduce(into: [:]) { (acc, event) in
            let components = self.calendar.dateComponents([.month, .year], from: event.time)
            let month = self.calendar.date(from: components)!
            acc[month, default: []].append(event)
        }
        self.events = buckets.sorted { ($0.key < $1.key) == descending }.map { $0.value.sorted { ($0.time < $1.time) == descending } }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    // MARK: Abstract methods
    
    fileprivate var status: MeetupModel.Event.Status {
        preconditionFailure()
    }
    
    fileprivate func attendance(for event: MeetupModel.Event) -> String {
        preconditionFailure()
    }
    
    fileprivate var descending: Bool {
        preconditionFailure()
    }
    
    // MARK: UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return events.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events[section].count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return events[section].first.map { monthFormatter.string(from: $0.time) }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StandardCell", for: indexPath)
        
        let event = events[indexPath.section][indexPath.row]
        cell.textLabel?.text = dayFormatter.string(from: event.time) + " (\(event.name.replacingOccurrences(of: " Geekstraveganza", with: "")))"
        cell.detailTextLabel?.text = attendance(for: event)
        return cell
    }
}

class UpcomingEventListViewController: EventListViewController {
    
    override var status: MeetupModel.Event.Status {
        return .upcoming
    }
    
    override func attendance(for event: MeetupModel.Event) -> String {
        return "\(event.yesRsvpCount)\(event.waitlistCount == 0 ? "" : " WL:\(event.waitlistCount)")"
    }
    
    override var descending: Bool {
        return true
    }
}

class PastEventListViewController: EventListViewController {
    
    override var status: MeetupModel.Event.Status {
        return .past
    }
    
    override func attendance(for event: MeetupModel.Event) -> String {
        return "\(event.yesRsvpCount)" // TODO: add number of no-shows here
    }
    
    override var descending: Bool {
        return false
    }
}
