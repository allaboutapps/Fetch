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
    
    @discardableResult
    func loadData() -> AnyPublisher<Organization, FetchError> {
        return GithubAPI.Org
            .organization(with: organizationName)
            .requestModel()
            .handleEvents(receiveOutput: { [weak self] (organisation) in
                DispatchQueue.main.async {
                    self?.organisation = organisation
                }
            })
            .eraseToAnyPublisher()
    }
    
}
