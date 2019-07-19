//

import UIKit

class MembersViewController: MembersListViewController {

    var members = Set<MeetupModel.Member>() {
        didSet {
            sorted = members.sorted { _, _ in true } // TODO
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)

        return cell
    }
}
