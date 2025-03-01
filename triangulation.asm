section .data
	; ===============================
    ; Signal triangulation detection module. Works thru direct 
	; Ground control data injection, or passed thru pereferials
    ; ===============================
    gps_device db "/dev/serial0", 0   ; UART GPS module
    bt_command db "hcitool rssi AA:BB:CC:DD:EE:FF", 0   ; Bluetooth RSSI command
    sdr_command db "rtl_sdr -f 915000000 -s 2.4e6 -g 20", 0   ; SDR command (915 MHz)
    
    gps_buffer resb 256  ; Buffer for GPS NMEA sentences
    bt_buffer resb 64    ; Buffer for Bluetooth RSSI data
    sdr_buffer resb 1024 ; Buffer for SDR signal data

    speed_of_light dd 299792458.0
    estimated_x dd 0.0
    estimated_y dd 0.0
	
	signal_strengths dd 50.0, 40.0, 30.0, 20.0  ; Example RSS values (dBm) from 4 receivers
    receiver_coords dd 0.0, 0.0, 10.0, 10.0, 20.0, 5.0, 30.0, 15.0  ; (x,y) positions of 4 receivers
    path_loss_factor dd 3.0     ; Path loss exponent (urban environment ~3)
    reference_distance dd 1.0   ; Reference distance (1m)
    reference_signal dd -30.0   ; Signal at reference distance
    speed_of_signal dd 299792458.0  ; Speed of light in m/s
    estimated_x dd 0.0
    estimated_y dd 0.0

section .bss
    gps_x resd 1  ; GPS latitude
    gps_y resd 1  ; GPS longitude
    bt_rssi resd 1  ; Bluetooth RSSI value
    sdr_tdoa resd 1  ; TDOA from SDR
    distances resd 4      ; Estimated distances (1 per receiver)
    time_diffs resd 4     ; Time differences
    filtered_x resd 1     ; Kalman-filtered X
    filtered_y resd 1     ; Kalman-filtered Y

section .text
    global _start
    extern printf
    extern system  ; Used for calling system commands

_start:

; RSS Distance Calculation Using Log-Distance Path Loss Model
rss_loop:
    fld dword [reference_signal]  ; Load reference signal strength
    fsub dword [esi]              ; Subtract measured signal
    fdiv dword [path_loss_factor] ; Divide by path loss exponent
    fld1
    fscale                        ; Compute 10^(difference/path_loss_factor)
    fstp dword [edi]              ; Store computed distance

    add esi, 4  ; Next RSS value
    add edi, 4  ; Next distance slot
    loop rss_loop

; Time Difference of Arrival (TDOA) Computation
    lea esi, receiver_coords
    lea edi, time_diffs
    mov ecx, 4  ; Loop counter for receivers

tdoa_loop:
    fld dword [esi]  ; Load receiver X coordinate
    fmul dword [speed_of_signal]  ; Multiply by speed of light
    fstp dword [edi]  ; Store computed time difference

    add esi, 8  ; Move to next (x,y) coordinate pair
    add edi, 4  ; Move to next time difference
    loop tdoa_loop

; Compute Estimated Position using Least-Squares Multilateration
    lea esi, receiver_coords
    lea edi, distances
    mov ecx, 4
    xorps xmm0, xmm0   ; Sum X
    xorps xmm1, xmm1   ; Sum Y
    xorps xmm2, xmm2   ; Sum Distances

position_loop:
    movaps xmm3, [esi]  ; Load (x, y) coordinates
    movaps xmm4, [edi]  ; Load distance

    addps xmm0, xmm3    ; Sum X coordinates
    addps xmm1, xmm3    ; Sum Y coordinates
    addps xmm2, xmm4    ; Sum distances

    add esi, 8  ; Move to next receiver coordinate
    add edi, 4  ; Move to next distance
    loop position_loop

    divps xmm0, xmm2  ; Normalize X
    divps xmm1, xmm2  ; Normalize Y

    movaps [estimated_x], xmm0  ; Store estimated X
    movaps [estimated_y], xmm1  ; Store estimated Y

