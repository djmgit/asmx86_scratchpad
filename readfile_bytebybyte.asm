; Compile with: nasm -f elf <file_name>.asm
; Link with (64 bit systems require elf_i386 option): ld -m elf_i386 <file_name>.o -o <file_name>
; Run with: ./<file_name>

; Read a file byte by byte and print to stdout
 
SECTION .data
msg1    db      'Hello world from ASM X86 powered by NASM', 0h          ; NOTE the null terminating byte
 
SECTION .text
global  _start
 
_start:
 
    mov     eax, msg1
    call    wtokenize
 
    call    quit

;----------------------------------------------
; void wtokenise(String message)
; Function to space split a string and print each word in a new line.
wtokenize:
    push edx
    push ecx
    push ebx
    push eax
    mov ebx, eax
.nextchar:

    ; parse the string, if we encounter whitespace (hex 20h) then we have found the end of the current word
    cmp byte [eax], 20h
    jz .newword
    cmp byte [eax], 0
    jz .newword
    inc eax
    jmp .nextchar

.newword:

    ; store start and end of the previous word in stack
    push eax    ; eax = end + 1 of the previous word
    push ebx    ; ebx = start of the previous word
    sub eax, ebx    ; store length of the word in eax

.printword:
    mov edx, eax    ; store length of word in edx
    mov ecx, ebx    ; store start position (address) of the string in ecx
    mov ebx, 1      ; 1 is std output
    mov eax, 4      ; 4 is the syscall number for write syscall
    int 80h         ; call syscall handler

    ; print a new line
    mov eax, 0Ah    ; mov 0Ah (new line in hex) to eax
    push eax        ; save eax on stack
    mov edx, 1      ; store 1 in edx, because thats the length of the string (newline) we are going to print
    mov ecx, esp    ; move starting postion (address) of the string to ecx which is basically stack pointer
    mov ebx, 1      ; move std out to ebx
    mov eax, 4      ; same as before
    int 80h         
    
    pop eax         ; pop eax once to get rid of the 0Ah from stack
    pop ebx         ; restore the start of the previous word in ebx
    pop eax         ; retsore the end of the previous word in eax
    cmp byte[eax], 0
    jz .finished

.bypass_all_whitespaces:
    inc eax         ; increment eax to point to the beginning of the next word
    cmp byte[eax], 20h  ; check if next byte is whitespace as well, if so we need to skip it
    jz .bypass_all_whitespaces
    mov ebx, eax    ; set ebx to start of the next word
    jmp .nextchar   ; repeat the parsing process

.finished:

    ; restore the early state of all the registers we used
    pop eax         
    pop ebx
    pop ecx
    pop edx
    ret

quit:
    mov     ebx, 0
    mov     eax, 1
    int     80h
    ret
