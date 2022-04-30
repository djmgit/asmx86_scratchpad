; Compile with: nasm -f elf <file_name>.asm
; Link with (64 bit systems require elf_i386 option): ld -m elf_i386 <file_name>.o -o <file_name>
; Run with: ./<file_name>

; This code implements word reversal via swapping
; We maintain pointers to start and end of the string
; and keep swapping the characters in memory.
; Inline doc yet to be improved.
 
SECTION .data
msg1    db      'elephant', 0h          ; NOTE the null terminating byte
 
SECTION .text
global  _start
 
_start:
 
    mov     eax, msg1
    call    reverse_word
 
    call    quit

;----------------------------------------------

reverse_word:
    push edx
    push ecx
    push ebx
    push eax
    mov ebx, eax
.nextchar:
    cmp byte[eax], 0
    jz .reverse_util
    inc eax
    jmp .nextchar

.reverse_util:
    push eax
    dec eax
.reverse:
    mov cl, byte [ebx]
    mov dl, byte [eax]
    mov [eax], cl
    mov [ebx], dl
    dec eax
    inc ebx
    cmp ebx, eax
    jg .reversal_finished
    jmp .reverse

.reversal_finished:
    pop eax
    pop ebx

.print_word:
    sub eax, ebx
    mov edx, eax
    mov ecx, ebx
    mov ebx, 1
    mov eax, 4
    int 80h

    mov eax, 0Ah
    push eax
    mov edx, 1
    mov ecx, esp
    mov ebx, 1
    mov eax, 4
    int 80h

.restore_registers:
    pop eax
    mov eax, ebx
    pop ebx
    pop ecx
    pop edx

    ret

quit:
    mov     ebx, 0
    mov     eax, 1
    int     80h
    ret
