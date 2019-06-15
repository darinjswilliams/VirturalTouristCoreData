//
//  TravelViewController.swift
//  VirturalTouristUdacity
//
//  Created by Darin Williams on 6/8/19.
//  Copyright © 2019 dwilliams. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelViewController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate, NSFetchedResultsControllerDelegate {

    
    @IBOutlet weak var mapView: MKMapView!
    var mapAnnotations = [MKAnnotation]()
    var travelCoordinates : CLLocationCoordinate2D?
    var coordinatesData: String = ""
    
    //lets set up dependencty injections
    var dataController:DataController!
    
    
    //MARK Define FetchResultController
    var fetchedResultsController : NSFetchedResultsController<Pin>!
    var pins : [Pin] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setUpFetchResultController()
        
        if !pins.isEmpty {
            for pin in pins {
                addPin(coordinates: CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude))
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        //MARK tear down Fetch Controller
        fetchedResultsController = nil
    }
    

    
    @IBAction func pinPressed(_ sender: UILongPressGestureRecognizer) {
        
        //MARK CHECK PIN FOR STATE
        print("here is the value \(sender.state.rawValue)")
       
        let location = sender.location(in: mapView)
        
        travelCoordinates = mapView.convert(location, toCoordinateFrom: self.mapView)
   
        // Add annotation:
        let annotation = MKPointAnnotation()
        annotation.coordinate = travelCoordinates!
        
        let long = travelCoordinates!.longitude
        let lat = travelCoordinates!.latitude
        
        annotation.title = String(lat)+String(long)

        
        let region = MKCoordinateRegion(center: travelCoordinates!, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        
        mapView.setRegion(region, animated: true)

         if sender.state == .began {
            
            mapView.addAnnotation(annotation)
            
            
         } else if sender.state == .ended {
            
             savePinLocationToCoreData(longitude: long, latitude: lat)
        }
           
    }
    
    
      //MARK SETUP FetchResult Contoller
     @discardableResult func setUpFetchResultController() -> [Pin]? {
        
        let fetchRequest : NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "coordinates", ascending: false)
        //Use predicate to search
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        //Instaniate fetch results controller
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        //MARK set fetch result controller delegate
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch  {
            fatalError("Fetching the Pins could not be performed \(error.localizedDescription)")
        }
        
        
        //MARK GET PINS
        do {
            let totalPins = try fetchedResultsController.managedObjectContext.count(for: fetchRequest)
            for i in 0..<totalPins {
                pins.append(fetchedResultsController.object(at: IndexPath(row: i, section: 0)))
            }
            return pins
        } catch {
            return nil
        }
        
    }
    
    
    func savePinLocationToCoreData(longitude: CLLocationDegrees, latitude: CLLocationDegrees){
        
        do{
            let pin = Pin(context: dataController.viewContext)
            pin.latitude  = latitude
            pin.longitude  = longitude
            coordinatesData = String(latitude)+String(longitude)
            pin.coordinates = coordinatesData
            print("TravelCtrl \(String(describing: pin.coordinates))")
            
            //MARK: When pins are dropped on the map, the pins are persisted as Pin instances in Core Data and the context is saved.
            try dataController.viewContext.save()
            print("Saving Pin to Core data")
        }
        catch let error
        {
            print(error)
        }
    }
    
    
    func addPin(coordinates: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinates
        mapView.addAnnotation(annotation)
        mapAnnotations.append(annotation)
        mapView.showAnnotations(mapAnnotations, animated: true)
    }
    
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        
        //Get current Coordinates
        self.travelCoordinates = view.annotation?.coordinate
        print("mapView : \(self.travelCoordinates)")
    
//        //fetch current location data
//        let fetchRequest : NSFetchRequest<Pin> = Pin.fetchRequest()
//
//        //Use predicate to search
//        fetchRequest.predicate = NSPredicate(format: "coordinates == %@", coordinatesData)
//        print("CoordinatesData \(coordinatesData)")
//
//        if let result = try?  dataController.viewContext.fetch(fetchRequest)
//        {
//            if(result.count > 0)
//            {
//                print("CoordinateData: \(coordinatesData)")
//                self.pins = [result[0]]
//            }
//            else
//            {
//                return
//            }
//        }
        
        self.performSegue(withIdentifier: "showPhotos", sender: self)
        
    }
    
    // each pin's rendering
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: annotationId)
            pinView?.canShowCallout = true
            pinView?.pinTintColor = .blue
            pinView?.rightCalloutAccessoryView = UIButton(type:.detailDisclosure)
        } else {
            pinView?.annotation = annotation
        }
        return pinView
    }

    
    //MARK: All Controller inherit prepare, which is called before performSeque
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let controllerViewDest = segue.destination as?  PhotoAlbumViewController else {
            print("Can not transition to photo album view controller")
            return
        }
        
        print("TravlCrtl..Coordinates \(String(describing: self.travelCoordinates?.latitude))")
            print("TravlCrtl..Coordinates \(String(describing: self.travelCoordinates?.longitude))")
//        print("count in pins \(pins.count)")
//
//
//
//        for pin in pins {
//            if pin.latitude == self.travelCoordinates!.latitude && pin.longitude == self.travelCoordinates!.longitude {
//
//                print("latitude: \(pin.latitude)")
//                print("longitude: \(pin.longitude)")
                controllerViewDest.coordinates = self.travelCoordinates
//                controllerViewDest.pin = pin
                controllerViewDest.dataController = self.dataController
            }
//        }
//    }
    
    

}
