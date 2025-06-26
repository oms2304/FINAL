import Foundation
import WatchConnectivity

class PhoneSessionManager: NSObject, WCSessionDelegate {
    
    static let shared = PhoneSessionManager()
    
    private override init() {
        super.init()
        activateSession()
    }
    
    private func activateSession() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    func sendInfoToWatch(userInfo: [String: Any]) {
        WCSession.default.transferUserInfo(userInfo)
    }
    
    // ✅ Required delegate methods:
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
            print("📲 Phone WCSession activated: \(activationState.rawValue)")
            if let error = error {
                print("⚠️ WCSession activation error: \(error.localizedDescription)")
            }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        print("ℹ️ Session became inactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        print("ℹ️ Session deactivated")
        WCSession.default.activate() // reactivate if needed
    }
}


