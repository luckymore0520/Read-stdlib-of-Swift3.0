//: Playground - noun: a place where people can play

import UIKit

class StreetAddress {
    let number: String
    let street: String
    let unit: String?
    
    init(_ number: String, _ street: String, unit: String? = nil) {
        self.number = number
        self.street =  street
        self.unit = unit
    }
}


extension StreetAddress : Equatable {
    public static func ==(lhs: StreetAddress, rhs: StreetAddress) -> Bool {
        return lhs.number == rhs.number &&
        lhs.street == rhs.street &&
        lhs.unit == rhs.unit
    }
}


let addresses = [StreetAddress("1490", "Grove Street"),StreetAddress("2119", "Maple Avenue"),StreetAddress("1400", "16th Street")]
let home = StreetAddress("1400", "16th Street")

print(addresses[0] == home)
print(addresses.contains(home))

//注意，contains中实际上就是通过 == 来比较的，如果Struct 不实现 equatable 协议，上面的两个方法都会报错

let anotherHome = StreetAddress("1400", "16th Street")

print(anotherHome == home)
print(anotherHome === home)




