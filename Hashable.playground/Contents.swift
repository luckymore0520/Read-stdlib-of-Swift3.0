//: Playground - noun: a place where people can play

import UIKit

let descriptions: [AnyHashable : Any] = [
    AnyHashable("😄") : "emoji",
    AnyHashable(42) : "an Int",
    AnyHashable(Int8(43)) : "an Int8",
    AnyHashable(Set(["a", "b"])): "a set of strings"
]

print(descriptions[AnyHashable(42)]!)

print(descriptions["😄"])
print(descriptions[AnyHashable(Set(["a", "b"]))]!)

let x = AnyHashable(Int(42))
let y = AnyHashable(UInt8(42))
print(x == y)
// Prints "false" because `Int` and `UInt8` are different types
print(x == AnyHashable(Int(42)))

x.base



class Base: Hashable {
    var value: Int = 0;
    var hashValue: Int {
        print (value.hashValue)
        return value.hashValue
    }
    
    public static func ==(lhs: Base, rhs: Base) -> Bool {
        return lhs.value == rhs.value
    }
}

class Derived1 : Base {
    
}

class Derived2 : Base, _HasCustomAnyHashableRepresentation {
    func _toCustomAnyHashable() -> AnyHashable? {
         let customRepresentation = Derived1()
        return AnyHashable(customRepresentation as Base)
    }
}

let a = AnyHashable(Derived1())
let b = AnyHashable(Derived2())
print (a == b)

