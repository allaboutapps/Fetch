//
//  GithubProfileViewController.swift
//  Example
//
//  Created by Oliver Krakora on 12.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import UIKit
import Fetch

class OrganizationViewController: UIViewController {
    
    @IBOutlet private var avatarImageView: UIImageView!
    
    @IBOutlet private var organizationLabel: UILabel!
    
    @IBOutlet private var locationLabel: UILabel!
    
    @IBOutlet private var websiteLabel: UILabel!
    
    @IBOutlet private var segmentedControl: UISegmentedControl!
    
    @IBOutlet private var containerView: UIView!
    
    private lazy var childs: [UIViewController] = {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let repositoryVC = storyboard.instantiateViewController(withIdentifier: String(describing: RepositoryListViewController.self)) as! RepositoryListViewController
        repositoryVC.resource = GithubAPI.Org.repositories(for: organizationName)
        let usersVC = storyboard.instantiateViewController(withIdentifier: String(describing: UserListViewController.self)) as! UserListViewController
        usersVC.resource = GithubAPI.Org.members(for: organizationName)
        
        return [repositoryVC, usersVC]
    }()
    
    private let organizationName = "allaboutapps"
    
    private lazy var resource = GithubAPI.Org.organization(with: organizationName)
    
    private var organization: Organization?
        
    private var disposable: RequestToken?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupChilds()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
    }
    
    deinit {
        disposable?.cancel()
    }
    
    private func setupChilds() {
        for child in childs.reversed() {
            child.view.isHidden = true
            child.willMove(toParent: self)
            child.view.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(child.view)
            child.didMove(toParent: self)
            NSLayoutConstraint.activate([
                child.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                child.view.topAnchor.constraint(equalTo: containerView.topAnchor),
                child.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                child.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
        }
        childs.first?.view.isHidden = false
    }
    
    private func loadData() {
        disposable = resource.fetch { [weak self] result, _ in
            if case let .success(value) = result {
                self?.organization = value.model
            }
            self?.setupView()
        }
    }
    
    private func setupView() {
        guard let organization = organization else { return }
        
        if let avatarURL = organization.avatarURL, let data = try? Data(contentsOf: avatarURL) {
            avatarImageView.image = UIImage(data: data)
        }
        
        organizationLabel.text = organization.name
        locationLabel.text = organization.location
        if let url = organization.blogURL {
            websiteLabel.attributedText = NSAttributedString(string: url.absoluteString, attributes: [NSAttributedString.Key.link: url])
        }
        websiteLabel.text = organization.blogURL?.absoluteString
    }
    
    @IBAction private func updateChildViewController(_ sender: Any) {
        var allChilds = childs
        let currentVC = allChilds.remove(at: segmentedControl.selectedSegmentIndex)
        allChilds.forEach { $0.view.isHidden = true }
        containerView.bringSubviewToFront(currentVC.view)
        currentVC.view.isHidden = false
    }
}
