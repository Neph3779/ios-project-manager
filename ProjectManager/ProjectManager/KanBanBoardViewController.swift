//
//  ProjectManager - ViewController.swift
//  Created by yagom. 
//  Copyright © yagom. All rights reserved.
// 

import UIKit
import SnapKit

final class KanBanBoardViewController: UIViewController {
    private let outerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 10
        return stackView
    }()

    private let toDoTableView: KanBanTableView = {
        let tableView = KanBanTableView(statusName: "TODO", tasks: [dummy, dummy])
        tableView.register(KanBanBoardCell.self, forCellReuseIdentifier: KanBanBoardCell.reuseIdentifier)
        return tableView
    }()

    private let doingTableView: KanBanTableView = {
        let tableView = KanBanTableView(statusName: "DOING", tasks: [dummy, dummy])
        tableView.register(KanBanBoardCell.self, forCellReuseIdentifier: KanBanBoardCell.reuseIdentifier)
        return tableView
    }()

    private let doneTableView: KanBanTableView = {
        let tableView = KanBanTableView(statusName: "DONE", tasks: [dummy, dummy])
        tableView.register(KanBanBoardCell.self, forCellReuseIdentifier: KanBanBoardCell.reuseIdentifier)
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpView()
        setTableViewDelegate()
        setTableViewDataSource()
        setUpOuterStackView()
    }

    private func setUpView() {
        view.backgroundColor = .systemBackground
        navigationItem.title = "Project Manager"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(touchUpTaskAddButton)
        )
    }

    private func setTableViewDataSource() {
        toDoTableView.dataSource = self
        doingTableView.dataSource = self
        doneTableView.dataSource = self
    }

    private func setTableViewDelegate() {
        toDoTableView.delegate = self
        doingTableView.delegate = self
        doneTableView.delegate = self
    }

    private func setUpOuterStackView() {
        view.addSubview(outerStackView)
        outerStackView.snp.makeConstraints { $0.edges.equalTo(view) }

        outerStackView.addArrangedSubview(toDoTableView)
        outerStackView.addArrangedSubview(doingTableView)
        outerStackView.addArrangedSubview(doneTableView)
    }

    @objc func touchUpTaskAddButton() {
        let taskDetailViewController = TaskDetailViewController(mode: .add)
        taskDetailViewController.view.backgroundColor = .systemBackground
        taskDetailViewController.modalPresentationStyle = .formSheet
        present(UINavigationController(rootViewController: taskDetailViewController), animated: true, completion: nil)
    }
}

// MARK: - DataSource

extension KanBanBoardViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let tableView = tableView as? KanBanTableView else { return 0 }
        return tableView.tasks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: KanBanBoardCell.reuseIdentifier,
                                                       for: indexPath) as? KanBanBoardCell,
              let tableView = tableView as? KanBanTableView
        else {
            return UITableViewCell()
        }

        cell.setText(
            title: tableView.tasks[indexPath.row].title,
            description: tableView.tasks[indexPath.row].description,
            date: tableView.tasks[indexPath.row].date.description
        )

        return cell
    }
}

// MARK: - Delegate

extension KanBanBoardViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let tableView = tableView as? KanBanTableView else { return .none }

        let view = UIView()
        view.backgroundColor = .systemGray

        let statusLabel: UILabel = {
            let label = UILabel()
            label.text = tableView.statusName
            label.font = UIFont.preferredFont(forTextStyle: .largeTitle)
            return label
        }()

        let countLabel: UILabel = {
            let label = UILabel()
            label.text = tableView.tasks.count.description
            label.clipsToBounds = true
            label.textAlignment = .center
            label.layer.borderWidth = 2
            label.layer.cornerRadius = 5
            label.layer.borderColor = UIColor.black.cgColor
            label.font = UIFont.preferredFont(forTextStyle: .body)
            return label
        }()

        view.addSubview(statusLabel)
        view.addSubview(countLabel)

        statusLabel.snp.makeConstraints { label in
            label.top.equalTo(view).inset(10)
            label.leading.equalTo(view).inset(10)
            label.centerY.equalTo(view)
            label.bottom.equalTo(view).inset(10)
        }

        countLabel.snp.makeConstraints { label in
            label.leading.equalTo(statusLabel.snp.trailing).offset(10)
            label.centerY.equalTo(view)
            label.width.equalTo(25)
            label.height.equalTo(25)
        }

        return view
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let contextualAction = UIContextualAction(style: .destructive, title: "delete", handler: { _, _, _ in })
        return UISwipeActionsConfiguration(actions: [contextualAction])
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let taskDetailViewController = TaskDetailViewController(mode: .edit)
        taskDetailViewController.view.backgroundColor = .systemBackground
        taskDetailViewController.modalPresentationStyle = .formSheet
        present(UINavigationController(rootViewController: taskDetailViewController), animated: true, completion: nil)
    }
}
