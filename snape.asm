.model small            ; Use small memory model (separate 64KB code/data)
.stack 100h             ; Allocate 256 bytes of stack space

.data
    direction db 0              ; Snake's movement direction (0=right, 1=left, 2=up, 3=down)
    x db 40                     ; Snake's current x position (column)
    y db 12                     ; Snake's current y position (row)
    foodX db 30                 ; Food's x position
    foodY db 10                 ; Food's y position
    msg db 'GAME OVER$'         ; Game over message
    foodChar db '*'             ; Character to display food
    blockChar db 219            ; Character to display snake
    spaceChar db ' '            ; Character to erase snake
    food_positions_x db 10, 20, 30, 40, 50, 60, 70 ; X coordinates for food
    food_positions_y db 5, 10, 15, 12, 8, 18, 20   ; Y coordinates for food
    food_index db 0             ; Index to track current food location
    food_count equ 7            ; Total food positions
    score dw 0                  ; Score counter
    scoreMsg db 'Score: $'      ; Score message prefix

.code
start:
    mov ax, @data               ; Initialize data segment
    mov ds, ax

    call cls                    ; Clear the screen
    call draw_border            ; Draw game borders
    call draw_food              ; Draw the initial food
    call draw_snake             ; Draw the snake

main_loop:
    call delay                  ; Delay for pacing
    call get_key                ; Check and handle user input
    call erase_snake            ; Remove the old snake from screen
    call update_position        ; Update snake position based on direction
    call check_food             ; Check if snake ate the food
    call draw_snake             ; Draw snake at new position
    call display_score          ; Display current score
    call check_border           ; Check if snake hits border
    jmp main_loop               ; Repeat game loop

; -------------------------------------
cls:
    mov ax, 0600h               ; Function to scroll screen
    mov bh, 07                  ; Attribute for blank space
    mov cx, 0                   ; Upper-left corner
    mov dx, 184Fh               ; Lower-right corner
    int 10h                     ; BIOS video interrupt
    ret

; -------------------------------------
draw_border:
    mov cx, 0                   ; Start from left edge
top_bottom:
    mov dh, 0                   ; Top row
    mov dl, cl
    call draw_char_border       ; Draw top border character

    mov dh, 24                  ; Bottom row
    mov dl, cl
    call draw_char_border       ; Draw bottom border character

    inc cl
    cmp cl, 80                  ; Until column 79
    jne top_bottom

    mov cx, 1
sides:
    mov dh, cl
    mov dl, 0                   ; Left border
    call draw_char_border

    mov dl, 79                  ; Right border
    call draw_char_border

    inc cl
    cmp cl, 24                  ; Until row 23
    jne sides
    ret

draw_char_border:
    push ax
    push bx
    push cx
    mov ah, 02h                 ; Set cursor position
    mov bh, 0
    int 10h

    mov ah, 09h                 ; Write character and attribute
    mov al, '#'                 ; Border character
    mov bh, 0
    mov bl, 07                  ; Light gray
    mov cx, 1
    int 10h
    pop cx
    pop bx
    pop ax
    ret

; -------------------------------------
delay:
    mov cx, 0Fh                 ; Delay loop counter
del_loop:
    loop del_loop               ; Burn CPU cycles
    ret

; -------------------------------------
get_key:
    mov ah, 01h                 ; Check for keystroke
    int 16h
    jz no_key                   ; No key pressed

    mov ah, 00h                 ; Get key press
    int 16h

    cmp ah, 4Bh
    je left
    cmp ah, 4Dh
    je right
    cmp ah, 48h
    je up
    cmp ah, 50h
    je down
    jmp no_key

up:
    cmp direction, 3            ; If currently going down
    je no_key                   ; Don’t allow reverse
    mov direction, 2            ; Set to up
    jmp no_key

down:
    cmp direction, 2            ; If currently going up
    je no_key
    mov direction, 3
    jmp no_key

left:
    cmp direction, 0            ; If going right
    je no_key
    mov direction, 1
    jmp no_key

right:
    cmp direction, 1            ; If going left
    je no_key
    mov direction, 0

no_key:
    ret

; -------------------------------------
erase_snake:
    mov ah, 02h         ; Set cursor position
    mov bh, 0           ; Video page 0
    mov dh, y           ; Row = y
    mov dl, x           ; Column = x
    int 10h             ; Call BIOS interrupt to move cursor

    mov ah, 09h         ; Write character and attribute
    mov al, spaceChar   ; al = ' ' (space character)
    mov bh, 0           ; Video page
    mov bl, 7           ; Attribute = light gray on black
    mov cx, 1           ; Write once
    int 10h             ; Call BIOS interrupt to print
    ret

