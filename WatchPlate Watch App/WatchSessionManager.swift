//
//  WatchSessionManager.swift
//  WatchPlate Watch App
//
//  Created by Omar Sabeha on 6/21/25.
//

import Foundation
import WatchConnectivity
import SwiftUI
import Combine

class WatchSessionManager: NSObject, WCSessionDelegate, ObservableObject {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        if let error = error {
            print("❌ Watch session activation failed: \(error.localizedDescription)")
        } else {
            print("✅ Watch session activated with state: \(activationState.rawValue)")
        }
    }
    
    static let shared = WatchSessionManager()

    @Published var receivedData: [String: Any] = [:]

    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            self.receivedData = message
            print("⌚️ Received data on watch: \(message)")
        }
    }
}
