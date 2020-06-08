//
//  CLLocationExtension.swift
//  Quick Weather-MAC
//
//  Created by Ozan Mirza on 2/12/19.
//  Copyright © 2019 Ozan Mirza. All rights reserved.
//

import CoreLocation

extension CLLocationManager {
    
    
    static func getLocation(forPlaceCalled name: String,
                     completion: @escaping(CLLocation?) -> Void) {
        
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(name) { placemarks, error in
            
            guard error == nil else {
                print("*** Error in \(#function): \(error!.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let placemark = placemarks?[0] else {
                print("*** Error in \(#function): placemark is nil")
                completion(nil)
                return
            }
            
            guard let location = placemark.location else {
                print("*** Error in \(#function): placemark is nil")
                completion(nil)
                return
            }
            
            completion(location)
        }
    }
}
