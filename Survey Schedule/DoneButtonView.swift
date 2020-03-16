//
//  DoneButtonView.swift
//  Survey Schedule
//
//  Created by Jasper Hsieh on 3/15/20.
//  Copyright © 2020 Jasper Hsieh. All rights reserved.
//

import SwiftUI

struct DoneButtonView: View {
    var body: some View {
        Button(action: {
            print("click Done")
        }){
            Text("Done")
                .fontWeight(.bold)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(20)
        }
    }
}

struct DoneButtonView_Previews: PreviewProvider {
    static var previews: some View {
        DoneButtonView()
    }
}
