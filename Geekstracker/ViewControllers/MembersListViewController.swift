import UIKit

class MembersListViewController: UITableViewController {

    var sorted = [MeetupModel.Member]() {
        didSet {
            DispatchQueue.main.async { self.tableView.reloadData() }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sorted.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StandardCell", for: indexPath)

        let member = sorted[indexPath.row]
        cell.textLabel?.text = member.name
        cell.detailTextLabel?.text = nil
        return cell
    }
}

