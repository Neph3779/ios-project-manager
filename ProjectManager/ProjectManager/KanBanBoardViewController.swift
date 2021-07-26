//
//  ProjectManager - ViewController.swift
//  Created by yagom. 
//  Copyright © yagom. All rights reserved.
// 

import UIKit
import SnapKit

final class KanBanBoardViewController: UIViewController {
    private let loadingIndicator = UIActivityIndicatorView(style: .large)

    private let toDoHeaderView = TaskTableHeaderView()

    private let doingHeaderView = TaskTableHeaderView()

    private let doneHeaderView = TaskTableHeaderView()

    private let headerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 10
        return stackView
    }()

    private let toDoTableView: KanBanTableView = {
        let tableView = KanBanTableView(status: .TODO)
        tableView.register(KanBanBoardCell.self, forCellReuseIdentifier: KanBanBoardCell.reuseIdentifier)
        return tableView
    }()

    private let doingTableView: KanBanTableView = {
        let tableView = KanBanTableView(status: .DOING)
        tableView.register(KanBanBoardCell.self, forCellReuseIdentifier: KanBanBoardCell.reuseIdentifier)
        return tableView
    }()

    private let doneTableView: KanBanTableView = {
        let tableView = KanBanTableView(status: .DONE)
        tableView.register(KanBanBoardCell.self, forCellReuseIdentifier: KanBanBoardCell.reuseIdentifier)
        return tableView
    }()

    private let tableStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 10
        return stackView
    }()

    init() {
        super.init(nibName: nil, bundle: nil)
        TaskManager.shared.taskManagerDelegate = self
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        fetchTaskData()
        setUpView()
        setTableViewDelegate()
        setTableViewDataSource()
        setUpHeaderStackView()
        setUpTableStackView()
        setUpLoadingIndicator()
    }

    private func fetchTaskData() {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            do {
                try TaskManager.shared.fetchTasks()
                DispatchQueue.main.async {
                    self.toDoTableView.reloadData()
                    self.doingTableView.reloadData()
                    self.doneTableView.reloadData()
                    self.loadingIndicator.stopAnimating()
                }
            } catch {
                let alert = UIAlertController(title: "데이터 불러오기 실패",
                                              message: "데이터를 불러오는 과정에서 오류가 발생했어요😢",
                                              preferredStyle: .alert)
                self.present(alert, animated: true, completion: nil)
            }
        }
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

        toDoTableView.dragDelegate = self
        doingTableView.dragDelegate = self
        doneTableView.dragDelegate = self

        toDoTableView.dropDelegate = self
        doingTableView.dropDelegate = self
        doneTableView.dropDelegate = self
    }

    private func setUpHeaderStackView() {
        view.addSubview(headerStackView)

        headerStackView.snp.makeConstraints { stackView in
            stackView.top.equalTo(view.safeAreaLayoutGuide)
            stackView.leading.equalTo(view.safeAreaLayoutGuide)
            stackView.trailing.equalTo(view.safeAreaLayoutGuide)
        }

        headerStackView.addArrangedSubview(toDoHeaderView)
        headerStackView.addArrangedSubview(doingHeaderView)
        headerStackView.addArrangedSubview(doneHeaderView)

        toDoHeaderView.setText(
            status: TaskStatus.TODO.rawValue,
            count: TaskManager.shared.toDoTasks.count.description)

        doingHeaderView.setText(
            status: TaskStatus.DOING.rawValue,
            count: TaskManager.shared.doingTasks.count.description
        )

        doneHeaderView.setText(
            status: TaskStatus.DONE.rawValue,
            count: TaskManager.shared.doneTasks.count.description
        )
    }

    private func setUpTableStackView() {
        view.addSubview(tableStackView)
        tableStackView.snp.makeConstraints { stackView in
            stackView.top.equalTo(headerStackView.snp.bottom)
            stackView.leading.equalTo(view)
            stackView.trailing.equalTo(view)
            stackView.bottom.equalTo(view)
        }

        tableStackView.addArrangedSubview(toDoTableView)
        tableStackView.addArrangedSubview(doingTableView)
        tableStackView.addArrangedSubview(doneTableView)
    }

    private func setUpLoadingIndicator() {
        view.addSubview(loadingIndicator)
        loadingIndicator.snp.makeConstraints { loadingIndicator in
            loadingIndicator.center.equalToSuperview()
        }
        loadingIndicator.startAnimating()
    }

    @objc func touchUpTaskAddButton() {
        let taskDetailViewController = TaskDetailViewController(mode: .add)
        taskDetailViewController.view.backgroundColor = .systemBackground
        taskDetailViewController.modalPresentationStyle = .formSheet
        present(UINavigationController(rootViewController: taskDetailViewController), animated: true, completion: nil)
    }
}

