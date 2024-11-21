+++
title= "NahamCTF 2024 writeups for Ring Cycle 1"
author= "curtain"
date= 2024-05-27

[taxonomies]
tags = [ "CTF", "Rev"]
categories = [ "Writeups"]

[extra]
toc = true
comment = true
+++

# Basic

## Getting Started

I had just solved the first three challenges in these series. These all have the similar pattern, which requires you enter
a correct passphrase, then the flag will print to stdout, Otherwise, print error info and exit.

```sh
❯ ./basics
What is the passphrase of the vault?
> give me the flag
Wrong passphrase!
```

## Basic Analysis

1. the program will check our passphrase, so there must be some operations with the input passphrase.
2. compare it with the target.

Load the program into IDA, we can see the main function like this:

```c,linenos
  printf("What is the passphrase of the vault?\n> ");
  fgets(s, 50, stdin);
  if ( (unsigned __int8)check(s) )
  {
    stream = fopen("basics.txt", "r");
    if ( !stream )
      return -1;
    fseek(stream, 0LL, 2);
    nmemb = ftell(stream);
    fseek(stream, 0LL, 0);
    ptr = calloc(nmemb, 1uLL);
    if ( !ptr )
      return -1;
    fread(ptr, 1uLL, nmemb, stream);
    fclose(stream);
    printf((const char *)ptr);
    v4 = strlen(s);
    MD5(s, v4, v9);
    printf("flag{");
    for ( i = 0; i <= 15; ++i )
      printf("%02x", (unsigned __int8)v9[i]);
    puts("}");
  }
  else
  {
    puts("Wrong passphrase!");
  }
  return 0;
```

Our input pass will store into `s`, then if the `check(s)` return true, the flag will compute(MD5) according to the input `s`.
Otherwise, the **Wrong passphease!** message puts and exit.

Let's deep into `check()` function:

```c
  v10 = __readfsqword(0x28u);
  for ( i = 0; i <= 24; ++i )
  {
    v4 = *(_BYTE *)(i + a1);
    s1[i] = *(_BYTE *)(50 - i - 1LL + a1);
    s1[49 - i] = v4;
  }
  for ( j = 0; j <= 49; ++j )
  {
    v3 = s1[j];
    s1[j] = s1[j + 1];
    s1[j + 1] = v3;
  }
  s1[49] = 0;
  for ( k = 0; k <= 47; k += 2 )
  {
    v2 = s1[k];
    s1[k] = s1[k + 1];
    s1[k + 1] = v2;
  }
  strcpy(s2, "eyrnou jngkiaccre af suryot arsto  tdyea rre aouY");
  return strcmp(s1, s2) == 0;
```

Here, it's pretty clear what's the operations does to the input `s`.

So far, we can draw the following conclusions:

- The string `s` we input, the maximum length is 49, according to `fgets(s, 50)` and `man 3 fgets`, the last bytes will be `\0`.
- In the `check()` function, the input `s` have been handle:
  1. Exchange the front the back parts.
  2. Swap adjacent elements in order, NOTE: pay attention to the index.
  3. Swap adjacent elements in order again, but this time, the step is two, so the last swap is `s[46] ~ s[47]`, the last element `s[48]` stand still.
- Ater above, `s` check with string `eyrnou jngkiaccre af suryot arsto  tdyea rre aouY`.

### One Step Closer

In the Exchange of the first step, we first exchange `s[0] ~ s[49]`, but according to `fgets()` behavior, `s[49]` must be `\0`, so after exchange, we
got following 'string', **which make sense to second step.**:

{{ figure(src="./info.png") }}

In second step, swap the adjacent elememts, so `s[0]` which is `\0`, will swap to last eventually. cause the last index is 49, it will swap `c[50]`
into array, which is not the user input. so here we can see `s[49] = 0`, make this element disappear.

## Solution

After analysis, we based on string `eyrnou jngkiaccre af suryot arsto  tdyea rre aouY`, then **reverse** the two(second step make no sense, according analysis) step of handle of `s` will get the
correct passrase.

```c
#include <stdio.h>

static char target[50] = "eyrnou jngkiaccre af suryot arsto  tdyea rre aouY";
int main() {
	for(int i = 0; i <= 47; i+=2) {
		char tmp = target[i];
		target[i] = target[i + 1];
		target[i + 1] = tmp;
	}
	for (int i = 0; i <= 24; i++) {
		char tmp = target[i];
		target[i] = target[48 - i];
		target[48 - i] = tmp;
	}
	printf("%s\n", target);
	return 0;
}
```

use the correct passphrase we can get flag:

```sh
❯ ./basics
What is the passphrase of the vault?
> You are ready to start your safe cracking journey
*******************************************************************************
          |                   |                  |                     |
 _________|________________.=""_;=.______________|_____________________|_______
|                   |  ,-"_,=""     `"=.|                  |
|___________________|__"=._o`"-._        `"=.______________|___________________
          |                `"=._o`"=._      _`"=._                     |
 _________|_____________________:=._o "=._."_.-="'"=.__________________|_______
|                   |    __.--" , ; `"=._o." ,-"""-._ ".   |
|___________________|_._"  ,. .` ` `` ,  `"-._"-._   ". '__|___________________
          |           |o`"=._` , "` `; .". ,  "-._"-._; ;              |
 _________|___________| ;`-.o`"=._; ." ` '`."\` . "-._ /_______________|_______
|                   | |o;    `"-.o`"=._``  '` " ,__.--o;   |
|___________________|_| ;     (#) `-.o `"=.`_.--"_o.-; ;___|___________________
____/______/______/___|o;._    "      `".o|o_.--"    ;o;____/______/______/____
/______/______/______/_"=._o--._        ; | ;        ; ;/______/______/______/_
____/______/______/______/__"=._o--._   ;o|o;     _._;o;____/______/______/____
/______/______/______/______/____"=._o._; | ;_.--"o.--"_/______/______/______/_
____/______/______/______/______/_____"=.o|o_.--""___/______/______/______/____
/______/______/______/______/______/______/______/______/______/______/[TomekK]
*******************************************************************************
flag{8562e979f1f754537a4e872cc20a73e8}
```
