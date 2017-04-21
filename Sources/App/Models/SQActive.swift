import Foundation
import Vapor

struct SQActive: Model {
    var exists: Bool = false
    var id: Node?
    
    let username: String      // 昵称
    let sex: String           // 性别
    let headimgurl: String    // 头像
    let account: String       // 发送人账号
    let actcontent: String    // 动态内容 限制250字
    var zancount: Int         // 点赞数
    let commoncount: Int      // 评论数
    let photostr: String      // 配图，字符串，用，号切割成数组
    let sqlocal: String       // 位置
    let acttime: String       // 动态发送时间
    let rcuserid: String
    let width: Double
    let height: Double
    
    init(username: String, sex: String, headimgurl: String, account: String, actcontent: String, photostr: String, zancount: Int, commoncount: Int, sqlocal: String, acttime: String,rcuserid: String, width: Double, height: Double) {
        self.id = nil
        
        self.username = username
        self.sex = sex
        self.headimgurl = headimgurl
        
        self.account = account
        self.actcontent = actcontent
        self.zancount = zancount
        self.commoncount = commoncount
        self.photostr = photostr
        self.sqlocal = sqlocal
        self.acttime = acttime
        
        self.rcuserid = rcuserid
        
        self.width = width;
        self.height = height;
    }
    
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        
        username = try node.extract("username")
        sex = try node.extract("sex")
        headimgurl = try node.extract("headimgurl")
        
        account = try node.extract("account")
        actcontent = try node.extract("actcontent")
        zancount = try node.extract("zancount")
        commoncount = try node.extract("commoncount")
        photostr = try node.extract("photostr")
        sqlocal = try node.extract("sqlocal")
        acttime = try node.extract("acttime")
        rcuserid = try node.extract("rcuserid")
        
        width = try node.extract("width")
        height = try node.extract("height")
    }
    
    // Node Represen table
    func makeNode(context: Context) throws -> Node {
        return try Node(node: ["id": id,
                               "username": username,
                               "sex": sex,
                               "headimgurl": headimgurl,
                               "account": account,
                               "actcontent": actcontent,
                               "zancount": zancount,
                               "commoncount": commoncount,
                               "photostr":photostr,
                               "sqlocal": sqlocal,
                               "acttime": acttime,
                               "rcuserid": rcuserid,
                               "width": width,
                               "height": height
            ])
    }
    
    // Preparation
    static func prepare(_ database: Database) throws {
        try database.create("SQActives") { rctokens in
            rctokens.id()
            rctokens.string("username")
            rctokens.string("sex")
            rctokens.string("headimgurl")
            
            rctokens.string("account")
            rctokens.string("actcontent")
            rctokens.int("zancount")
            rctokens.int("commoncount")
            rctokens.string("photostr")
            rctokens.string("sqlocal")
            rctokens.string("acttime")
            rctokens.string("rcuserid")
            
            rctokens.double("width")
            rctokens.double("height")
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete("SQActives")
    }
}
