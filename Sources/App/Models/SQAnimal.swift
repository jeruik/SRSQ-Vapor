//
//  SQAnimal.swift
//  HelloVapor
//
//  Created by 小菜 on 17/3/10.
//
//


import Foundation
import Vapor

// 动物模型
struct SQAnimal: Model {
    var exists: Bool = false
    var id: Node?
    let dog: String
    let cat: String
    
    let sqperson_id: Int
    
    init(dog: String, cat: String, sqperson_id: Int) {
        self.id = nil
        self.dog = dog
        self.cat = cat
        self.sqperson_id = sqperson_id
    }
    
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        dog = try node.extract("dog")
        cat = try node.extract("cat")
        sqperson_id = try node.extract("sqperson_id")
    }
    
    // Node Represen table
    func makeNode(context: Context) throws -> Node {
        return try Node(node: ["id": id,
                               "dog": dog,
                               "cat": cat,
                               "sqperson_id": sqperson_id
            ])
    }
    
    // Preparation
    static func prepare(_ database: Database) throws {
        try database.create("SQAnimals") { rctokens in
            rctokens.id()
            rctokens.string("dog")
            rctokens.string("cat", length: 10, optional: false, unique: false, default: nil)
            rctokens.int("sqperson_id", optional: false, unique: false, default: nil)
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete("SQAnimals")
    }
    
}
