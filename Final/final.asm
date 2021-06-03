#make_bin#

#LOAD_SEGMENT=FFFFh#
#LOAD_OFFSET=0000h#

#CS=0000h#
#IP=0000h#

#DS=0000h#
#ES=0000h#

#SS=0000h#
#SP=FFFEh#

#AX=0000h#
#BX=0000h#
#CX=0000h#
#DX=0000h#
#SI=0000h#
#DI=0000h#
#BP=0000h#



; add your code here
jmp start1
db  5 dup(0)     

dw  nmi_isr
dw  0000

db  500 dup(0)

;IVT 80h- record
dw  str_isr
dw  0000h

;IVT 81h- enter delay
dw  0000h
dw  0000h

;IVT 82h- stop
dw  stop_isr
dw  0000h

;IVT 83h- pause
dw  pause_isr
dw  0000h

;IVT 84h- sound replay
dw  play_str
dw  0000h

;IVT 85h- next ADC Input 
dw  ADCrecord
dw  0000h

;IVT 86h- DAC next output
dw  DACout
dw  0000h

;IVT 87h- --
dw  0000h
dw  0000h       


db  500 dup(0)                          


; kb table
TABLE_K     DB     07DH,0EEh,0EDH,0EBH,0DEH,0DDH,0DBH,0BEH,0BDH,0BBH
			DB     07EH,07BH
;display table
TABLE_D  DB     3FH,  06H, 5BH, 4FH, 66H, 6DH
         DB     7DH,  27H, 7FH, 6FH



sio_dac equ 00h
sioadc equ 02h
siobsr equ 04h
;0 - gate0
;1 - gate1
;2 - gate2
;3 - recording
;4 - playing
;5 - paused
;6 - ready
;7 - error
siocreg equ 06h

dio_sta equ 10h
dioled equ 12h
diokbd equ 14h
diocreg equ 16h

tiocnt0 equ 20h
tiocnt1 equ 22h
tiocnt2 equ 24h
tiocreg equ 26h

irhreg0 equ 30h
irhreg1 equ 32h




           

;main program
start1:      
cli
; intialize ds, es,ss to start of RAM
mov       ax,0200h
mov       ds,ax
mov       es,ax
mov       ss,ax
mov       sp,0FFFEH



;DATA DECLARATIONS
AUDIO_DATA  db 6000 dup(0);for data storage
SIZE        dw 00h        ;For size
DELAY       db 00h        ;delay entered
STATUS      db 00h        ;current status
LED         db 00h        ;output status



nop 
nop
nop 
nop


                                                 




;initialize sio- portA:o/p, portB:i/p, portC:o/p
mov       al,82h
out       siocreg,al    

mov       al, 00h
out       sio_dac,al
;mov        al, 0FCh
;out        siobsr, al ; set gates as 0 and LEDs as 1   



mov        al,88h
out        diocreg,al  

mov        al,0ffh
out        dioled,al

     

;initialize timers- timer0:mode3,1ms ; timer1:mode3,x ms
mov        al,36h
out        tiocreg,al   ;timer0 setup 
mov        al,76h
out        tiocreg,al   ;timer1 setup 


mov        al,0F4h                       
out        tiocnt0,al
mov        al,01h       
out        tiocnt0,al   ;count for timer0      



;initialize PIC- EOI required, no cascade, edge-triggered, vectors from 80h, 
mov     al, 13h
out     irhreg0, al ;icw1

mov     al, 80h
out     irhreg1, al ;icw2 - vector no.

mov     al, 01h
out     irhreg1, al ;icw4

mov     al, 00h
out     irhreg1, al ;ocw1 - IMR    
     
;ADD IN EACH INTERRUPT
;mov    al, 20h
;out    irhreg0, al ;ocw2 - EOI                        
                                
                                
;PROGRAM STARTS HERE, WAIT FOR RECORD SIGNAL



mov STATUS,00h

mov LED, 07Bh                      
mov al, LED
out dio_sta,al
                           
       
sti                    
                           
st1:
cmp STATUS, 00h
jz st1



rec_start:

;recording input goes here    

mov LED, 7Ch 
mov al, LED
out dio_sta,al;start timer count, and show recording

mov di, 00h      ;clear SI for use
mov SIZE, 00h    ;clear memory also      



con_rec:         ;continue recording

                         
cmp SIZE,15d
jnz con_rec      ;keep recording till we get 6000 samples(6s X 1000 samples/sec)


cli

mov LED, 07Bh
mov al, LED
out dio_sta,al;stop timer count, and  recording

mov di, 00h 

or STATUS,02h
;recording finished here

mov al,00h             
out sio_dac,al

;input delay here 
mov al, 0bfh
out dioled,al

X0: MOV  AL,00H
    OUT  diokbd, AL
X1: IN   AL, diokbd
    AND  AL,0F0H
    CMP  AL,0F0H
    JNZ  X1
    CALL D20MS
    MOV  AL,00H
    OUT  diokbd ,AL
