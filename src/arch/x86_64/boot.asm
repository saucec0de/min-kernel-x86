global start

section .text
bits 32         ;32-bit instructions in protected mode
                ;64-bit in long mode

start:
    mov esp, stack_top    ;initialize stack pointer

    ;checks
    call check_multiboot
    call check_cpuid
    call check_long_mode

    ;print `Hello, World!` to screen
    mov dword [0xB8000], 0x2F652F48
    mov dword [0xB8004], 0x2F6C2F6C
    mov dword [0xB8008], 0x2F2C2F6F
    mov dword [0xB800C], 0x2F572F20
    mov dword [0xB8010], 0x2F722F6F
    mov dword [0xB8014], 0x2F642F6C
    mov word  [0xB8018], 0x2F21

    hlt         ;halt the CPU

error:
    ;print `ERR: error_code` and halt
    mov dword [0xB8000], 0x4F524F45
    mov dword [0xB8004], 0x4F3A4F52
    mov dword [0xB8008], 0x4F204F20
    mov byte  [0xB800A], al
    hlt

check_multiboot:
    cmp eax, 0x36D76289
    jne .NoMultiboot
    ret

check_cpuid:
    ; Check if CPUID is supported by attempting to flip the ID bit (bit 21) in
    ; the FLAGS register. If we can flip it, CPUID is available.

    ; Copy FLAGS in to EAX via stack
    pushfd
    pop eax

    ; Copy to ECX as well for comparing later on
    mov ecx, eax

    ; Flip the ID bit
    xor eax, 1 << 21

    ; Copy EAX to FLAGS via the stack
    push eax
    popfd

    ; Copy FLAGS back to EAX (with the flipped bit if CPUID is supported)
    pushfd
    pop eax

    ; Restore FLAGS from the old version stored in ECX (i.e. flipping the ID bit
    ; back if it was ever flipped).
    push ecx
    popfd

    ; Compare EAX and ECX. If they are equal then that means the bit wasn't
    ; flipped, and CPUID isn't supported.
    xor eax, ecx
    jz .NoCPUID
    ret

check_long_mode:
    ; Long mode can only be detected using the extended functions of CPUID
    ; (> 0x80000000), so we have to check if the function that determines
    ; whether long mode is available or not is actually available
    mov eax, 0x80000000    ; Set the A-register to 0x80000000.
    cpuid                  ; CPU identification.
    cmp eax, 0x80000001    ; Compare the A-register with 0x80000001.
    jb .NoLongMode         ; It is less, there is no long mode.

    ; Use the extended function to detect long mode
    mov eax, 0x80000001    ; Set the A-register to 0x80000001.
    cpuid                  ; CPU identification.
    test edx, 1 << 29      ; Test if the LM-bit, which is bit 29, is set in the
                           ; D-register.
    jz .NoLongMode         ; They aren't, there is no long mode.

set_up_page_tables:


NoMultiboot:
    mov al, "0"
    jmp error

NoCPUID:
    mov al, "1"
    jmp error

NoLongMode:
    mov al, "2"
    jmp error

section .bss
stack_bot:
    resb 64
stack_top:

align 4096
p4_table:
    resb 4096
p3_table:
    resb 4096
p2_table:
    resb 4096
