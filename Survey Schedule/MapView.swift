//
//  MapView.swift
//  Survey Schedule
//
//  Created by Jasper Hsieh on 3/11/20.
//  Copyright © 2020 Jasper Hsieh. All rights reserved.
//

import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    var locationManager = CLLocationManager()
    func setupManager() {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestAlwaysAuthorization()
    }
    func makeUIView(context: Context) -> MKMapView {
        setupManager()
        let mapView = MKMapView(frame: UIScreen.main.bounds)
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        //mapView.delegate = context.coordinator
        //mapView.delegate = mapView
        return mapView
        //return MKMapView(frame: .zero)
    }
    func updateUIView(_ uiView: MKMapView, context: Context) {
    }
    /*
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView

        init(_ parent: MapView) {
            self.parent = parent
        }
    }*/
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
    }
}