X2: IN   AL, diokbd
    AND  AL,0F0H
    CMP  AL,0F0H
    JZ   X2
    CALL D20MS
    MOV  AL,00H
    OUT  diokbd ,AL
    IN   AL, diokbd
    AND  AL,0F0H
    CMP  AL,0F0H
    JZ   X2
    MOV  AL, 0EH
    MOV  BL,AL
    OUT  diokbd,AL
    IN   AL,diokbd
    AND  AL,0F0H
    CMP  AL,0F0H
    JNZ  X3
    MOV  AL, 0DH
    MOV  BL,AL
    OUT  diokbd ,AL
    IN   AL,diokbd
    AND  AL,0F0H
    CMP  AL,0F0H
    JNZ  X3
    MOV  AL, 0BH
    MOV  BL,AL
    OUT  diokbd,AL
    IN   AL,diokbd
    AND  AL,0F0H
    CMP  AL,0F0H
    JNZ  X3
    MOV  AL, 07H
    MOV  BL,AL
    OUT  diokbd,AL
    IN   AL,diokbd
    AND  AL,0F0H
    CMP  AL,0F0H
    JZ   X2
X3: OR   AL,BL
    MOV  CX,0FH
    MOV  DI,00H
X4: CMP  AL,CS:TABLE_K[DI]
    JZ   X5
    INC  DI
    LOOP X4
X5:   
    LEA  BX, TABLE_D
    MOV  AL, CS:[BX+DI]
    NOT  AL
    
    CMP  DI, 0Ah
    JNZ  X6
    MOV  AL, 0BFh
    OUT  dioled, AL
    MOV  DX, 0h
    MOV  DI, 0h
    JMP  X0
     
X6: CMP  DI, 0Bh
    JZ   X7
    OUT  dioled,AL
    MOV  DX, DI
    JMP  X0
    
X7: LEA  BX, TABLE_D
    CMP  DX, 0h
    JZ   X0
    MOV  DI, DX
    MOV  AL, CS:[BX+DI]
    NOT  AL
    AND  AL, 7Fh
    OUT  dioled,al 


mov DELAY, dl
or STATUS, 04h
;INPUT FINISHES HERE--- OUTPUT IS IN DI and DX


;Put number in timer 1 so that we have rate-generator for DAC    
mov al,dl      ;changed here-------------------------------------------------------------------   
inc dl              
out tiocnt1,al
mov al,00h       
out tiocnt1,al ;count for timer1

mov     al, 20h
out     irhreg1, al ;ocw2 - EOI
	
ready:              
mov LED, 05Bh
mov al, LED
out dio_sta,al  ;put READY LED ON


sti
;WAIT FOR PLAY SIGNAL HERE



play_wait:
    cmp STATUS, 01h
    je rec_start

	cmp STATUS, 0Fh
	jne play_wait
	

mov SI, 00h
mov DI, 00h

mov LED, 0F7h
mov al, LED
out dio_sta,al  ;put READY LED OFF,PLAYING ON
 
 


playing:

cmp STATUS, 01h
je rec_start



cmp SI,SIZE
jnz playing      ;keep recording till we play all samples


cli


mov LED, 5Bh
mov al, LED
out dio_sta,al  ;put READY LED ON, PLAYING OFF

             
mov al,00h             
out sio_dac,al

sti

mov STATUS, 07h
jmp ready







D20MS: mov  cx,2220 ; delay generated will be approx 0.45 secs
xn:    loop xn
ret



;ISR TO RECORD NEXT DIGITAL INPUT
ADCrecord: 
	cmp STATUS, 01h
	jnz AD
	
	lea     bx, AUDIO_DATA
	in      al,sioadc
	mov     [bx+DI],al
	inc     DI
	mov     SIZE,DI  

AD:	mov     al, 20h
	out     irhreg0, al ;ocw2 - EOI
	iret


;ISR TO START RECORDING
str_isr:
	
	mov STATUS, 01h


ex1:mov     al, 20h
	out     irhreg0, al ;ocw2 - EOI
	iret


	
;ISR TO START PLAYING	
play_str:
	cmp STATUS, 07h
	jnz ex2
	
	mov STATUS, 0Fh


ex2:mov     al, 20h
	out     irhreg0, al ;ocw2 - EOI
	iret



;ISR TO PLAY NEXT OUTPUT TO DAC
DACout: 
	cmp STATUS, 0Fh
	jnz DA

	
	lea     bx, AUDIO_DATA
	
	mov     al,[BX+SI]  
	out     sio_dac,al
	inc     SI  


DA:	mov     al, 20h
	out     irhreg0, al ;ocw2 - EOI
	iret

	
	
	
pause_isr:
	cmp STATUS, 0Fh
	jnz nr 
	
	mov STATUS, 07h


    mov LED, 6Bh
    mov al, LED
    out dio_sta,al;show paused

nr: mov     al, 20h
	out     irhreg0, al ;ocw2 - EOI
	iret
    
    
    
    
    
stop_isr:
	cmp STATUS, 0Fh
	jnz nr2
	
	mov STATUS, 07h
	mov SI, 00h         ;reset count
	
	
    mov LED, 5Bh
    mov al, LED
    out dio_sta,al      ;show ready


nr2:mov     al, 20h
	out     irhreg0, al ;ocw2 - EOI
	iret	
	
nmi_isr:
	;not required 
	iret



