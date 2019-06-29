//
//  ViewController.swift
//  Northstar
//
//  Created by Daxit Agarwal on 6/5/19.
//

import UIKit
import Mapbox
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import MapboxGeocoder
import SwiftGRPC


// MGLPointAnnotation subclass
class PGETowerAnnotation: MGLPointAnnotation {
}
// end MGLPointAnnotation subclass


class ViewController: UIViewController, MGLMapViewDelegate {
    //MARK: Properties
    var mapView: NavigationMapView!
    var directionsRoute: Route?
    var client: NorthstarCloud_NorthStarServiceServiceClient?
    @IBOutlet weak var navInfo: UIView!
    @IBOutlet weak var addressBox: UILabel!
    @IBOutlet weak var addressBoxMin: UILabel!
    @IBOutlet weak var navButton: UIButton!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView = NavigationMapView(frame: view.bounds)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(mapView, belowSubview: navInfo)
        
        //Style Nav Info UI View
        self.navInfo.layer.cornerRadius = 10
        
        mapView.delegate = self
        
        mapView.showsUserLocation = true
        mapView.setUserTrackingMode(.follow, animated: true)
        
        // Add a gesture recognizer to the map view
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress(_:)))
        mapView.addGestureRecognizer(longPress)
        
        // Load the GRPC Client
        self.client = NorthstarCloud_NorthStarServiceServiceClient.init(address: "localhost:50051", secure: false)
        var requestImage = NorthstarCloud_GetImageRequest()
        requestImage.imageName = "fire_burned.jpg"
        requestImage.imageID = "1861cf56-69a5-41e6-8e2b-476d854fcbc7"
        _ = try? self.client?.getImage(requestImage) {NorthstarCloud_GetImageReply, callResult in print(callResult)}
        print("\n Hitesh")
        
