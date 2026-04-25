;**************************************
;
;	Bootloader
;				Stage 1
;
;**************************************

bits 16										; Generate code to run on a processor operating in 16-bit mode
org 0x7c00									; Load this code into memory starting from address 0x7C00


jmp MAIN									; Jump over BPB
nop											; 

;****************************************
;	BIOS PARAMETER BLOCK  
;****************************************
											; Offset
bpb_oem_identifier db "MSWIN4.1"			; 0x03	
bpb_bytes_per_sector dw 512					; 0x0b
bpb_sectors_per_cluster db 1				; 0x0d
bpb_reserved_sectors dw 1					; 0x0e
bpb_file_allocation_tables db 2				; 0x10
bpb_root_directory_entries dw 512			; 0x11 - How many files/folders we can create in root directory
bpb_total_sectors dw 0						; 0x13
bpb_media_descriptor db 0xf8				; 0x15 - Hard drive
bpb_sectors_per_fat dw 18					; 0x16
bpb_sectors_per_track dw 32					; 0x18
bpb_heads_per_cylinder dw 2					; 0x1a
bpb_hidden_sectors dw 0						; 0x1c
bpb_large_sector dd 131070					; 0x20


;*****************************************
;  EXTENDED BOOT RECORD  
;*****************************************

ebpb_drive_number db 0						; 0x24
ebpb_flags db 0								; 0x25
ebpb_extended_boot_signature db 0x29		; 0x26
ebpb_volume_id_serial_number dd 0			; 0x27
ebpb_volume_label db "Hard disk  "			; 0x2b - Must be 11 characters
ebpb_file_system_identifier db "FAT16   "	; 0x36 - Must be 8 characters


MAIN:										
mov [ebpb_drive_number], dl					; Save current drive number which is passed by BIOS via DL register

;--------------------------
; Create stack
;--------------------------
cli											; Clear interrupt flag
mov ax, 0x0000
mov ss, ax
mov sp, 0xffff								; Stack memory address SS:SP | 0:FFFF
sti											; Set interrupt flag


DISPLAY_MESSAGE:
mov ah, 0x13								; Function 0x13
mov al, 0x01								; Move cursor after writing
mov bh, 0									; Page number
mov bl, 0x0f								; White color
mov cx, message_length						; String length
mov dh, [0x0d]								; Row
mov dl, 0x0a								; Column
mov bp, message								; String address
int 0x10									; 


READ_DISK:
mov ax, 0x1000								; Write data from disk into memory address 0x1000 (ES:BX)
mov es, ax
xor bx, bx

	.READ:
	mov ah, 0x02							; Function 0x02
	mov al, 0x01							; Number of sectors to read
	mov ch, 0								; Cylinder number
	mov cl,	0x02							; Sector number
	mov dh, 0								; Head number
	mov dl, [ebpb_drive_number]				; Drive number
	int 0x13								; Read data from disk
	jc	.READ
	jmp 0x1000:0	


;-----------------------------------------------------------------------
message db "Bootloader - Stage 1"			; String to be displayed
message_length equ ($ - message)			; Length of the string

times (510 - ($ - $$)) db 0					; Pade with zeroes until we get 510 byte in size.
dw 0xaa55									; Boot signature 
