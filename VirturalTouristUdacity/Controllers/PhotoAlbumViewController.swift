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

class PhotoAlbumViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, MKMapViewDelegate, NSFetchedResultsControllerDelegate
 {
   
    
    @IBOutlet weak var newCollection: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var flowLayOut: UICollectionViewFlowLayout!
    
    var fetchResultsController : NSFetchedResultsController<Photo>!
    
    var coordinates: CLLocationCoordinate2D!
    var pin: Pin!

    var dataController:DataController!
 
    
    var page = 1
    var pages =  0

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.initializeMapView()
        self.setupFlowLayOut()
        
        //GET PHOTOS
       setupFetchedResultsControllerAndGetPhotos()
        
        callParseFlickrApi(url: EndPoints.getAuthentication(coordinates.latitude, coordinates.longitude).url)

        
        collectionView.reloadData()

    }
    
    //MARK - TEAR DOWN FETCH RESULT CONTROLLER
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        fetchResultsController = nil
    }

    
    //MARK Back button
    @IBAction func backButtonPressed(_ sender: UIBarButtonItem) {
        
          self.dismiss(animated: true, completion: nil)
    }
    
    
    //Mark New Collection of Photo
    @IBAction func newCollectionButtonPressed(_ sender: UIButton) {
        
        let photoSet = fetchResultsController.fetchedObjects
        let fetchRequest : NSFetchRequest<Photo> = Photo.fetchRequest()
        
        //MARK DELETE ALL PHOTOS FROM GCD
        print("PHOTOS IN PHOTOTSET \(String(describing: photoSet?.count))")
        for photo in photoSet! {
            dataController.viewContext.delete(photo as NSManagedObject)
        }
        
        //Lets generate random number for new page of photos
        if self.pages > 0 {
            print("good number")
        } else {
            self.pages = 2
            
        }
        
         let randomPageNumber = Int.random(in: page...self.pages)
        
    
        // Create Batch Delete Request
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult>)
        
        // Configure Batch Update Request
        batchDeleteRequest.resultType = .resultTypeCount
        
        do {
            // Execute Batch Request
            let batchDeleteResult = try dataController.viewContext.execute(batchDeleteRequest) as! NSBatchDeleteResult
            
            print("The batch delete request has deleted \(batchDeleteResult.result!) records.")
          
            // Reset Managed Object Context
            dataController.viewContext.reset()
            
            // Perform Fetch
            try self.fetchResultsController.performFetch()
            
            // Reload Table View
          
            if let indexPath = collectionView.indexPathsForSelectedItems {
                            collectionView.reloadItems(at: indexPath)
                        }
            
            collectionView.reloadData()
            
            
        } catch {
            let updateError = error as NSError
            print("\(updateError), \(updateError.userInfo)")
        }
        callParseFlickrApi(url: EndPoints.getPhotos(randomPageNumber, coordinates.latitude, coordinates.longitude).url)
        
    
//        if let indexPath = collectionView.indexPathsForSelectedItems {
//            collectionView.reloadItems(at: indexPath)
//        }
     
        print("New Collection")
    }
    
    
    func callParseFlickrApi (url: URL) {
        
        ClientAPI.processPhotos(url: url, completionHandler: self.handleGetFlickerPhotos(photos:error:))
    }
    
    func handleGetFlickerPhotos(photos:FlickerResponse?, error:Error?) {
        
        guard let photos = photos else {
            print("Unable to Download photos from Flicker \(error)")
            return
        }
        
        self.pages = Int(photos.photos.pages)
        self.saveImagesToCoreData(photos: photos)
        
    }
    
    
    //MARK Save IMage  to Core Data
    func saveImagesToCoreData(photos:FlickerResponse?) {
        
        
        for image in (photos?.photos.photo)! {
            let photo = Photo(context: dataController.viewContext)
           
          
               photo.photoURL = EndPoints.getImageUrl(image.farm, image.server, image.id, image.secret).stringValue

               ClientAPI.taskDownLoadPhotosData(url: EndPoints.getImageUrl(image.farm, image.server, image.id, image.secret).url) { (response, error) in
               
                photo.images = (response?.pngData()) as Data?
//                print(response!)
                
            }
            
            do{
               try dataController.viewContext.save()
               print("Savng to Core Data")
            } catch {
                print("Couldn't save to Core Data")
            }
            
      
           
        }
        
    }
 
   
    //MARK TABLE DATA SOURCE
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        print("count in numberOfSections \(fetchResultsController.sections?.count)")
        return fetchResultsController.sections?.count ?? 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        
        let aPhotoImage = fetchResultsController.object(at: indexPath)
        
              let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FlickrCollectionViewCell", for: indexPath) as! FlickrCollectionViewCell
        
        // Render as bit map before rendering
        cell.layer.shouldRasterize = true
        
        // Scale the raster content to size of  main screen
        cell.layer.rasterizationScale = UIScreen.main.scale
        cell.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.015)
        
        
        DispatchQueue.main.async {
   
            if let data = aPhotoImage.images as Data? {
               cell.photoImage.image = UIImage(data: data)
//            } else {
//                //Place holder image
//                cell.photoImage.image = UIImage(named: "VirtualTourist_76")
            }
            
            if let indexPath = collectionView.indexPathsForSelectedItems {
                collectionView.reloadItems(at: indexPath)
            }

        }
        return cell
    }

    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let photo = fetchResultsController.object(at: indexPath)
     
        print("Deleting Photo \(photo)")
        dataController.viewContext.delete(photo)
        try? dataController.viewContext.save()
        collectionView.reloadData()
//        if let indexPath = collectionView.indexPathsForSelectedItems {
//            collectionView.reloadItems(at: indexPath)
//        }
        
        
        return
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

}

extension PhotoAlbumViewController {
    fileprivate func initializeMapView() {
        let annotation = MKPointAnnotation()
        
        guard case let pin = Pin(context: dataController.viewContext) else {
            print("Invalid Pin")
            return
            
        }
        print("PhtoCtrl coordinates \(String(describing: pin.coordinates))")
        
        
        annotation.coordinate = coordinates
        annotation.title = "Coordinates Found"
        
        self.mapView.addAnnotation(annotation)
        let region = MKCoordinateRegion(center: coordinates!, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        mapView.setRegion(region, animated: true)
    }
    
    
    fileprivate func setupFlowLayOut() {
        let space:CGFloat = 8
        let dimension = (view.frame.size.width - (2 * space)) / 4.0
        let hdimention = (view.frame.size.height - (2 * space)) / 4.0
        flowLayOut.minimumInteritemSpacing = space
        flowLayOut.minimumLineSpacing = space
        flowLayOut.itemSize = CGSize(width: dimension, height: hdimention)
    }
    
    func setupFetchedResultsControllerAndGetPhotos() {
        // set up fetched results controller
        let fetchRequest : NSFetchRequest<Photo> = Photo.fetchRequest()
    
        let sortDescriptor = NSSortDescriptor(key: "images", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchResultsController.delegate = self
        
        do {
            try fetchResultsController.performFetch()
        } catch {
            fatalError(error.localizedDescription)
        }
        
    }
}

//extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
//
//    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
//        let sectionIndexSet = IndexSet(integer: sectionIndex)
//
//        switch type {
//        case .insert:
//                self.collectionView?.insertSections(sectionIndexSet)
//                break
//
//        case .delete:
//                self.collectionView?.deleteSections(sectionIndexSet)
//                break
//
//        case .update:
//                self.collectionView?.reloadSections(sectionIndexSet)
//                break
//
//        case .move:
//            assertionFailure()
//            break
//        }
//    }
//
//
//
//}
