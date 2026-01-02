import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Google Maps API Key - substitua pela sua chave em ios/Runner/AppDelegate.swift
    // Obtenha sua chave em: https://console.cloud.google.com/google/maps-apis
    GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY_HERE")

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
