//
//  UInt32+Random.swift
//  HelloVapor
//
//  Created by 小菜 on 17/2/27.
//
//
import libc

extension UInt32 {
    static func random() -> UInt32 {
        let max = UInt32.max
        #if os(Linux)
            let val = UInt32(libc.random() % Int(max))
        #else
            let val = UInt32(arc4random_uniform(max))
        #endif
        return val
    }
}
