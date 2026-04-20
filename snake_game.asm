IDEAL
MODEL small
STACK 100h
DATASEG
stars dw (12*80+40)*2, (12*80+39)*2, (12*80+38)*2, 1997 dup(0)      ;every possile snake star
pressed db 0														;rel time keyboard input
len dw 3															;real time snakes length
starting_len dw 0													;first length
apple_location dw 0													;apple location 1-2000
head_location dw 0													;head location  1-2000
dir db 'd'															;last direction
game_over_pixels dw 0,733,734,735,736,813,893,895,896,973,976,1053,1054,1055,1056,739,740,741,742,819,822,899,900,901,902,979,982,1059,1062,745,749,825,826,828,829,905,907,909,985,989,1065,1069,751,752,753,754,755,831,911,912,913,914,991,1071,1072,1073,1074,1075,763,764,765,766,843,846,923,926,1003,1006,1083,1084,1085,1086,770,774,850,854,930,934,1011,1013,1092,778,779,780,781,782,858,938,939,940,941,1018,1098,1099,1100,1101,1102,784,785,786,787,864,867,944,945,946,947,1024,1026,1104,1107
;pixels to draw 'game over'

CODESEG

proc clear_draw
    push bp
    mov bp,sp
    push ax
    push bx
    push cx
    push si
    push di

    xor si,si		 	
    mov cx,[bp+4] 	;[len]
draw_loop:
	mov bx, [bp+6]   ;offset stars      
	mov di, [bx + si]    ;move the position of the current star to di

	mov al,[bp+8]  
	mov ah, [bp+10]  
	mov [es:di], ax        
	add si, 2             ;increase si to reach the next star
    loop draw_loop
	
    pop di
    pop si
    pop cx
    pop bx
    pop ax
    pop bp
    ret 8
endp clear_draw

proc delay
    push bp
    mov bp,sp
    push cx
    push dx
	
    mov cx,[bp+4]     ;5BB 
dly1:
    mov dx,[bp+4]	  ;5BB	
dly2:
    dec dx
    jnz dly2
    dec cx
    jnz dly1
	
	;bigass loop to slow the game
	
    pop dx
    pop cx
    pop bp
    ret 2
endp delay

proc apple
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx
    push si
    push di  
	
rnd_again:
    mov ax, [bp+4]  ;[es:6ch] take the clock to get random number 
	mov di,[bp+12] ;[head_location]
    xor ax, di     ;di always changes so xor makes it more random

    mov bx, 1920   ;all the pixels from line 2
    div bx         ;divide random / 1920      
    mov ax, dx     ;the random number is 0-1920    
    shl ax, 1      ;because every pixels taskes 2 bytes
	add ax,160     ;now the random is 80-2000

    xor si, si
    mov cx, [bp+8]     ;[len] 
	mov bx, [bp+6]     ;offset stars
check_snake:    
    cmp ax, [bx+si]    ;check random so it wont generate on the snake   
    je rnd_again
    add si, 2		   ;move to next star	
    loop check_snake

ok_random:
    mov bx, [bp+10]     ;offset apple_location
    mov [bx], ax        ;saves new apple location

    mov di, ax     
    mov al,'@'   
    mov ah, 4    
    mov [es:di], ax     ;prints apple  
	
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret 10
endp apple

proc move_snake
    push bp
    mov bp,sp
    push ax
    push bx
    push si
    push di
	
	push 28
	push ' '
    push offset stars
    push [len]
    call clear_draw   ;clears snake

    mov si,[bp+10]	;[len]
    dec si          ;becouse the first location in stars is 0
    shl si,1        ;becouse every star takes 2 bytes

