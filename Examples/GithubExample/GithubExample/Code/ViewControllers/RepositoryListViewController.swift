//
//  RepositoryListViewController.swift
//  GithubExample
//
//  Created by Oliver Krakora on 12.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import UIKit
import Fetch

class RepositoryListViewController: UIViewController {
    
    @IBOutlet private var tableView: UITableView!
    
    var resource: Resource<[Repository]>!
    
    private var repositories: [Repository]?
    
    private var disposable: RequestToken?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.refreshControl = {
            let refreshControl = UIRefreshControl()
            refreshControl.addTarget(self, action: #selector(forceReloadData), for: .valueChanged)
            return refreshControl
        }()
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
    }
    
    @objc private func forceReloadData() {
        loadData(force: true)
    }
    
    private func loadData(force: Bool = false) {
        let cachePolicy: CachePolicy? = force ? CachePolicy.networkOnlyUpdateCache : nil
        disposable = resource.fetch(cachePolicy: cachePolicy) { [weak self] result, _ in
            if case let .success(value) = result {
                self?.repositories = value.model
            }
            self?.tableView.refreshControl?.endRefreshing()
            self?.tableView.reloadData()
        }
    }
}

extension RepositoryListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return repositories?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let repository = repositories![indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: RepositoryCell.reuseIdentifier, for: indexPath) as! RepositoryCell
        cell.configure(with: repository)
        return cell
    }
}

extension RepositoryListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}
