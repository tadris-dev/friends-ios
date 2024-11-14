import CoreLocation
import Foundation
import MapKit

struct Location: Hashable {
    
    let latitude: Double
    let longitude: Double
    
    var clLocation: CLLocation { .init(latitude: latitude, longitude: longitude) }
    var coordinate: CLLocationCoordinate2D { .init(latitude: latitude, longitude: longitude) }
    var region: MKCoordinateRegion {
        let delta: Double = 0.01
        let span = MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta)
        return .init(center: coordinate, span: span)
    }
    
    var place: String {
        get async {
            (try? await Geocoding.placeName(for: self)) ?? "Unknown"
        }
    }
    
    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    static func == (lhs: Location, rhs: Location) -> Bool {
        lhs.latitude == rhs.latitude
        && lhs.longitude == rhs.longitude
    }
}
