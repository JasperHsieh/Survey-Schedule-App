//
//  CircleImage.swift
//  Survey Schedule
//
//  Created by Jasper Hsieh on 4/2/20.
//  Copyright © 2020 Jasper Hsieh. All rights reserved.
//

import SwiftUI

struct CircleImage: View {
    var image: Image
    var body: some View {
        image
        .resizable()
            .frame(width: 200, height: 200)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 4))
            .shadow(radius: 10)
    }
}

//struct CircleImage_Previews: PreviewProvider {
//    static var previews: some View {
//        CircleImage()
//    }
//}
