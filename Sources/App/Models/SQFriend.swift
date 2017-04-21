import Foundation
import Vapor

struct SQFriend: Model {
    var exists: Bool = false
    var id: Node?
    
    var username: String
    let sex: String
    var headimgurl: String
    
    let rcuserid: String
    let deviceno: String
    let way: String
    let account: String
    let pwd: String
    var aboutme:String
    var zannum: Int
    
    var photos: String
    var tags: String
    var activities: String
    
//    var sqrctoken_id: Int
    
    init(username: String,sex: String, headimgurl: String, rcuserid: String, deviceno: String, way: String, account: String, pwd: String, aboutme:String, zannum:Int ,photos:String, tags:String, activities: String) {
        self.id = nil
        self.username = username
        self.sex = sex
        self.headimgurl = headimgurl
        
        self.rcuserid = rcuserid
        self.deviceno = deviceno
        self.way = way
        self.account = account
        self.pwd = pwd
        self.aboutme = aboutme
        self.zannum = zannum;
        
        self.photos = photos;
        self.tags = tags;
        self.activities = activities;
//        self.sqrctoken_id = sqrctoken_id
    }
    
    // Node Initializable
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        username = try node.extract("username")
        sex = try node.extract("sex")
        headimgurl = try node.extract("headimgurl")
        
        rcuserid = try node.extract("rcuserid")
        deviceno = try node.extract("deviceno")
        way = try node.extract("way")
        account = try node.extract("account")
        pwd = try node.extract("pwd")
        aboutme = try node.extract("aboutme")
        zannum = try node.extract("zannum")
    
        photos = try node.extract("photos")
        tags = try node.extract("tags")
        activities = try node.extract("activities")
        
//        sqrctoken_id = try node.extract("id")
    }
    
    // Node Represen table
    func makeNode(context: Context) throws -> Node {
        return try Node(node: ["id": id,
                               "username": username,
                               "sex": sex,
                               "headimgurl": headimgurl,
                               
                               "rcuserid": rcuserid,
                               "deviceno": deviceno,
                               "way": way,
                               "account": account,
                               "pwd": pwd,
                               "aboutme":aboutme,
                               "zannum":zannum,
                            
                               "photos":photos,
                               "tags":tags,
                               "activities":activities,
//                               "sqrctoken_id":sqrctoken_id
            ])
    }
    
    // Preparation
    static func prepare(_ database: Database) throws {
        try database.create("SQFriends") { friends in
            friends.id()
            friends.string("username")
            friends.string("sex")
            friends.string("headimgurl")
            
            friends.string("rcuserid")
            friends.string("deviceno")
            friends.string("way")
            friends.string("account")
            friends.string("pwd")
            friends.string("aboutme")
            friends.int("zannum")
            
            friends.string("photos")
            friends.string("tags")
            friends.string("activities")
            
//            friends.int("sqrctoken_id")
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete("SQFriends")
    }
}

import Auth

extension SQFriend: Auth.User {
    static func authenticate(credentials: Credentials) throws -> Auth.User {
        let user: SQFriend?
        
        switch credentials {
        case let id as Identifier:
            user = try SQFriend.find(id.id)
        case let accessToken as AccessToken:
            user = try SQFriend.query().filter("access_token", accessToken.string).first()
        case let apiKey as APIKey:
            user = try SQFriend.query().filter("email", apiKey.id).filter("password", apiKey.secret).first()
        default:
            throw Abort.custom(status: .badRequest, message: "Invalid credentials.")
        }
        
        guard let u = user else {
            throw Abort.custom(status: .badRequest, message: "User not found")
        }
        return u
    }
    static func register(credentials: Credentials) throws -> Auth.User {
        throw Abort.custom(status: .badRequest, message: "Register not supported.")
    }
}

import HTTP

extension Request {
    func user() throws -> SQFriend {
        guard let user = try auth.user() as? SQFriend else {
            throw Abort.custom(status: .badRequest, message: "Invalid user type.")
        }
        return user
    }
}
