+++
title= "NahmCTF 2024 writeups for Ring Cycle 3"
author= "curtain"
date= 2024-05-28T14:22:40+08:00

[taxonomies]
tags=["CTF", "Rev"]
categories= [ "Security"]

[extra]
toc = true
comment = true
+++

# Start

We already known that program need us input correct passphrase, this time we get some other info:

```sh
❯ ll valkyrie rhinegold basics
-rwxr-xr-x 1 ada ada 16704 May 24 09:19 basics
-rwxr-xr-x 1 ada ada 16768 May 24 09:19 rhinegold
-rwxr-xr-x 1 ada ada 42584 May 24 09:19 valkyrie
```

Here, the file size of this level is far greater than first two, maybe we guess there are more complex code(_.text_) or data(.\*data).

# Code Content

Load it into IDA, As we guessed, the `main` function become more complex. but we can still find some clues.

```c,hl_lines=1 2
  o___60(0LL, o___78);
  printf(o___78);
  fgets(
    s,
    *((_DWORD *)&o___64
    + 3 * ((((unsigned int)o___56 | 7) - ((2 * ((unsigned int)o___56 | 7)) & (unsigned int)(o___56 >> 63))) % 0xA))
  % (unsigned int)dword_A0B4
  + 23,
    stdin);
```

Both `printf()` and `o___60()` use `o___78` as argument, we deep into `o___60()`:

```c,linenos
unsigned __int64 __fastcall o___60(unsigned int a1, _BYTE *a2)
{
  unsigned __int64 result; // rax

  result = a1;
  switch ( a1 )
  {
    case 0u:
      qmemcpy(a2, "What is the passphrase of the vault?\n> ", 39);
      result = (unsigned __int64)(a2 + 39);
      a2[39] = 0;
      break;
    case 1u:
      qmemcpy(a2, "valkyrie.txt", 12);
      result = (unsigned __int64)(a2 + 12);
      a2[12] = 0;
      break;
    case 2u:
      *a2 = 'r';
      result = (unsigned __int64)(a2 + 1);
      a2[1] = 0;
      break;
    case 3u:
      *a2 = 'f';
      a2[1] = 'l';
      a2[2] = 'a';
      a2[3] = 'g';
      a2[4] = '{';
      result = (unsigned __int64)(a2 + 5);
      a2[5] = 0;
      break;
    case 4u:
      *a2 = '%';
      a2[1] = '0';
      a2[2] = '2';
      a2[3] = 'x';
      result = (unsigned __int64)(a2 + 4);
      a2[4] = 0;
      break;
    // ...
```

So `o___60()` will based on argument `a1` to set `a2`, which is the varible `o___78`. Next is the `fgets()`,
but here we see the second args `size` is a complex expression, how can we get it's exact value?

Similar to this situation of finding the value of a complex expression, there are generally two ways to do this:

1. use some debug tools like `GDB`, break at that place, goto there.
2. use trace tools like `strace/ltrace` etc.

Here we can use the first one:

```sh
 → 0x7ffff79c8380 <fgets+0000>     endbr64
   0x7ffff79c8384 <fgets+0004>     push   r14
   0x7ffff79c8386 <fgets+0006>     push   r13
   0x7ffff79c8388 <fgets+0008>     push   r12
   0x7ffff79c838a <fgets+000a>     push   rbp
   0x7ffff79c838b <fgets+000b>     push   rbx
──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────── threads ────
[#0] Id 1, Name: "valkyrie", stopped 0x7ffff79c8380 in _IO_fgets (), reason: BREAKPOINT
────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────── trace ────
[#0] 0x7ffff79c8380 → _IO_fgets(buf=0x7fffffffe6e0 "@@UUUU", n=0x1a, fp=0x7ffff7b63aa0 <_IO_2_1_stdin_>)
[#1] 0x5555555555af → main()
```

We get that `size = 0x1a`. After `fget()` from `stdin`, and then it should be some **check** logic.

