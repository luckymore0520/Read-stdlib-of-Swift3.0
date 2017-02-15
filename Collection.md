
在日常的编程中，关于集合类型的特性大部分情况下用 `Swift` 标准库提供的 `Set`、`Dictionary`以及 `Array` 完全足够了， 当然，必要时也可以自己定制自己的集合，这就意味着需要了解与之相关的协议，而理解这些协议也对于我们更好地使用已有的集合类型有莫大帮助。 而集合相关的协议无非就是 `Sequence` 与 `Collection`。


关于 `Swift` 的 `Sequence` 和 `Collection` 实际上包含了一系列的协议（当然，这两个本身就是协议），为了理解其工作原理并且正确使用，需要理清这些协议之间的关系以及各自的用途。


从用途上来说， 一个 `Collection` 必然是一个 `Sequence` ，简而言之，`Collection` 包含了 `Sequence` 所有的特性，同时又具备更加丰富的功能。

`Sequence` 的核心是 `迭代`，它可以生成一个迭代器，完成遍历，即为其核心也是唯一的功能，在`遍历`的基础上，`Swift` 为 `Sequence` 实现了诸多诸如 `map`、`filter` 这些大家用的比较多的方法的默认实现。

`Collection` 相比于 `Sequence`， 最大的特点在于`下标`，即不需要遍历也可以取到任意位置的元素（元素的位置是固定的），这就意味着 `Collection` 在可遍历的基础上增加了诸多下标相关的功能。

具体的差别将在下文通过源码来具体分析。



从实际的代码关系上来说，用一张图即可说明：

