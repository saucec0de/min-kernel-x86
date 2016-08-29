# min-kernel-x86
> Switch the minimal x86 kernel to 64-bit long mode and set up Paging.

## Introduction

Following the introductions in [BASIC.md], the CPU is currently in
32-bit protected mode. It allows to access up to 4GiB memory, but now we
want to extend it to 64-bit long mode. Paging will also be set up in
this document.

[BASICS.md]: ./BASICS.md


