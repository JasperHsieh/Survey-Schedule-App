//
//  StationMapView.swift
//  Survey Schedule
//
//  Created by Jasper Hsieh on 4/2/20.
//  Copyright © 2020 Jasper Hsieh. All rights reserved.
//

import SwiftUI
import MapKit

struct StationMapView: UIViewRepresentable {
    var coordinate: CLLocationCoordinate2D
    var station: Station

    func makeUIView(context: Context) -> MKMapView {
        MKMapView(frame: .zero)
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        let span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        uiView.setRegion(region, animated: true)
        uiView.addAnnotation(station)
    }
}

//struct StationMapView_Previews: PreviewProvider {
//    static var previews: some View {
//        StationMapView()
//    }
//}
