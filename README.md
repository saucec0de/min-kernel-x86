# min-kernel-x86
> A minimal x86 kernel

The project is still on-going.

## Overview
This work follows [@phil-opp][1]'s blog post ["A minimal x86 kernel"][2].
In the ordinary post series, it was then extended with Rust, a system
programming language. However, here, in future, I may extend it with C
language.

The key knowledge of how to create a minimal x86 operating system kernel
is put in [BASICS.md]. The blog post has more detailed information. The
kernel, in fact, does very simple task. It will boot and print a line of
`Hello, World!` to the screen.

[1]: https://github.com/phil-opp
[2]: http://blog.phil-opp.com/rust-os/multiboot-kernel.html
[BASICS.md]: ./BASICS.md


## Todo
1. Extend the kernel with C language.
2. Write a simple bootloader instead of using GRUB 2.

