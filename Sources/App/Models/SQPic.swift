
import Foundation
import Vapor

struct SQPic: Model {
    var exists: Bool = false
    var id: Node?
    let pic: String
    
    init(pic: String) {
        self.id = nil
        self.pic = pic
    }
    
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        pic = try node.extract("pic")
    }
    
    // Node Represen table
    func makeNode(context: Context) throws -> Node {
        return try Node(node: ["id": id,
                               "pic": pic
            ])
    }
    
    // Preparation
    static func prepare(_ database: Database) throws {
        try database.create("SQPics") { rctokens in
            rctokens.id()
            rctokens.string("pic")
            
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete("SQPics")
    }
}
