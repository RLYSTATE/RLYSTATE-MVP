//
//  Location.swift
//  Rlystate_V2
//
//  Created by Shervin Mobasheri on 12/22/23.
//

import CoreLocation
import MapKit

struct Location {
    let title: String
    let name: String
    let coordinate: CLLocationCoordinate2D
}

extension Location: Equatable {
    static func == (lhs: Location, rhs: Location) -> Bool {
        return lhs.title == rhs.title &&
               lhs.name == rhs.name &&
               lhs.coordinate.latitude == rhs.coordinate.latitude &&
               lhs.coordinate.longitude == rhs.coordinate.longitude
    }
}


