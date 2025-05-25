import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterStreamHandler {
  private var initialUrl: URL?
  private var eventSink: FlutterEventSink?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Register the Flutter plugins (including share_intent_service)
    GeneratedPluginRegistrant.register(with: self)

    // Capture cold-start URL if the app was launched via “Open with” or a URL scheme
    if let url = launchOptions?[.url] as? URL {
      initialUrl = url
    }

    // Set up the MethodChannel and EventChannel
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // Method channel for initial share
    let methodChannel = FlutterMethodChannel(
      name: "com.madlabz.bepbuddy/share_intent",
      binaryMessenger: controller.binaryMessenger
    )
    methodChannel.setMethodCallHandler { [weak self] call, result in
      if call.method == "getInitialShare" {
        // Return the cold-start file path, if any
        result(self?.initialUrl?.path)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    // Event channel for runtime shares
    let eventChannel = FlutterEventChannel(
      name: "com.madlabz.bepbuddy/share_intent_events",
      binaryMessenger: controller.binaryMessenger
    )
    eventChannel.setStreamHandler(self)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Handle files opened while the app is already running
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    if let sink = eventSink {
      // send it straight away
      sink(url.path)
    } else {
      // hold onto it if the event stream isn’t listening yet
      initialUrl = url
    }
    return super.application(app, open: url, options: options)
  }

  // MARK: - FlutterStreamHandler

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    // if we have a pending initial URL, send it
    if let url = initialUrl {
      events(url.path)
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }
}