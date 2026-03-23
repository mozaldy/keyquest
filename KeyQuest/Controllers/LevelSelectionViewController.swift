import UIKit

/// Displays a grid of level cards. Completed levels show stars, locked levels are dimmed.
class LevelSelectionViewController: UIViewController {

    private var collectionView: UICollectionView!
    private let levels = Level.allLevels

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Levels"
        view.backgroundColor = .systemBackground
        setupCollectionView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.reloadData()
    }

    // MARK: - Setup

    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 160, height: 180)
        layout.minimumInteritemSpacing = 16
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(LevelCell.self, forCellWithReuseIdentifier: LevelCell.reuseID)

        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

// MARK: - UICollectionView DataSource & Delegate

extension LevelSelectionViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ cv: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return levels.count
    }

    func collectionView(_ cv: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = cv.dequeueReusableCell(withReuseIdentifier: LevelCell.reuseID, for: indexPath) as! LevelCell
        let level = levels[indexPath.item]
        cell.configure(with: level)
        return cell
    }

    func collectionView(_ cv: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let level = levels[indexPath.item]
        guard LevelProgress.isUnlocked(levelId: level.id) else { return }

        let vc = LevelGameViewController(level: level)
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - Level Cell

class LevelCell: UICollectionViewCell {
    static let reuseID = "LevelCell"

    private let containerView = UIView()
    private let levelNumberLabel = UILabel()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let starsLabel = UILabel()
    private let lockIcon = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        containerView.layer.cornerRadius = 16
        containerView.clipsToBounds = true
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        // Level number
        levelNumberLabel.font = UIFont.systemFont(ofSize: 36, weight: .bold)
        levelNumberLabel.textAlignment = .center

        // Title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textAlignment = .center

        // Description
        descriptionLabel.font = UIFont.preferredFont(forTextStyle: .caption2)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 2

        // Stars
        starsLabel.font = UIFont.systemFont(ofSize: 18)
        starsLabel.textAlignment = .center

        // Lock
        lockIcon.image = UIImage(systemName: "lock.fill")
        lockIcon.tintColor = .tertiaryLabel
        lockIcon.contentMode = .scaleAspectFit
        lockIcon.isHidden = true

        let stack = UIStackView(arrangedSubviews: [levelNumberLabel, titleLabel, descriptionLabel, starsLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(stack)
        containerView.addSubview(lockIcon)

        lockIcon.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -8),

            lockIcon.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            lockIcon.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            lockIcon.widthAnchor.constraint(equalToConstant: 32),
            lockIcon.heightAnchor.constraint(equalToConstant: 32)
        ])
    }

    func configure(with level: Level) {
        let unlocked = LevelProgress.isUnlocked(levelId: level.id)
        let completed = LevelProgress.isCompleted(levelId: level.id)

        levelNumberLabel.text = "\(level.id)"
        titleLabel.text = level.title
        descriptionLabel.text = level.description

        if unlocked {
            containerView.backgroundColor = .secondarySystemGroupedBackground
            lockIcon.isHidden = true
            levelNumberLabel.isHidden = false
            titleLabel.isHidden = false
            descriptionLabel.isHidden = false
            starsLabel.isHidden = false
            containerView.alpha = 1.0

            if completed, let best = LevelProgress.bestScore(levelId: level.id) {
                let starCount = LevelProgress.stars(forMistakes: best)
                let filled = String(repeating: "⭐", count: starCount)
                let empty = String(repeating: "☆", count: 3 - starCount)
                starsLabel.text = filled + empty
            } else {
                starsLabel.text = "☆☆☆"
            }
        } else {
            containerView.backgroundColor = .tertiarySystemGroupedBackground
            lockIcon.isHidden = false
            levelNumberLabel.isHidden = true
            titleLabel.isHidden = true
            descriptionLabel.isHidden = true
            starsLabel.isHidden = true
            containerView.alpha = 0.6
        }
    }
}
