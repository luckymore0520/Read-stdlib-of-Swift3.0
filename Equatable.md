#Equatable

##源码阅读
可比较的

```
public protocol Equatable {
  static func == (lhs: Self, rhs: Self) -> Bool
}
```

该协议不依赖于任何其他协议，定义了操作符 `==`，实现该协议就可以完成对象和对象之间的比较。



同时在该源文件中，还直接定义了 `!=` 的操作符

``` 
public func != <T : Equatable>(lhs: T, rhs: T) -> Bool {
  return !(lhs == rhs)
}
```

用于比较两个Equatable的对象
在该文件中定义了 `===` 的操作符，该操作符用于比较两个对象的引用是否一致，比如如果定义两个 Integer，他们的值是相同的，所以 `==` 返回为 True， 但是如果两个的引用是不同的 `===` 返回为 False， 具体见 Equatable.playground

另外需要注意的是， `===`操作符只能用于 AnyObject 即对象， 结构体、枚举是不能使用的


```
public func === (lhs: AnyObject?, rhs: AnyObject?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return Bool(Builtin.cmp_eq_RawPointer(
        Builtin.bridgeToRawPointer(Builtin.castToNativeObject(l)),
        Builtin.bridgeToRawPointer(Builtin.castToNativeObject(r))
      ))
  case (nil, nil):
    return true
  default:
    return false
  }
}
```

有 `===` 自然也有 `!==` 

```
public func !== (lhs: AnyObject?, rhs: AnyObject?) -> Bool {
  return !(lhs === rhs)
}
```