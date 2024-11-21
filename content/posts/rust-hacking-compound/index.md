+++
title = "Rust Hacking - Compound Type (Part II)"
author = ["curtainp"]
date = 2024-05-16T16:56:20+08:00
lastmod = 2024-05-16T16:56:20+08:00
draft = false

[taxonomies]
tags = ["Rust", "Hacking"]
categories = ["Programming"]

[extra]
toc = true
comment = true
+++

这次我们来看看在 Rust 中如何表示 Compound Type (内存中)，新建示例项目，并打开 `src/main.rs` 写入如下代码：

```rust,linenos
#[derive(Debug)]
struct MyStruct {
    a: i32,
    b: u64,
    c: String,
}

#[derive(Debug)]
enum MyEnum {
    First(i32),
    Second(usize),
}

impl MyStruct {
    fn new(a: i32, b: u64, c: String) -> Self {
        Self{a, b, c}
    }
}

fn main() {
   let my_struct = MyStruct::new(1, 2, String::from("hello"));
   let my_first = MyEnum::First(3);
   let my_second = MyEnum::Second(4);
   let my_tuple = (5, 6, 7);
   let my_array = [8, 9, 10];
   println!("struct: {}, {}, {}", my_struct.a, my_struct.b, my_struct.c);
   println!("tuple: {my_tuple:?}");
   println!("array: {my_array:?}");
   if let MyEnum::First(a) = my_first {
       println!("enum: {a}");
   }
   if let MyEnum::Second(b) = my_second {
       println!("enum: {b}");
   }
}
```

## Analysis {#analysis}

Rust 编译器会根据 Size 和 Alignment 调整结构中各个字段在内存中布局，详情可参考 <https://doc.rust-lang.org/reference/type-layout.html>.

### Struct {#struct}

`GDB` 加载编译的二进制，根据上次分析的入口，我们下断点到 `compound_type::main` 上， `run` 起程序即可断到程序入口，查看 `main` 的反汇编结果，可得出如下分析图：

{{ figure(src="./ida.png") }}

可以看到，Rust 编译器 `默认` 情况下并未按照结构体定义的顺序放置各个字段（此处的顺序是 c, b, a)

### Tuple &amp;&amp; Array {#tuple-and-and-array}

紧挨着 Struct 的初始化就是 Tuple 和 Array, 在初始化时并未明确指明具体类型，此处编译器默认两者类型都是 `i32`, 汇编中可得出这一推断：

{{ figure(src="./ida2.png") }}

### Enum {#enum}

继续往下，即是 `Enum` 的初始化，具体参考 [Enum Memory Layout](https://rust-lang.github.io/unsafe-code-guidelines/layout/enums.html#layout-of-a-data-carrying-enums-without-a-repr-annotation)

{{ figure(src="./ida3.png") }}

## 总结 {#总结}

- Compound Type 基于 Scalar Type 组合起来，其基本内存布局符合预期
- 需要注意的是： **在未明确要求的情况下（without annotation)，编译器不保证各个成员的布局与定义一致，所以在需要明确的布局时，务必使用 `[repr()]` 类注解**
