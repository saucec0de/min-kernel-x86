arch   ?= x86_64
kernel := build/kernel-${arch}.bin
iso    := build/min-os-${arch}.iso

src_arch   := src/arch/${arch}
src_grub   := ${src_arch}/grub
build_boot := build/isofiles/boot
build_grub := ${build_boot}/grub
build_arch := build/arch/${arch}

linker   := ${src_arch}/linker.ld
grub_cfg := ${src_grub}/grub.cfg
asm_src  := $(wildcard ${src_arch}/*.asm)
asm_obj  := $(patsubst ${src_arch}/%.asm, ${build_arch}/%.o, \
			  ${asm_src})

.PHONY: all clean build run

all: ${iso}

build: ${iso}

run: ${build}
	@qemu-system-x86_64 -cdrom ${iso}

${kernel}: ${linker} ${asm_obj}
	@ld -n -T ${linker} -o ${kernel} ${asm_obj}

${iso}: ${kernel} ${grub_cfg}
	@mkdir -p ${build_grub}
	@cp ${kernel} ${build_boot}/kernel.bin
	@cp ${grub_cfg} ${build_grub}
	@grub-mkrescue -o ${iso} build/isofiles 2>/dev/null

${build_arch}/%.o: ${src_arch}/%.asm
	@mkdir -p ${build_arch}
	@nasm -felf64 $< -o $@

clean:
	@rm -r build