move_loop:
    mov bx,[bp+8]	;offset stars
    add bx,si       ;bx the star we want to move
    mov di,bx
    sub di,2        ;di the star before the star we want to move
    mov ax,[di]
    mov [bx],ax     ;moving the di's star to bx's star (the star gets the location of the star infront)
    sub si,2		;the next star
    jnz move_loop   ;keep moving till si = 0 (stars ended)
	
	mov si,[bp+8]     ;offset stars
	mov ax,[bp+6]     ;the amount of movement
	add ax,[si]       ;ax is the new head loation
	mov di,[bp+4]     ;offset head_location
	mov [si],ax       ;updates offset stars
	mov [di],ax       ;updates head location    	

	
    
    push 2
	push '*'
    push offset stars
    push [len]
    call clear_draw   ;draws the snake

    pop di
    pop si
    pop cx
    pop ax
    pop bp
    ret 8
endp move_snake

proc after_move
    push bp
    mov bp,sp
    push ax
    push bx
    push dx
    push si
    push di

	push [len]             ;[bp+8]
	push offset stars     ;[bp+6]
	push [head_location]  ;[bp+4]
	call collision        ;check if head touches any star  

	mov si,[bp+12]  ;offset dir
	mov ax,[bp+10]  ;[pressed]
	mov [si],ax     ;updates dir to be the previous diraction
	
	push 07BBh
	call delay      ;calls delay
	
	mov ax,[bp+4]    ;[head_location]
	mov bx,[bp+6]    ;offset apple_location
	cmp [bx],ax        ;check if apple is eaten

	jne no_apple     ;if not - jumps to the end
	
	mov bx,[bp+8]  ;offset len
	mov ax,[bx]   
	inc ax  
	mov [bx],ax    ;increase length by 1

	push [head_location] ;[bp+12]
    push offset apple_location	;[bp+10]
	push [len]			;[bp+8]
    push offset stars	;[bp+6]
    push [es:6Ch]		;[bp+4]
    call apple     
	
no_apple:
    pop di
    pop si
    pop dx
    pop bx
    pop ax
    pop bp
    ret 10
endp after_move

proc check_right
	push bp
    mov bp,sp
    push ax
    push bx
    push dx
    push si
	push ds
	
	mov ax,[bp+4] ;[stars]
    mov bx,160    ;160 bytes in a line
    div bx        ;location/160
    cmp dx,158    ;checks if snake is close to the border
    jae end_right ;if so - die
	
	mov ax,[bp+6] ;[dir]
	cmp ax,'a'    ;check if trying to make 180 turn
	je skip_right
	
		
	push [len]				;[bp+10]
	push offset stars 		;[bp+8]
	push 2					;[bp+6]
	push offset head_location ;[bp+4] 
    call move_snake           
    jmp call_after_move
	
	skip_right:
	mov si, [bp+8]   ;offset pressed
	mov al, 'a'
	mov [ds:si], al  ;puts last dircation into pressed
	jmp far ptr skip_key  ;jumps to start new procces of movement
	
	end_right:
	pop ds 
    pop si
    pop dx
    pop bx
    pop ax
    pop bp
	
    push offset game_over_pixels
    call over                      ;die if hit border
endp check_right

proc check_left
	push bp
    mov bp,sp
    push ax
    push bx
    push dx
    push si
	push ds
	
	mov ax,[bp+6]   ;[dir]
	cmp ax,'d'      ;check if trying to make 180 turn
	je skip_left
	
	mov ax,[bp+4] ;[stars]
    mov bx,160    ;160 bytes in a line
    div bx        ;location/160
    cmp dx,0      ;checks if snake is close to the left border
    je end_left   ;if so - die
	
		
	push [len]				;[bp+10]
	push offset stars 		;[bp+8]
	push -2					;[bp+6]
	push offset head_location ;[bp+4] 
    call move_snake           ;move snake to the left
    jmp call_after_move
	
	skip_left:
	mov si, [bp+8]   ;offset pressed
	mov al, 'd'
	mov [ds:si], al  ;puts last direction into pressed
	jmp far ptr skip_key  ;jumps to start new process of movement
	
	end_left:
	pop ds 
    pop si
    pop dx
    pop bx
    pop ax
    pop bp
    push offset game_over_pixels
    call over         ;die if hit left border
endp check_left

