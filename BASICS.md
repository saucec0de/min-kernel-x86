# min-kernel-x86
> The basic knowledge of the minimal x86 kernel


## BIOS

When the computer is turned on, BIOS will be loaded into the reserved
part of memory from some special flash memory. Then BIOS runs some
self-tests and initialization routines of the hardware. After that, BIOS
searches bootable devices. If it successfully finds one, then the
control is transferred to its bootloader.

The bootloader is a small portion of executable code stored at the
beginning of the device. It determines the location of the kernel image
on the device and load it into memory. It also needs to switch the CPU
to "[protected mode][1]", because x86 CPUs start in the very limited [real
mode][2] by default (to be compatible to programs from 1978).

[1]: https://en.wikipedia.org/wiki/Protected_mode
[2]: http://wiki.osdev.org/Real_Mode

## Bootloader

Writing a bootloader may be a complex project. Here we use one of the
[well-tested bootloaders][3], [GRUB 2][4] bootloader. But in future, a
simple bootloader may be written to replace GRUB 2 in this part.

[3]: https://en.wikipedia.org/wiki/Comparison_of_boot_loaders
[4]: http://wiki.osdev.org/GRUB_2

## Multiboot

GRUB 2 follows [Multiboot Specification][5], which describes how a
bootloader can load an x86 operating system kernel. Here we will use
[Multiboot 2 Specification][6].

The kernel we write need indicate that it supports Multiboot and every
Multiboot-compliant bootloader can boot it. To this end, referencing to
the Section 3.1.2 in [Multiboot 2 Specification][6], our kernel must
start with a *Multiboot Header*, which has the following format:

| **Field**     | **Type**        | **Value**                                                    |
|---------------|-----------------|--------------------------------------------------------------|
| magic number  | u32             | Identifies the header, which must be `0xE85250D6`            |
| architecture  | u32             | `0` for 32-bit (protected) mode of i386, `4` for 32-bit MIPS |
| header length | u32             | Total header size in bytes, including tags and magic fields  |
| checksum      | u32             | `-(magic + architecture + header_length)`, sum must be zero  |
| tags          | variable        | Kinds of (type, flags, size)                                 |
| end tag       | (u16, u16, u32) | `(0, 0, 8)`                                                  |

For an x86 machine, the following bootloader header works:

```asm
section .multiboot_header
header_start:
    dd 0xE85250D6               ;magic number
    dd 0                        ;protected mode of i386
    dd header_end-header_start  ;header length
    ;checksum
    dd 0x100000000-(0xE85250D6+0+(header_end-header_start))

    ;optional multiboot tags
    ;none here

    ;end tag
    dw 0                        ;type
    dw 0                        ;flags
    dd 8                        ;size
header_end:
```

Some basic knowledge of assembly language is required:
* section
* label (which marks a memory location)
* `dd`: define double (32-bit), `dw`: define word (16-bit); they just
* output the specific constants

Notice that the formula of the checksum is a negetive integer
(`checksum+header_length` should be zero) which cannot fit into 32-bit.
By subtracting it from 0x100000000, we keep the value positive without
changing its truncated value.

Then assemble this file using `nasm`, and look at the hex value of it:
```
$ nasm multiboot_header.asm
$ hexdump -x multiboot_header
0000000    50d6    e852    0000    0000    0018    0000    af12    17ad
0000010    0000    0000    0008    0000
0000018
```

[5]: https://en.wikipedia.org/wiki/Multiboot_Specification
[6]: http://nongnu.askapache.com/grub/phcoder/multiboot.pdf

## Boot the kernel

The bootloader then needs to boot the kernel. We put a short code in the
.text section which contains the executable codes. The file is named as
`boot_simple.asm`:
```asm
global start

section .text
bits 32         ;32-bit instructions in protected mode
                ;64-bit in long mode

start:
    ;print `Hello, World!` to screen
    mov dword [0xB8000], 0x2F652F48
    mov dword [0xB8004], 0x2F6C2F6C
    mov dword [0xB8008], 0x2F2C2F6F
    mov dword [0xB800C], 0x2F572F20
    mov dword [0xB8010], 0x2F722F6F
    mov dword [0xB8010], 0x2F642F6C
    mov dword [0xB8014], 0x2F202F21
    hlt         ;halt the CPU
```

