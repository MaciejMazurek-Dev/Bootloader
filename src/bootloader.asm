BITS 16							; Generate code to run on a processor operating in 16-bit mode
ORG 0x7C00						; Origin

message DB "Bootloader"
message_length equ ($ - message)


MOV AH, 0x13					; Function 0x13, interrupt 0x10
MOV AL, 1						; Move cursor after writing
MOV BH, 0						; Page number
MOV BL, 0x0F					; White color
MOV CX, message_length			;
MOV DH, 0x0D					; Row
MOV DL, 0x0A					; Column
MOV BP, message					; String address
INT 0x10


TIMES (510 - ($ - $$)) DB 0		; 
DB 0x55							; Boot signature (byte offset 510)
DB 0xAA							; Boot signature (byte offset 511)