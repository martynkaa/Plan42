//
//  ViewController.swift
//  Plan42
//
//  Created by Maryna POPOVYCH on 26.01.2019.
//  Copyright © 2019 Maryna POPOVYCH. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces


//let directionsApi = "AIzaSyAeuNLRnIR4n8Uf2cdc1VFFb-2OK2HNSR4"  // mpopovyc
let directionsApi = "AIzaSyCxl4gr6gw8u0DeyOqmKFaqrgP1TO4EGp4"    // afesyk

class MapVC: UIViewController, UISearchDisplayDelegate {
    
    
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var start: UITextField!
    @IBOutlet weak var destination: UITextField!
    @IBOutlet weak var showPath: UIButton!
    
    var resultsViewController: GMSAutocompleteResultsViewController?
    var searchController: UISearchController?
    var resultView: UITextView?
    
    var locationStart = CLLocation()
    var locationDestination = CLLocation()

    
    private let locationManager = CLLocationManager()
    
    enum Location {
        case start
        case destination
    }
    
    var locationNow = Location.start
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // request location
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startMonitoringSignificantLocationChanges()
        self.mapView.settings.compassButton = true
        self.mapView.settings.zoomGestures = true
    }

    
    func didFailAutocompleteWithError(_ error: Error) {
        //
    }
    
    //start location
    @IBAction func chooseStart(_ sender: UITextField) {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        locationNow = .start
        present(autocompleteController, animated: true, completion: nil)
    }
    
    //destination location
 
    @IBAction func chooseDestination(_ sender: UITextField) {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        locationNow = .destination
        present(autocompleteController, animated: true, completion: nil)
    }
    
    //SHOW PATH
    @IBAction func showPath(_ sender: UIButton) {
        let start = "\(locationStart.coordinate.latitude),\( locationStart.coordinate.longitude)"
        let dest = "\(locationDestination.coordinate.latitude),\( locationDestination.coordinate.longitude)"
        let url = URL(string : "https://maps.googleapis.com/maps/api/directions/json?origin=" + start + "&destination=" + dest + "&key=" + directionsApi)
        
        
            var request = URLRequest(url: url!)
            request.httpMethod = "POST"
            let task = URLSession.shared.dataTask(with: url!) {(data, response, error) in
                guard let data = data else { return }
                print(String(data: data, encoding: .utf8)!)
                do{
                    let json = try JSONSerialization.jsonObject(with: data, options:.allowFragments) as! [String : AnyObject]
                    let routes = json["routes"] as! NSArray
                    DispatchQueue.main.async {
                        self.mapView.clear()
                        
                            for route in routes
                            {
                                let routeOverviewPolyline:NSDictionary = (route as! NSDictionary).value(forKey: "overview_polyline") as! NSDictionary
                                let points = routeOverviewPolyline.object(forKey: "points")
                                let path = GMSPath.init(fromEncodedPath: points! as! String)
                                let polyline = GMSPolyline.init(path: path)
                                polyline.strokeWidth = 3
                                
                                let bounds = GMSCoordinateBounds(path: path!)
                                self.mapView!.animate(with: GMSCameraUpdate.fit(bounds, withPadding: 30.0))
                                
                                polyline.map = self.mapView
                            }
                    }
                }catch let error as NSError{
                    print("error:\(error)")
                }
            }
                task.resume()

    }
    
}

//request on location

extension MapVC: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard status == .authorizedWhenInUse else {
            return
        }
        locationManager.startUpdatingLocation()
        
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            return
        }
        
        mapView.camera = GMSCameraPosition(target: location.coordinate, zoom: 15, bearing: 0, viewingAngle: 0)
        
        locationManager.stopUpdatingLocation()
    }
    
}

extension MapVC :  GMSAutocompleteViewControllerDelegate {
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        //show marker?
        if locationNow == .start {
            start.text = place.name
            locationStart = CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
            showMarker(titleMarker: place.name, latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
        } else {
            destination.text = place.name
            locationDestination = CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
            showMarker(titleMarker: place.name, latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
        }
         dismiss(animated: true, completion: nil)
        
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        // TODO: show alert?
        print("Error: ", error.localizedDescription)
    }
    
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
         dismiss(animated: true, completion: nil)
        start.resignFirstResponder()
        destination.resignFirstResponder()
    }
    
   /* create marker! */
    
    func showMarker(titleMarker: String, latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2DMake(latitude, longitude)
        marker.title = title
        marker.map = mapView
    }
}


