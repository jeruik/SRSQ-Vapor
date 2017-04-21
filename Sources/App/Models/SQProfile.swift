import Foundation
import Vapor

struct SQProfile: Model {
    var exists: Bool = false
    var id: Node?
    let accesstoken: String
    let rctoken: String
    
    init(accesstoken: String, rctoken: String) {
        self.id = nil
        self.accesstoken = accesstoken
        self.rctoken = rctoken
    }
    
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        accesstoken = try node.extract("accesstoken")
        rctoken = try node.extract("rctoken")
    }
    
    // Node Represen table
    func makeNode(context: Context) throws -> Node {
        return try Node(node: ["id": id,
                               "accesstoken": accesstoken,
                               "rctoken": rctoken
            ])
    }
    
    // Preparation
    static func prepare(_ database: Database) throws {
        try database.create("SQProfiles") { rctokens in
            rctokens.id()
            rctokens.string("accesstoken")
            rctokens.string("rctoken")
            
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete("SQProfiles")
    }
}