// MARK: - TableView DataSource

extension KanBanBoardViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let tableView = tableView as? KanBanTableView else { return 0 }
        return tableView.tasks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: KanBanBoardCell.reuseIdentifier,
                                                       for: indexPath) as? KanBanBoardCell,
              let tableView = tableView as? KanBanTableView else { return UITableViewCell() }

        let task = tableView.tasks[indexPath.row]
        cell.setText(title: task.title, description: task.body, date: task.date)
        return cell
    }
}

// MARK: - TableView Delegate

extension KanBanBoardViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let tableView = tableView as? KanBanTableView else { return nil }

        let contextualAction = UIContextualAction(style: .destructive, title: "delete") { _, _, _ in
            TaskManager.shared.deleteTask(indexPath: indexPath, status: tableView.status)
        }
        return UISwipeActionsConfiguration(actions: [contextualAction])
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let tableView = tableView as? KanBanTableView else { return }

        let taskDetailViewController = TaskDetailViewController(
            mode: .edit,
            status: tableView.status,
            indexPath: indexPath
        )

        taskDetailViewController.view.backgroundColor = .systemBackground
        taskDetailViewController.modalPresentationStyle = .formSheet
        present(UINavigationController(rootViewController: taskDetailViewController), animated: true, completion: nil)
    }
}

// MARK: - TaskManager Delegate

extension KanBanBoardViewController: TaskManagerDelegate {
    func taskDidCreated() {
        toDoHeaderView.countLabel.text = TaskManager.shared.toDoTasks.count.description
        toDoTableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
    }

    func taskDidEdited(indexPath: IndexPath, status: TaskStatus) {
        switch status {
        case .TODO:
            toDoTableView.reloadRows(at: [indexPath], with: .automatic)
            toDoHeaderView.countLabel.text = TaskManager.shared.toDoTasks.count.description
        case .DOING:
            doingTableView.reloadRows(at: [indexPath], with: .automatic)
            doingHeaderView.countLabel.text = TaskManager.shared.doingTasks.count.description
        case .DONE:
            doneTableView.reloadRows(at: [indexPath], with: .automatic)
            doneHeaderView.countLabel.text = TaskManager.shared.doneTasks.count.description
        }
    }

    func taskDidDeleted(indexPath: IndexPath, status: TaskStatus) {
        switch status {
        case .TODO:
            toDoTableView.deleteRows(at: [indexPath], with: .automatic)
            toDoHeaderView.countLabel.text = TaskManager.shared.toDoTasks.count.description
        case .DOING:
            doingTableView.deleteRows(at: [indexPath], with: .automatic)
            doingHeaderView.countLabel.text = TaskManager.shared.doingTasks.count.description
        case .DONE:
            doneTableView.deleteRows(at: [indexPath], with: .automatic)
            doneHeaderView.countLabel.text = TaskManager.shared.doneTasks.count.description
        }
    }
}

// MARK: - Drag Delegate

extension KanBanBoardViewController: UITableViewDragDelegate {
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard let tableView = tableView as? KanBanTableView else { return [] }

