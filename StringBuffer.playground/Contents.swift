//: Playground - noun: a place where people can play

import UIKit




var str = "Hello, playground"

print(str.characters)
//CharacterView(_core: Swift._StringCore(_baseAddress: Optional(0x0000000112e55960), _countAndFlags: 17, _owner: nil))

str += String()
let savedStr = str;

print(str.characters)

//CharacterView(_core: Swift._StringCore(_baseAddress: Optional(0x0000610000073520), _countAndFlags: 17, _owner: Optional(Swift._HeapBufferStorage<Swift._StringBufferIVars, Swift.UInt16>)))

str += "!"
print(str.characters)
print(savedStr.characters)
//CharacterView(_core: Swift._StringCore(_baseAddress: Optional(0x0000608000069820), _countAndFlags: 18, _owner: Optional(Swift._HeapBufferStorage<Swift._StringBufferIVars, Swift.UInt16>)))




//print (str.characters)
str.append("!")
//print(str)
//print (str.characters)
//CharacterView(_core: Swift._StringCore(_baseAddress: Optional(0x00000001144388d0), _countAndFlags: 17, _owner: nil))

func printStr(_ strInFunction:String) {
    print (strInFunction.characters)
    //CharacterView(_core: Swift._StringCore(_baseAddress: Optional(0x000000010d7d48d0), _countAndFlags: 17, _owner: nil))

}
//printStr(str)



let anotherStr = str + "!"
let nextStr = str + "!"
let thirdStr = str + "!"
print(anotherStr._core._owner)

//CharacterView(_core: Swift._StringCore(_baseAddress: Optional(0x0000610000264e60), _countAndFlags: 18, _owner: Optional(Swift._HeapBufferStorage<Swift._StringBufferIVars, Swift.UInt16>)))

let hello = "a\(anotherStr)"
print(hello.characters)
let anotherHello = "a\(anotherStr)"

print(anotherHello.characters)

let thirdHello = "a\(anotherStr)"
print(thirdHello.characters)

