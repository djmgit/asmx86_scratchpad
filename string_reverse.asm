; Compile with: nasm -f elf <file_name>.asm
; Link with (64 bit systems require elf_i386 option): ld -m elf_i386 <file_name>.o -o <file_name>
; Run with: ./<file_name>

; This code uses a swapping logic to reverse a word and print it
 
SECTION .data
msg1    db      'matrix', 0h          ; NOTE the null terminating byte
 
SECTION .text
global  _start
 
_start:
 
    mov     eax, msg1   ; move address of msg1 to eax
    call    reverse_word    ; call reveral routine
 
    call    quit    ; quit program

;----------------------------------------------

reverse_word:
    push edx    ; save state of all the registers we are going to use
    push ecx
    push ebx
    push eax
    mov ebx, eax    ; move the starting address of our string to ebx as well

; in the below loop, we are trying to reach the end of the string
.nextchar:
    cmp byte[eax], 0    ; if  we are at the end, start with revrsal
    jz .reverse_util    ; jump to reversal
    inc eax             ; increment eax
    jmp .nextchar       ; loop back

.reverse_util:
    push eax            ; save eax on stack, we are storing the end of the string (with null) on stack
    dec eax             ; reduce eax by one, now we have the location of the las byte/character of the string in eax

; we now have two pointers
; ebx: contains location of the first character of the string
; eax: contains location of the last character of the string
; the idea is to continuously swap the characters inplace in memory refered to by
; the locations in ebx and eax and in each cycle we move one character forward and
; one character backward by incrementing ebx and decrementing eax
; When ebx becomes greater than eax, we are done.
.reverse:
    mov cl, byte [ebx]          ; move char at [ebx] to cl
    mov dl, byte [eax]          ; move char at [eax] to dl
    mov [eax], cl               ; swap
    mov [ebx], dl               ; swap
    dec eax                     ; come one character backward
    inc ebx                     ; go one character forward
    cmp ebx, eax                ; check if we have hit base case which is ebx > eax
    jg .reversal_finished       ; if so then we are done, time to print
    jmp .reverse                ; else continue

.reversal_finished:
    pop eax                     ; get back the address of actual string end with null
    pop ebx                     ; get back the address of the start of the string

.print_word:
    sub eax, ebx                ; get the length of the string for printing
    mov edx, eax                ; store lenght of the string in edx for printing
    mov ecx, ebx                ; store the starting of the string in ecx
    mov ebx, 1                  ; we want to output to std output
    mov eax, 4                  ; syscall for sys_write
    int 80h                     ; call syscall interrupt

    mov eax, 0Ah                ; repeat the above steps for printing a new line
    push eax
    mov edx, 1
    mov ecx, esp
    mov ebx, 1
    mov eax, 4
    int 80h

.restore_registers:             ; restore all the registers to prior state
    pop eax
    mov eax, ebx
    pop ebx
    pop ecx
    pop edx

    ret                         ; return

; routine to quit the program
quit:
    mov     ebx, 0
    mov     eax, 1
    int     80h
    ret
