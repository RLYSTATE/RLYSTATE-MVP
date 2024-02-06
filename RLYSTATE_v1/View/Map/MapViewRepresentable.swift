//  MapViewRepresentable.swift
//  Rlystate_V2
//
//  Created by Shervin Mobasheri on 12/19/23.
//

import SwiftUI
import MapKit
import FirebaseFirestore


struct MapViewRepresentable: UIViewRepresentable {
    
    let usermapView = MKMapView()
    let locationManager = LocationManager()
    @Binding var mapState: MapViewState
    @EnvironmentObject var locationViewModel:  LocationSearchViewModel
    var onAnnotationSelected: (Post) -> Void
    
    func makeUIView(context: Context) -> MKMapView {  /// MKMapview?
        usermapView.delegate = context.coordinator
        usermapView.isRotateEnabled = false
        usermapView.showsUserLocation = true
        usermapView.userTrackingMode = .follow
        // Set the initial region and fetch posts in this method
              configureInitialViewState()
              fetchAndGroupPosts()
        
        
        return usermapView
    }
    private func configureInitialViewState() {
           // Set the initial region to Manhattan
           let manhattanRegion = MKCoordinateRegion(
               center: CLLocationCoordinate2D(latitude: 40.7700, longitude: -73.9800), // Manhattan coordinates
               span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
           )
           usermapView.setRegion(manhattanRegion, animated: true)
       }
       
    private func fetchAndGroupPosts() {
           Firestore.firestore().collection("Posts").addSnapshotListener { (querySnapshot, error) in
               if let error = error {
                   print("DEBUG: Error fetching documents: \(error.localizedDescription)")
                   return
               }
               
               guard let documents = querySnapshot?.documents else {
                   print("DEBUG: No documents in 'Posts' collection.")
                   return
               }
               
               let posts: [Post] = documents.compactMap { try? $0.data(as: Post.self) }
               createAnnotations(from: posts)
           }
       }
       private func createAnnotations(from posts: [Post]) {
           print("DEBUG: Creating annotations")
           DispatchQueue.main.async {
               // Remove all existing annotations
               self.usermapView.removeAnnotations(self.usermapView.annotations)
               // Add new annotations
               posts.forEach { post in
                   let annotation = PostAnnotation(post: post)
                   self.usermapView.addAnnotation(annotation)
                   //print("DEBUG: Annotation added for post: \(post.text)")
               }
           }
       }
    
    /// Update UI View
    func updateUIView(_ uiView: MKMapView, context: Context) {
        print("DEBUG: Map state is \(mapState)")
        
        switch mapState {
        case .noInput:
            context.coordinator.clearMapViewandRecenterOnUserLocation()
            //reapplyAllAnnotations(to: uiView)
            break
        case .searchingForLocation:
            break
        case .locationSelected:
            if let coordinate = locationViewModel.selectedLocation?.coordinate {
                print("DEBUG: Centering map on \(coordinate)")
                                   let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
                                   uiView.setRegion(region, animated: true)
                context.coordinator.addAndSelectAnnotation(withCoordinate: coordinate)
                
                // Add search result annotation
                                  let searchAnnotation = MKPointAnnotation()
                                  searchAnnotation.coordinate = coordinate
                                  uiView.addAnnotation(searchAnnotation)
            }
            break
        }
    }
    private func reapplyAllAnnotations(to mapView: MKMapView) {
           // Clear previous search annotation
        clearSearchAnnotations(from: mapView)
        // Fetch posts again or use a stored property for posts
        fetchAndGroupPosts()
       }
    
    class SearchResultAnnotation: NSObject, MKAnnotation {
          dynamic var coordinate: CLLocationCoordinate2D
          // Add other properties if needed, like title or subtitle

          init(coordinate: CLLocationCoordinate2D) {
              self.coordinate = coordinate
          }
      }
    
    
    private func clearSearchAnnotations(from mapView: MKMapView) {
            // Remove only search-related annotations
            let searchAnnotations = mapView.annotations.filter { $0 is MKPointAnnotation }
            mapView.removeAnnotations(searchAnnotations)
        }
    
    func makeCoordinator() -> MapCoordinator {
        return MapCoordinator(parent: self, onAnnotationSelected: onAnnotationSelected) // onAnnotationSelected: onAnnotationSelected
    }
}

extension MapViewRepresentable {
    class MapCoordinator: NSObject, MKMapViewDelegate {
        
        // Properties
        
        let parent: MapViewRepresentable
        var currentRegion: MKCoordinateRegion?
        var onAnnotationSelected: (Post) -> Void
        
        // Lifecycle
        init(parent: MapViewRepresentable, onAnnotationSelected: @escaping (Post) -> Void) {
            self.parent = parent
            self.onAnnotationSelected = onAnnotationSelected
            super.init()
        }
        
        // MapViewDelegate
        
        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            let region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
            self.currentRegion = region
            
            parent.usermapView.setRegion(region, animated: true)
            
            }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
              if let annotation = view.annotation as? PostAnnotation {
                  // Zoom to the annotation's location
                  let region = MKCoordinateRegion(center: annotation.coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
                  mapView.setRegion(region, animated: true)

                  // Handle the selected post
                  DispatchQueue.main.async {
                      self.onAnnotationSelected(annotation.post)
                  }
              }
          }
        
        
        // Helpers
        
        func addAndSelectAnnotation(withCoordinate coordinate: CLLocationCoordinate2D) {
            parent.usermapView.removeAnnotations(parent.usermapView.annotations)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            parent.usermapView.addAnnotation(annotation)
            parent.usermapView.selectAnnotation(annotation, animated: true)
            
            // Set the map region to be centered on the annotation with a closer zoom level
            let zoomRegion = MKCoordinateRegion(center: coordinate, latitudinalMeters: 500, longitudinalMeters: 500) // Adjust the meters for desired zoom level
            parent.usermapView.setRegion(zoomRegion, animated: true)
        }
        
        func clearMapViewandRecenterOnUserLocation() {
            parent.reapplyAllAnnotations(to: parent.usermapView)
            
            if let currentRegion = currentRegion {
                parent.usermapView.setRegion(currentRegion, animated: true)
            }
        
        }
    }
}
