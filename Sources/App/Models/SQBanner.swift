import Foundation
import Vapor

struct SQBanner: Model {
    var exists: Bool = false
    var id: Node?
    
    var imgurl: String  // 图片地址
    let neturl: String  // 跳转网页地址
    let btype: Int      // banner类型： 1.网页。 2.跳与该用户聊天
    let squserid: String// btype 为 2 时，该字段有值，
    let bannertext: String
    
    init(imgurl: String, neturl: String, btype: Int, squserid: String, bannertext: String) {
        self.id = nil
        self.imgurl = imgurl
        self.neturl = neturl
        self.btype = btype
        self.squserid = squserid
        self.bannertext = bannertext
    }
    
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        imgurl = try node.extract("imgurl")
        neturl = try node.extract("neturl")
        btype = try node.extract("btype")
        squserid = try node.extract("squserid")
        bannertext = try node.extract("bannertext")
    }
    
    // Node Represen table
    func makeNode(context: Context) throws -> Node {
        return try Node(node: ["id": id,
                               "imgurl": imgurl,
                               "neturl": neturl,
                               "btype": btype,
                               "squserid": squserid,
                               "bannertext": bannertext
            ])
    }
    
    // Preparation
    static func prepare(_ database: Database) throws {
        try database.create("SQBanners") { rctokens in
            rctokens.id()
            rctokens.string("imgurl")
            rctokens.string("neturl")
            rctokens.int("btype")
            rctokens.string("squserid")
            rctokens.string("bannertext")
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete("SQBanners")
    }
}
