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
        Button(action: doneAction){
            Text("Done")
                .fontWeight(.bold)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(20)
        }
    }
}

func doneAction(){
    print("Click Done")
    //var stations_everyday = [1: "test"]
    //var tmp = [1: [[1], [2], [3,4]]]
    let stations_everyday = [1: [["CS25", "CS21", "RE1", "CER15", "RE5", "RE38", "ZAP15", "SLME", "RE7", "RE6"], ["CSE1", "RE4", "CER1", "DOR72", "RE36"], ["CS35", "CS9", "CS8", "RE36", "DOR37", "CS34", "DOR38", "DOR39"], ["CS3", "CRJ", "RE36", "CW1B", "CS7"]], 2: [["CS25", "RE3", "RE35", "RE2", "CS31", "RE39", "COSO3", "RE40"], ["J217", "CS28", "CS23", "CS22", "COSO3", "CS24", "CS66", "CS26", "COSO2"], ["CS43", "COSO1", "CS44"], ["RE13"]], 3: [["CS25", "RE13", "RE11", "RE34", "RE31", "RE32", "CS19", "CSE5", "RE24", "CS18", "RE25"], ["CSE3", "RE30", "RE29", "CS10", "RE26", "CS70", "RE27A", "RE28", "CSE4"], ["CS13", "CS12", "CS11", "CS10", "RE33"]], 4: [["CS25", "RE9", "RE37", "CSE2", "RE8", "RE10"], ["B-14", "DOR68", "CS20"], ["RE14", "RE12", "RE18", "CS17", "RE19", "CS16", "RE22A", "RE20", "RE21"], ["ZAP29", "RE15", "RE16", "RE17", "ZAP28"], ["ZAP2", "CS67"], ["CGB"]], 5: [["CS25", "CS29", "CS52", "J4", "CS41", "CS30"], ["CGB", "CS1", "DOR66", "DOR65", "DOR64", "B-15"], ["CS37", "CS36", "CS38"]], 6: [["CS25", "RE33", "CS36"], ["CS64"], ["CS63"], ["CS65", "CS5", "CS4", "CS6", "CS7"], ["J214"]], 7: [["CS25", "JOSRIDGE", "CS15", "CS14", "VOLPK"]]]
    print(stations_everyday)
}

struct DoneButtonView_Previews: PreviewProvider {
    static var previews: some View {
        DoneButtonView()
    }
}
