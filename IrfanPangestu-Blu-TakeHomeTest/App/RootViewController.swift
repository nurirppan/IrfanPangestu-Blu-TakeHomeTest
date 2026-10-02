import UIKit

/// Composes the feature screens; the screens never know about each other. The controls sit in a stack
/// below the list, so hiding them gives the space back and the list's last rows are never covered.
final class RootViewController: UIViewController {
    private let listNavigationController = UINavigationController(rootViewController: SongListViewController())
    private let controlsViewController = PlayerControlsViewController()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        addChild(listNavigationController)
        addChild(controlsViewController)

        let stackView = UIStackView(arrangedSubviews: [listNavigationController.view, controlsViewController.view])
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        listNavigationController.didMove(toParent: self)
        controlsViewController.didMove(toParent: self)
    }
}