```c
  s[25] = (((o___56 & 0xF7) - (~(_BYTE)o___56 & 8)) | o___66) * (((o___56 & 0xF7) - (~(_BYTE)o___56 & 8)) & o___66)
        + (((o___56 & 0xF7) - (~(_BYTE)o___56 & 8)) & ~(_BYTE)o___66)
        * (((~(_BYTE)o___56 & 8) + ~(o___56 & 0xF7)) & o___66);
  if ( !(unsigned __int8)((__int64 (__fastcall *)(char *))o___76)(s) )
  {
    // NOTE: this is the fail branch, cause `o___60` with first arg 6. see it.
    o___60(6u, o___47);
    printf(o___47);
    return *((_DWORD *)&o___64 + 3 * ((unsigned int)abs64(o___56 - 9) % 0xA) + 1) % (unsigned int)dword_A0CC - 5;
  }
  o___60(1u, o___52);
  o___60(2u, o___58);
  stream = fopen(o___52, o___58);
  if ( (FILE *)(int)(*((_DWORD *)&o___64
```

`s[25]` that is the last element assignment by a complex expression, we also use above trick, break at the `call` of `o___76`

```sh
 → 0x555555555d6e <main+0a2f>      call   0x555555557a02 <o___76>
   ↳  0x555555557a02 <o+0000>         endbr64
      0x555555557a06 <o+0004>         push   rbp
      0x555555557a07 <o+0005>         mov    rbp, rsp
      0x555555557a0a <o+0008>         push   r15
      0x555555557a0c <o+000a>         push   r14
      0x555555557a0e <o+000c>         push   r13
──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────── arguments (guessed) ────
o___76 (
   $rdi = 0x00007fffffffe6e0 → "AAAAAAAAAAAAAAAAAAAAAAAAA",
   $rsi = 0x0000000000000000,
   $rdx = 0x0000000000000000
)
──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────── threads ────
[#0] Id 1, Name: "valkyrie", stopped 0x555555555d6e in main (), reason: SINGLE STEP
────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────── trace ────
[#0] 0x555555555d6e → main()
─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
gef➤  x/26bx 0x00007fffffffe6e0
0x7fffffffe6e0: 0x41    0x41    0x41    0x41    0x41    0x41    0x41    0x41
0x7fffffffe6e8: 0x41    0x41    0x41    0x41    0x41    0x41    0x41    0x41
0x7fffffffe6f0: 0x41    0x41    0x41    0x41    0x41    0x41    0x41    0x41
0x7fffffffe6f8: 0x41    0x00
```

So `s[25] == 0`, and the check function is `o___76()`, which should return `true` represent correct passphrase.

## Check Logic

When decompile function `o___76()`, IDA will give us some err info, after investigate, there're some useless data in code section.
{{ figure(src="./logic.png") }}
Let's `NOP` it. and then create function at start.

```c
  v19 = malloc(0x18uLL);
  v19[2] = v19;
  *v19 = v19;
  o___75 = (__int64)v19;
  for ( i = 0; i <= 2; ++i )
  {
    v21 = malloc(0x18uLL);
    v21[2] = i * ((~(_BYTE)o___56 | 0xFFFFFFF7) + o___56 + 9);
    *((_QWORD *)v21 + 2) = *(_QWORD *)(o___75 + 16);
    *(_QWORD *)v21 = o___75;
    **(_QWORD **)(o___75 + 16) = v21;
    *(_QWORD *)(o___75 + 16) = v21;
  }
  o___63 = *(_QWORD *)(o___75 + 16);
  o___70 = o___63;
  if ( o___71 != o___77 )
    o___76(a1);
  if ( o___71 == o___77 )
    v1 = 76;
  else
    v1 = 4;
```

Note fourth from last line, if the variable `o___71` != `o___77` will call itself recursively, cause these two variable resident at `.bss`.
So we break at that

