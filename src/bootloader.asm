;**************************************
;
;	Bootloader
;				Stage 1
;
;**************************************



bits 16									; Generate code to run on a processor operating in 16-bit mode
org 0x7c00								; Load this code into memory starting from address 0x7C00


jmp main								; Jump over BPB
nop										; 

;*************************
;*	BIOS PARAMETER BLOCK *
;*************************
										; Offset
oem_identifier db "MSWIN4.1"			; 0x03	
bytes_per_sector dw 512					; 0x0b
sectors_per_cluster db 1				; 0x0d
reserved_sectors dw 1					; 0x0e
file_allocation_tables db 2				; 0x10
root_directory_entries dw 512			; 0x11 - How many files/folders we can create in root directory
total_sectors dw 0						; 0x13
media_descriptor db 0xf8				; 0x15 - Hard drive
sectors_per_fat dw 18					; 0x16
sectors_per_track dw 32					; 0x18
heads_per_cylinder dw					; 0x1a
hidden_sectors dw 0						; 0x1c
large_sector dd 131070					; 0x20

;**************************
;*  EXTENDED BOOT RECORD  *
;**************************

drive_number db 0						; 0x24
flags db 0								; 0x25
extended_boot_signature db 0x29			; 0x26


message db "Bootloader - Stage 1"		; String to be displayed
message_length equ ($ - message)		; Length of the string

drive_number db 

main:
mov drive_number, dl					; Get current drive number

display_mssage:
		mov ah, 0x13					; Function 0x13
		mov al, 0x01					; Move cursor after writing
		mov bh, 0						; Page number
		mov bl, 0x0f					; White color
		mov cx, message_length			; String length
		mov dh, [0x0d]					; Row
		mov dl, 0x0a					; Column
		mov bp, message					; String address
		int 0x10						; 

read_disk:
mov ax, 0x1000							; Write data from disk into memory address 0x1000 (ES:BX)
mov es, ax
xor bx, bx

	.read
	mov ah, 0x02						; Function 0x02
	mov al, 0x01						; Number of sectors to read
	mov ch, 0							; Cylinder number
	mov cl,	0x02						; Sector number
	mov dh, 0							; Head number
	mov dl, [drive_number]				; Drive number
	int 0x13							; Read data from disk
	jc	.read
	jmp 0x1000:0	


times (510 - ($ - $$)) db 0				; Pade with zeroes until we get 510 byte in size.
db 0x55									; Boot signature (byte offset 510)
db 0xaa									; Boot signature (byte offset 511)