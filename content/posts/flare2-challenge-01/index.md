+++
title = "Flare2-challenge-01"
author = ["curtainp"]
date = 2023-11-28T17:28:00+08:00
lastmod = 2023-12-01T12:02:24+08:00
draft = false

[taxonomies]
tags = ["FireEye", "Rev", "CTF"]
categories = ["Writeups"]

[extra]
toc = true
comment = true
+++

## 文件信息 {#文件信息}

下载 [flare_on_start_2015](https://www.flare-on.com/files/Flare-On_start_2015.exe) 后，首先使用[DIE](https://github.com/horsicq/Detect-It-Easy) 查看文件信息：
{{ figure(src="./die.png", alt="file info")}}

检测到该文件是[cabinet_format](https://en.wikipedia.org/wiki/Cabinet) 格式（一种压缩格式，运行时自解压）。运行之后会提示同意 EULA 并选择解压位置，解压之后再次查看文件信息：
{{ figure(src="./die2.png", alt="file info")}}

可以看到是一个 PE32 控制台程序，查看其导入表，仅导入了 `kernel32.dll` ，导入到符号如下：

1.  [LoadLibraryA](https://learn.microsoft.com/en-us/windows/win32/api/libloaderapi/nf-libloaderapi-getprocaddress)
2.  [GetProcAddress](https://learn.microsoft.com/en-us/windows/win32/api/libloaderapi/nf-libloaderapi-getprocaddress)
3.  [GetStdHandle](https://learn.microsoft.com/en-us/windows/console/getstdhandle)
4.  [WriteConsoleA](https://learn.microsoft.com/en-us/windows/console/writeconsole)
5.  [ReadFile](https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-readfile)
6.  [WriteFile](https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-writefile)

跟文件 IO 和标准流操作相关的函数，使用 **IDA Pro** 静态分析，可以看到程序逻辑非常简单，仅仅有一个 `start` 函数，主体逻辑也一目了然：
{{ figure(src="./ida.png", alt="ida info")}}

## 代码分析 {#代码分析}

函数开头调用 `GetStdHandle` 获取标准输入输出的 handle, 后续使用：

```asm
call ds:GetStdHandle
mov [ebp+std_input_handle], eax
push 0FFFFFFF5h ; std_output_handle
call ds:GetStdHandle
mov [ebp+std_output_handle], eax
```

之后通过 `ReadFile` 将用户输入保存到 `0x402158`:

```asm
push 0 ; lpOverlapped
lea eax, [ebp+NumberOfBytesWritten]
push eax ; lpNumberOfBytesRead
push 32h ; '2' ; nNumberOfBytesToRead
push offset byte_402158 ; lpBuffer
push [ebp+std_input_handle] ; hFile
call ds:ReadFile
```

下面即是核心逻辑，循环将用户输入的字符 `xor 0x7d` 并与 `expect_buffer` 比较，若不相等则跳转到 `fail_branch`:

```asm
.text:0040104B 31 C9 xor ecx, ecx ; set to 0(counter)
.text:0040104B
.text:0040104D
.text:0040104D loc_40104D:
.text:0040104D 8A 81 58 21 40 00 mov al, input_buffer[ecx]
.text:00401053 34 7D xor al, 7Dh
.text:00401055 3A 81 40 21 40 00 cmp al, expect_buffer[ecx]
.text:0040105B 75 1E jnz short fail_branch
.text:0040105B
.text:0040105D 41 inc ecx
.text:0040105E 83 F9 18 cmp ecx, 18h ; loop counter
.text:00401061 7C EA
```

`expect_buffer` 内容如下：

```asm
.data:00402140 1F expect_buffer db 1Fh ; DATA XREF: start+55↑r
.data:00402141 08 db 8
.data:00402142 13 db 13h
.data:00402143 13 db 13h
.data:00402144 04 db 4
.data:00402145 22 db 22h ; "
.data:00402146 0E db 0Eh
.data:00402147 11 db 11h
.data:00402148 4D db 4Dh ; M
.data:00402149 0D db 0Dh
.data:0040214A 18 db 18h
.data:0040214B 3D db 3Dh ; =
.data:0040214C 1B db 1Bh
.data:0040214D 11 db 11h
.data:0040214E 1C db 1Ch
.data:0040214F 0F db 0Fh
.data:00402150 18 db 18h
.data:00402151 50 db 50h ; P
.data:00402152 12 db 12h
.data:00402153 13 db 13h
.data:00402154 53 db 53h ; S
.data:00402155 1E db 1Eh
.data:00402156 12 db 12h
.data:00402157 10 db 10h
.data:00402158 00 input_buffer db 0 ; DATA XREF: start+3D↑o
```

## Solution {#solution}

```python
#!/usr/bin/env python2
s = [0x1F,0x8,0x13,0x13,0x4,0x22,0x0E,0x11,0x4D,0x0D,0x18,0x3D,0x1B,0x11,0x1C,0x0F,0x18,0x50,0x12,0x13,0x53,0x1E,0x12,0x10]
print ''.join([chr(i ^ 0x7d) for i in s])
```

执行即可得到 `flag`:

```powershell
PS D:\personal\vm_share\Flare-On-Challenges\Challenges\2015\Challenge 1> python.exe .\solution.py
bunny_sl0pe@flare-on.com
```
