import UIKit

extension UIView {
    /// Every view of type `T` below this one, depth first; lets tests read a screen without private outlets.
    func descendants<T: UIView>(of type: T.Type) -> [T] {
        subviews.flatMap { subview -> [T] in
            let match = (subview as? T).map { [$0] } ?? []
            return match + subview.descendants(of: type)
        }
    }
}
