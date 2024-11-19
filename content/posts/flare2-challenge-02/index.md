+++
title = "Flare2-challenge-02"
author = ["curtainp"]
date = 2023-12-08T19:08:05+08:00
lastmod = 2023-12-08T19:08:05+08:00
draft = false

[taxonomies]
tags = ["FireEye", "Rev", "CTF"]
categories = ["Security"]

[extra]
toc = true
comment = true
+++

## 文件信息 {#文件信息}

使用 `flare` 密码解压之后得到 very_success.exe 文件，[DIE](https://github.com/horsicq/Detect-It-Easy) 查看 PE 信息：
{{ figure(src="./die.png") }}

## 代码分析 {#代码分析}

安全环境中（虚拟机）执行此程序，可以看到提示输入 key:
{{ figure(src="./key.png") }}

且初步判断与命令行参数、程序输入长度无关。加载到 **IDA Pro** 中分析，程序仅仅有两个函数（除去 start 之外），且 `start` 函数开始就直接调用 `0x401000`:

```asm
.text:004010DF E8 1C FF FF FF call sub_401000
.text:004010DF
.text:004010E4 AF scasd ；有些奇怪的指令，scas ？
.text:004010E5 AA stosb
.text:004010E5 start endp
```

进入 `sub_401000` 分析：
{{ figure(src="./ida.png") }}

根据分析注释，可以得出：

1.  地址 `0x4010E4` 处并不是代码，而是 **key_buffer** （在处理函数中可以验证）
2.  `sub_401084` 返回 0 代表失败进入 ”failure" 分支，反之则进入“success" 分支，但两个分支打印提示信息就结束了，要得到 `flag` 还要从 `sub_401084` 关键函数中分析
3.  `sub_401084` 有明显的几个参数，已于图中标出

### 关键逻辑 sub_401084 {#关键逻辑-sub-401084}

{{ figure(src="./ida2.png") }}

分析得出：

1.  user_input_length 必须大于等于 37
2.  `ecx` 作为 key_buffer 指针，从尾部开始往前移动，而不是从前往后

处理的关键逻辑如图中分析，可以在 **python Script** 中模拟上述逻辑即可到处 expect_input (flag)

```python
#!/usr/bin/env python

def split_reg(reg):
reg8h = reg >> 8
reg8l = reg & 0xff
return (reg8h, reg8l)

def make_reg16_from_hl(reg8h, reg8l):
return (reg8h << 8) | reg8l

rol = lambda val, r_bits, max_bits=8: \
 (val << r_bits % max_bits) & (2**max_bits - 1) | \
 ((val & (2**max_bits - 1)) >> (max_bits - (r_bits % max_bits)))

# xor ebx, ebx

bx = 0

# mov ecx, 25h

cx = 0x25
user_buffer = []

# already in reversed

encrypt_buffer = [0xa8, 0x9a, 0x90, 0xb3, 0xb6, 0xbc, 0xb4, 0xab, 0x9d, 0xae, 0xf9, 0xb8, 0x9d, 0xb8, 0xaf, 0xba, 0xa5, 0xa5, 0xba, 0x9a, 0xbc, 0xb0, 0xa7, 0xc0, 0x8a, 0xaa, 0xae, 0xaf, 0xba, 0xa4, 0xec, 0xaa, 0xae, 0xeb, 0xad, 0xaa, 0xaf]
stack = []
ax = 0
dx = 0

for c, i in enumerate(encrypt_buffer):
saved_ax = ax
saved_bx = bx
saved_cx = cx
saved_dx = dx

    # brute force
    for probe_char in range(255):
        # mov dx, bx
        dx = bx
        #(dh, dl) = split_reg(dx)

        # and dx, 3
        dx = dx & 0x3
        (dh, dl) = split_reg(dx)

        # mov ax, 0x1C7
        ax = 0x1C7
        (ah, al) = split_reg(ax)
        # push eax
        stack.append(ax)
        # sahf
        cf = 1
        # lodsb
        al = probe_char
        # xor al, [esp + 4]
        al = al ^ 0xC7
        ax = make_reg16_from_hl(ah, al)

        # xchg cl, dl
        saved_dx = dx
        dx = cx
        cx = saved_dx
        (ch, cl) = split_reg(cx)
        # rol ah, cl
        ah = rol(ah, cl)
        ax = make_reg16_from_hl(ah, al)

        # adc al, ah
        al = al + ah + cf
        ax = make_reg16_from_hl(ah, al)

        # xchg cl, dl
        saved_dx = dx
        dx = cx
        cx = saved_dx
        (ch, cl) = split_reg(cx)
        (dh, dl) = split_reg(dx)
        # xor edx, edx
        dx = 0
        # and eax, FFh
        ax = ax & 0xff
        (ah, al) = split_reg(ax)
        # add bx, ax
        bx = bx + ax

        if ax == encrypt_buffer[c]:
            user_buffer.append(probe_char)
            ax = stack.pop()
            cx -= 1
            break
        else:
            ax = saved_ax
            bx = saved_bx
            cx = saved_cx
            dx = saved_dx

print(''.join([chr(i) for i in user_buffer]))
```
