; Compile with: nasm -f elf <file_name>.asm
; Link with (64 bit systems require elf_i386 option): ld -m elf_i386 <file_name>.o -o <file_name>
; Run with: ./<file_name>

; Reads a file byte by byte and prints it to stdout
; WIP
 
SECTION .text
global  _start
 
_start:
 
    mov     eax, file_name   ; move address of msg1 to eax
    call    read_file    ; call reveral routine
 
    call    quit    ; quit program

;----------------------------------------------

read_file:
    push eax
    ;push ecx
    ;push ebx
    ;push edx
    ;mov edx, eax
    mov ecx, 0
    mov ebx, eax
    mov eax, 5
    int 80h
    mov [fd_in], eax
    ;push ecx
    mov [bytecount], dword 0h

.set_seek_offset:
    ;pop ecx
    mov edx, 0
    mov ecx, [bytecount]
    mov ebx, [fd_in]
    mov eax, 19
    int 80h
    ;push ecx

.read_byte:
    mov edx, 1
    mov ecx, content
    mov ebx, [fd_in]
    mov eax, 3
    int 80h

    add dword[bytecount], eax


.print_byte:
    mov edx, 1
    mov ecx, content
    mov ebx, 1
    mov eax, 4
    int 80h

;.print_newline:
    ;mov eax, 0Ah
    ;push eax
    ;mov edx, 1
    ;mov ecx, esp
    ;mov ebx, 1
    ;mov eax, 4
    ;int 80h

    ;pop eax
    jmp .set_seek_offset

.close_file:
    mov ebx, [fd_in]
    mov eax, 6
    int 80h

.finshed:
    pop eax
    pop eax
    ret

; routine to quit the program
quit:
    mov     ebx, 0
    mov     eax, 1
    int     80h
    ret

SECTION .data
file_name db 'test_file.txt'

SECTION .bss
fd_in resd 1
content resb 1
bytecount resd 1
