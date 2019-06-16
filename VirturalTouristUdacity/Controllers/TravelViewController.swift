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
    var pin : Pin!
    
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
        
        // Save pin to CoreData
         pin = Pin(context: dataController.persistentContainer.viewContext)


        // Add annotation:
        let annotation = MKPointAnnotation()
        annotation.coordinate = travelCoordinates!
        
        pin.latitude = travelCoordinates!.latitude
        pin.longitude = travelCoordinates!.longitude
        pin.coordinates = String(pin.latitude)+String(pin.longitude)
        
        let long = travelCoordinates!.longitude
        let lat = travelCoordinates!.latitude
//        let pin = Pin(context: dataController.persistentContainer.viewContext)
        
        annotation.title = String(pin.latitude)+String(pin.longitude)

        
        let region = MKCoordinateRegion(center: travelCoordinates!, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        
        mapView.setRegion(region, animated: true)

         if sender.state == .began {
            
            mapView.addAnnotation(annotation)
            
            
         } else if sender.state == .ended {
            
            savePinLocationToCoreData(longitude: long, latitude: lat, pin: pin)
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
    
    
    func savePinLocationToCoreData(longitude: CLLocationDegrees, latitude: CLLocationDegrees, pin: Pin){
        
        do{
            self.pin = Pin(context: dataController.persistentContainer.viewContext)
            pin.latitude  = latitude
            pin.longitude  = longitude
            pin.coordinates = String(latitude)+String(longitude)
            print("TravelCtrl \(String(describing: pin.coordinates))")
            
            //MARK: When pins are dropped on the map, the pins are persisted as Pin instances in Core Data and the context is saved.
            try dataController.persistentContainer.viewContext.save()
            pins.append(pin)
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
        print("mapView : \(String(describing: self.travelCoordinates))")
    
        
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
        print("TravlCrl...Pin \(String(describing: pin))")

        for pin in pins{
            if pin.latitude == self.travelCoordinates?.latitude && pin.longitude == self.travelCoordinates?.longitude {
                controllerViewDest.pin = pin
                controllerViewDest.coordinates = self.travelCoordinates
        
                controllerViewDest.dataController = self.dataController
            }

        }
    }

}
