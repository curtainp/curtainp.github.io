+++
title = "Flare2-challenge-04"
author = ["curtainp"]
date = 2023-12-12T20:41:34+08:00
lastmod = 2023-12-12T20:41:34+08:00
draft = false

[taxonomies]
tags = ["FireEye", "Rev", "CTF"]
categories = ["Writeups"]

[extra]
toc = true
comment = true
+++

## 文件信息 {#文件信息}

解压之后使用 [DIE](https://github.com/horsicq/Detect-It-Easy) 查看文件信息：
{{ figure(src="./die.png") }}

可以看到有明显的[ UPX](https://upx.github.io/) 特征码，首先尝试使用其自带的脱壳功能：
{{ figure(src="./upx.png") }}

## 程序分析 {#程序分析}

脱壳之后即是正常的 PE 程序，在虚拟机中运行可以看到与加壳版输出不一致：
{{ figure(src="./upx2.png") }}

由于 **UPX** 本身自带的 stub 是不会修改原始程序逻辑的，此处可以猜测此程序有修改过脱壳的 stub. 使用 **IDA** 打开 unpack 版分析输出的 `2 + 2 = 5` 相关引用：
{{ figure(src="./ida.png") }}

唯一引用，可以看到 `5` 是硬编码到程序中的：
{{ figure(src="./ida_hard.png") }}

### 修改的 stub 分析 {#修改的-stub-分析}

下面要找到 `packed` 版本中对此地址的操作，使用动态调试 **x32dbg** 加载 `packed` 版本，对字符串 `5` 地址处下硬件访问断点，运行程序，跳过两次无关的地址即可看到：
{{ figure(src="./dbg.png") }}

此处修改下面紧接着就是 `OEP` 跳转，也验证了确实是在 stub 中修改了原始程序。注意到上面还有一个循环，将内存偏移 `0x51BB` 处的字符串的前 `52` 个字符异或 `0x20`.
此修改的 stub 对原始程序做了如下修改：

<div class="table-caption">
  <span class="table-number">Table 1:</span>
  modify stub logic
</div>

| offset     | initial value                                                      | stub packed value                                                  |
| ---------- | ------------------------------------------------------------------ | ------------------------------------------------------------------ |
| 0x004051B8 | 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/' | 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789+/' |
| 0x0040524C | 5                                                                  | 4                                                                  |

了解了 stub 对程序的修改，接下来对原始程序的后续逻辑分析：
{{ figure(src="./ida_logic.png") }}

标记 1 处在 `packed` 后即总为真。标记 2 处程序判断 `命令行参数` 必须提供一个，否则进入退出逻辑；标记 3 处对此参数调用 `atoi` 并作为 `sub_4012E0` 的参数。

### sub_4012E0 逻辑（get_crypt_hash) {#sub-4012e0-逻辑-get-crypt-hash}

{{ figure(src="./ida_logic2.png") }}

## Solution {#solution}

得到 `md5(argv[1])` 之后，查找此地址的引用，即可看到如下逻辑：
{{ figure(src="./ida_logic3.png") }}

根据动态调试的结果，此逻辑会 **比较 md5(argv[1]) 与 md5(index_of_current_hour)** ，不相等则进入退出逻辑（相等的分支再没有提前跳出的判断逻辑），传入当前系统时间作为程序参数，即可得到 flag:
{{ figure(src="./ida_logic4.png") }}
