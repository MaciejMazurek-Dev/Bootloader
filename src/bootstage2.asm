;*********************************
;
;	Bootloader
;				Stage 2
;
;*********************************

bits 16

jmp main

message db "Bootloader Stage 2"
MESSAGE_LENGTH equ $ - message


main:

;-------------------------
; Display message
;-------------------------
xor ax, ax
mov es, ax
mov bp, message
mov ah, 13
mov al, 1
mov bh, 0
mov bl, 15
mov cx, MESSAGE_LENGTH
mov dh, 12
mov dl, 10
int 0x10


cli
hlt
