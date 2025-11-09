[org 0x7c00]
[bits 16]

start:
    xor ax, ax
    mov ds, ax
    mov ss, ax
    mov sp, 0x7c00
    mov ax, 0x0003
    int 0x10

    mov si, welcome
    call print
    call newline

main:
    mov si, prompt
    call print

    mov di, buffer
    call input

    call parse
    call newline
    jmp main

print:
    lodsb
    test al, al
    jz done
    mov ah, 0x0e
    int 0x10
    jmp print
done:
    ret

input:
    mov ah, 0
    int 0x16
    cmp al, 0x0d
    je input_done
    cmp al, 0x08
    je backspace
    stosb
    mov ah, 0x0e
    int 0x10
    jmp input

backspace:
    cmp di, buffer
    je input
    dec di
    mov al, 0x08
    mov ah, 0x0e
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 0x08
    int 0x10
    jmp input

input_done:
    mov al, 0
    stosb
    ret

newline:
    mov al, 0x0d
    mov ah, 0x0e
    int 0x10
    mov al, 0x0a
    mov ah, 0x0e
    int 0x10
    ret

parse:
    mov si, buffer
    call tolower

    mov si, buffer
    mov di, cmd_ver
    call strcmp
    jc do_ver

    mov si, buffer
    mov di, cmd_restart
    call strcmp
    jc do_restart

    mov si, buffer
    mov di, cmd_close
    call strcmp
    jc do_close

    mov si, buffer
    mov di, cmd_color
    call strcmp
    jc do_color

    mov si, buffer
    mov di, cmd_help
    call strcmp
    jc do_help

    mov si, unknown
    call print
    ret

do_ver:
    mov si, ver_msg
    call print
    ret

do_restart:
    mov si, restart_msg
    call print
    call newline
    mov ax, 0
    mov ds, ax
    mov [0x472], word 0x1234 
    jmp 0xffff:0x0000

do_close:
    mov si, close_msg
    call print
    call newline
    cli
halt:
    hlt
    jmp halt

do_color:
    mov si, buffer
    add si, 6
    lodsb
    cmp al, '0'
    jb color_error
    cmp al, '9'
    jbe is_digit
    cmp al, 'a'
    jb color_error
    cmp al, 'f'
    ja color_error
    sub al, 'a' - 10
    jmp set_color
is_digit:
    sub al, '0'
set_color:
    mov ah, 0x09
    mov al, ' '
    mov bh, 0
    mov cx, 1
    mov bl, al
    int 0x10
    ret
color_error:
    mov si, color_err
    call print
    ret

do_help:
    mov si, help_msg
    call print
    ret

strcmp:
    push si
    push di
.loop:
    mov al, [si]
    mov bl, [di]
    cmp al, bl
    jne no_match
    or al, al
    jz match
    inc si
    inc di
    jmp .loop
match:
    pop di
    pop si
    stc
    ret
no_match:
    pop di
    pop si
    clc
    ret

tolower:
    pusha
.loop:
    lodsb
    cmp al, 'A'
    jb .next
    cmp al, 'Z'
    ja .next
    add al, 32
    mov [si-1], al
.next:
    or al, al
    jnz .loop
    popa
    ret

welcome     db 'jaguwnos 3 BETA', 0
prompt      db '>', 0
cmd_ver     db ' ver', 0
cmd_restart db ' restart', 0
cmd_close   db ' close', 0
cmd_color   db ' color', 0
cmd_help    db ' help', 0
ver_msg     db ' jaguwnos wersja 3 BETA', 0
restart_msg db ' REBOOT', 0
close_msg   db ' HALT', 0
help_msg    db '?= ver, restart, close, color, help', 0
unknown     db '?', 0
color_err   db '!', 0
buffer      times 28 db 0

times 510-($-$$) db 0
dw 0xaa55