//
//  ContentView.swift
//  awesomepragmaapp
//
//  Created by Dario Carlomagno on 05/10/2019.
//  Copyright © 2019 Bold Ideas ltd. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    
    private let stackViewSpacing: CGFloat = 8.0
    
    var body: some View {
        VStack(alignment: .center, spacing: stackViewSpacing) {
            Text("Hello #PragmaConf2019! 👋")
            Text("Try out the Slackbot 🤖 integration 🚀")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
