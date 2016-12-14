##Swift 3.0 标准库源码阅读笔记——String再探，从StringBuffer讲起


首先讲一讲已有的资料是怎么讲String的内存管理机制。

在 Swift Programming Language 中， 有这样一段描述：

> Swift 的String类型是值类型。 如果您创建了一个新的字符串，那么当其进行常量、变量赋值操作，或在函数/方法中传递时，会进行值拷贝。 任何情况下，都会对已有字符串值创建新副本，并对该新副本进行传递或赋值操作。 值类型在 结构体和枚举是值类型 中进行了详细描述。
> 
> Swift 默认字符串拷贝的方式保证了在函数/方法中传递的是字符串的值。 很明显无论该值来自于哪里，都是您独自拥有的。 您可以确信传递的字符串不会被修改，除非你自己去修改它。
> 
> 在实际编译时，Swift 编译器会优化字符串的使用，使实际的复制只发生在绝对必要的情况下，这意味着您将字符串作为值类型的同时可以获得极高的性能。


在 `String` 的源码注释中，有这样的解释：

> Although strings in Swift have value semantics, strings use a copy-on-write
> strategy to store their data in a buffer. This buffer can then be shared
> by different copies of a string. A string's data is only copied lazily,
> upon mutation, when more than one string instance is using the same
> buffer. Therefore, the first in any sequence of mutating operations may
> cost O(*n*) time and space.
> 
> When a string's contiguous storage fills up, a new buffer must be allocated
> and data must be moved to the new storage. String buffers use an
> exponential growth strategy that makes appending to a string a constant
> time operation when averaged over many append operations.


首先 String 是一个结构体，不再是一个对象，所以在函数/方法传递中，直接进行值拷贝。然而在 `Swift Programming Language` 中也有提到过，在实际情况下，只会在绝对必要的情况下进行复制，所以可以保证 `String` 在是结构体的情况下也保持极高的性能。

在 `String` 源码的注释中，我们可以从更深层次的角度去理解这个“优化”——“use a copy-on-write stragety to store their data in buffer"，有一个 `Buffer` 的概念，这个 Buffer 可以被多个 string 共享。

下面是一个 Demo：

```swift
var str = "Hello, playground"
print (str.characters)
//CharacterView(_core: Swift._StringCore(_baseAddress: Optional(0x00000001144388d0), _countAndFlags: 17, _owner: nil))

func printStr(_ strInFunction:String) {
    print (strInFunction.characters)
    //CharacterView(_core: Swift._StringCore(_baseAddress: Optional(0x000000010d7d48d0), _countAndFlags: 17, _owner: nil))

}
printStr(str)
let anotherStr = str + "!"
print(anotherStr.characters)
//CharacterView(_core: Swift._StringCore(_baseAddress: Optional(0x0000610000264e60), _countAndFlags: 18, _owner: Optional(Swift._HeapBufferStorage<Swift._StringBufferIVars, Swift.UInt16>)))
```

在上一篇文章中，我们有分析过 `String` 的结构，有一个 `_StringCore` 的结构体的属性，这个属性真正存储了 `String` 的数据结构，一个是 `_baseAddress` 是一个指针类型， 一个是 `_countAndFlags` 是长度，还有一个 `owner`，可以为`nil` 也可能是一个`_HeapBufferStorage` 但是具体作用位置，像上面的代码中，我们对一个 `str` 作了一个加法的产物就会有一个 `_owner`.

我们可以看到， 当对 str 进行一次值拷贝的时候，两个 str 实际上共享着同一块内存区域，即`0x00000001144388d0`。


###StringBuffer和HeapBuffer

`String` 可以由 `_StringBuffer` 来构建的，同样的，`_StringCore` 也是，我们来找找 _StringBuffer 的代码来一探究竟。

`_StringBuffer` 同样是一个结构体，并且只有一个属性 `_storage` 类型为 `_HeapBuffer<_StringBufferIVars, UTF16.CodeUnit>`

所以我们先看看 `HeapBuffer` 是什么样的结构。

`Heap` 众所周知，是`堆`，堆内存是区别于栈区、全局数据区和代码区的另一个内存区域。堆允许程序在运行时动态地申请某个大小的内存空间。最大的特点就是可以`动态分配`，`String`的`Buffer`是存储在堆上面的。

> When a string's contiguous storage fills up, a new buffer must be allocated
> and data must be moved to the new storage. String buffers use an
> exponential growth strategy that makes appending to a string a constant
> time operation when averaged over many append operations.
> 

从这段解释也可以验证，当然，似乎所有的编程语言在处理 `String` 的内存管理的时候都是使用的堆。


回过头，我们来看看 `HeapBuffer` 到底是什么个情况，打开`HeapBuffer.swift`，我们惊喜地看到了至今为止看到的第一个 `class` 即类，`Swift Standard Library` 的 `class` 是屈指可数的。

