import UIKit

/// Root screen with two main options: Free Play and Levels.
class HomeViewController: UIViewController {

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "KeyQuest"
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.prefersLargeTitles = true
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - UI

    private func setupUI() {
        // Logo / subtitle
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Learn to read sheet music"
        subtitleLabel.font = UIFont.preferredFont(forTextStyle: .title3)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center

        // Free Play button
        let freePlayButton = createButton(
            title: "🎹  Free Play",
            subtitle: "Play freely and see notes on the staff",
            color: .systemBlue,
            action: #selector(freePlayTapped)
        )

        // Levels button
        let levelsButton = createButton(
            title: "📚  Levels",
            subtitle: "Learn notes step by step",
            color: .systemGreen,
            action: #selector(levelsTapped)
        )

        // Stack
        let stack = UIStackView(arrangedSubviews: [subtitleLabel, freePlayButton, levelsButton])
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            freePlayButton.heightAnchor.constraint(equalToConstant: 80),
            levelsButton.heightAnchor.constraint(equalToConstant: 80)
        ])
    }

    private func createButton(title: String, subtitle: String, color: UIColor, action: Selector) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.subtitle = subtitle
        config.baseBackgroundColor = color
        config.baseForegroundColor = .white
        config.cornerStyle = .large
        config.titleAlignment = .center
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
            return out
        }
        config.subtitleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = UIFont.preferredFont(forTextStyle: .caption1)
            return out
        }

        let button = UIButton(configuration: config)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    // MARK: - Actions

    @objc private func freePlayTapped() {
        let vc = MainViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func levelsTapped() {
        let vc = LevelSelectionViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
}
