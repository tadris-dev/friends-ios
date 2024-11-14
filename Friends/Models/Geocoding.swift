import CoreLocation
import MapKit

class Geocoding {
    
    static func placeName(for location: Location) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            CLGeocoder().reverseGeocodeLocation(location.clLocation) { placemarks, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: placemarks?.first?.locality ?? "Unknown")
                }
            }
        }
    }
    
    static func formattedDistance(from location: Location, to otherLocation: Location) -> String {
        let distance = location.clLocation.distance(from: otherLocation.clLocation)
        return MKDistanceFormatter().string(fromDistance: distance)
    }
}
