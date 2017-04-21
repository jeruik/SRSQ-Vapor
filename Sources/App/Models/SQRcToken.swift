import Foundation
import Vapor

struct SQRcToken: Model {
    var exists: Bool = false
    var id: Node?
    
    let account: String
    let token: String
    let openid: String
    var rctoken: String
    
    init(account:String,token:String, openid:String, rctoken: String) {
        self.id = nil
        
        self.account = account
        self.token = token
        self.openid = openid
        self.rctoken = rctoken
    }
    
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        account = try node.extract("account")
        token = try node.extract("token")
        rctoken = try node.extract("rctoken")
        openid = try node.extract("openid")
    }
    
    // Node Represen table
    func makeNode(context: Context) throws -> Node {
        return try Node(node: ["id": id,
                               "account": account,
                               "token": token,
                               "openid": openid,
                               "rctoken": rctoken,
            ])
    }
    
    // Preparation
    static func prepare(_ database: Database) throws {
        try database.create("SQRcTokens") { rctokens in
            rctokens.id()
            rctokens.string("account")
            rctokens.string("token")
            rctokens.string("openid")
            rctokens.string("rctoken")
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete("SQRcTokens")
    }
}
