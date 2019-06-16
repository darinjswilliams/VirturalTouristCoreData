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

class PhotoAlbumViewController: UIViewController,  MKMapViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource
{
    
    
    @IBOutlet weak var newCollection: UIButton!
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var flowLayOut: UICollectionViewFlowLayout!
    
    
    var coordinates: CLLocationCoordinate2D?
    var pin: Pin?
    
    var dataController:DataController?
    
    var fetchResultsController : NSFetchedResultsController<Photo>!
    
    private var blockOperation = BlockOperation()
    
    var imageArray: [Data] = []
    var  photoArray:  [Photo] = []
    var page = 1
    var pages =  0
    var  existingPin : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
       initializeMapView()
       LoadingViewActivity.show(mapView, loadingText: "Loading")
       setupFetchedResultsControllerAndGetPhotos()
      
        print("Coordinates \(String(describing: self.coordinates))")
        print("Pin \(String(describing: self.pin))")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
     
        
        
        if existingPin {
            print("reload data")
            
            if let indexPath = collectionView.indexPathsForSelectedItems {
                collectionView.reloadItems(at: indexPath)
            }
            
        } else {
            
            callParseFlickrApi(url: EndPoints.getAuthentication(coordinates!.latitude, coordinates!.longitude).url)
            
        }
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
        self.saveImagesToCoreData(photos: photos )
    }
    
    
    //MARK Save Image  to Core Data as Binary
    func saveImagesToCoreData(photos:FlickerResponse?) {
        
         LoadingViewActivity.hide()
          for image in (photos?.photos.photo)! {
            
            let photo = Photo(context: dataController!.viewContext)
            
            photo.pin = self.pin
           
            ClientAPI.taskDownLoadPhotosData(url: EndPoints.getImageUrl(image.farm, image.server, image.id, image.secret).url) { (response, error) in
        
                guard let response = response else {
                    return
                }
                
           photo.images = response
          print("saveImages to core daa")
         }
        
        do {
            try dataController?.viewContext.save()
        } catch let error {
            
            print("saveImages: \(error.localizedDescription)")
        }
            
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
        return fetchResultsController.sections?.count ?? 1
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
extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    
    //MARK SETUP FETCH RESULTS CONTROLLER
    func setupFetchedResultsControllerAndGetPhotos() {
        // set up fetched results controller
        let fetchRequest : NSFetchRequest<Photo> = Photo.fetchRequest()
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "pin = %@", argumentArray: [pin])
        
        fetchResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController!.persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchResultsController.delegate = self

        do {
            try fetchResultsController.performFetch()
        } catch  let error {
            print("PhotoAlbumViewController: catchStatement \(error.localizedDescription)")
            fatalError(error.localizedDescription)
        }
        
        
        do {
            
            let totalCount = try fetchResultsController.managedObjectContext.count(for: fetchRequest)
            
            if totalCount > 0 {
                print("total count \(totalCount)")
                existingPin = true
            } else {
                existingPin = false
            }
            
        } catch let error {
            print("setupFetchedResultsControllerAndGetPhotos: \(error.localizedDescription)")
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

