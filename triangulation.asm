section .data
    gps_device db "/dev/serial0", 0   ; UART GPS module
    bt_command db "hcitool rssi AA:BB:CC:DD:EE:FF", 0   ; Bluetooth RSSI command
    sdr_command db "rtl_sdr -f 915000000 -s 2.4e6 -g 20", 0   ; SDR command (915 MHz)
    
    gps_buffer resb 256  ; Buffer for GPS NMEA sentences
    bt_buffer resb 64    ; Buffer for Bluetooth RSSI data
    sdr_buffer resb 1024 ; Buffer for SDR signal data

    speed_of_light dd 299792458.0
    estimated_x dd 0.0
    estimated_y dd 0.0

section .bss
    gps_x resd 1  ; GPS latitude
    gps_y resd 1  ; GPS longitude
    bt_rssi resd 1  ; Bluetooth RSSI value
    sdr_tdoa resd 1  ; TDOA from SDR

section .text
    global _start
    extern printf
    extern system  ; Used for calling system commands

_start:
    ; ===============================
    ; 1. READ GPS DATA (UART)
    ; ===============================
    mov rdi, gps_device
    mov rsi, gps_buffer
    mov rdx, 256
    call read_gps_data

    ; Parse GPS coordinates
    lea rsi, gps_buffer
    call parse_gps

    ; ===============================
    ; 2. FETCH BLUETOOTH RSSI
    ; ===============================
    mov rdi, bt_command
    mov rsi, bt_buffer
    mov rdx, 64
    call execute_shell_command

    ; Parse RSSI value
    lea rsi, bt_buffer
    call parse_rssi

    ; ===============================
    ; 3. PROCESS SDR DATA (TDOA/AoA)
    ; ===============================
    mov rdi, sdr_command
    mov rsi, sdr_buffer
    mov rdx, 1024
    call execute_shell_command

    ; Process TDOA from SDR
    lea rsi, sdr_buffer
    call process_sdr_tdoa

    ; ===============================
    ; 4. COMPUTE POSITION (MULTILATERATION)
    ; ===============================
    call calculate_position

    ; ===============================
    ; 5. EXIT
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
