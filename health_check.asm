section .data
    hardware_ok_message db "All hardware components operational", 0
    hardware_fail_message db "Hardware failure detected", 0

section .bss
    hardware_status resb 8  ; Storage for hardware check results

section .text
    global check_hardware_status
    extern printf

; Check if all connected hardware is operational
check_hardware_status:
    push rbp
    mov rbp, rsp
    mov rdi, hardware_status
    mov rcx, 8  ; Assume 8 hardware components
    xor rax, rax
.loop:
    cmp rcx, 0
    je .check_done
    mov al, [rdi]
    cmp al, 0
    jne .hardware_fail
    inc rdi
    dec rcx
    jmp .loop

.hardware_fail:
    mov rdi, hardware_fail_message
    call printf
    jmp .done

.check_done:
    mov rdi, hardware_ok_message
    call printf

.done:
    pop rbp
    ret
