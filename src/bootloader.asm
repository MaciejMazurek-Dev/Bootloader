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
;					
;	Disk 32MB
;	33 554 432 bytes
;	65 536 sectors 
;****************************************
											; Offset
bpb_oem_identifier db "MSWIN4.1"			; 0x03 - By official FAT Specification this value is meaningless (apparentlly)
bpb_bytes_per_sector dw 512					; 0x0b - 512 is a standard value
bpb_sectors_per_cluster db 1				; 0x0d
bpb_reserved_sectors dw 1					; 0x0e - The value is 1 because we are reserving only one sector ( 512 bytes ) for our stage 1 bootloader
bpb_file_allocation_tables db 2				; 0x10 - First fat is the main one, the second is backup copy
bpb_root_directory_entries dw 512			; 0x11 - Number of files/folders we can create in root directory
bpb_total_sectors dw 0						; 0x13 - The value is 0 if disk/partition have more than 65535 sectors
bpb_media_descriptor db 0xf8				; 0x15 - Is it a hard drive a floppy or whatever? 
bpb_sectors_per_fat dw 256					; 0x16
bpb_sectors_per_track dw 32					; 0x18
bpb_heads_per_cylinder dw 1024				; 0x1a
bpb_hidden_sectors dd 0						; 0x1c
bpb_large_sector dd 65536					; 0x20 - Total number of sectors on disk (This field is used if there is more than 65535 sectors on disk)


;*****************************************
;  EXTENDED BOOT RECORD  
;*****************************************

ebpb_drive_number db 0						; 0x24
ebpb_flags db 0								; 0x25
ebpb_extended_boot_signature db 0x29		; 0x26
ebpb_volume_id_serial_number dd 0x09090909	; 0x27
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
xor ax, ax
mov es, ax									; Set register ES to 0 
mov bp, message								; String address ES:BP								
mov ah, 0x13								; Function 0x13
mov al, 0x01								; Move cursor after writing
mov bh, 0									; Page number
mov bl, 0x0f								; White color
mov cx, message_length						; String length
mov dh, 0x0d								; Row
mov dl, 0x0a								; Column
int 0x10									; 


;READ_DISK:
;mov ax, 0x1000								; Write data from disk into memory address 0x1000 (ES:BX)
;mov es, ax
;xor bx, bx
;
;	.READ:
;	mov ah, 0x02							; Function 0x02
;	mov al, 0x01							; Number of sectors to read
;	mov ch, 0								; Cylinder number
;	mov cl,	0x02							; Sector number
;	mov dh, 0								; Head number
;	mov dl, [ebpb_drive_number]				; Drive number
;	int 0x13								; Read data from disk
;	jc	.READ
;	jmp 0x1000:0	
cli
hlt

;-----------------------------------------------------------------------
message db "Bootloader - Stage 1"			; String to be displayed
message_length equ ($ - message)			; Length of the string

times (510 - ($ - $$)) db 0					; Pade with zeroes until we get 510 byte in size.
dw 0xaa55									; Boot signature 
