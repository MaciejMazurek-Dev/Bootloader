;**************************************
;   Bootloader
;   Stage 1
;**************************************

bits 16                                     ; Set 16-bit real mode
org 0x7c00                                  ; BIOS loads the bootloader at physical address 0x7C00

                                            ; Offset:
jmp main                                    ; 0x01 - Jump over BPB to executable code
nop                                         ; 0x02 - NOP padding to ensure BPB starts at offset 0x03

;****************************************
;   BIOS PARAMETER BLOCK (BPB)
;
;   Disk: 32MB
;   33 554 432 bytes
;   65 536 sectors 
;****************************************
                                            ; Offset:
bpb_oem_identifier db "MSWIN4.1"            ; 0x03 - OEM Identifier
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

ebpb_drive_number db 0                      ; 0x24
ebpb_flags db 0                             ; 0x25
ebpb_extended_boot_signature db 0x29        ; 0x26
ebpb_volume_id_serial_number dd 0x09090909  ; 0x27
ebpb_volume_label db "Hard disk  "          ; 0x2b - String size must be 11 bytes
ebpb_file_system_identifier db "FAT16   "   ; 0x36 - String size must be 8 bytes


;-----------------------------------
; Constants
;-----------------------------------
STAGE2_ADDRESS equ 0x7e00                   ; Memory address where Stage 2 will be loaded



;*******************************
; ENTRY POINT
;*******************************
main:                                       
mov [ebpb_drive_number], dl                 ; Save the drive number passed by BIOS in DL

;--------------------------
; Setup stack
;--------------------------
cli                                         ; Disable interrupts during stack setup
xor ax, ax
mov ss, ax                                  ; Set register SS to 0
mov sp, 0xffff                              ; Stack memory address SS:SP | 0:FFFF
sti                                         ; Re-enable interrupts

;-----------------------
; Display message
;-----------------------
xor ax, ax
mov es, ax                                  ; Set ES to 0 for string pointer 
mov bp, message                             ; String pointer ES:BP                              
mov ah, 0x13                                ; BIOS interrupt: Write String
mov al, 0x01                                ; Move cursor after text
mov bh, 0                                   ; Page number
mov bl, 0x0f                                ; White text
mov cx, MESSAGE_LENGTH                      ; String length
mov dh, 0x0d                                ; Row
mov dl, 0x0a                                ; Column
int 0x10                                    ; 

;--------------------------------------------------------
; Load Stage 2 from disk
;--------------------------------------------------------

; Find the address of root directory table
; (number of file allocation tables * sectors per file allocation table) + reserved sectors
xor ax, ax
mov al, [bpb_file_allocation_tables]        ; I use AL because source is a byte 
mov bx, [bpb_sectors_per_fat]
mul bx
mov cx,ax
add cx, [bpb_reserved_sectors]


; Find the size of root directory table
; (number of root directory entries * 32 bytes per entry) / bytes per sector
mov ax, bpb_root_directory_entries
mov bx, 32
mul bx
mov bx, [bpb_bytes_per_sector]
div bx



;mov ax, STAGE2_ADDRESS             ; Write data from disk into memory (ES:BX)
;mov es, ax
;xor bx, bx
;
;read_disk:
;mov ah, 0x02                           ; Function 0x02
;mov al, 0x01                           ; Number of sectors to read
;mov ch, 0                              ; Cylinder number
;mov cl,    0x02                            ; Sector number
;mov dh, 0                              ; Head number
;mov dl, [ebpb_drive_number]                ; Drive number
;int 0x13                               ; 
;jc read_disk
;jmp 0x1000:0

; Halt system
cli
hlt


;-----------------------------------------------------------------------
message db "Bootloader - Stage 1"           ; String to be displayed
MESSAGE_LENGTH equ ($ - message)            ; Length of the message

times (510 - ($ - $$)) db 0                 ; Pad with zeros up to byte 510
dw 0xaa55                                   ; Boot signature 