; -------------------------------------
draw_snake:             ;Prints a solid block character (¦) in bright green at the new snake position.
    mov ah, 02h         ; Set cursor position
    mov bh, 0
    mov dh, y           ; Row
    mov dl, x           ; Column
    int 10h

    mov ah, 09h         ; Write character and attribute
    mov al, blockChar   ; al = 219 (¦ solid block)
    mov bh, 0
    mov bl, 10          ; Bright green attribute
    mov cx, 1
    int 10h             ; Print the snake block
    ret


; -------------------------------------
draw_food:
    mov ah, 02h          ; BIOS function: Set cursor position
    mov bh, 0            ; Video page 0 (standard)
    mov dh, foodY        ; Row = foodY (vertical coordinate)
    mov dl, foodX        ; Column = foodX (horizontal coordinate)
    int 10h              ; Call BIOS interrupt to move the cursor


    mov ah, 09h          ; BIOS function: Write character with attribute
    mov al, foodChar     ; Character to print = '*'
    mov bh, 0            ; Video page 0
    mov bl, 12           ; Color attribute = bright red (text mode color code)
    mov cx, 1            ; Number of times to print character = 1
    int 10h              ; Call BIOS to draw the character


; -------------------------------------
update_position:
    cmp direction, 0            ; Is the direction right?
    jne check_left              ; If not, jump to check_left
    inc x                       ; Move right (increase column)
    jmp done                    ; Jump to end of function

check_left:
    cmp direction, 1
    jne check_up
    dec x                       ; Move left (decrease column)
    jmp done

check_up:
    cmp direction, 2
    jne check_down
    dec y                       ; Move up (decrease row)
    jmp done 
    
check_down:
    inc y                       ; Only case left is down
done:
    ret

; -------------------------------------
display_score:
    mov ah, 02h         ; BIOS function: Set cursor position
    mov bh, 0           ; Video page 0
    mov dh, 0           ; Row = 0 (top row)
    mov dl, 65          ; Column = 65 (towards right)
    int 10h             ; Move the cursor to (65, 0)


    mov ah, 09h         ; Display string
    lea dx, scoreMsg    ; Load address of 'Score: $' string
    int 21h             ; Print the string


    mov ax, score       ; Load current score value into AX
    call print_number   ; Call function to print the number as ASCII
    ret                 ; Return from display_score


; -------------------------------------
check_food:
    mov al, x
    cmp al, foodX
    jne not_eaten
    mov al, y
    cmp al, foodY
    jne not_eaten

    inc score                  ; Increase score
    call display_score

    mov al, food_index
    inc al
    cmp al, food_count
    jne no_wrap
    mov al, 0
no_wrap:
    mov bl, al                 ; Move new food_index into BL (array index)
    mov al, food_positions_x[bx]  ; Load new X position from array
    mov foodX, al              ; Update foodX
    mov al, food_positions_y[bx]  ; Load new Y position from array
    mov foodY, al              ; Update foodY


    call draw_food

not_eaten:
    ret

; -------------------------------------
check_border:
    cmp x, 1
    jb game_over
    cmp x, 78
    ja game_over
    cmp y, 1
    jb game_over
    cmp y, 23
    ja game_over
    ret

; -------------------------------------
game_over:
    mov ah, 02h                 ; Set cursor position
    mov bh, 0
    mov dh, 12
    mov dl, 30
    int 10h

    mov ah, 09h                 ; Print GAME OVER message
    lea dx, msg
    int 21h

    hlt                         ; Halt execution

; -------------------------------------
print_number:
    ; AX = number to print
    push ax
    push bx
    push cx
    push dx

    xor cx, cx                  ; Clear CX - will count number of digits
    mov bx, 10                  ; Divisor = 10 for decimal division ,  since we're dividing by 10 to extract digits.

next_digit:
    xor dx, dx          ; Clear DX before division (important for division)
    div bx              ; Divide AX by BX (10)
                        ; Result (quotient) in AX, remainder in DX
    push dx             ; Push remainder (digit) onto stack
    inc cx              ; Increment digit count
    cmp ax, 0           ; If quotient is zero, we have all digits
    jne next_digit      ; Else, repeat division on quotient


print_loop:
    pop dx              ; Pop digit from stack (last extracted = most significant digit)
    add dl, '0'         ; Convert digit to ASCII character
    mov ah, 02h         ; DOS function: print character in DL
    int 21h
    loop print_loop     ; Loop CX times (number of digits)


    pop dx
    pop cx
    pop bx
    pop ax                     ;Restore registers from the stack.
    ret

end start                      ; End program, set start as entry point