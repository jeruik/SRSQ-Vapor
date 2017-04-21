import Vapor
import VaporPostgreSQL
import HTTP
import Auth
import TurnstileCrypto
import Foundation

// MARK: - 0.初始化

let drop = Droplet()
let auth = AuthMiddleware(user:SQFriend.self)
drop.middleware.append(auth)
do {
    try drop.addProvider(VaporPostgreSQL.Provider.self)
} catch {
    print("Error adding provider: \(error)")
}
drop.preparations = [SQFriend.self,SQRcToken.self,SQAllUser.self,SQProfile.self,SQActive.self,SQBanner.self,SQPic.self,SQPerson.self,SQAnimal.self]

drop.get { req in
    return try drop.view.make("welcome", [
        "message": drop.localization[req.lang, "welcome", "title"] ])
}

// MARK: - 1.朋友 第三方登陆 API
drop.group("friends") { friends in

    // MARK: - 1.1 如果该用户已经登陆过，可以从cookie中获取用户信息
    let protect = ProtectMiddleware(error:
        Abort.custom(status: .forbidden, message: "Not authorized.")
    )
    friends.group(protect) { secure in
        secure.get("secure") { req in
            
            let haveFriend = try req.user()
            let rc = try SQRcToken.query().filter("account",haveFriend.account).first()
            return try JSON(node: [
                "result" : "0",
                "token":rc!.token,
                "rctoken":rc!.rctoken,
                "data": haveFriend.makeJSON()
                ])
        }
    }
    
    friends.post("friendLogin") { req in
        
        guard let openid = req.data["openid"]?.string else {
            throw Abort.badRequest
        }
        let rc = try SQRcToken.query().filter("openid",openid).first()
        if rc != nil { // 用户直接登陆
            let haveFriend = try SQFriend.query().filter("account",rc!.account).first()
//            let creds = Identifier(id: (haveFriend?.id)!) // 缓存用户登录信息，下次直接从cookie获取
//            try req.auth.login(creds)
            
            return try JSON(node: [
                "result" : "0",
                "token":rc!.token,
                "rctoken":rc!.rctoken,
                "data": haveFriend!.makeJSON()
                ])
        } else {
            // 用户不存在，创建用户
            return try JSON(node: [
                "result" : "4040",
                ])
        }
    }
    // 保存融云token 接口
    friends.post("rctoken") { req in
        guard let username = req.data["username"]?.string else {
            throw Abort.badRequest
        }
        guard let sex = req.data["sex"]?.string else {
            throw Abort.badRequest
        }
        guard let headimgurl = req.data["headimgurl"]?.string else {
            throw Abort.badRequest
        }
        guard let openid = req.data["openid"]?.string else {
            throw Abort.badRequest
        }
        guard let deviceno = req.data["deviceno"]?.string else {
            throw Abort.badRequest
        }
        guard let way = req.data["way"]?.string else {
            throw Abort.badRequest
        }
        guard let rctoken = req.data["rctoken"]?.string else {
            throw Abort.badRequest
        }
        guard let rcuserid = req.data["rcuserid"]?.string else {
            throw Abort.badRequest
        }

        // ===================================  条件限制 =================================== //
        let haveRc = try SQRcToken.query().filter("openid",openid).first()
        if haveRc != nil { // 已经存在
            return try JSON(node: [
                "result" : "4000",
                ])
        }
        let allF = try SQFriend.query().filter("deviceno",deviceno).all()
        if allF.count >= 10 {
            return try JSON(node: [
                "result" : "4000",
                ])
        }
        // ===================================  条件限制 =================================== //
        
        // 生成账号
        var acc_date = Date().timeIntervalSince1970*100
        let acc_tempTimeStr = String(format: "%.f", acc_date)
        let account_RandStr = URandom().secureToken
        let account = way + acc_tempTimeStr + account_RandStr
        
        // 生成token
        var date = Date().timeIntervalSince1970*100
        let tempTimeStr = String(format: "%.f", date)
        let randStr = URandom().secureToken
        let token = tempTimeStr + randStr
        
        var friend = SQFriend(username: username,sex:sex, headimgurl: headimgurl,rcuserid:rcuserid, deviceno: deviceno, way: way, account: account, pwd:"", aboutme:"", zannum:0, photos:"",tags:"", activities:"")
        try friend.save()
        
        var rc = SQRcToken(account:account, token:token, openid:openid, rctoken: rctoken)
        try rc.save()
        
        return try JSON(node: [
            "result" : "0",
            "token":rc.token,
            "rctoken":rc.rctoken,
            "data": friend.makeJSON()
            ])
    }
    // 所有用户赞 接口
    friends.post("zan") { req in
        guard let rcuserid = req.data["rcuserid"]?.string else {
            throw Abort.badRequest
        }
        var friend = try SQFriend.query().filter("rcuserid", rcuserid).first()
        friend?.zannum += 1
        try friend?.save()
        return try JSON(node: [
            "result" : "0",
            ])
    }
}
// MARK: - 2.个人资料
drop.group("user") { user in

    // 查询个人中心资料
    user.post("profile") { req in
        guard let account = req.data["account"]?.string else {
            throw Abort.badRequest
        }
        var friend = try SQFriend.query().filter("account", account).first()
        if friend != nil {
            return try JSON(node: [
                "result" : "0",
                "data":JSON(node: friend!.makeJSON())
                ])
        } else {
            return try JSON(node: [
                "result" : "1",
                ])
        }
    }
    
    // 更新个人中心资料
    user.post("updateNick") { req in
        guard let account = req.data["account"]?.string else {
            throw Abort.badRequest
        }
        guard let token = req.data["token"]?.string else {
            throw Abort.badRequest
        }
        guard let username = req.data["username"]?.string else {
            throw Abort.badRequest
        }
        
        var friend = try SQFriend.query().filter("account", account).first()
        if friend != nil {
            var rcModel = try SQRcToken.query().filter("token", token).first()
            if rcModel != nil {
                if (rcModel?.token.equals(any: token))! {
                    friend?.username = username
                    try friend?.save()
                    return try JSON(node: [
                        "result" : "0",
                        ])
                } else {
                    return try JSON(node: [
                        "result" : "1",
                        ])
                }
            } else {
                return try JSON(node: [
                    "result" : "1",
                    ])
            }
        } else {
            return try JSON(node: [
                "result" : "1",
                ])
        }
    }
    
    user.post("updateAboutMe") { req in
        guard let account = req.data["account"]?.string else {
            throw Abort.badRequest
        }
        guard let token = req.data["token"]?.string else {
            throw Abort.badRequest
        }
        guard let aboutme = req.data["aboutme"]?.string else {
            throw Abort.badRequest
        }
        
        var friend = try SQFriend.query().filter("account", account).first()
        if friend != nil {
            var rcModel = try SQRcToken.query().filter("token", token).first()
            if rcModel != nil {
                if (rcModel?.token.equals(any: token))! {
                    friend?.aboutme = aboutme
                    try friend?.save()
                    return try JSON(node: [
                        "result" : "0",
                        ])
                } else {
                    return try JSON(node: [
                        "result" : "1",
                        ])
                }
            } else {
                return try JSON(node: [
                    "result" : "1",
                    ])
            }
        } else {
            return try JSON(node: [
                "result" : "1",
                ])
        }
    }
    user.post("updateTags") { req in
        guard let account = req.data["account"]?.string else {
            throw Abort.badRequest
        }
        guard let token = req.data["token"]?.string else {
            throw Abort.badRequest
        }
        guard let tags = req.data["tags"]?.string else {
            throw Abort.badRequest
        }
        
        var friend = try SQFriend.query().filter("account", account).first()
        if friend != nil {
            var rcModel = try SQRcToken.query().filter("token", token).first()
            if rcModel != nil {
                if (rcModel?.token.equals(any: token))! {
                    friend?.tags = tags
                    try friend?.save()
                    return try JSON(node: [
                        "result" : "0",
                        ])
                } else {
                    return try JSON(node: [
                        "result" : "1",
                        ])
                }
            } else {
                return try JSON(node: [
                    "result" : "1",
                    ])
            }
        } else {
            return try JSON(node: [
                "result" : "1",
                ])
        }
    }
    user.post("updatePhotos") { req in
        guard let account = req.data["account"]?.string else {
            throw Abort.badRequest
        }
        guard let token = req.data["token"]?.string else {
            throw Abort.badRequest
        }
        guard let photos = req.data["photos"]?.string else {
            throw Abort.badRequest
        }
        
        var friend = try SQFriend.query().filter("account", account).first()
        if friend != nil {
            var rcModel = try SQRcToken.query().filter("token", token).first()
            if rcModel != nil {
                if (rcModel?.token.equals(any: token))! {
                    friend?.photos = photos
                    try friend?.save()
                    return try JSON(node: [
                        "result" : "0",
                        "photos" : photos
                        ])
                } else {
                    return try JSON(node: [
                        "result" : "1",
                        ])
                }
            } else {
                return try JSON(node: [
                    "result" : "1",
                    ])
            }
        } else {
            return try JSON(node: [
                "result" : "1",
                ])
        }
    }
    user.post("updateHeaderImage") { req in
        guard let account = req.data["account"]?.string else {
            throw Abort.badRequest
        }
        guard let token = req.data["token"]?.string else {
            throw Abort.badRequest
        }
        guard let headimgurl = req.data["headimgurl"]?.string else {
            throw Abort.badRequest
        }
        var friend = try SQFriend.query().filter("account", account).first()
        if friend != nil {
            var rcModel = try SQRcToken.query().filter("token", token).first()
            if rcModel != nil {
                if (rcModel?.token.equals(any: token))! {
                    friend?.headimgurl = headimgurl
                    try friend?.save()
                    return try JSON(node: [
                        "result" : "0",
                        "headimgurl" : headimgurl
                        ])
                } else {
                    return try JSON(node: [
                        "result" : "1",
                        ])
                }
            } else {
                return try JSON(node: [
                    "result" : "1",
                    ])
            }
        } else {
            return try JSON(node: [
                "result" : "1",
                ])
        }
    }
}
// MARK: - 3.广场 API
drop.group("allUsers") { allUsers in
        allUsers.get("allFriends") { req in
            let friends = try SQFriend.all()
            let sqpic = try SQPic.all().first
            return try JSON(node: [
                "result" : "0",
                "data" : JSON(node: friends.makeJSON()),
                "pic" : sqpic?.pic,
                "color" : "FC6E5E"
                ])
        }
}

