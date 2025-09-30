import Foundation
import SwiftData

@Model
final class Service {
    var name: String
    var port: Int
    var customHost: String?
    var customUseHTTPS: Bool?
    var symbolName: String?
    var category: String?
    var createdAt: Date

    init(name: String, port: Int, createdAt: Date = .now) {
        self.name = name
        self.port = port
        self.createdAt = createdAt
    }
}
