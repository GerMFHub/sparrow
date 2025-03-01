section .data
    triangulation_data db "triangulation_data", 0 ; Simuliuojamas trianguliacijos modulio failas
    aes_key db "1234567890ABCDEF1234567890ABCDEF"  ; 32 baitų AES-256 raktas
    comm_buffer resb 256  ; Buferis išsiunčiamiems/gautiems duomenims
    ground_control_ip db "192.168.1.100", 0  ; GCS IP adresas
    lora_device db "/dev/ttyS0", 0  ; LoRa įrenginio nuoroda
    bt_device db "hci0", 0  ; Bluetooth interfeisas

section .bss
    drone_position resb 64  ; Drąno pozicija
    source_position resb 64  ; Signalo šaltinio pozicija
    encrypted_data resb 256  ; Užšifruoti duomenys

section .text
    global _start
    extern triangulation_get_data  ; Funkcija iš triangulation.asm
    extern aes_encrypt, aes_decrypt  ; AES šifravimo funkcijos
    extern send_tcp_packet, recv_tcp_packet  ; TCP funkcijos
    extern send_udp_packet, recv_udp_packet  ; UDP funkcijos
    extern send_lora_packet, recv_lora_packet  ; LoRa funkcijos
    extern send_bt_packet, recv_bt_packet  ; Bluetooth funkcijos

_start:
    ; ==========================
    ; 1. GAUTI TRIANGULIACIJOS DUOMENIS
    ; ==========================
    mov rdi, triangulation_data
    lea rsi, source_position
    lea rdx, drone_position
    call triangulation_get_data  ; Gauti buvimo vietos duomenis

    ; ==========================
    ; 2. ŠIFRUOTI DUOMENIS PRIEŠ SIUNTIMĄ
    ; ==========================
    lea rdi, drone_position  ; Šifruojamas pranešimas
    lea rsi, encrypted_data  ; Saugojimo vieta
    lea rdx, aes_key         ; AES-256 raktas
    call aes_encrypt         ; Šifruoti duomenis

    ; ==========================
    ; 3. IŠSIŲSTI DUOMENIS GROUND CONTROL STATION (TCP)
    ; ==========================
    lea rdi, ground_control_ip  ; GCS IP adresas
    lea rsi, encrypted_data     ; Siunčiami duomenys
    mov rdx, 256                ; Duomenų dydis
    call send_tcp_packet        ; Siųsti užšifruotą paketą per TCP

    ; ==========================
    ; 4. SIŲSTI DUOMENIS KITIEMS DRONAMS PER LORA
    ; ==========================
    lea rdi, lora_device  ; LoRa įrenginys
    lea rsi, encrypted_data  ; Užšifruoti duomenys
    mov rdx, 256  ; Dydis
    call send_lora_packet  ; Siųsti per LoRa

    ; ==========================
    ; 5. SIŲSTI DUOMENIS ARTIMIEMS DRONAMS PER BLUETOOTH
    ; ==========================
    lea rdi, bt_device  ; Bluetooth interfeisas
    lea rsi, encrypted_data  ; Užšifruoti duomenys
    mov rdx, 256  ; Dydis
    call send_bt_packet  ; Siųsti per Bluetooth

    ; ==========================
    ; 6. GAUTI DUOMENIS IŠ KITŲ DRONŲ PER LORA
    ; ==========================
    lea rdi, comm_buffer  ; Buferis priimamam pranešimui
    mov rsi, 256  ; Maksimalus dydis
    call recv_lora_packet  ; Gauti paketą per LoRa

    ; ==========================
    ; 7. GAUTI DUOMENIS IŠ ARTIMŲ DRONŲ PER BLUETOOTH
    ; ==========================
    lea rdi, comm_buffer  ; Buferis priimamam pranešimui
    mov rsi, 256  ; Maksimalus dydis
    call recv_bt_packet  ; Gauti paketą per Bluetooth

    ; ==========================
    ; 8. GAUTI DUOMENIS IŠ GROUND CONTROL STATION (UDP)
    ; ==========================
    lea rdi, comm_buffer  ; Buferis priimamam pranešimui
    mov rsi, 256  ; Maksimalus dydis
    call recv_udp_packet  ; Gauti paketą per UDP

    ; ==========================
    ; 9. IŠŠIFRUOTI GAUTUS DUOMENIS
    ; ==========================
    lea rdi, comm_buffer  ; Gautas užšifruotas pranešimas
    lea rsi, drone_position  ; Iššifruoti į šią vietą
    lea rdx, aes_key         ; AES-256 raktas
    call aes_decrypt         ; Iššifruoti duomenis

    ; ==========================
    ; 10. ATVYKUSIUS DUOMENIS PANAUDOTI NAVIGACIJOJE
    ; ==========================
    ; Čia galima būtų įdėti papildomą navigacijos algoritmą

    ; ==========================
    ; 11. UŽBAIGTI PROGRAMĄ
    ; ==========================
    mov eax, 60  ; sys_exit syscall numeris
    xor edi, edi
    syscall