```sh
 → 0x555555557b66 <o+0164>         cmp    rdx, rax
   0x555555557b69 <o+0167>         je     0x555555557b80 <o___76+382>
   0x555555557b6b <o+0169>         mov    rax, QWORD PTR [rbp-0xd8]
   0x555555557b72 <o+0170>         mov    rdi, rax
   0x555555557b75 <o+0173>         call   0x555555557a02 <o___76>
   0x555555557b7a <o+0178>         mov    BYTE PTR [rbp-0xcd], al
──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────── threads ────
[#0] Id 1, Name: "valkyrie", stopped 0x555555557b66 in o (), reason: BREAKPOINT
────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────── trace ────
[#0] 0x555555557b66 → o()
[#1] 0x555555555d73 → main()
─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
gef➤  p/x $rdx
$2 = 0x55555555f2e0
gef➤  p/x $rax
$3 = 0x55555555f2e0
gef➤
```

So we can move on:

```c
  nptr[0] = v1;
  nptr[1] = *((_DWORD *)&o___64
            + 3
            * (((unsigned int)((o___56 + 9) >> 63) ^ ((_DWORD)o___56 + (unsigned int)((o___56 + 9) >> 63) + 9)) % 0xA))
          % (unsigned int)dword_A0B4
          + 108;
  if ( o___71 == o___77 )
    v2 = 118;
  else
    v2 = 122;
  nptr[2] = v2;
  nptr[3] = (o___56 ^ 6 | o___66) * ((o___56 ^ 6) & o___66)
          + (~(_BYTE)o___66 & (o___56 ^ 6)) * ((o___56 ^ 0xF9) & o___66)
          + 101;
  nptr[4] = *((_DWORD *)&o___64
            + 3
            * (((unsigned int)o___56 - ((unsigned int)((o___56 - 10) >> 63) & (2 * ((_DWORD)o___56 - 10))) - 10) % 0xA)
            + 1)
          % (unsigned int)dword_A0CC
          - 5;
  if ( o___71 == o___77 )
    v3 = 10;
  else
    v3 = 9;
  if ( o___71 == o___77 )
    v4 = 0LL;
  else
    v4 = (char **)((char *)&dword_0 + 2);
  seed = strtol(nptr, v4, v3);
  srand(seed);
```

Hey, we encounter the same patter again, let's break at `strtol`, see what's the arguments pass to.

```sh
 → 0x555555557da4 <o+03a2>         call   0x5555555551d0 <strtol@plt>
   ↳  0x5555555551d0 <strtol@plt+0000> endbr64
      0x5555555551d4 <strtol@plt+0004> bnd    jmp QWORD PTR [rip+0x8dc5]        # 0x55555555dfa0 <strtol@got.plt>
      0x5555555551db <strtol@plt+000b> nop    DWORD PTR [rax+rax*1+0x0]
      0x5555555551e0 <fread@plt+0000> endbr64
      0x5555555551e4 <fread@plt+0004> bnd    jmp QWORD PTR [rip+0x8dbd]        # 0x55555555dfa8 <fread@got.plt>
      0x5555555551eb <fread@plt+000b> nop    DWORD PTR [rax+rax*1+0x0]
──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────── arguments (guessed) ────
strtol@plt (
   $rdi = 0x00007fffffffdb6b → 0x0000000065766f4c ("Love"?),
   $rsi = 0x0000000000000000,
   $rdx = 0x000000000000000a,
   $rcx = 0x0000000000000000
)
──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────── threads ────
[#0] Id 1, Name: "valkyrie", stopped 0x555555557da4 in o (), reason: BREAKPOINT
────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────── trace ────
[#0] 0x555555557da4 → o()
[#1] 0x555555555d73 → main()
─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
gef➤
```

Oh, the string "Love" is passed. so we know the seed of `srand()` is 0. Next is the core logic for processing our input `a1`.

