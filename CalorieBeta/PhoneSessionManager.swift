//
//  PhoneSessionManager.swift
//  MyFitPlate
//
//  Created by Omar Sabeha on 6/21/25.
//

import Foundation
import WatchConnectivity

class PhoneSessionManager: NSObject, WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        if let error = error {
            print("❌ Watch session activation failed: \(error.localizedDescription)")
        } else {
            print("✅ Watch session activated with state: \(activationState.rawValue)")
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        print("🔄 Watch session became inactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        print("🔄 Watch session deactivated")

        // On watchOS, you must re-activate the session after deactivation
        WCSession.default.activate()
    }

    
    static let shared = PhoneSessionManager()
    
    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    func sendDataToWatch(_ data: [String: Any]) {
        if WCSession.default.isReachable {
            print("Sending data to Watch: \(data)")
            WCSession.default.sendMessage(data, replyHandler: nil, errorHandler: { error in
                print("Error sending message to watch: \(error)")
            })
        } else {
            print("Watch is not reachable")
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("Recieved message from watch: \(message)")
    }
    
    func pingWatch() {
        let data = ["ping": "Hello from iphone"]
        sendDataToWatch(data)
    }
}
