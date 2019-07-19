//

import Foundation

extension DateFormatter {
    convenience init(_ format: String) {
        self.init()
        dateFormat = format
    }
}
