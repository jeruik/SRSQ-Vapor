//
//  SQPerson.swift
//  HelloVapor
//
//  Created by 小菜 on 17/3/10.
//
//


import Foundation
import Vapor

// 人物模型，一个人可以拥有多个宠物
struct SQPerson: Model {
    var exists: Bool = false
    var id: Node?
    let name: String
    
    init(name: String) {
        self.id = nil
        self.name = name
    }
    
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        name = try node.extract("name")
    }
    
    // Node Represen table
    func makeNode(context: Context) throws -> Node {
        return try Node(node: ["id": id,
                               "name": name
            ])
    }
    
    // Preparation
    static func prepare(_ database: Database) throws {
        try database.create("SQPersons") { rctokens in
            rctokens.id()
            rctokens.string("name")
            
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete("SQPersons")
    }
}
