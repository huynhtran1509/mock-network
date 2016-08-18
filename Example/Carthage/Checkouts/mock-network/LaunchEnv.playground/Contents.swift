//: Playground - noun: a place where people can play

import UIKit

func add(dict: inout [String:String]) {
    dict["c"] = "d"
}


var x: [String:String] = [:]

x["a"] = "b"

add(dict: &x)


x
