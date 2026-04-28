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



cli
hlt
