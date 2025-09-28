import Foundation
import SwiftData

@Model
final class AppSettings {
    var host: String
    var useHTTPS: Bool

    init(host: String = "192.168.1.100", useHTTPS: Bool = false) {
        self.host = host
        self.useHTTPS = useHTTPS
    }
}
