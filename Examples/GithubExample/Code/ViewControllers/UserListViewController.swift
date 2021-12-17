//
//  UserListViewController.swift
//  GithubExample
//
//  Created by Oliver Krakora on 12.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import UIKit
import Fetch

class UserListViewController: UIViewController {
    
    @IBOutlet private var tableView: UITableView!
    
    var resource: Resource<[User]>!
    
    private var users: [User]?
    
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
    
    deinit {
        disposable?.cancel()
    }
    
    @objc private func forceReloadData() {
        loadData(force: true)
    }
    
    private func loadData(force: Bool = false) {
        let cachePolicy: CachePolicy? = force ? CachePolicy.networkOnlyUpdateCache : nil
        
        disposable = resource.fetch(cachePolicy: cachePolicy) { [weak self] result, _ in
            if case let .success(value) = result {
                self?.users = value.model
            }
            self?.tableView.reloadData()
            self?.tableView.refreshControl?.endRefreshing()
        }
    }
}

extension UserListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let user = users![indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: UserCell.reuseIdentifier) as! UserCell
        cell.configure(with: user)
        return cell
    }
}

extension UserListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}