        switch tableView.status {
        case .TODO:
            let fileURL = TaskManager.shared.toDoTasks[indexPath.row].objectID.uriRepresentation()
            guard let toDoItemProvider = NSItemProvider(contentsOf: fileURL) else { return [] }

            let dragItem = UIDragItem(itemProvider: toDoItemProvider)
            dragItem.localObject = TaskManager.shared.toDoTasks[indexPath.row]
            session.localContext = DragSessionLocalContext(sourceIndexPath: indexPath)

            return [dragItem]
        case .DOING:
            let fileURL = TaskManager.shared.doingTasks[indexPath.row].objectID.uriRepresentation()
            guard let doingItemProvider = NSItemProvider(contentsOf: fileURL ) else { return [] }

            let dragItem = UIDragItem(itemProvider: doingItemProvider)
            dragItem.localObject = TaskManager.shared.doingTasks[indexPath.row]
            session.localContext = DragSessionLocalContext(sourceIndexPath: indexPath)

            return [dragItem]
        case .DONE:
            let fileURL = TaskManager.shared.doneTasks[indexPath.row].objectID.uriRepresentation()
            guard let doneItemProvider = NSItemProvider(contentsOf: fileURL ) else { return [] }

            let dragItem = UIDragItem(itemProvider: doneItemProvider)
            dragItem.localObject = TaskManager.shared.doneTasks[indexPath.row]
            session.localContext = DragSessionLocalContext(sourceIndexPath: indexPath)

            return [dragItem]
        }
    }

    func tableView(_ tableView: UITableView, dragSessionDidEnd session: UIDragSession) {
        guard let localContext = session.localContext as? DragSessionLocalContext,
              let tableView = tableView as? KanBanTableView,
              localContext.didDragDropCompleted == true else { return }

        if localContext.isReordering,
           let destinationIndexPath = localContext.destinationIndexPath {
            switch tableView.status {
            case .TODO:
                let task = TaskManager.shared.toDoTasks.remove(at: localContext.sourceIndexPath.row)
                TaskManager.shared.toDoTasks.insert(task, at: destinationIndexPath.row)
                tableView.moveRow(at: localContext.sourceIndexPath, to: destinationIndexPath)
            case .DOING:
                let task = TaskManager.shared.doingTasks.remove(at: localContext.sourceIndexPath.row)
                TaskManager.shared.doingTasks.insert(task, at: destinationIndexPath.row)
                tableView.moveRow(at: localContext.sourceIndexPath, to: destinationIndexPath)
            case .DONE:
                let task = TaskManager.shared.doneTasks.remove(at: localContext.sourceIndexPath.row)
                TaskManager.shared.doneTasks.insert(task, at: destinationIndexPath.row)
                tableView.moveRow(at: localContext.sourceIndexPath, to: destinationIndexPath)
            }

            TaskManager.shared.saveTasks()
            return
        }

        switch tableView.status {
        case .TODO:
            TaskManager.shared.toDoTasks.remove(at: localContext.sourceIndexPath.row)
        case .DOING:
            TaskManager.shared.doingTasks.remove(at: localContext.sourceIndexPath.row)
        case .DONE:
            TaskManager.shared.doneTasks.remove(at: localContext.sourceIndexPath.row)
        }

        tableView.deleteRows(at: [localContext.sourceIndexPath], with: .automatic)
        TaskManager.shared.saveTasks()
    }
}

// MARK: - Drop Delegate

extension KanBanBoardViewController: UITableViewDropDelegate {
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        guard let localContext = coordinator.session.localDragSession?.localContext as? DragSessionLocalContext,
              let item = coordinator.items.first,
              let dragTask = item.dragItem.localObject as? Task,
              let tableView = tableView as? KanBanTableView else { return }

        let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(row: 0, section: 0)

        if item.sourceIndexPath != nil {
            localContext.isReordering = true
            localContext.destinationIndexPath = destinationIndexPath
            localContext.didDragDropCompleted = true
            return
        }

        switch tableView.status {
        case .TODO:
            dragTask.status = TaskStatus.TODO.rawValue
            TaskManager.shared.toDoTasks.insert(dragTask, at: destinationIndexPath.row)
            toDoTableView.insertRows(at: [destinationIndexPath], with: .automatic)
        case .DOING:
            dragTask.status = TaskStatus.DOING.rawValue
            TaskManager.shared.doingTasks.insert(dragTask, at: destinationIndexPath.row)
            doingTableView.insertRows(at: [destinationIndexPath], with: .automatic)
        case .DONE:
            dragTask.status = TaskStatus.DONE.rawValue
            TaskManager.shared.doneTasks.insert(dragTask, at: destinationIndexPath.row)
            doneTableView.insertRows(at: [destinationIndexPath], with: .automatic)
        }

        switch coordinator.proposal.operation {
        case .move:
            coordinator.drop(item.dragItem, toRowAt: destinationIndexPath)
        default:
            return
        }

        localContext.didDragDropCompleted = true
    }

    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }
}