; Apply Kalman Filter to Estimated Position
    fld dword [filtered_x]
    fmul dword [filtered_x]  ; Prediction
    fld dword [estimated_x]
    fsubp                      ; Difference
    fmul dword [path_loss_factor] ; Scaling Factor
    fadd dword [filtered_x]
    fstp dword [filtered_x]  ; Store filtered X

    fld dword [filtered_y]
    fsub dword [estimated_y]
    fmul dword [path_loss_factor]
    fadd dword [filtered_y]
    fstp dword [filtered_y]  ; Store filtered Y

   ; Exit
    mov eax, 60
    xor edi, edi
    syscall
    ; ===============================
    ;  READ GPS DATA (UART)
    ; ===============================
    mov rdi, gps_device
    mov rsi, gps_buffer
    mov rdx, 256
    call read_gps_data

    ; Parse GPS coordinates
    lea rsi, gps_buffer
    call parse_gps

    ; ===============================
    ;  FETCH BLUETOOTH RSSI
    ; ===============================
    mov rdi, bt_command
    mov rsi, bt_buffer
    mov rdx, 64
    call execute_shell_command

    ; Parse RSSI value
    lea rsi, bt_buffer
    call parse_rssi

    ; ===============================
    ;  PROCESS SDR DATA (TDOA/AoA)
    ; ===============================
    mov rdi, sdr_command
    mov rsi, sdr_buffer
    mov rdx, 1024
    call execute_shell_command

    ; Process TDOA from SDR
    lea rsi, sdr_buffer
    call process_sdr_tdoa

    ; ===============================
    ;  COMPUTE POSITION (MULTILATERATION)
    ; ===============================
    call calculate_position

    ; ===============================
    ;  EXIT
    ; ===============================
    mov eax, 60  ; Exit syscall
    xor edi, edi
    syscall

; ========================================
; FUNCTION: READ GPS DATA (UART)
; ========================================
read_gps_data:
    mov eax, 2    ; sys_open
    mov edi, rdi  ; GPS device file
    mov esi, 0    ; Read-only
    syscall       ; Open file descriptor

    mov ebx, eax  ; Store file descriptor
    mov eax, 0    ; sys_read
    mov edi, ebx  ; File descriptor
    syscall       ; Read GPS data

    ret

; ========================================
; FUNCTION: PARSE GPS COORDINATES
; ========================================
parse_gps:
    ; Extract GPS Latitude and Longitude from NMEA
    lea rdi, gps_buffer
    ; Simplified parsing logic
    ret

; ========================================
; FUNCTION: EXECUTE SHELL COMMAND (BT & SDR)
; ========================================
execute_shell_command:
    mov rdi, rsi
    call system  ; Call shell command
    ret

; ========================================
; FUNCTION: PARSE BLUETOOTH RSSI
; ========================================
parse_rssi:
    lea rdi, bt_buffer
    ; Extract numeric value from command output
    ret

; ========================================
; FUNCTION: PROCESS SDR DATA (TDOA)
; ========================================
process_sdr_tdoa:
    lea rdi, sdr_buffer
    ; Compute TDOA based on signal arrival times
    ret

; ========================================
; FUNCTION: CALCULATE POSITION (MULTILATERATION)
; ========================================
calculate_position:
    fld dword [gps_x]     ; Load GPS latitude
    fadd dword [bt_rssi]  ; Add RSSI-based estimate
    fadd dword [sdr_tdoa] ; Add SDR TDOA-based estimate
    fstp dword [estimated_x]

    fld dword [gps_y]     ; Load GPS longitude
    fadd dword [bt_rssi]  ; Add RSSI-based estimate
    fadd dword [sdr_tdoa] ; Add SDR TDOA-based estimate
    fstp dword [estimated_y]

    ret
