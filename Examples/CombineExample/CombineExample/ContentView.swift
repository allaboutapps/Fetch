//
//  ContentView.swift
//  CombineExample
//
//  Created by Stefan Wieland on 02.08.19.
//  Copyright © 2019 allaboutapps GmbH. All rights reserved.
//

import SwiftUI
import Combine

struct ContentView: View {
    
    @ObservedObject
    var viewModel: OrganizationListViewModel

    var body: some View {
        
        Group {
            if viewModel.organisation == nil {
                Text("Loading")
            } else {
                Text(viewModel.organisation!.name)
            }
        }.onAppear {
            self.viewModel.loadData()
        }
        
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(viewModel: OrganizationListViewModel())
    }
}
#endif