//        navigateButton.addTarget(self, action: #selector(navigateButtonWasPressed(_:)), for: .touchUpInside)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        let alert = UIAlertController(title: "Evacuate Immediately", message: "A wildfire is approaching your location.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Start Navigation", style: .default, handler: {(UIAlertAction) in
            let navigationViewController = NavigationViewController(for: self.directionsRoute!)
            self.present(navigationViewController, animated: true, completion: nil)
        }))
        
        Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { timer in
            self.present(alert, animated: true)
        }
        
    }
    
    
    func mapViewDidFinishLoadingMap(_ mapView: MGLMapView) {
        // Plot 10 random saftey zones
        var lastCoord: CLLocationCoordinate2D?
        for i in 1...10 {
            let annotation = MGLPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: 37.220818 + Double.random(in: 0.01...0.03), longitude: -121.782621 + Double.random(in: 0.005...0.03))
            annotation.title = "Navigate to Safe Zone " + String(i)
            mapView.addAnnotation(annotation)
            calculateRoute(from: (mapView.userLocation!.coordinate), to: annotation.coordinate) { (route, error) in
                if error != nil {
                    print("Error calculating route")
                }
            }
            lastCoord = annotation.coordinate
        }
        
        // Show last route
        if let coord = lastCoord {
            self.showDestination(coordinate: coord)
        }
        
        // Plot 5 random pg&e towers
        for _ in 1...5 {
            let annotation = PGETowerAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: 37.220818 + Double.random(in: -0.01...0.03), longitude: -121.782621 + Double.random(in: -0.005...0.03))
            annotation.title = "(Fire Risk) Power"
            mapView.addAnnotation(annotation)
        }
    }
    
    func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        if let _ = annotation as? PGETowerAnnotation {
            return MGLAnnotationImage(image: UIImage(named: "powervector")!, reuseIdentifier: "power")
        }
        return nil
    }

    
    @objc func didLongPress(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else { return }
        
        // Converts point where user did a long press to map coordinates
        let point = sender.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        
        // Create a basic point annotation and add it to the map
        let annotation = MGLPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = "Start navigation"
        mapView.addAnnotation(annotation)
        
        // Calculate the route from the user's location to the set destination
        calculateRoute(from: (mapView.userLocation!.coordinate), to: annotation.coordinate) { (route, error) in
            if error != nil {
                print("Error calculating route")
            }
        }
        
        self.showDestination(coordinate: coordinate)
    }
    
    // Calculate route to be used for navigation
    func calculateRoute(from origin: CLLocationCoordinate2D,
                        to destination: CLLocationCoordinate2D,
                        completion: @escaping (Route?, Error?) -> ()) {
        
        // Coordinate accuracy is the maximum distance away from the waypoint that the route may still be considered viable, measured in meters. Negative values indicate that a indefinite number of meters away from the route and still be considered viable.
        let origin = Waypoint(coordinate: origin, coordinateAccuracy: -1, name: "Start")
        let destination = Waypoint(coordinate: destination, coordinateAccuracy: -1, name: "Finish")
        
        // Specify that the route is intended for automobiles avoiding traffic
        let options = NavigationRouteOptions(waypoints: [origin, destination], profileIdentifier: .automobileAvoidingTraffic)
        
        // Generate the route object and draw it on the map
        _ = Directions.shared.calculate(options) { [unowned self] (waypoints, routes, error) in
            self.directionsRoute = routes?.first
            // Draw the route on the map after creating it
            self.drawRoute(route: self.directionsRoute!)
        }
        
    }
    
    func drawRoute(route: Route) {
        guard route.coordinateCount > 0 else { return }
        // Convert the route’s coordinates into a polyline
        var routeCoordinates = route.coordinates!
        let polyline = MGLPolylineFeature(coordinates: &routeCoordinates, count: route.coordinateCount)
        
        // If there's already a route line on the map, reset its shape to the new route
        if let source = mapView.style?.source(withIdentifier: "route-source") as? MGLShapeSource {
            source.shape = polyline
        } else {
            let source = MGLShapeSource(identifier: "route-source", features: [polyline], options: nil)
            
            // Customize the route line color and width
            let lineStyle = MGLLineStyleLayer(identifier: "route-style", source: source)
            lineStyle.lineColor = NSExpression(forConstantValue: #colorLiteral(red: 0.1897518039, green: 0.3010634184, blue: 0.7994888425, alpha: 1))
            lineStyle.lineWidth = NSExpression(forConstantValue: 3)
            
            // Add the source and style layer of the route line to the map
            mapView.style?.addSource(source)
            mapView.style?.addLayer(lineStyle)
        }
    }

    // Implement the delegate method that allows annotations to show callouts when tapped
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
    }
    
    // Present the navigation view controller when the callout is selected
    func mapView(_ mapView: MGLMapView, tapOnCalloutFor annotation: MGLAnnotation) {
        let navigationViewController = NavigationViewController(for: directionsRoute!)
        self.present(navigationViewController, animated: true, completion: nil)
    }
    
    @IBAction func navigateZone(_ sender: Any) {
        let navigationViewController = NavigationViewController(for: directionsRoute!)
        self.present(navigationViewController, animated: true, completion: nil)
    }
    
    func showDestination(coordinate: CLLocationCoordinate2D) {
        // main.swift
        let options = ReverseGeocodeOptions(coordinate: coordinate)
        // Or perhaps: ReverseGeocodeOptions(location: locationManager.location)
        
        let _ = Geocoder.shared.geocode(options) { (placemarks, attribution, error) in
            guard let placemark = placemarks?.first else {
                return
            }
            print(placemark.addressDictionary ?? "")
            print(placemark.postalAddress?.street ?? "")
            print(placemark.postalAddress?.city ?? "")
            print(placemark.postalAddress?.state ?? "")
            print(placemark.postalAddress?.postalCode ?? "")
            print("")
            print(placemark.formattedName)
            
            self.addressBox.text = placemark.formattedName
            if let address = placemark.postalAddress {
                self.addressBoxMin.text = address.city + ", " + address.state + " " + address.postalCode
            }
            
        }
    }
}
