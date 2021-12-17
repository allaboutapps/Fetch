//
//  OrganizationListViewModel.swift
//  CombineExample
//
//  Created by Stefan Wieland on 02.08.19.
//  Copyright © 2019 allaboutapps GmbH. All rights reserved.
//

import Foundation
import Fetch
import Combine

class OrganizationListViewModel: ObservableObject {
       
    private let organizationName = "allaboutapps"
    
    @Published
    var organisation: Organization? = nil
    
    var cancellable: Cancellable?
    
    func loadData() {
        cancellable = GithubAPI.Org
            .organization(with: organizationName)
            .requestModel()
            .sink(receiveCompletion: { result in
                switch result {
                case .finished:
                    print("finished")
                case .failure(let error):
                    print("error", error)
                }
            }, receiveValue: { [weak self] (organization) in
                self?.organisation = organization
                print("Received value")
            })
    }
    
}