```c
  for ( j = 0;
        j <= 25;
        j += ((2 * (o___56 | 9) + (o___56 ^ 0xFFFFFFF6) + 1) | o___66)
           * ((2 * (o___56 | 9) + (o___56 ^ 0xFFFFFFF6) + 1) & o___66)
           + ((-2 - (2 * (o___56 | 9) + (o___56 ^ 0xFFFFFFF6))) & o___66)
           * ((2 * (o___56 | 9) + (o___56 ^ 0xFFFFFFF6) + 1) & ~(_DWORD)o___66)
           + 1 )
  {
    nptr[j + 5] = *(_BYTE *)(j + a1) ^ rand();
  }
  v18 = *((_DWORD *)&o___64
        + 3 * (((unsigned int)((o___56 + 1) >> 63) ^ ((_DWORD)o___56 + (unsigned int)((o___56 + 1) >> 63) + 1)) % 0xA)
        + 1)
      % (unsigned int)dword_A0CC
      + 20LL;
  if ( o___71 == o___77 )
    goto LABEL_23;
  do
  {
    v20 = rand() % ((o___71 != o___77) + (unsigned __int64)(o___71 == o___77) + v18);
    v17 = nptr[v18 + 5];
    nptr[v18 + 5] = nptr[v20 + 5];
    nptr[v20 + 5] = v17;
    v18 += (o___71 != o___77) - (unsigned __int64)(o___71 == o___77);
LABEL_23:
    ;
  }
  while ( v18 > (unsigned __int64)(*((_DWORD *)&o___64
                                   + 3
                                   * (((unsigned int)o___56
                                     - ((unsigned int)((o___56 - 5) >> 63) & (2 * ((_DWORD)o___56 - 5)))
                                     - 5)
                                    % 0xA)
                                   + 1)
                                 % (unsigned int)dword_A0CC)
```

The same as before, we dynamic debug use `GDB`, after that, we can make this logic more clear like this:

```c
  srand(0);
  for (int j = 0; j <= 25; j++) {
    // index from 5, cause first 5 byte for "Love\0".
    nptr[5 + j] = a1[j] ^ rand();
  }
  int v18 = 25;
  do {
    int rand_idx = rand() % (v18 + 1);
    char tmp = nptr[v18 + 5];
    nptr[v18 + 5] = nptr[rand_idx + 5];
    nptr[rand_idx + 5] = tmp;
    v18--;
  } while (v18 > 0)
```

Finally, after a long section for assignment for `v23`, which is the target, we can get the final check:

```c
for ( k = *((_DWORD *)&o___64
            + 3 * (((unsigned int)o___56 - ((unsigned int)((o___56 - 1) >> 63) & (2 * ((_DWORD)o___56 - 1))) - 1) % 0xA))
          % (unsigned int)dword_A0B4
          - 3;
        (int)((((o___56 & 0xFFFFFFF5) - (~(_BYTE)o___56 & 0xA)) | o___66)
            * (((o___56 & 0xFFFFFFF5) - (~(_BYTE)o___56 & 0xA)) & o___66)
            + (((~(_BYTE)o___56 & 0xA) + ~(o___56 & 0xFFFFFFF5)) & o___66)
            * (((o___56 & 0xFFFFFFF5) - (~(_BYTE)o___56 & 0xA)) & ~(_DWORD)o___66))
      + 25LL >= k;
        k = *((_DWORD *)&o___64
            + 3
            * (((((int)((unsigned __int64)o___56 >> 31) >> 31) ^ (unsigned int)(2 * o___56))
              - ((int)((unsigned __int64)o___56 >> 31) >> 31))
             % 0xA)
            + 1)
          % (unsigned int)dword_A0CC
          + k
          - 4 )
  {
    if ( *((_DWORD *)&o___64
         + 3 * (((unsigned int)o___56 - ((unsigned int)((o___56 + 6) >> 63) & (2 * ((_DWORD)o___56 + 6))) + 6) % 0xA))
       % (unsigned int)dword_A0B4 == dword_A0A8
      && nptr[k + 5] != v23[k] )
    {
      return o___71 != o___77;
    }
  }
  return 1LL;
```

We can break at the beginning of `for` statement to see what in the `v23`.

