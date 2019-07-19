//

import UIKit

class CurrentEventViewController: MembersListViewController {

    var event: MeetupModel.Event!
    var attendance: [MeetupModel.Attendance]! {
        didSet {
            sorted = attendance.map { $0.member }
        }
    }

    private var seen = [MeetupModel.Member: Bool]()

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        let member = sorted[indexPath.row]
        cell.accessoryView = {
            let tracker = UISwitch()
            tracker.isOn = seen[member, default: member.isHost]
            tracker.tag = indexPath.row
            tracker.addTarget(self, action: #selector(setSeen), for: .valueChanged)
            return tracker
        }()
        return cell
    }

    @objc
    private func setSeen(_ sender: UISwitch) {
        let member = sorted[sender.tag]
        seen[member] = sender.isOn
    }
}
