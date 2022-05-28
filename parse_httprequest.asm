; Compile with: nasm -f elf <file_name>.asm
; Link with (64 bit systems require elf_i386 option): ld -m elf_i386 <file_name>.o -o <file_name>
; Run with: ./<file_name>

; The objective of this code is to parse the first line of a http request like the following
;   GET /index.html HTTP/1.1
; We will assume for the sake of simplicity that the request is available in a memory location
; the object will be to extract all the pieces that is the method, path, protocol and version
; and print them in different lines with proper label, something like this:
;   HTTP METHOD : GET
;   HTTP PATH : /index
;   PROTOCOL : HTTP
;   HTTP VERSION : 1.1
; the extracted parts will be stored in their own memry locations

; sys_write_macro
; we will be using this macro whenever we want to print something to stdout
; Usage : sys_write <memory_location_of_content>, <number_of_bytes_to_print>
%macro sys_write_string 2
    push edx                                ; save edx, ecx, ebx and eax on stack as usual
    push ecx
    push ebx
    push eax
    mov edx, %2                             ; put the second arg that is length of string in edx
    mov ecx, %1                             ; put the memory location of the content in ecx
    mov ebx, 1                              ; stdout
    mov eax, 4                              ; syscall number for write syscall
    int 80h                                 ; invoke the kernel
    pop eax                                 ; restore eax, ebx, ecx, edx
    pop ebx
    pop ecx
    pop edx
%endmacro

SECTION .text
global  _start
 
_start:

    call    process_request                 ; call process_request routine
    call    quit                            ; quit program

; this is a tiny routine to calculate the length of a string
strlen:
    push ebx                                ; store ebx and eax on stack
    push eax
    mov ebx, eax                            ; make ebx store value of eax which will basically be the memory location of the content
.loop_strlen_start:                 
    cmp byte [eax], 0                       ; compare current byte with 0
    jz  .loop_strlen_end                    ; if yes then end loop
    inc eax                                 ; go to next byte
    jmp .loop_strlen_start                  ; loop
.loop_strlen_end:
    sub eax, ebx                            ; now eax should point to the end of the string, subtracting ebx from eax should give the length of the string
    pop ebx                                 ; flush both ebx and eax values from stack, however eax will contain the string length
    pop ebx
    ret                                     ; return

; routine to process the request
process_request:

    mov eax, request                        ; mov the memory location of request to eax, we will be looping over this string byte by byte

.process_http_request:

    mov edx, http_method                    ; mov the memory location of the http_method variable to edx

; some insights on what we are doing:
;
; we know that the method, path and protcol/version is separated by single whitespace
; So first encounter with whitespace means the end of http_method, the second means the
; end of the path.
;
; Next we need to deal with procol/version pair so we start looking for '/'. The encounter of
; '/' means the end of the protocol and finally the encounter if 0 means the end or the end of
; the version.
;
; As we loop byte by byte we keep copying those bytes to byte locations of respective variables. 
.parse_http_method:
    cmp byte [eax], 20h                     ; check for white space
    jz .process_http_path                   ; if white space then we are done with method, start with path
    mov cl, byte [eax]                      ; move a byte from memory to cl
    mov byte [edx], cl                      ; move the content of cl to a byte location in our method variable's memory location
    inc edx                                 ; increment edx
    inc eax                                 ; increment eax
    jmp .parse_http_method                  ; loop back

.process_http_path:                     

    mov byte [edx], 0                       ; before we begin with path processing, add 0 to the end of method to mark string termination
    mov edx, http_path                      ; just like before move http_path variable's memory location to edx
    inc eax                                 ; increment eax, because right now we are on a white space.

.parse_http_path:

    cmp byte [eax], 20h                     ; same as before, check for a white space
    jz .process_protocol                    ; if white space found, then we are done with path, jump to protocol processing
    mov cl, byte [eax]                      ; move a byte from memory location of the request pointed by eax to cl
    mov byte [edx], cl                      ; move the byte from cl to the path variable memory location
    inc edx                                 ; increment edx
    inc eax                                 ; increment eax
    jmp .parse_http_path                    ; loop back

.process_protocol:

    mov byte [edx], 0                       ; as earlier we terminate path string with a 0
    mov edx, http_protocol                  ; start with protocol parsing by moving the variable location to edx
    inc eax                                 ; we are on whitespace so increment eax

.parse_protocol:

    cmp byte [eax], 2Fh                     ; this time we check for 2Fh which is the hex equivalent of '/'
    jz .process_version                     ; if '/' found then start with version procesing
    mov cl, byte [eax]                      ; same as before move a byte from memory location pointed by eax, to cl
    mov byte [edx], cl                      ; move that byte from cl to memory location pointed by edx
    inc edx                                 ; increment edx
    inc eax                                 ; increment eax
    jmp .parse_protocol                     ; loop back

.process_version:
    mov byte [edx], 0                       ; 0 terminate protocol
    mov edx, http_version                   ; mov http_version variable location to eax
    inc eax                                 ; increment eax

.parse_version:

    cmp byte [eax], 0                       ; this time we compare with 0, since there is nothing after the protocol version
    jz .display                             ; if 0 found then start with display
    mov cl, byte [eax]                      ; move the content from memory to cl
    mov byte [edx], cl                      ; move from cl to memory location pointed by edx
    inc edx                                 ; increment edx
    inc eax                                 ; increment eax
    jmp .parse_version                      ; loop back

.display:
    mov byte [edx], 0                       ; before starting with actual display, 0 terminate version

    sys_write_string method_label, method_label_len             ; display the http method lable using our macro
    mov eax, http_method                                        ; move memmory locatio of http_method variable to eax, for length calculation
    call strlen                                                 ; we get back the lenght in eax
    sys_write_string http_method, eax                           ; print it using our macro
    sys_write_string new_line, 1                                ; print a new line
    sys_write_string path_label, path_label_len                 ; display label for http_path
    mov eax, http_path                                          ; calculate length of http_path
    call strlen
    sys_write_string http_path, eax                             ; print path
    sys_write_string new_line, 1                                ; print new line
    sys_write_string protocol_label, protocol_label_len         ; display label for protocol
    mov eax, http_protocol                                      ; calculate the length of the protocol variable
    call strlen
    sys_write_string http_protocol, eax                         ; display the protocol
    sys_write_string new_line, 1                                ; print new line
    sys_write_string version_label, version_label_len           ; display version label
    mov eax, http_version                                       ; calculate length of version
    call strlen
    sys_write_string http_version, eax                          ; print the version
    sys_write_string new_line, 1                                ; print new line
    ret                                                         ; return from the method


; routine to quit the program
quit:
    mov     ebx, 0
    mov     eax, 1
    int     80h
    ret

; we diefine all our known data here
SECTION .data
request db 'GET /index HTTP/1.1', 0h
method_label db 'HTTP METHOD : ', 0h
method_label_len equ $-method_label
path_label db 'HTTP PATH : ', 0h
path_label_len equ $-path_label
protocol_label db 'PROTOCOL : ', 0h
protocol_label_len equ $-protocol_label
version_label db 'HTTP VERSION : ', 00h
version_label_len equ $-version_label
new_line db 0Ah
white_space db 20h

; all the uninitialised variables are defined here.
SECTION .bss            
byte_read resb 1
http_method resb 10
http_path resb 255
http_protocol resb 10
http_version resb 3
