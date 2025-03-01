section .data
    jamming_signal db 0
    jamming_strength dq 0.0
    leading_drone db -1
    triangulated_position dq 0.0, 0.0, 0.0  ; X, Y, Z coordinates
    swarm_status db "Analyzing swarm jamming signals", 0
    lead_drone_msg db "New leading drone assigned: ", 0
    eta_msg db "ETA to target: ", 0
    error_msg db "Error detected: Attempting recovery", 0
    recovery_msg db "Recovery successful", 0

section .bss
    drone_jamming_signals resq 10  ; Store signal strengths from 10 drones
    drone_positions resq 30  ; Store X, Y, Z coordinates of 10 drones
    drone_speeds resq 10  ; Store speeds of drones
    drone_gps_coordinates resq 20  ; Store latitude & longitude of 10 drones
    eta_result resq 1  ; Store estimated time of arrival
    error_flag resb 1  ; Flag for error handling

section .text
    global analyze_jamming
    global calculate_drone_location
    global calculate_eta
    global error_handler
    extern printf
    extern sqrt

; Function: analyze_jamming
; Inputs: None
; Outputs: Determines strongest jamming source and assigns leading drone
analyze_jamming:
    push rbp
    mov rbp, rsp
    mov rdi, swarm_status
    call printf

    mov rsi, drone_jamming_signals
    mov rcx, 10  ; Assuming max 10 drones
    xor rax, rax ; Reset max strength index
    xor rdx, rdx ; Reset highest signal value
    
.loop:
    cmp rcx, 0
    je .set_leader
    movsd xmm0, [rsi]
    ucomisd xmm0, xmm1
    jbe .skip
    mov rdx, rcx  ; Store index as new leader
    movsd xmm1, xmm0  ; Store max signal strength
.skip:
    add rsi, 8
    dec rcx
    jmp .loop

.set_leader:
    mov [leading_drone], dl  ; Update leading drone
    mov rdi, lead_drone_msg
    call printf
    
    ; Triangulation based on multiple drones
    mov rax, 0
    mov rdi, triangulated_position
    fld qword [drone_jamming_signals + 0]
    fld qword [drone_jamming_signals + 8]
    faddp st1, st0
    fld qword [drone_jamming_signals + 16]
    faddp st1, st0
    fld qword [drone_jamming_signals + 24]
    faddp st1, st0
    fdiv qword [jamming_strength]
    fstp qword [rdi]
    
    pop rbp
    ret

; Function: calculate_drone_location
; Inputs: Drone ID
; Outputs: Updates drone's exact location in space (X, Y, Z, GPS)
calculate_drone_location:
    push rbp
    mov rbp, rsp
    mov rsi, [rbp+8]  ; Drone ID
    lea rdx, drone_positions
    lea rcx, drone_gps_coordinates
    
    movsd xmm0, [rdx + rsi * 24]  ; Load X coordinate
    movsd xmm1, [rdx + rsi * 24 + 8]  ; Load Y coordinate
    movsd xmm2, [rdx + rsi * 24 + 16]  ; Load Z coordinate
    
    movsd xmm3, [rcx + rsi * 16]  ; Load Latitude
    movsd xmm4, [rcx + rsi * 16 + 8]  ; Load Longitude
    
    pop rbp
    ret

; Function: calculate_eta
; Inputs: Leading drone ID, target location
; Outputs: Estimated time of arrival
calculate_eta:
    push rbp
    mov rbp, rsp
    mov rsi, [rbp+8]  ; Leading drone ID
    mov rdx, triangulated_position  ; Target position
    lea rcx, drone_positions
    lea rdi, drone_speeds
    
    ; Calculate Euclidean distance to target
    movsd xmm0, [rdx]  ; Target X
    subsd xmm0, [rcx + rsi * 24]  ; Target X - Drone X
    mulsd xmm0, xmm0  
    
    movsd xmm1, [rdx + 8]  ; Target Y
    subsd xmm1, [rcx + rsi * 24 + 8]  ; Target Y - Drone Y
    mulsd xmm1, xmm1  
    
    movsd xmm2, [rdx + 16]  ; Target Z
    subsd xmm2, [rcx + rsi * 24 + 16]  ; Target Z - Drone Z
    mulsd xmm2, xmm2  
    
    addsd xmm0, xmm1  
    addsd xmm0, xmm2  
    call sqrt  ; Compute square root (distance)
    
    ; Divide by speed to get ETA
    divsd xmm0, [rdi + rsi * 8]
    movsd [eta_result], xmm0
    
    mov rdi, eta_msg
    call printf
    
    pop rbp
    ret

; Function: error_handler
; Inputs: None
; Outputs: Detects and attempts recovery from errors
error_handler:
    push rbp
    mov rbp, rsp
    mov rdi, error_msg
    call printf
    
    mov al, [error_flag]
    test al, al
    jz .no_error

    ; Attempt recovery by resetting necessary values
    mov [leading_drone], -1
    mov qword [jamming_strength], 0.0
    mov qword [triangulated_position], 0.0
    mov qword [triangulated_position + 8], 0.0
    mov qword [triangulated_position + 16], 0.0
    mov byte [error_flag], 0  ; Clear error flag
    
    mov rdi, recovery_msg
    call printf

.no_error:
    pop rbp
    ret
