//
//  PhotoAlbumViewController.swift
//  VirturalTouristUdacity
//
//  Created by Darin Williams on 6/8/19.
//  Copyright © 2019 dwilliams. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class PhotoAlbumViewController: UIViewController,  MKMapViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, NSFetchedResultsControllerDelegate 
{

    
    @IBOutlet weak var newCollection: UIButton!
  
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var collectionView: UICollectionView!
  
    @IBOutlet weak var flowLayOut: UICollectionViewFlowLayout!
 
    
    var coordinates: CLLocationCoordinate2D?
    var pin: Pin!

    var dataController:DataController?
    
     var fetchResultsController : NSFetchedResultsController<Photo>!
    
    private var blockOperation = BlockOperation()
 
    
    var page = 1
    var pages =  0

    override func viewDidLoad() {
        super.viewDidLoad()

       
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    
        print("Coordinates \(String(describing: coordinates))")
        print("Pin \(String(describing: pin))")
        self.initializeMapView()
        
    
        setupFetchedResultsControllerAndGetPhotos()
        
        callParseFlickrApi(url: EndPoints.getAuthentication(coordinates!.latitude, coordinates!.longitude).url)
        

    }
    
    //MARK - TEAR DOWN FETCH RESULT CONTROLLER
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
    }

    //Mark New Collection Button
    @IBAction func newCollectionButton(_ sender: UIBarButtonItem) {
        print("New Collection")
    }
    
    //MARK Back button
    @IBAction func backButtonPressed(_ sender: UIBarButtonItem) {
        
          self.dismiss(animated: true, completion: nil)
    }
    
    
    //Mark Call Parse API to get Photos
    func callParseFlickrApi (url: URL) {
        
        ClientAPI.processPhotos(url: url, completionHandler: self.handleGetFlickerPhotos(photos:error:))
    }
    
    func handleGetFlickerPhotos(photos:FlickerResponse?, error:Error?) {
        
        guard let photos = photos else {
            print("Unable to Download photos from Flicker \(String(describing: error))")
            return
        }
        
            self.pages = Int(photos.photos.pages)
            self.saveImagesToCoreData(photos: photos)
    }
    
    
    //MARK Save Image  to Core Data as Binary
    func saveImagesToCoreData(photos:FlickerResponse?) {
        
        
        for image in (photos?.photos.photo)! {
            let photo = Photo(context: dataController!.viewContext)
            
            
            photo.photoURL = EndPoints.getImageUrl(image.farm, image.server, image.id, image.secret).stringValue
            
            ClientAPI.taskDownLoadPhotosData(url: EndPoints.getImageUrl(image.farm, image.server, image.id, image.secret).url) { (response, error) in
                
                photo.images = (response?.pngData()) as Data?
                
            }
//            DispatchQueue.main.async {
//
            do{
                try self.dataController!.viewContext.save()
                print("Savng to Core Data")

            } catch  let error {
                print("Couldn't save to Core Data \(error.localizedDescription)")
            }
//        }
        }
        
        collectionView.reloadData()
        
    }
 
    //MARK Render  each pin's
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
    
    // MARK: - UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchResultsController.sections?.count ?? 0
    }
    
    //Mark NumberOfItemsInSection
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    
    //Mark CellForItemAt
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let aPhotoImage = fetchResultsController.object(at: indexPath)
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FlickrCollectionViewCell", for: indexPath) as! FlickrCollectionViewCell
        
        DispatchQueue.main.async {
            do {
                if let data = aPhotoImage.images as Data? {
                    cell.photoImage.image = UIImage(data: data)
                  }
            } catch let error {
                print("CellForItemAt \(error.localizedDescription)")
            }
            
        }

        return cell
    }

}

extension PhotoAlbumViewController {
    
    //MARK INITIALIZE MAP VIEW
    fileprivate func initializeMapView() {
        
        let annotation = MKPointAnnotation()
      
        guard self.coordinates != nil else {
            print("coordinates are null")
            return
        }
        
        annotation.coordinate = self.coordinates!
        annotation.title = "Coordinates Found"
        
        
        self.mapView.addAnnotation(annotation)
        let region = MKCoordinateRegion(center: self.coordinates!, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        mapView.setRegion(region, animated: true)
    }

}


//Mark Update Collection with Notifications
extension PhotoAlbumViewController {
    
    //MARK SETUP FETCH RESULTS CONTROLLER
    func setupFetchedResultsControllerAndGetPhotos() {
        // set up fetched results controller
        let fetchRequest : NSFetchRequest<Photo> = Photo.fetchRequest()
        
        let sortDescriptor = NSSortDescriptor(key: "images", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController!.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchResultsController.delegate = self
        
        do {
            try fetchResultsController.performFetch()
        } catch  let error {
            print("PhotoAlbumViewController: catchStatement \(error.localizedDescription)")
            fatalError(error.localizedDescription)
        }
        
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {

        switch type {
        case .insert:
            guard let newIndexPath = newIndexPath else { break }

            blockOperation.addExecutionBlock {
                self.collectionView?.insertItems(at: [newIndexPath])
            }
        case .delete:
            guard let indexPath = indexPath else { break }

            blockOperation.addExecutionBlock {
                self.collectionView?.deleteItems(at: [indexPath])
            }
        case .update:
            guard let indexPath = indexPath else { break }

            blockOperation.addExecutionBlock {
                self.collectionView?.reloadItems(at: [indexPath])
            }
        case .move:
            guard let indexPath = indexPath, let newIndexPath = newIndexPath else { return }

            blockOperation.addExecutionBlock {
                self.collectionView?.moveItem(at: indexPath, to: newIndexPath)
            }
        }
    }
}

