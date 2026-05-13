;**************************************
;   Bootloader
;   Stage 1
;**************************************

bits 16                                     ; Set 16-bit real mode
org 0x7c00                                  ; BIOS loads the bootloader at physical address 0x7C00

                                            ; Offset:
jmp MAIN                                    ; 0x01 - Jump over BPB to executable code
nop                                         ; 0x02 - NOP padding to ensure BPB starts at offset 0x03


;****************************************
;   BIOS PARAMETER BLOCK (BPB)
;
;   Disk: 32MB
;   33 554 432 bytes
;   65 536 sectors 
;****************************************
bpb_oem_identifier db "MMAZUREK"            ; 0x03 - OEM Identifier
bpb_bytes_per_sector dw 512                 ; 0x0b - Standard sector size
bpb_sectors_per_cluster db 1                ; 0x0d
bpb_reserved_sectors dw 1                   ; 0x0e - Usually 1 for the bootloader sector itself
bpb_file_allocation_tables db 2             ; 0x10 - First FAT is the main one, the second is backup copy
bpb_root_directory_entries dw 512           ; 0x11 - Max entries in the root directory
bpb_total_sectors dw 0                      ; 0x13 - 0 if the partition has more than 65535 sectors
bpb_media_descriptor db 0xf8                ; 0x15 - Type of media (hard drive, floppy etc.)
bpb_sectors_per_fat dw 256                  ; 0x16
bpb_sectors_per_track dw 32                 ; 0x18
bpb_heads_per_cylinder dw 1024              ; 0x1a
bpb_hidden_sectors dd 0                     ; 0x1c
bpb_large_sector dd 65536                   ; 0x20 - Used when total sectors exceed 65535


;*****************************************
;  EXTENDED BOOT RECORD  
;*****************************************
ebpb_drive_number db 0x00                   ; 0x24
ebpb_flags db 0x00                          ; 0x25
ebpb_extended_boot_signature db 0x29        ; 0x26
ebpb_volume_id_serial_number dd 0x09090909  ; 0x27
ebpb_volume_label db "Hard_diskMM"          ; 0x2b - String size must be 11 bytes
ebpb_file_system_identifier db "FAT16   "   ; 0x36 - String size must be 8 bytes


;************************************************************************************************
;   Device Address Packet (DAP)
;   Data structure used for LBA reading/writing
;************************************************************************************************
DAP:                                            ; Offset
dap_packet_size db 16                           ; 0     ; Size of DAP. Minimum 16 bytes
dap_reserved_1 db 0                             ; 1     ; Reserved. Always 0
dap_blocks_to_transfer db 0                     ; 2     ; Number of blocks (sectors) to transfer. Max value 127 (can more, check docs). 
dap_reserved_2 db 0                             ; 3     ; Reserved. Always 0
dap_host_buffer_addr dd STAGE_TWO_STARTING_ADDR                       ; 4     ; Address of HOST transfer buffer. Seg:Offset
dap_lba_addr dq 0                               ; 5     ; Starting LBA address on the target device.


;**************************************
; DATA
;**************************************

stage_one_message db "Bootloader - Stage 1"               
STAGE_ONE_MESSAGE_LEN equ ( $ - stage_one_message )           

;test_message db "Test message"
;TEST_MESSAGE_LEN equ ($- test_message)

disk_message db "Loading Bootloader Stage 2"
DISK_MESSAGE_LEN equ ($ - disk_message)

stage_two_load_message db "Stage 2 loaded successfully"
STAGE_TWO_LOAD_MESSAGE_LEN equ ( $ - stage_two_load_message )

stage_two_filename db "bootstage2"
STAGE_TWO_FILENAME_LEN equ ( $ - stage_two_filename )
stage_two_file_extension db "bin"
STAGE_TWO_FILE_EXTENSION_LEN equ ( $ - stage_two_file_extension )

; Load bootloader stage 2 under this address
STAGE_TWO_STARTING_ADDR equ 0x7E00        

; Row counter for PRINT STRING procedure
row_counter db 0x0c



;****************************** 
; PRINT STRING
;
; Register  |    Value
;-------------------------------
; CX        |    String length     
; BP        |    String address
;******************************
PRINT_STRING:
xor ax, ax
mov es, ax                                  ; Set ES to 0 for string pointer 
mov ah, 0x13                                ; Service number: Write String
mov al, 0x01                                ; Move cursor after text
mov bh, 0x00                                ; Page number
mov bl, 0x0f                                ; White text
mov dh, [row_counter]                       ; Row
inc [row_counter]                           ; Place next string on the new line
mov dl, 0x02                                ; Column
int 0x10  
ret                                         ; Return nothing



;############################################################################################
;
;       ENTRY POINT
;
;############################################################################################
MAIN:                                       
mov [ebpb_drive_number], dl                 ; Save the drive number passed by BIOS in DL

; Setup stack
cli                                         ; Disable interrupts during stack setup
xor ax, ax
mov ss, ax                                  ; Set register SS to 0
mov sp, 0x7C00                              ; Stack memory address SS:SP | 0:7C00
sti                                         ; Re-enable interrupts

; Welcome message
mov bp, stage_one_message                                                         
mov cx, STAGE_ONE_MESSAGE_LEN
call PRINT_STRING                                  


;*************************
; Load Bootloader Stage 2
;*************************

mov cx, DISK_MESSAGE_LEN 
mov bp, disk_message
call PRINT_STRING

; Calculate the starting address of root directory table
; (number of file allocation tables * sectors per file allocation table) + reserved sectors
xor ax, ax
xor bx, bx
mov al, BYTE [bpb_file_allocation_tables]
mov bx, WORD [bpb_sectors_per_fat]
mul bx
add ax, WORD [bpb_reserved_sectors]
mov [dap_lba_addr], ax

; Calculate the size of root directory table
; (number of root directory entries * 32 bytes per entry) / bytes per sector
xor ax, ax
xor bx, bx
mov ax, WORD [bpb_root_directory_entries]
mov bx, 32
mul bx
mov bx, WORD [bpb_bytes_per_sector]
div bx
mov [dap_blocks_to_transfer], al

LOAD_ROOT_DIRECTORY_TABLE:
mov ah, 0x42
mov dl, [ebpb_drive_number]
mov si, DAP
int 0x13
jc LOAD_ROOT_DIRECTORY_TABLE ; Carry Flag set = error, try again
mov cx, STAGE_TWO_LOAD_MESSAGE_LEN
mov bp, stage_two_load_message
call PRINT_STRING





cli
hlt

times (510 - ($ - $$)) db 0                 ; Pad with zeros up to byte 510
dw 0xaa55                                   ; Boot signature 