// MARK: - 4.banner API
drop.group("sqbanner") { sqbanner in
    sqbanner.get("banner") { req in
        return try JSON(node: SQBanner.all().makeJSON())
    }
    // 新增banner条
    sqbanner.post("addbanner") { req in
        guard let imgurl = req.data["imgurl"]?.string else {
            throw Abort.badRequest
        }
        guard let neturl = req.data["neturl"]?.string else {
            throw Abort.badRequest
        }
        guard let btype = req.data["btype"]?.int else {
            throw Abort.badRequest
        }
        guard let squserid = req.data["squserid"]?.string else {
            throw Abort.badRequest
        }
        guard let bannertext = req.data["bannertext"]?.string else {
            throw Abort.badRequest
        }
        
        var banner = SQBanner(imgurl: imgurl, neturl: neturl, btype: btype, squserid: squserid, bannertext: bannertext)
        try banner.save()
        return try JSON(node: [
            "result" : "0"
        ])
    }
    
    sqbanner.post("sqpic") { rep in
        guard let pic = rep.data["pic"]?.string else {
            throw Abort.badRequest
        }
        var sqpic = SQPic(pic: pic)
        try sqpic.save()
        return try JSON(node: [
            "result" : "0"
            ])
    }
}

// MARK: - 5.动态 API
drop.group("sqacitves") { sqacitves in

    sqacitves.post("act") { req in
        guard let page = req.data["page"]?.int else {
            throw Abort.badRequest
        }
        return try JSON(node: [
            "result" : "0",
            "data" : JSON(node: SQActive.all().makeJSON()),
            "haveMore":"Y"
            ])
    }
    sqacitves.post("release") { req in

        guard let username = req.data["username"]?.string else {
            throw Abort.badRequest
        }
        guard let sex = req.data["sex"]?.string else {
            throw Abort.badRequest
        }
        guard let headimgurl = req.data["headimgurl"]?.string else {
            throw Abort.badRequest
        }
        guard let account = req.data["account"]?.string else {
            throw Abort.badRequest
        }
        guard let token = req.data["token"]?.string else {
            throw Abort.badRequest
        }
        guard let actcontent = req.data["actcontent"]?.string else {
            throw Abort.badRequest
        }
        guard let zancount = req.data["zancount"]?.int else {
            throw Abort.badRequest
        }
        guard let commoncount = req.data["commoncount"]?.int else {
            throw Abort.badRequest
        }
        guard let photostr = req.data["photostr"]?.string else {
            throw Abort.badRequest
        }
        guard let sqlocal = req.data["sqlocal"]?.string else {
            throw Abort.badRequest
        }
        guard let acttime = req.data["acttime"]?.string else {
            throw Abort.badRequest
        }
        guard let rcuserid = req.data["rcuserid"]?.string else {
            throw Abort.badRequest
        }
        guard let width = req.data["width"]?.double else {
            throw Abort.badRequest
        }
        guard let height = req.data["height"]?.double else {
            throw Abort.badRequest
        }
        
        var rcToken = try SQRcToken.query().filter("account", account).first()
        if (rcToken?.token.equals(any: token))! {
            var act = SQActive(username: username, sex: sex, headimgurl: headimgurl, account: account, actcontent: actcontent, photostr: photostr, zancount: zancount, commoncount: commoncount, sqlocal: sqlocal, acttime: acttime, rcuserid: rcuserid, width: width, height: height)
            try act.save()
            
            var fri = try SQFriend.query().filter("account", account).first()
            if (fri?.activities.equals(any: ""))! {
                fri?.activities = acttime
            } else {
                fri?.activities = (fri?.activities)! + "," + acttime
            }
            try fri?.save()
            return try JSON(node: [
                "result" : "0",
                "data" : JSON(node: act.makeJSON())
                ])
        } else {
            return try JSON(node: [
                "result" : "1",
                ])
        }
    }
    sqacitves.post("zan") { req in
        guard let id = req.data["id"]?.string else {
            throw Abort.badRequest
        }
        var act = try SQActive.query().filter("id", id).first()
        act?.zancount += 1
        try act?.save()
        return try JSON(node: [
            "result" : "0",
            ])
    }
}
// MARK: - 6.Apple 专用
drop.group("apple") { apple in
    apple.post("login") { req in
        guard let account = req.data["account"]?.string else {
            throw Abort.badRequest
        }
        guard let pwd = req.data["pwd"]?.string else {
            throw Abort.badRequest
        }
        if account.equals(any: "123456789") && pwd.equals(any: "123654") {
            let haveFriend = try SQFriend.query().filter("id", 1).first()
            let rc =  try SQRcToken.query().filter("account", (haveFriend?.account)!).first()
            return try JSON(node: [
                "result" : "0",
                "token":rc!.token,
                "rctoken":rc!.rctoken,
                "data": haveFriend!.makeJSON()
                ])
        }
        let f = try SQFriend.query().filter("name",.greaterThan, 21).all()
        
        let haveFriend = try SQFriend.query().filter("pwd", "123").first()
        let rc =  try SQRcToken.query().filter("account", (haveFriend?.account)!).first()
        return try JSON(node: [
            "result" : "1"
            ])
    }
}

