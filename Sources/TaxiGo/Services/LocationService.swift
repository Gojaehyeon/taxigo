import Foundation
import CoreLocation
import Observation

/// Thin wrapper around CLLocationManager that publishes MeterTicks
/// while `isActive` is true. Lives on the main actor because
/// `CLLocationManager` delegate callbacks arrive on the thread where
/// the manager was created — we always init from `@MainActor` code.
@Observable
@MainActor
final class LocationService: NSObject, @preconcurrency CLLocationManagerDelegate {
    enum Authorization { case unknown, denied, authorized }

    private let manager = CLLocationManager()
    private var lastLocation: CLLocation?
    private var lastTickAt: Date?

    var authorization: Authorization = .unknown
    var isActive: Bool = false
    var latestSpeed: Double = 0           // m/s
    var latestAccuracy: Double = .infinity
    var lastError: Error?

    /// Published stream of ticks the ViewModel consumes.
    var onTick: ((MeterTick) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.activityType = .automotiveNavigation
        manager.distanceFilter = 5
    }

    func requestPermission() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            authorization = .denied
        default:
            authorization = .authorized
        }
    }

    func start() {
        guard authorization == .authorized else {
            requestPermission()
            return
        }
        isActive = true
        lastLocation = nil
        lastTickAt = nil
        manager.startUpdatingLocation()
    }

    func stop() {
        isActive = false
        manager.stopUpdatingLocation()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            authorization = .authorized
        case .denied, .restricted:
            authorization = .denied
        default:
            authorization = .unknown
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isActive, let loc = locations.last else { return }
        latestAccuracy = loc.horizontalAccuracy
        guard loc.horizontalAccuracy > 0, loc.horizontalAccuracy <= 50 else { return }

        let now = loc.timestamp
        let dt = lastTickAt.map { now.timeIntervalSince($0) } ?? 0
        let dd = lastLocation.map { loc.distance(from: $0) } ?? 0
        let speed = max(0, loc.speed)
        latestSpeed = speed
        lastLocation = loc
        lastTickAt = now

        guard dt > 0 else { return }
        let tick = MeterTick(timestamp: now, deltaDistance: dd, speed: speed, deltaTime: dt)
        onTick?(tick)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        lastError = error
        #if DEBUG
        print("[LocationService] didFailWithError: \(error.localizedDescription)")
        #endif
    }
}
