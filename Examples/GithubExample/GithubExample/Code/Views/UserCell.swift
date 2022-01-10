//
//  UserCell.swift
//  GithubExample
//
//  Created by Oliver Krakora on 12.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import UIKit

class UserCell: UITableViewCell {
    
    private static let avatarDownloadQueue = DispatchQueue(label: "at.allaboutapps.avatars")
    
    @IBOutlet private var avatarImageView: UIImageView!
    
    @IBOutlet private var usernameLabel: UILabel!
    
    private var user: User!
    
    private var loadImageWorkItem: DispatchWorkItem?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        loadImageWorkItem?.cancel()
        avatarImageView.image = nil
    }
    
    func configure(with user: User) {
        self.user = user
        usernameLabel.text = user.username
        loadImage()
    }
    
    private func loadImage() {
        guard let url = user.avatarURL else { return }
        
        loadImageWorkItem = DispatchWorkItem { [weak self] in
            guard let data = try? Data(contentsOf: url) else { return }
            DispatchQueue.main.async {
                self?.avatarImageView.image = UIImage(data: data)
            }
        }
        UserCell.avatarDownloadQueue.async(execute: loadImageWorkItem!)
    }
}

extension UserCell {
    static let reuseIdentifier = "\(UserCell.self)"
}