proc check_up
	push bp
    mov bp,sp
    push ax
    push bx
    push si
	push ds
	
	mov ax,[bp+4] ;[stars]
	cmp ax,320       ;checks if snake is at top border
    jb end_up       ;if above top border, die
	
	mov ax,[bp+6]  ;[dir]
	cmp ax,'s'     ;check if trying to make 180 turn
	je skip_up
	
		
	push [len]				;[bp+10]
	push offset stars 		;[bp+8]
	push -160				;[bp+6]
	push offset head_location ;[bp+4] 
    call move_snake           ;move snake up
    jmp call_after_move
	
	skip_up:
	mov si, [bp+8]   ;offset pressed
	mov al, 's'
	mov [ds:si], al  ;puts last direction into pressed
	jmp far ptr skip_key  ;jumps to start new process of movement
	
	end_up:
	pop ds
    pop si
    pop dx
    pop ax
    pop bp
    push offset game_over_pixels
    call over         ;die if hit top border
endp check_up

proc check_down
	push bp
    mov bp,sp
    push ax
    push bx
    push si
	push ds
	
	mov ax,[bp+4] ;[stars]
	cmp ax,3840 ;24*160   ;checks if snake is at bottom border
    jae end_down          ;if so - die
	
	mov ax,[bp+6]  ;[dir]
	cmp ax,'w'     ;check if trying to make 180 turn
	je skip_down
	
		
	push [len]				;[bp+10]
	push offset stars 		;[bp+8]
	push 160				;[bp+6]
	push offset head_location ;[bp+4] 
    call move_snake           ;move snake down
    jmp call_after_move
	
	skip_down:
	mov si, [bp+8]   ;offset pressed
	mov al, 'w'
	mov [ds:si], al  ;puts last direction into pressed
	jmp far ptr skip_key  ;jumps to start new process of movement
	
	end_down:
	pop ds
    pop si
    pop bx
    pop ax
    pop bp
    push offset game_over_pixels
    call over         ;die if hit bottom border
endp check_down

proc setup
	push bp
    mov bp,sp
    push ax
    push bx
    push cx
    push di
	
	mov ax,0B800h
	mov es,ax

	mov ax,[bp+4]  ;[stars]
	mov bx, [bp+6] ;offset head_location
    mov [bx],ax    ;sets first head location
	
    xor di,di
    mov cx,2000
	
clear_loop:
    mov al,' '
    mov ah,28
    mov [es:di],ax
    add di,2
    loop clear_loop         ;clears screen
	
	xor di,di
    mov cx,80
	
clear_loop1:
    mov al,' '
    mov ah,0
    mov [es:di],ax
    add di,2
    loop clear_loop1          ;draws black line on the top of the screen
	
    push 2		 ;[bp+10]
    push '*'       ;[bp+8]
    push offset stars ;[bp+6]
    push [len]   ;[bp+4]
    call clear_draw            ;draws snake
	
	push [head_location] ;[bp+12]
    push offset apple_location	;[bp+10]
	push [len]			;[bp+8]
    push offset stars	;[bp+6]
    push [es:6Ch]		;[bp+4]
    call apple     	           ;draws first apple
	
	pop di
    pop cx
    pop bx
    pop ax
    pop bp
	ret 4 
endp setup

proc collision
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push si

    mov ax, [bp+4]      ;[head_location]
    mov bx, [bp+6]      ;offset stars
    mov cx, [bp+8]      ;[len]
    mov si, 2           ;because you stars checking from the second stars and not th head

snake_collision:
    cmp ax, [bx+si]     ;compare head location to star location
    je collision_found  
    add si, 2           ;next star
    loop snake_collision
    jmp no_collision

collision_found:
    push offset game_over_pixels
    call over                     ;snake dies if collision found

no_collision:
    pop si
    pop cx
    pop bx
    pop ax
    pop bp
    ret 6
endp collision