![](https://github.com/luckymore0520/Read-stdlib-of-Swift3.0/raw/master/SequenceAndCollection.png)
 
两者同作为协议， `Collection` 继承与 `Sequence`， 同时又继承了 `Indexable` 这个关于 `下标索引` 的协议，  `Sequence` 依赖于 `IteratalProtocol` 这个用于实现迭代的协议。 `Collection` 本身具有针对迭代的默认实现，依赖于 `IndexingIterator`。

具体的实现，同样会在下文配合源码进行分析。


##Sequence


###IteratorProtocol  迭代器

`IteratorProtocol` 这个协议和 `Sequence` 是紧密相连的，`Sequence` 通过创建一个迭代器来访问对应位置的元素。无论是使用 `for` 循环还是 `while` 语句，实质上都是生成了一个迭代器来进行工作。

比如：

```swift
let animals = ["Antelope", "Butterfly", "Camel", "Dolphin"]
for animal in animals {
    print(animal)
}
```

实质上做的工作是：

```swift
var animalIterator = animals.makeIterator()
while let animal = animalIterator.next() {
	print(animal)
}
```

通过 `makeIterator` 创建一个迭代器，调用迭代器的 `next()` 方法获取下一个元素，直至返回 `nil`


###使用Demo

```swift
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

```


这里 `Countdown` 作为一个 `Sequence` 需要实现一个 `makeIterator` 的方法，返回一个 实现了`IteratorProtocol`的对象，通过该对象来实现迭代。


###IteratorProtocol

`IteratorProtocol` 本身只定义了一个方法—— next()。

```swift
public protocol IteratorProtocol {
  /// The type of element traversed by the iterator.
  associatedtype Element
  mutating func next() -> Element?
}
```

`associatedtype` 关联类型， Swift 中使用这个关键字来代表泛型，这里的 `Element` 的类型是自定义的。


Demo源代码参见 [SequenceAndCollection.Playground](https://github.com/luckymore0520/Read-stdlib-of-Swift3.0/tree/master/SequenceAndCollection.playground)


###Sequence 

```swift
public protocol Sequence {
  //迭代器
  associatedtype Iterator : IteratorProtocol
  //元素的类型
  associatedtype SubSequence
  
  // 返回迭代器
  func makeIterator() -> Iterator

  // 数量
  var underestimatedCount: Int { get }
  
  // 定义了关于 Sequence 的一些方法的声明，实际上这些方法在协议扩展中都给出了高效的默认实现。
  func map<T>(
    _ transform: (Iterator.Element) throws -> T
  ) rethrows -> [T]

  func filter(
    _ isIncluded: (Iterator.Element) throws -> Bool
  ) rethrows -> [Iterator.Element]

  func dropLast(_ n: Int) -> SubSequence
  
  func drop(
    while predicate: (Iterator.Element) throws -> Bool
  ) rethrows -> SubSequence

  func prefix(_ maxLength: Int) -> SubSequence

  func prefix(
    while predicate: (Iterator.Element) throws -> Bool
  ) rethrows -> SubSequence

  func suffix(_ maxLength: Int) -> SubSequence
  
  func split(
    maxSplits: Int, omittingEmptySubsequences: Bool,
    whereSeparator isSeparator: (Iterator.Element) throws -> Bool
  ) rethrows -> [SubSequence]

  .... 
}
```

`Sequence` 的核心是 `makeIterator`，用户实际上只需要实现 `makeIterator` 方法就可以使用 `Swift` 标准库为开发者编写的所有高效的关于 `Sequence` 的方法，总而言之，只需要一个迭代器就足够了。

我们以 `map` 方法为例：

```swift
public func map<T>(
    _ transform: (Iterator.Element) throws -> T
  ) rethrows -> [T] {
    let initialCapacity = underestimatedCount
    var result = ContiguousArray<T>()
    result.reserveCapacity(initialCapacity)

    var iterator = self.makeIterator()

    // Add elements up to the initial capacity without checking for regrowth.
    for _ in 0..<initialCapacity {
      result.append(try transform(iterator.next()!))
    }
    // Add remaining elements, if any.
    while let element = iterator.next() {
      result.append(try transform(element))
    }
    return Array(result)
 }

```

这是 `Sequence` 中 `map` 方法的默认实现，代码也很容易看懂，通过创建迭代器，对元素进行遍历，对每个元素执行 `transform()` 方法，并存进 `array` 中，最后将 `array` 返回，从而实现了 `map` 方法。



##Collection

###什么是 Collection ？
首先一个 `Collection` 必定是一个 `Sequence`（ `Collection` 协议本身继承 `Sequence`)，`Collection` 的特点在于：

- 可遍历多次
- 非破坏性
- 可使用索引下标访问元素 

这些特定决定了 Swift 标准库中的 `Array` 和 `Dictionary` 实质上都是 `Collection`。

要实现一个自定义的 `Collection` 需要实现`startIndex` 和 `endIndex` 属性以及 `index(after:)` 和 `subscript(position: Index) -> _Element { get }` 下标方法。

值得注意的是，默认情况下`Collection`并不需要实现 `Sequence` 的 `makeIterator` 方法也不需要额外定义一个迭代器，因为基于`Collection` 已有的方法已经可以实现迭代器的功能，在标准库中通过协议扩展的方式以及定义了一个 `IndexingIterator` 的结构体来为 `Collection` 完成了默认的 `Sequence` 实现方案。

```swift
//这是默认情况，在Collection的定义中，Iterator就是 IndexingIterator<Self>，意味着如果使用者不自定义 Collection 的 Iterator， 会使用默认的迭代器。
extension Collection where Iterator == IndexingIterator<Self> {
  /// Returns an iterator over the elements of the collection.
  public func makeIterator() -> IndexingIterator<Self> {
    return IndexingIterator(_elements: self)
  }
}

public struct IndexingIterator<
  Elements : _IndexableBase
> : IteratorProtocol, Sequence {

  init(_elements: Elements) {
    self._elements = _elements
    self._position = _elements.startIndex
  }

  public mutating func next() -> Elements._Element? {
    if _position == _elements.endIndex { return nil }
    let element = _elements[_position]
    _elements.formIndex(after: &_position)
    return element
  }

  internal let _elements: Elements
  internal var _position: Elements.Index
}
```

###Demo

```swift
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
```

首先 `Collection` 

具体可以见 [SequenceAndCollection.Playground](https://github.com/luckymore0520/Read-stdlib-of-Swift3.0/tree/master/SequenceAndCollection.playground) 中的 Demo


我们先看看 `Collection` 协议的定义：

```swift
public protocol Collection : _Indexable, Sequence {

  associatedtype IndexDistance : SignedInteger = Int
  
  associatedtype Iterator : IteratorProtocol = IndexingIterator<Self>

  func makeIterator() -> Iterator
  
  //一些扩展方法
  associatedtype SubSequence : _IndexableBase, Sequence = Slice<Self>
  subscript(position: Index) -> Iterator.Element { get }
  subscript(bounds: Range<Index>) -> SubSequence { get }
  associatedtype Indices : _Indexable, Sequence = DefaultIndices<Self>
  var indices: Indices { get }
  func prefix(upTo end: Index) -> SubSequence
  func suffix(from start: Index) -> SubSequence
  func prefix(through position: Index) -> SubSequence
  var isEmpty: Bool { get }
  var count: IndexDistance { get }
  func _customIndexOfEquatableElement(_ element: Iterator.Element) -> Index??
  var first: Iterator.Element? { get }
  func index(_ i: Index, offsetBy n: IndexDistance) -> Index
  func index(
    _ i: Index, offsetBy n: IndexDistance, limitedBy limit: Index
  ) -> Index?
  func distance(from start: Index, to end: Index) -> IndexDistance
}
```

`Collection` 的协议本身继承了 `Sequence` 协议，意味着此前提到过的所有 `Sequence` 所具有的方法它一样具有，它多出来的协议大部分都跟其的 `索引` 的特性相关。

`Collection` 的协议还继承了 `_Indexable` 的协议，`_Indexable` 协议本身又继承了 `_IndexableBase` 协议，下面我们从下往上来看。

```swift
public protocol _IndexableBase {
  associatedtype Index : Comparable
  //这两个需要用户自己实现
  var startIndex: Index { get }
  var endIndex: Index { get }

  associatedtype _Element

  subscript(position: Index) -> _Element { get }

  associatedtype SubSequence

  subscript(bounds: Range<Index>) -> SubSequence { get }

  func _failEarlyRangeCheck(_ index: Index, bounds: Range<Index>)
  func _failEarlyRangeCheck(_ index: Index, bounds: ClosedRange<Index>)
  func _failEarlyRangeCheck(_ range: Range<Index>, bounds: Range<Index>)
  //这个方法需要用户实现	
  func index(after i: Index) -> Index
  
  func formIndex(after i: inout Index)
}
```

首先，这里的 `Index` 作为泛型必须是 `Comparable` 的，`_IndexableBase` 实质上就定义了 `可索引` 的关键成分，包括 `startIndex`，`endIndex` 以及`index(after:)` 方法， 并且定义了下标方法，包括根据下标获得单独一个元素以及根据下标范围获得一个 `SubSequence`

```swift
public protocol _Indexable : _IndexableBase {
 
  associatedtype IndexDistance : SignedInteger = Int
  func index(_ i: Index, offsetBy n: IndexDistance) -> Index
  func index(
    _ i: Index, offsetBy n: IndexDistance, limitedBy limit: Index
  ) -> Index?
  func formIndex(_ i: inout Index, offsetBy n: IndexDistance)
  func formIndex(
    _ i: inout Index, offsetBy n: IndexDistance, limitedBy limit: Index
  ) -> Bool
  func distance(from start: Index, to end: Index) -> IndexDistance
}
```

`_Indexable` 继承自 `_IndexableBase`，新增了一些关于 `Index` 的扩展方法，并且增加了一个 `IndexDistance` 的距离概念。


当然，这上面两个协议基本上不会被使用，依然推荐使用 `Collection` 协议，原因很显然，因为它具有最丰富的接口。

>> In most cases, it's best to ignore this protocol and use the `Collection`
protocol instead, because it has a more complete interface.



总的来说， `Collection` 相比于 `Sequence` 引入了下标的概念，需要使用者提供下标的开始位置和结束位置，并且提供获取下一个下标的方法，有了这三个要素，`Collection`相比于`Sequence`就可以实现更多的功能。


