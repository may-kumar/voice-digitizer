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
jmp     st1     
nop
dw      0000h
dw      0000h
dw      t_isr
dw      0000h

db     1012 dup(0)    
; kb table
TABLE_K     DB     0EEh,0EDH,0EBH,0E7H
			DB     0DEH,0DDH,0DBH,0D7H
			DB     0BEH,0BDH,0BBH,0B7H
			DB     07EH,07DH,07BH,077H

;display table
TABLE_D  DB     3FH,  06H, 5BH,  4FH, 66H, 6DH
DB      7DH,  27H, 7FH, 6FH, 77H, 7CH,
DB        39H,  5EH, 79H, 71H
;main program

st1:      cli  

sioml equ 00h
sioadc equ 02h
sioll equ 04h
siocreg equ 06h


tiocnt1 equ 10h
tiocnt2 equ 12h
tiocnt3 equ 14h
tiocreg equ 16h  

; intialize ds, es,ss to start of RAM
mov       ax,0200h
mov       ds,ax
mov       es,ax
mov       ss,ax
mov       sp,0FFFEH
;intialise porta & upper port C as input ,portb & lower portc as output
mov           al,82h
out           siocreg,al     


mov         al,0ffh     
not al
out        sioml,al             
mov al, 3fh
not al
out sioll, al       


		  mov       al,36h
		  out       tiocreg,al
		  mov       al,0F4h
		  out       tiocnt1,al
		  mov       al,01h
		  out       tiocnt1,al        
		  mov       si, 0000h       
		  
		  mov  0000h, 10h
		  mov  0001h, 11h
		  mov  0002h, 12h
		  mov  0003h, 13h
		   
;loop till isr
x1:       jmp       x1                    
           

x0: jmp x0


t_isr:    
          in          al,sioadc         
          and         ah,0h
          mov         dx,ax     
          
          mov         BX, 0001h
          mov         [BX + SI], al
          inc         si      
          
          mov         DI, dx 
          and         DI,00F0h   
          ror         di,01h
          ror         di,01h
          ror         di,01h
          ror         di,01h       
          
          
          LEA         BX, TABLE_D 
          MOV         AL, CS:[BX+DI]
          NOT         AL
          out         sioml,al    
                                
          mov         DI, dx
          and         DI,000Fh  
          
                               
          LEA         BX, TABLE_D  
          MOV         AL, CS:[BX+DI]
          NOT         AL
          out         sioll,al                         
          iret           