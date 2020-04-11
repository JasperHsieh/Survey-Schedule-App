//
//  LoadingView.swift
//  Survey Schedule
//
//  Created by Jasper Hsieh on 4/7/20.
//  Copyright © 2020 Jasper Hsieh. All rights reserved.
//

import SwiftUI

struct LoadingView: View {
    @State private var amosPulsing = false
    @State private var innerPulsing = false
    @State private var middlePulsing = false
    @State private var outerPulsing = false
    @EnvironmentObject private var dynamicRouting: DynamicRouting

//    let gradient = AnyView(RadialGradient(gradient: Gradient(colors: [Color.orange
//    , Color.yellow]), center: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, startRadius: /*@START_MENU_TOKEN@*/5/*@END_MENU_TOKEN@*/, endRadius: /*@START_MENU_TOKEN@*/500/*@END_MENU_TOKEN@*/)
//    .edgesIgnoringSafeArea(.all))

    var body: some View {

        ZStack {

            RadialGradient(gradient: Gradient(colors: [Color.orange
                , Color.yellow]), center: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, startRadius: /*@START_MENU_TOKEN@*/5/*@END_MENU_TOKEN@*/, endRadius: /*@START_MENU_TOKEN@*/500/*@END_MENU_TOKEN@*/)
                .edgesIgnoringSafeArea(.all)
            Image("c3")
                .scaleEffect(amosPulsing ? 1.2 : 0.5, anchor: .center)
                .animation(Animation.easeOut(duration: 1).repeatForever(autoreverses: true).delay(0.1))
                .onAppear() {
                        self.outerPulsing.toggle()
                }

            Image("c2")
                .scaleEffect(amosPulsing ? 1.2 : 0.5, anchor: .center)
                .animation(Animation.easeOut(duration: 1).repeatForever(autoreverses: true).delay(0.2))
                .onAppear() {
                        self.middlePulsing.toggle()
                }

            Image("c1")
                .scaleEffect(amosPulsing ? 1.2 : 0.5, anchor: .center)
                .animation(Animation.easeOut(duration: 1).repeatForever(autoreverses: true).delay(0.3))
                .onAppear() {
                        self.innerPulsing.toggle()
                }

            Image("m1")
                .scaleEffect(amosPulsing ? 1 : 1.4, anchor: .center)
                .animation(Animation.easeOut(duration: 1).repeatForever(autoreverses: true))
                .onAppear() {
                    self.amosPulsing.toggle()
            }
            Text("Calculating routes")
            .foregroundColor(.white)
            .bold()
        }
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
    }
}
