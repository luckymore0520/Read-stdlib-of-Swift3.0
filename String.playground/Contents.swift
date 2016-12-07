//: Playground - noun: a place where people can play

import UIKit

//创建
//string literals 直接字符串创建
let greeting = "Hello"

//string interpolation 插值构建

//用一个反斜杠`\`加括号 变量来插到 String中，相比原来 NSString的 stringWithFormat 更加方便
var name = "Rosa"
let personalizedGreeting = "Welcome, \(name)!"




//修改
var otherGreeting = greeting
otherGreeting += " Have a nice time!"
print(otherGreeting)
print(greeting)
// Prints "Welcome!"  原来的不受影响



//比较 
let cafe1 = "Cafe\u{301}"
let cafe2 = "Café"
print(cafe1 == cafe2)
// Prints "true"  最后的值为 true



//视图


// characterView
// characters 是一个用户可读的视图
// 类似"é"这样的字符实际上是由多个 unicode 组成的，但是在characterView里是单一的一个字符
let cafe = "Cafe\u{301} du 🌍"
cafe.characters
//string.characters 返回的是一个 CharacterView 不是一个 Array
print(cafe.characters.count)
// Prints "9" 注意，
print(Array(cafe.characters))
// Prints "["C", "a", "f", "é", " ", "d", "u", " ", "🌍"]"


//Unicode Scalar View
//Unicode Scalar View 表示 String 的 Unicode 标量的集合，（32位

print (cafe.unicodeScalars.count)
print (Array(cafe.unicodeScalars))
print(cafe.unicodeScalars.map { $0.value })
// Prints "[67, 97, 102, 101, 769, 32, 100, 117, 32, 127757]"

//同 characterView 不同， Unicode Scalar View 中 é 为两个 uinicode 字符
print(cafe.utf16.count)
// Prints "11"
print(Array(cafe.utf16))
// Prints "[67, 97, 102, 101, 769, 32, 100, 117, 32, 55356, 57101]"





//UTF-16 View
print(Array("🌍".utf16))
//[55356, 57101]
print(Array("🌍".unicodeScalars))
//["\u{0001F30D}"]

let nscafe = cafe as NSString
print (nscafe.length)
// Prints 11
print(nscafe.character(at: 10))
// Print  57101




//UTF-8 View
print(cafe.utf8.count)
//Prints "14"
print(Array(cafe.utf8))
//240, 159, 140, 141]"

let cLength = strlen(cafe)
print(cLength)
//Prints "14"


let index = cafe.characters.index(cafe.startIndex, offsetBy: 8)
print(cafe[index])

name = "Marie Curie"
let firstSpace = name.characters.index(of: " ")!
let firstName = String(name.characters.prefix(upTo: firstSpace))
print(firstName)
//Prints "Marie"


let firstSpaceUTF8 = firstSpace.samePosition(in: name.utf8)
print(Array(name.utf8.prefix(upTo: firstSpaceUTF8)))
//Prints "[77, 97, 114, 105, 101]"

var s: String? = "Foo"
print(s?.characters)
var t: String? = "Foo"
print(t?.characters)
t = t! + " Hello"
print(t?.characters)
//Optional(Swift.String.CharacterView(_core: Swift._StringCore(_baseAddress: Optional(0x00006180000595b0), _countAndFlags: 9, _owner: Optional(Swift._HeapBufferStorage<Swift._StringBufferIVars, Swift.UInt16>))))
print(s?.characters)
//Optional(Swift.String.CharacterView(_core: Swift._StringCore(_baseAddress: Optional(0x00000001103ab0cc), _countAndFlags: 3, _owner: nil)))



