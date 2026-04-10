import Flutter
import UIKit
import AVFoundation
import CoreLocation

public class IosPermissionPlugin: NSObject, FlutterPlugin, CLLocationManagerDelegate {
  private var locationManager: CLLocationManager?
  private var locationPermissionResult: FlutterResult?
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    // Camera permission channel
    let cameraChannel = FlutterMethodChannel(name: "com.aviatorapp.native_permissions", binaryMessenger: registrar.messenger())
    let cameraInstance = IosPermissionPlugin()
    registrar.addMethodCallDelegate(cameraInstance, channel: cameraChannel)
    
    // Location permission channel
    let locationChannel = FlutterMethodChannel(name: "com.aviatorapp.native_location_permissions", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(cameraInstance, channel: locationChannel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    // Camera permission methods
    case "requestCameraPermission":
      requestCameraPermissionNative(result: result)
    case "getCameraPermissionStatus":
      getCameraPermissionStatus(result: result)
    // Location permission methods
    case "requestLocationPermission":
      requestLocationPermissionNative(result: result)
    case "getLocationPermissionStatus":
      getLocationPermissionStatus(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  // MARK: - Native Camera Permission Methods
  
  private func requestCameraPermissionNative(result: @escaping FlutterResult) {
    print("🎥 [Swift] Requesting camera permission natively...")
    
    let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
    print("🎥 [Swift] Current camera authorization status: \(authStatus.rawValue)")
    
    switch authStatus {
    case .authorized:
      print("🎥 [Swift] Camera permission already granted")
      result(true)
    case .notDetermined:
      print("🎥 [Swift] Camera permission not determined, requesting...")
      AVCaptureDevice.requestAccess(for: .video) { granted in
        DispatchQueue.main.async {
          print("🎥 [Swift] Camera permission request result: \(granted)")
          result(granted)
        }
      }
    case .denied:
      print("🎥 [Swift] Camera permission denied, forcing request...")
      // Force request even if denied before
      AVCaptureDevice.requestAccess(for: .video) { granted in
        DispatchQueue.main.async {
          print("🎥 [Swift] Forced camera permission request result: \(granted)")
          result(granted)
        }
      }
    case .restricted:
      print("🎥 [Swift] Camera permission restricted by device policy")
      result(false)
    @unknown default:
      print("🎥 [Swift] Unknown camera permission status")
      result(false)
    }
  }
  
  private func getCameraPermissionStatus(result: @escaping FlutterResult) {
    print("🎥 [Swift] getCameraPermissionStatus method called")
    let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
    print("🎥 [Swift] Camera permission status check: \(authStatus.rawValue)")
    print("🎥 [Swift] Auth status enum: \(authStatus)")
    
    // Create detailed status info
    var statusInfo: [String: Any] = [:]
    
    switch authStatus {
    case .authorized:
      statusInfo["status"] = "authorized"
      statusInfo["canUseCamera"] = true
      statusInfo["canRequest"] = false
      statusInfo["needsSettings"] = false
      statusInfo["description"] = "Camera access granted by user"
    case .notDetermined:
      statusInfo["status"] = "notDetermined"
      statusInfo["canUseCamera"] = false
      statusInfo["canRequest"] = true
      statusInfo["needsSettings"] = false
      statusInfo["description"] = "User hasn't been asked for camera permission yet"
    case .denied:
      statusInfo["status"] = "denied"
      statusInfo["canUseCamera"] = false
      statusInfo["canRequest"] = true // iOS allows re-requesting even if denied
      statusInfo["needsSettings"] = true
      statusInfo["description"] = "User explicitly denied camera access"
    case .restricted:
      statusInfo["status"] = "restricted"
      statusInfo["canUseCamera"] = false
      statusInfo["canRequest"] = false
      statusInfo["needsSettings"] = false
      statusInfo["description"] = "Camera access restricted by device policy or parental controls"
    @unknown default:
      statusInfo["status"] = "unknown"
      statusInfo["canUseCamera"] = false
      statusInfo["canRequest"] = false
      statusInfo["needsSettings"] = false
      statusInfo["description"] = "Unknown camera permission status"
    }
    
    // Add additional system info
    statusInfo["rawValue"] = authStatus.rawValue
    statusInfo["timestamp"] = Date().timeIntervalSince1970
    statusInfo["deviceModel"] = UIDevice.current.model
    statusInfo["systemVersion"] = UIDevice.current.systemVersion
    
    print("🎥 [Swift] Detailed camera status: \(statusInfo)")
    print("🎥 [Swift] About to return result with type: \(type(of: statusInfo))")
    print("🎥 [Swift] Result keys: \(statusInfo.keys)")
    result(statusInfo)
  }
  
  // MARK: - Native Location Permission Methods
  
  private func requestLocationPermissionNative(result: @escaping FlutterResult) {
    print("📍 [Swift] Requesting location permission natively...")
    
    if locationManager == nil {
      locationManager = CLLocationManager()
      locationManager?.delegate = self
    }
    
    let authStatus = locationManager?.authorizationStatus ?? .notDetermined
    print("📍 [Swift] Current location authorization status: \(authStatus.rawValue)")
    
    switch authStatus {
    case .authorizedWhenInUse, .authorizedAlways:
      print("📍 [Swift] Location permission already granted")
      result(true)
    case .notDetermined:
      print("📍 [Swift] Location permission not determined, requesting...")
      locationPermissionResult = result
      locationManager?.requestWhenInUseAuthorization()
    case .denied:
      print("📍 [Swift] Location permission denied, forcing request...")
      locationPermissionResult = result
      locationManager?.requestWhenInUseAuthorization()
    case .restricted:
      print("📍 [Swift] Location permission restricted by device policy")
      result(false)
    @unknown default:
      print("📍 [Swift] Unknown location permission status")
      result(false)
    }
  }
  
  private func getLocationPermissionStatus(result: @escaping FlutterResult) {
    print("📍 [Swift] getLocationPermissionStatus method called")
    
    if locationManager == nil {
      locationManager = CLLocationManager()
    }
    
    let authStatus = locationManager?.authorizationStatus ?? .notDetermined
    let locationServicesEnabled = CLLocationManager.locationServicesEnabled()
    
    print("📍 [Swift] Location permission status check: \(authStatus.rawValue)")
    print("📍 [Swift] Location services enabled: \(locationServicesEnabled)")
    print("📍 [Swift] Auth status enum: \(authStatus)")
    
    // Create detailed status info
    var statusInfo: [String: Any] = [:]
    
    switch authStatus {
    case .authorizedWhenInUse:
      statusInfo["status"] = "authorizedWhenInUse"
      statusInfo["canUseLocation"] = true
      statusInfo["canRequest"] = false
      statusInfo["needsSettings"] = false
      statusInfo["description"] = "Location access granted when app is in use"
      statusInfo["authorizationType"] = "whenInUse"
    case .authorizedAlways:
      statusInfo["status"] = "authorizedAlways"
      statusInfo["canUseLocation"] = true
      statusInfo["canRequest"] = false
      statusInfo["needsSettings"] = false
      statusInfo["description"] = "Location access granted always"
      statusInfo["authorizationType"] = "always"
    case .notDetermined:
      statusInfo["status"] = "notDetermined"
      statusInfo["canUseLocation"] = false
      statusInfo["canRequest"] = true
      statusInfo["needsSettings"] = false
      statusInfo["description"] = "User hasn't been asked for location permission yet"
      statusInfo["authorizationType"] = nil
    case .denied:
      statusInfo["status"] = "denied"
      statusInfo["canUseLocation"] = false
      statusInfo["canRequest"] = true // iOS allows re-requesting even if denied
      statusInfo["needsSettings"] = true
      statusInfo["description"] = "User explicitly denied location access"
      statusInfo["authorizationType"] = nil
    case .restricted:
      statusInfo["status"] = "restricted"
      statusInfo["canUseLocation"] = false
      statusInfo["canRequest"] = false
      statusInfo["needsSettings"] = false
      statusInfo["description"] = "Location access restricted by device policy or parental controls"
      statusInfo["authorizationType"] = nil
    @unknown default:
      statusInfo["status"] = "unknown"
      statusInfo["canUseLocation"] = false
      statusInfo["canRequest"] = false
      statusInfo["needsSettings"] = false
      statusInfo["description"] = "Unknown location permission status"
      statusInfo["authorizationType"] = nil
    }
    
    // Add additional system info
    statusInfo["rawValue"] = authStatus.rawValue
    statusInfo["timestamp"] = Date().timeIntervalSince1970
    statusInfo["deviceModel"] = UIDevice.current.model
    statusInfo["systemVersion"] = UIDevice.current.systemVersion
    statusInfo["locationServicesEnabled"] = locationServicesEnabled
    
    print("📍 [Swift] Detailed location status: \(statusInfo)")
    print("📍 [Swift] About to return result with type: \(type(of: statusInfo))")
    print("📍 [Swift] Result keys: \(statusInfo.keys)")
    result(statusInfo)
  }
  
  // MARK: - CLLocationManagerDelegate
  
  public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    print("📍 [Swift] Location authorization changed: \(status.rawValue)")
    
    if let result = locationPermissionResult {
      switch status {
      case .authorizedWhenInUse, .authorizedAlways:
        print("📍 [Swift] Location permission granted")
        result(true)
      case .denied, .restricted:
        print("📍 [Swift] Location permission denied or restricted")
        result(false)
      case .notDetermined:
        // Still waiting for user response
        break
      @unknown default:
        result(false)
      }
      locationPermissionResult = nil
    }
  }
}
