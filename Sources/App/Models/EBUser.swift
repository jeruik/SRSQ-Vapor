////
////  EBUser.swift
////  HelloVapor
////
////  Created by 小菜 on 17/3/22.
////
////
//
//import Foundation
//import Vapor
//import Auth
//import HTTP
//import Fluent
//import Turnstile
//import TurnstileCrypto
//
//enum Error: Swift.Error {
//    case userNotFound
//    case registerNotSupported
//    case unsupportedCredentials
//}
//
//final class EBUser: User {
//    var id: Node?
//    var username: String
//    var nickname: String
//    var avatar: String
//    var password: String
//    var exists: Bool = false
//    
//    init(username: String, nickname: String, avatar: String, password: String) {
//        self.username = username
//        self.nickname = nickname
//        self.avatar = avatar
//        self.password = BCrypt.hash(password: password)
//    }
//    
//    init(credentials: UsernamePassword) {
//        self.username = credentials.username
//        self.password = BCrypt.hash(password: credentials.password)
//        self.nickname = ""
//        self.avatar = ""
//    }
//    
//    init(node: Node, in context: Context) throws {
//        id = try node.extract("id")
//        username = try node.extract("username")
//        nickname = try node.extract("nickname")
//        avatar = try node.extract("avatar")
//        password = try node.extract("password")
//    }
//    
//    func makeNode(context: Context) throws -> Node {
//        return try Node(node: [
//            "id": id,
//            "username": username,
//            "nickname": nickname,
//            "avatar": avatar,
//            "password": password
//            ])
//    }
//    
//    static func prepare(_ database: Database) throws {
//        try database.create("ebusers") { users in
//            users.id()
//            users.string("username")
//            users.string("nickname")
//            users.string("avatar")
//            users.string("password")
//        }
//    }
//    
//    static func revert(_ database: Database) throws {
//        try database.delete("ebusers")
//    }
//    
//    static func authenticate(credentials: Credentials) throws -> User {
//        var user: EBUser?
//        switch credentials {
//        case let credentials as UsernamePassword:
//            let fetchedUser = try EBUser.query()
//                .filter("username", credentials.username)
//                .first()
//            if let password = fetchedUser?.password,
//                password != "",
//                (try? BCrypt.verify(password: credentials.password, matchesHash: password)) == true {
//                user = fetchedUser
//            }
//            
//        default:
//            throw UnsupportedCredentialsError()
//        }
//        
//        if let user = user {
//            return user
//        } else {
//            throw IncorrectCredentialsError()
//        }
//    }
//    
//    static func register(credentials: Credentials) throws -> Auth.User {
//        var user: EBUser
//        
//        switch credentials {
//        case let credentials as UsernamePassword:
//            user = EBUser(credentials: credentials)
//        default:
//            throw UnsupportedCredentialsError()
//        }
//        if try EBUser.query().filter("username", user.username).first() == nil {
//            try user.save()
//            return user
//        } else {
//            throw AccountTakenError()
//        }
//    }  
//}
//
//drop.post("register") { request in
//    guard let username = request.data["username"]?.string,
//        let password = request.data["password"]?.string else {
//            return try drop.view.make("register", ["flash": "Missing username or password"])
//    }
//    let credentials = UsernamePassword(username: username, password: password)
//    
//    do {
//        try _ = EBUser.register(credentials: credentials)
//        try request.auth.login(credentials)
//        return Response(redirect: "/")
//    } catch let e as TurnstileError {
//        return try drop.view.make("register", Node(node: ["flash": e.description]))
//    }
//}
//
//drop.post("login") { request in
//    guard let username = request.data["username"]?.string,
//        let password = request.data["password"]?.string else {
//            return try drop.view.make("login", ["flash": "Missing username or password"])
//    }
//    let credentials = UsernamePassword(username: username, password: password)
//    do {
//        try request.auth.login(credentials)
//        return Response(redirect: "/")
//    } catch let e {
//        return try drop.view.make("login", ["flash": "Invalid username or password"])
//    }
//}