The `global` exports the label `start`. At address `0xB8000` begins [VGA
text buffer][7]. We move the characters `Hello, World!` to it. A
characters are represented as a combination of an 8-bit color code and
an 8-bit [ASCII code][8]. `0x2F` means grey (`0x2`) background and white
(`0x0F`) font color. `0x48` is `H`, `0x65` is `e`, and so on.

```
$ nasm boot_simple.asm
$ hexdump -x boot_simple
0000000    05c7    8000    000b    2f48    2f65    05c7    8004    000b
0000010    2f6c    2f6c    05c7    8008    000b    2f6f    2f2c    05c7
0000020    800c    000b    2f20    2f57    05c7    8010    000b    2f6f
0000030    2f72    05c7    8010    000b    2f6c    2f64    05c7    8014
0000040    000b    2f21    2f20    00f4
0000047
```

By the way, we can diassemble the hex file by:
```
$ ndisasm -b 32 boot_simple
00000000  C70500800B00482F  mov dword [dword 0xb8000],0x2f652f48
         -652F
0000000A  C70504800B006C2F  mov dword [dword 0xb8004],0x2f6c2f6c
          -6C2F
00000014  C70508800B006F2F  mov dword [dword 0xb8008],0x2f2c2f6f
          -2C2F
0000001E  C7050C800B00202F  mov dword [dword 0xb800c],0x2f572f20
          -572F
00000028  C70510800B006F2F  mov dword [dword 0xb8010],0x2f722f6f
          -722F
00000032  C70510800B006C2F  mov dword [dword 0xb8010],0x2f642f6c
          -642F
0000003C  C70514800B00212F  mov dword [dword 0xb8014],0x2f202f21
          -202F
00000046  F4                hlt
```

[7]: https://en.wikipedia.org/wiki/VGA-compatible_text_mode#Access_methods
[8]: https://en.wikipedia.org/wiki/ASCII#ASCII_printable_code_chart

## ELF Object File

The executable should be [ELF][9] executable if we want to boot it
through GRUB. So that we need to create an [ELF objects][10] and link
them together using a [linker script][11]. The linker script `linker.ld`
looks like this:
```asm
ENTRY(start)    /* entry point after loading the kernel */

SECTIONS {
    . = 1M;     /* the load address of 1st section */

    .boot :
    {
        *(.multiboot_header)    /* must at the beginning */
    }

    .text :
    {
        *(.text)
    }
}
```

We set the load address of the first section to `0x100000` so that it
will not overlap with the reserved memory of e.g. VGA text buffer.

The ELF objects can be generated by:
```
$ nasm -f elf64 multiboot_header.asm
$ nasm -f elf64 boot_simple.asm
$ ld -n -o kernel.bin -T linker.ld multiboot_header.o boot_simple.o
$ objdump -h kernel.bin

kernel.bin:     file format elf64-x86-64

Sections:
Idx Name          Size      VMA               LMA               File off  Algn
  0 .boot         00000018  0000000000100000  0000000000100000  00000080  2**0
                  CONTENTS, ALLOC, LOAD, READONLY, DATA
  1 .text         00000047  0000000000100020  0000000000100020  000000a0  2**4
                  CONTENTS, ALLOC, LOAD, READONLY, CODE
```

`-n` flag is passed to linker to disable the automatic section alignment
in the executable. With automatic alignment, the linker may page align
the `.boot` section so that it may not be at the beginning of the
executable. You may need `x86_64‑elf‑ld` and `x86_64‑elf‑objdump`
instead of `ld` and `objdump` if not working on an x86_64 platform.

[9]: https://en.wikipedia.org/wiki/Executable_and_Linkable_Format
[10]: http://wiki.osdev.org/Object_Files
[11]: https://sourceware.org/binutils/docs/ld/Scripts.html

## Create ISO

To create an bootable ISO image, we need the following directory
structure:
```
isofiles
└── boot
    ├── grub
    │   └── grub.cfg
    └── kernel.bin
```

The `grub.cfg` is a simple [GRUB configuration file][12]:
```cfg
set timeout = 0
set default = 0

menuentry "MinOS" {
    multiboot2 /boot/kernel.bin
    boot
}
```

Make sure that the version of your `xorriso` is newer than `1.2.9`. Then
create the image by:
```
grub-mkrescue -o min-os.iso isofiles
```

All steps can be done within a [Makefile][13].

[12]: http://www.gnu.org/software/grub/manual/grub.html#Configuration
[13]: ./Makefile

## Run

As shown in [Makefile][13], we can boot our little kernel by:
```
qemu-system-x86_64 -cdrom min-os.iso
```

