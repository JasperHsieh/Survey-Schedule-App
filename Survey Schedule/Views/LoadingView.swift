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

    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var dynamicRouting: DynamicRouting

    @State private var showingWelcome = false
    @State private var showDetails = false

//    let gradient = AnyView(RadialGradient(gradient: Gradient(colors: [Color.orange
//    , Color.yellow]), center: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, startRadius: /*@START_MENU_TOKEN@*/5/*@END_MENU_TOKEN@*/, endRadius: /*@START_MENU_TOKEN@*/500/*@END_MENU_TOKEN@*/)
//    .edgesIgnoringSafeArea(.all))

    var body: some View {

        ZStack {

            RadialGradient(gradient: Gradient(colors: [Color.orange
                , Color.yellow]), center: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, startRadius: /*@START_MENU_TOKEN@*/5/*@END_MENU_TOKEN@*/, endRadius: /*@START_MENU_TOKEN@*/500/*@END_MENU_TOKEN@*/)
                .edgesIgnoringSafeArea(.all)
            if !dynamicRouting.doneLoading {
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

            if dynamicRouting.doneLoading {
                Image("m1")
                    .scaleEffect(1.3, anchor: .center)
                    .animation(Animation.easeOut(duration: 1).repeatForever(autoreverses: true).delay(0.3))

                VStack {
                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()
                    if showDetails{
                        Text("Next Station \(dynamicRouting.nextStation)")
                            .fontWeight(.bold)
                            .font(.title)
                            .padding()
                            //.background(Color.purple)
                            .foregroundColor(.white)
                            .padding()
                            //.border(Color.purple, width: 5)
                            .transition(AnyTransition.opacity.animation(.easeInOut(duration: 1.5)))

                        Button(action: {
                            self.presentationMode.wrappedValue.dismiss()
                        }) {

                            Text("GO")
                                .frame(minWidth: 80)
                                .foregroundColor(.white)
                                .font(.body)
                                .padding()
                                .background(Color.blue)
                                //.padding(.top)
                        }
                        .transition(AnyTransition.opacity.animation(.easeInOut(duration: 1.5)))
                    }
                    Spacer()
               // }
                }.onAppear(){
                    self.showDetails.toggle()
                }
            }
        }
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
    }
}