```swift
public // @testable (test/Prototypes/MutableIndexableDict.swift)
class _HeapBufferStorage<Value, Element> {
  public init() {}

  /// The type used to actually manage instances of
  /// `_HeapBufferStorage<Value, Element>`.
  typealias Buffer = _HeapBuffer<Value, Element>
  deinit {
    Buffer(self)._value.deinitialize()
  }

  final func __getInstanceSizeAndAlignMask() -> (Int, Int) {
    return Buffer(self)._allocatedSizeAndAlignMask()
  }
}
```

类和结构体、枚举最大的不同就是它是引用传递的，到了最底层果然是有一个`引用`了。

然而，对于`_HeapBufferStorage<Value, Element>`， Swift 依然使用了一个结构体`_HeapBuffer<Value,Element>`来管理，该结构体持有特定的一个 `Storage` 并且实现相关API, `Value` 为指针，`Element` 指针对应的对象类型。类似分配内存的操作也是在`_HeapBuffer`中调用对应的方法来做到的。

```swift
 internal func _allocatedSize() -> Int {
    return _swift_stdlib_malloc_size(_address)
  }

```

再往下就是更底层的东西了，目前就看到这。

在`_StringBuffer` 中， `Value` 是一个 `_StringBufferIVars` 的结构体， `Element` 是一个 `UTF16.CodeUnit`  

然后我发现看起来有点困难了，所以我决定接下来做一件工作，把 `_StringCore` -> `_StringBuffer` -> `_HeapBuffer` 中的几个关键元素一一对应上，越是底层越是难懂，那么从我们已经大致理解的`_StringCore`入手来对应底层的东西也许会有收获。


####_StringCore._baseAddress  起始地址

**对应 _StringBuffer.start**
	
```swift 
public // @testable
var start: UnsafeMutableRawPointer {
	return UnsafeMutableRawPointer(_storage.baseAddress)
}
```

首先，这是一个 `UnsafeMutableRawPointer` 对象，参数是 _storage.baseAddress，对应 _HeapBuffer.baseAddress
	
**对应 _HeapBuffer.baseAddress**

```swift
public // @testable
var baseAddress: UnsafeMutablePointer<Element> {
	return (_HeapBuffer._elementOffset() + _address).assumingMemoryBound(
  	to: Element.self)
}
```
_elementOffset() 针对特定`Element` 是一个固定的值，
_address 是其持有的对象 _storage（类型是class的_HeapBufferStorage）的指针

所以我们可以理解，这个`_baseAddress` 起始地址跟这个对象引用相关


####_StringCore.count  长度

**对应 _StringBuffer.usedCount**

```swift
 var usedCount: Int {
    return (usedEnd - start) >> elementShift
  }
```

usedEnd 是 `_StringBufferIVars` 中的一个属性 对应 `HeapBuffer`中的 `Value`，
> A past-the-end pointer for this buffer's stored data.
即末尾的后一个

start 就是起始位置，之前有提过

elementShift 也是 `Value` 中的一个属性，1代表 UTF-16，其他则是 0， 如果是 UTF-16 的话就要右移一位，一个 UTF-16 有两个字节。
> 1 if the buffer stores UTF-16; 0 otherwise.


####_StringCore.owner 

**对应 _StringBuffer.storage**，即 HeapBuffer 本身。


##从owner来看不同情况下String的创建方式 以及 String的加法

- 字面量：owner:nil
- 加法、append、插值： owner都不为nil

通过实验可以发现，只有在直接使用字面量来对 String 进行创建的时候，对应String的`StringCore`是没有`owner`的，

而通过运算符、append、插值等方法构建出来的 String， 即使值相同，它们所对应的地址空间也是不同的，owner 也不同。

>在实际编译时，Swift 编译器会优化字符串的使用，使实际的复制只发生在绝对必要的情况下，这意味着您将字符串作为值类型的同时可以获得极高的性能。

可以猜测，同样的值共享相同的Buffer，这点是在编译时做的优化，而在实际运行时，并没有办法做到这样的优化。


我们来看一个 String 加法的具体实现。

```swift
public static func + (lhs: String, rhs: String) -> String {
	if lhs.isEmpty {
	  return rhs
	}
	var lhs = lhs
	lhs._core.append(rhs._core)
	return lhs
}
```

String 的加法实际上是对 `_StringCore` 做 `append`，因为都是结构体，所以完全不用考虑重新创建一个新的 string


