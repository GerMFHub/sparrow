section .data
    encryption_key db "securekey123456", 0
    encryption_status db "Encrypting data...", 0
    decryption_status db "Decrypting data...", 0

section .bss
    drone_jamming_signals resq 10  ; Store signal strengths from 10 drones
    drone_positions resq 30  ; Store X, Y, Z coordinates of 10 drones
    drone_speeds resq 10  ; Store speeds of drones
    drone_gps_coordinates resq 20  ; Store latitude & longitude of 10 drones
    eta_result resq 1  ; Store estimated time of arrival
    error_flag resb 1  ; Flag for error handling
    encrypted_message resb 256

section .text
    global error_handler
    global encrypt_communication
    global decrypt_communication
    extern printf
    extern sqrt

; Function: encrypt_communication
; Inputs: Message to encrypt
; Outputs: Encrypted message in-place
encrypt_communication:
    push rbp
    mov rbp, rsp
    mov rdi, encryption_status
    call printf
    
    mov rsi, [rbp+8] ; Message pointer
    mov rcx, [rbp+16] ; Message length
    mov rdi, encryption_key ; Encryption key pointer

.loop:
    cmp rcx, 0
    je .done
    mov al, [rsi]
    xor al, [rdi]
    mov [rsi], al
    inc rsi
    inc rdi
    dec rcx
    cmp byte [rdi], 0
    jne .loop
    mov rdi, encryption_key  ; Reset key position
    jmp .loop
.done:
    pop rbp
    ret

; Function: decrypt_communication
; Inputs: Encrypted message
; Outputs: Decrypted message
decrypt_communication:
    push rbp
    mov rbp, rsp
    mov rdi, decryption_status
    call printf
    
    jmp encrypt_communication  ; Decryption is same as encryption (XOR-based)

; Other functions remain unchanged...