proc over
	push bp
    mov bp, sp
	
	push 05BBh
	call delay 
	
	xor di,di
	mov cx,2000
	over_loop:
    mov al,' '
    mov ah,0
    mov [es:di],ax
    add di,2
    loop over_loop   ;paints screen black
	
	mov si,[bp+4] ;offset game_over_pixels
    mov cx, 111
	mov al,' '
    mov ah, 195 
       
	
draw_over:
    mov di, [si]  ;moves the pixel location to di
    shl di, 1     ;every pixel takes 2 bytes       
    mov [es:di], ax   ;paints that pixel 
    add si, 2         ;next pixel to paint
    loop draw_over    ;goes on every pixel in 'game_over_pixels'
	
	pop bp
	jmp exit
endp over

proc print_score
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx
    push di
	
	xor di,di  ;cause the score would be in the location di=0

    mov ax, [bp+4]  ;score      
    cmp ax, 0
    jne convert_start
    mov al, '0'
    mov ah, 2
    mov [es:di], ax
    jmp print_done  ;if the score is 0: print 0 and jump out
	
	
convert_start:
    xor cx, cx      
    mov bx, 10      

convert_loop:
    xor dx, dx
    div bx          ;score/10
    push dx         ;dx = 0-9 number
    inc cx          ;cx holds the amount of digits
    cmp ax, 0       ;if number is not over - keep dividing
    jne convert_loop

print_digits:
    pop dx       	;pop the digit to print
    add dl, '0'     ;number to ascii
    mov al, dl
    mov ah, 2    
    mov [es:di], ax   ;prints digit
    add di, 2         ;next place
    loop print_digits ;does that for the amount of digits

print_done:
	pop di
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret 2
endp print_score



start:
    mov ax, @data
    mov ds,ax
	
	push offset head_location 	;[bp+6]
	push [stars]                ;[bp+4]
	call setup                  ;prepares screen
	
	mov ax, [len]
	mov [starting_len],ax      ;sets starting lenght
	
	
loopy:
	mov ax,[len]
	mov cx, [starting_len]
	sub ax,cx				;score = len - starting len
	push ax                ;pushes score 
	call print_score        ;prints score
	
	mov ah,1		
    int 16h
    jz skip_key			;if no button pressed - take no input
	
    mov ah,0
    int 16h
    mov [pressed],al     ;puts input in pressed
	
	skip_key:
	xor dx,dx
    mov bl,[pressed]     ;input is in bl
	
    cmp bl,'w'
    jne up               ;if not pressed - skip to the next check
	push offset pressed ;[bp+8]
	xor ax, ax
	mov al, [dir]
	push ax             ;[bp+6]
	push [stars]        ;[bp+4]
	call check_up       ;call up
	up:
	
    cmp bl,'s'
    jne down              ;if not pressed - skip to the next check
	push offset pressed ;[bp+8]
	xor ax, ax
	mov al, [dir]
	push ax          ;[bp+6]
	push [stars]    ;[bp+4]
	call check_down   ;call down
	down:           
	
    cmp bl,'a'
    jne left                ;if not pressed - skip to the next check
	push offset pressed     ;[bp+8]
	xor ax, ax
	mov al, [dir]
	push ax             ;[bp+6]
	push [stars]		;[bp+4]
	call check_left     ;call left
	left:          
	
    cmp bl,'d' 
    jne right               ;if not pressed - skip to the next check
	push offset pressed		;[bp+8]
	xor ax, ax
	mov al, [dir]
	push ax					;[bp+6]
	push [stars]             ;[bp+4]
	call check_right         ;call right
	right:
	
    cmp bl,'q'
    je call_over
	jmp loopy
	
	call_over:
	push offset game_over_pixels
    call over	;if 'q' pressed: end game and the snake dies
	
	
	call_after_move:        ;caller to after move
	push offset dir			;[bp+12]
	push [word ptr pressed]	;[bp+10]
	push offset len			;[bp+8]
	push offset apple_location	;[bp+6]
	push [head_location]	;[bp+4]
	call after_move       	
	jmp loopy
exit:
    mov ax,4C00h
    int 21h
END start
