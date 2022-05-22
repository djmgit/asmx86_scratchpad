; Compile with: nasm -f elf <file_name>.asm
; Link with (64 bit systems require elf_i386 option): ld -m elf_i386 <file_name>.o -o <file_name>
; Run with: ./<file_name>

; This code reads a file byte by byte and prints it to stdout
 
SECTION .text
global  _start
 
_start:
 
    mov     eax, file_name   ; move adress of file_name to eax
    call    read_file    ; call readfile routine
    call    quit    ; quit program

;----------------------------------------------

read_file:
    push eax                                ; save eax for later restore
    mov ecx, 0                              ; open file in readonly mode
    mov ebx, eax                            ; put file_name address in ebx
    mov eax, 5                              ; move sys_call number of sys_open to eax
    int 80h                                 ; invoke kernal
    mov [fd_in], eax                        ; move the file descriptor to memory
    mov [bytecount], dword 0h               ; initialise bytecount with 0

.set_seek_offset:
    mov edx, 0                              ; We want to read the file from the start, hence 0
    mov ecx, [bytecount]                    ; the offeset from which we want to read
    mov ebx, [fd_in]                        ; The file descriptor
    mov eax, 19                             ; put the sys_call number for sys_lseek in eax
    int 80h                                 ; invoke kernel

.read_byte:
    mov edx, 1                              ; we want to read only 1 byte
    mov ecx, content                        ; the memory location where we want to store the read byte
    mov ebx, [fd_in]                        ; move file descriptor from memory to ebx
    mov eax, 3                              ; move sys_call number for sys_read in eax
    int 80h                                 ; invoke kernel

.eof_check:

    ; we need to check if we have reached eof. That is on further increasing lseek's offset,
    ; read syscall will return error code.
    cmp eax, 0                              ; check if we have non positive integer in eax  
    je .close_file                          ; if yes, then jump to .close_file and end
    add dword[bytecount], eax               ; otherwise increment bytecount with number of bytes read which should be 1 in our case

.print_byte:                                
    mov edx, 1                              ; we want to print only 1 byte
    mov ecx, content                        ; move memory location of content in ecx
    mov ebx, 1                              ; we want to print to stdout
    mov eax, 4                              ; move sys call number for sys_write in eax
    int 80h                                 ; invoke kernel
    jmp .set_seek_offset                    ; loop

.close_file:                                
    mov ebx, [fd_in]                        ; move file descriptor to ebx
    mov eax, 6                              ; move sys_call number for sys_close to eax
    int 80h                                 ; invoke kernel

.finshed:
    pop eax                                 ; restore eax
    ret                                     ; return from function

; routine to quit the program
quit:
    mov     ebx, 0
    mov     eax, 1
    int     80h
    ret

SECTION .data
file_name db 'test_file.txt'                ; memory variable from name of the file

SECTION .bss            
fd_in resd 1                                ; varibale from file descriptor
content resb 1                              ; variable from content
bytecount resd 1                            ; variable for bytecount