```sh
 → 0x55555555b04a <o+3648>         movzx  edx, BYTE PTR [rbp+rax*1-0x80]
   0x55555555b04f <o+364d>         mov    eax, DWORD PTR [rbp-0xc8]
   0x55555555b055 <o+3653>         cdqe
   0x55555555b057 <o+3655>         movzx  eax, BYTE PTR [rbp+rax*1-0x60]
   0x55555555b05c <o+365a>         cmp    dl, al
   0x55555555b05e <o+365c>         je     0x55555555b087 <o___76+13957>
──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────── threads ────
[#0] Id 1, Name: "valkyrie", stopped 0x55555555b04a in o (), reason: BREAKPOINT
────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────── trace ────
[#0] 0x55555555b04a → o()
[#1] 0x555555555d73 → main()
─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
gef➤  x/26bx $rbp - 0x60
0x7fffffffdb90: 0xa7    0x86    0x8e    0x26    0x92    0x4c    0x54    0x6f
0x7fffffffdb98: 0x1d    0x96    0xd4    0x93    0x8b    0xa8    0x28    0xa9
0x7fffffffdba0: 0x18    0x9a    0x6a    0x5a    0x3e    0x9a    0x27    0x8b
0x7fffffffdba8: 0xee    0x1c
gef➤
```

So far, We've got all the clues to find the correct password:

1. logic for process input
2. the target memory bytes

**The same as before, we also need take care of the reverse order. btw, cause two step use the `rand()` both, we need prepare it in advance.**

# Solution

---

Here is my solution `c` program:

```c
#include <stdio.h>
#include <stdlib.h>

static char target[] = "\xa7\x86\x8e\x26\x92\x4c\x54\x6f\x1d\x96\xd4\x93\x8b\xa8\x28\xa9\x18\x9a\x6a\x5a\x3e\x9a\x27\x8b\xee\x1c";
int main() {
	srand(0);
	int xor[26] = {};
	for (int i = 0; i <=25; i++) {
		xor[i] = rand();
	}
	int idx[26] = {};
	for (int i = 25; i >=0; i --) {
		 idx[i] = rand() % (i + 1);
	}
	for (int i = 0; i < 26; i ++) {
		char tmp = target[i];
		target[i] = target[idx[i]];
		target[idx[i]] = tmp;
	}

	char orginal[26] = "";
	for (int i = 0; i <=25; i++) {
		orginal[i] = target[i] ^ xor[i];
	}

	printf("%s\n", orginal);

	return 0;
}
```

use that to get the flag:

```sh
❯ ./valkyrie
What is the passphrase of the vault?
> You've been thunderstruck

               -=*{ VALKYRIE }*=-  Co-sysop Valhalla BBS
                                   PH: +64-03-455-8584
  .       +       *          |\    .                    .
                              \\         *          .       +         .
       *       .        +      \\
                                \\      .      +                  *
  .     .      +    .          {====}
                                 (\\  ,,,,.         *      .           +
    +       *        .     *      \(),~`~`~~,
                                   \ ('_'|)))`  .             +
   .    .       .      +      .     \ \=,((((                             /
                                     \ !  )))),     +    .        *    +_/
            +      *       .        ,/_Y_(( \)                        _/
  --_.                             (  (   )\ \   *       ./\       . /~\~/v
      \_.     .     T_________T     \     / ) )        ./   \       /
         \,       '//////|\\\\\\'    )    \/ /       ./      \     /
           \,     /IT--T--T--T-I\   /     (_]      ,/         \_  /
             \,    I   U v U   I   |       |     ./             \/
               \,  I U.==.==.U I   !__,    |    /                \
                 \,I  |o=|=o|  I_.__|  \_~~/__,;                  \
                  ,I__|=o|o=|__I_   |  /|  |                       \.
                 /: ' : ' : ' : '\  |  ||  |
  --------------;   :   :   :   : '.(_-(|__(-------------------------------
  -----------------------------------\+/|\/:-------------------------------
               `'                     )\|/\;                 `'
       `'                            {,/ )\.]     `'
                            `'           {,/                          `'
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

flag{0f98ac306a8b3dab1b933121cd3f56a3}
```
