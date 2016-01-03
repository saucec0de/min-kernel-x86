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

# Multiboot

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
| checksum      | u32             | `(magic + architecture + header_length)`, must be zero       |
| tags          | variable        | Kinds of (type, flags, size)                                 |
| end tag       | (u16, u16, u32) | `(0, 0, 8)`                                                  |

[5]: https://en.wikipedia.org/wiki/Multiboot_Specification
[6]: http://nongnu.askapache.com/grub/phcoder/multiboot.pdf
