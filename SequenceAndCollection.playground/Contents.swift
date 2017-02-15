//: Playground - noun: a place where people can play

import UIKit


// Iterator 用法示例


struct CountDownIterator: IteratorProtocol {
    let countdown: Countdown
    var times = 0
    
    init(_ countdown: Countdown) {
        self.countdown = countdown;
    }
    
    mutating func next() -> Int? {
        let nextNumber = countdown.start - times
        guard nextNumber > 0 else {
            return nil
        }
        times += 1
        return nextNumber
    }
}


struct Countdown: Sequence {
    let start: Int
    func makeIterator() -> CountDownIterator {
        return CountDownIterator(self)
    }
}




let threeTwoOne = Countdown(start: 3)
for count in threeTwoOne {
    print("\(count)")
}






struct CollectionOfTwo<Element>: Collection {
    let elements: (Element, Element)
    init(_ first: Element, _ second: Element) {
        self.elements = (first, second)
    }
    var startIndex: Int { return 0 }
    var endIndex: Int   { return 2 }
    subscript(index: Int) -> Element {
        switch index {
            case 0: return elements.0
            case 1: return elements.1
            default: fatalError("Index out of bounds.")
        }
    }
    
    func index(after i: Int) -> Int {
        precondition(i < endIndex, "Can't advance beyond endIndex")
        return i + 1
    }
}


let collection = CollectionOfTwo("first", "second");
print(collection[0])






