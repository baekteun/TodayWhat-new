import WatchConnectivity
import Dependencies
import UserDefaultsClient

final class WatchSessionManager: NSObject, WCSessionDelegate, ObservableObject {
    @Dependency(\.userDefaultsClient) var userDefaultsClient
    var isReachable: Bool {
        session.isReachable
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        sendMessage(message: [:]) { items in
            guard
                let code = items["code"] as? String,
                let orgCode = items["orgCode"] as? String,
                let grade = items["grade"] as? Int,
                let `class` = items["class"] as? Int,
                let type = items["type"] as? String
            else {
                return
            }
            let major = items["major"] as Any
            let dict: [UserDefaultsKeys: Any] = [
                .grade: grade,
                .class: `class`,
                .schoolType: type,
                .orgCode: orgCode,
                .schoolCode: code,
                .major: major
            ]
            dict.forEach { key, value in
                self.userDefaultsClient.setValue(key, value)
            }
        }
    }
    
    static let shared = WatchSessionManager()
    private override init() {
        session = .default
        super.init()
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }

    private let session: WCSession

#if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
#endif
    func session(
        _ session: WCSession,
        didReceiveMessage message: [String : Any],
        replyHandler: @escaping ([String : Any]) -> Void
    ) {}

    func sendMessage(
        message: [String: Any],
        reply: @escaping ([String: Any]) -> Void,
        error: ((Error) -> Void)? = nil
    ) {
        guard session.activationState == .activated else {
            return
        }
        #if os(iOS)
        guard session.isWatchAppInstalled else {
            return
        }
        #endif
        print(session.isReachable)
        session.sendMessage(message, replyHandler: reply, errorHandler: error)
    }
}
