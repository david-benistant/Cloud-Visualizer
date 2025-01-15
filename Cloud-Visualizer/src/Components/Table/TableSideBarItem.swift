import SwiftUI
import AWSS3

struct TableSideBarItem {
    var name: String
    var icon: String = "star"
    var action : () -> Void = {}
    var disabled: Bool = false
}