// MARK: - 7.网页接口
drop.get("/srsq") { request in
    let dict = request.json
    return try drop.view.make("srsq/index.html")
}
drop.get("/home") { request in
    
    let id = request.data["id"]?.int
    if id != nil {
        return try JSON(node: [
            "result" : "1",
            "data":JSON(node: SQActive.find(id!)?.makeJSON())
            ])
    }
    return try drop.view.make("home/welcome.html")
}
drop.get("shareData") { request in
    guard let id = request.data["id"]?.string else {
        throw Abort.badRequest
    }
    var act = try SQActive.find(id)
    if act != nil {
        return try JSON(node: [
            "result" : "0",
            "data":JSON(node: act?.makeJSON())
            ])
    } else {
        return try JSON(node: [
            "result" : "1",
            ])
    }
}
drop.get("profileShare") { request in
    guard let account = request.data["id"]?.string else {
        throw Abort.badRequest
    }
    var act = try SQFriend.query().filter("account", account).first();
    if act != nil {
        return try JSON(node: [
            "result" : "0",
            "data":JSON(node: act?.makeJSON())
            ])
    } else {
        return try JSON(node: [
            "result" : "1",
            ])
    }
}
drop.get("/share") { request in
    return try drop.view.make("share/index.html")
}
// MARK: - 8.1 版本更新
drop.post("version") { request in

    guard let version = request.data["version"]?.string else {
        throw Abort.badRequest
    }
    if version.equals(any: "1.5.0") {
        return try JSON(node: [
            "result": "0",
            "msg": "0"
            ])
    } else {
        return try JSON(node: [
            "result": "1",
            "msg": "发现新版:1.3.0，更新内容:\n1.优化即时聊天IM\n2.压缩安装包大小\n3.极限省流量\n4.支持上传相册\n5.无限制内容分享\n6.动态发布支持连接，点击可调转\n7.社区列表流畅度提升\n8.支持https\n9.消息推送、自定义推送\n10.安全的cookie自动登录策略"
            ])
    }
}
// MARK: - 8.2 安全策略
drop.post("cysafee") { request in
    guard let v = request.data["v"]?.string else {
        throw Abort.badRequest
    }
    guard let c = request.data["c"]?.int else {
        throw Abort.badRequest
    }
    return try JSON(node: [
        "l": "111",
        "s": "1",
        "c": "0",
        ])
}

// MARK: - 9.1 演示 API
drop.get("leaf") { request in
    return try drop.view.make("template", [
        "greeting": "Hello, world!"
        ])
}
drop.get("session") { request in
    let json = try JSON(node: [
        "session.data": "\(request.session().data["name"])",
        "request.cookies": "\(request.cookies)",
        "instructions": "Refresh to see cookie and session get set."
        ])
    var response = try Response(status: .ok, json: json)
    try request.session().data["name"] = "Vapor"
    response.cookies["test"] = "123"
    
    return response
}
drop.get("data", Int.self) { request, int in
    return try JSON(node: [
        "int": int,
        "name": request.data["name"]?.string ?? "no name"
        ])
}
drop.get("json") { request in
    return try JSON(node: [
        "number": 123,
        "string": "test",
        "array": try JSON(node: [
            0, 1, 2, 3
            ]),
        "dict": try JSON(node: [
            "name": "Vapor",
            "lang": "Swift"
            ])
        ])
}

// MARK: - 10 待调查
// 1.cookie 时长

drop.resource("posts", PostController())
drop.run()
