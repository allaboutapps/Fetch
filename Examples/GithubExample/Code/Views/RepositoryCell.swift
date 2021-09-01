//
//  RepositoryCell.swift
//  GithubExample
//
//  Created by Oliver Krakora on 12.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import UIKit

class RepositoryCell: UITableViewCell {
 
    @IBOutlet private var nameLabel: UILabel!
    
    func configure(with repository: Repository) {
        nameLabel.text = repository.name
    }
}

extension RepositoryCell {
    static let reuseIdentifier = "\(RepositoryCell.self)"
}
