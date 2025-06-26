import WatchConnectivity
import Combine

class WatchSessionManager: NSObject, WCSessionDelegate, ObservableObject {
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
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
        activateSession()
    }

    func activateSession() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        DispatchQueue.main.async {
            self.receivedData = userInfo
            print("⌚ Watch received userInfo: \(userInfo)")
        }
    }
    
    

}
