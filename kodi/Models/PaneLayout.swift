import Foundation

enum PaneLayout: String, CaseIterable {
    case horizontal = "Side by Side"
    case vertical = "Stacked"
    case grid = "Grid"

    var icon: String {
        switch self {
        case .horizontal: "rectangle.split.3x1"
        case .vertical: "rectangle.split.1x2"
        case .grid: "square.grid.2x2"
        }
    }
}