```swift
  @inline(never)
  mutating func append(_ rhs: _StringCore) {
    _invariantCheck()
    let minElementWidth
    = elementWidth >= rhs.elementWidth
      ? elementWidth
      : rhs.isRepresentableAsASCII() ? 1 : 2

    let destination = _growBuffer(
      count + rhs.count, minElementWidth: minElementWidth)

    if _fastPath(rhs.hasContiguousStorage) {
      _StringCore._copyElements(
        rhs._baseAddress!, srcElementWidth: rhs.elementWidth,
        dstStart: destination, dstElementWidth:elementWidth, count: rhs.count)
    }
    else {
#if _runtime(_ObjC)
      _sanityCheck(elementWidth == 2)
      _cocoaStringReadAll(rhs.cocoaBuffer!,
        destination.assumingMemoryBound(to: UTF16.CodeUnit.self))
#else
      _sanityCheckFailure("subscript: non-native string without objc runtime")
#endif
    }
    _invariantCheck()
  }
```

_StringCore 里的代码就看的很难受了。 这里有几个关键点：

- minElementWidth 最小的元素长度，可能是 UT8-16 两位，也可能是1位（ASCII），做加法的时候显然要按照更小的那个来处理。 


```swift
  mutating func _growBuffer(
    _ newSize: Int, minElementWidth: Int
  ) -> UnsafeMutableRawPointer {
    let (newCapacity, existingStorage)
      = _claimCapacity(newSize, minElementWidth: minElementWidth)

    if _fastPath(existingStorage != nil) {
      return existingStorage!
    }

    let oldCount = count

    _copyInPlace(
      newSize: newSize,
      newCapacity: newCapacity,
      minElementWidth: minElementWidth)

    return _pointer(toElementAt:oldCount)
  }
```

- _growBuffer 函数，根据元素个数、元素长度获取空间，这里存在两种情况，一种是现有的 native buffer 可以找到足够的空间存放需要添加的 String， 直接分配返回， 另一种是需要开辟新的空间，会把原先的空间翻倍。growBuffer 返回的是可以用来存放需要添加的 String 的初始地址

- _StringCore._copyElements 这是一个静态方法，从实现上来看，直接对内存操作，把 rhs 直接拷贝到目标位置上。



总的来说，就是

- 1.统一元素长度
- 2.获取空间
- 3.拷贝



```

var str = "Hello, playground"

print(str.characters)
//CharacterView(_core: Swift._StringCore(_baseAddress: Optional(0x0000000112e55960), _countAndFlags: 17, _owner: nil))

str += String()
print(str.characters)

let savedStr = str;

//CharacterView(_core: Swift._StringCore(_baseAddress: Optional(0x0000610000073520), _countAndFlags: 17, _owner: Optional(Swift._HeapBufferStorage<Swift._StringBufferIVars, Swift.UInt16>)))

str += "!"
print(str.characters)
//CharacterView(_core: Swift._StringCore(_baseAddress: Optional(0x0000610000073520), _countAndFlags: 18, _owner: Optional(Swift._HeapBufferStorage<Swift._StringBufferIVars, Swift.UInt16>)))
print(savedStr.characters)
//CharacterView(_core: Swift._StringCore(_baseAddress: Optional(0x0000610000073520), _countAndFlags: 17, _owner: Optional(Swift._HeapBufferStorage<Swift._StringBufferIVars, Swift.UInt16>)))

```

再来看上面这段代码的输出：
第一个是字面常量，地址是`0x0000000112e55960 `
对str 做 += 操作，对象是一个空的 String， 地址是 `0x0000610000073520`，并且有了 owner

并且这两个的地址是不同的，一个是编译时就确定的，一个是要在运行时才能确定。
我的猜测是在编译时 Swift 的优化机制会统一处理 字面量的 String。 到了运行时，便会另外开辟空间去处理，另外一方面，前者没有 HeapBuffer 而后者有，我甚至可以猜测，两者的存储方式可能都有所差别。然而我并没有找到相关的文献来证明这个观点。


再次对它做 += 操作，对象是一个非空 String, 地址依然是 0x0000610000073520，只是长度变成了18
这也验证了上述代码，对_StringCore做 append 操作，直接对内存进行操作，并没有改变它的起始地址。

再者，在对 str 做第二次 += 操作前，我们声明了另外一个 savedStr 并且将 str 拷贝给它， 最后输出发现他们依然共享同一个起始地址，只是长度不同，所以他们依然共享了 StringBuffer。

##总结
其实从一开始就发现的一个疑问，为什么通过字面常量初始化的 `String` 没有 owner 而其他方式初始化的都有，通过阅读代码并没有得到一个确切的解释。依然只能够通过两者最明显的区别来猜测：编译时 VS 运行时。

在编译时，Swift 会针对 String 的字面量做优化，相同的字面量共享 Buffer。
在运行时，每个 StringCore 会有一个 Native Buffer，对 String 做修改实际上是修改 _StringCore， 处理过程中 _StringCore 依然会优先复用本身的 Buffer 并且使用最高效率的方式进行拷贝。


另外，本文还主要介绍了 StringBuffer 的具体结构和原理， 以及与 _StringCore 的对应关系，而实际上，_StringBuffer 可以用来构造一个完整的 `String`， 更多情况下，它是一个更底层的 `String` 的存储模型，并且是可以被部分共享的。
