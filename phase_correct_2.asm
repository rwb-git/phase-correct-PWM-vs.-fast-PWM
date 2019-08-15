.include "m8535def.inc"
.cseg

.org $0000
	rjmp RESET      ;Reset handle
   rjmp ext_int0
   rjmp ext_int1
   rjmp t2_comp_int                    ; t2comp
   rjmp t2_OV_int
   rjmp t1cap
   rjmp t1compa
   rjmp t1compb
   rjmp t1overflow
   rjmp t0overflow                     ; 10
   rjmp wut                            ; 11
   rjmp wut                            ; 12
   rjmp wut                            ; 13
   rjmp wut                            ; 14
   rjmp adc_int                        ; 15
   rjmp wut                            ; 16
   rjmp wut                            ; 17
   rjmp wut                            ; 18
   rjmp ext_int2                       ; 19
   rjmp t0comp

.DSEG

.org SRAM_START

scope_pin:                                         .BYTE 1   

compare:                                           .BYTE 1   
dir:                                               .BYTE 1   


.CSEG


ext_int0:
ext_int1:
t2_OV_int:
t1cap:
t1compb:
t1overflow:
t0overflow:
adc_int:                            ; 17
wut:                            ; 18
ext_int2:                       ; 19

   reti


;-----------------------------------------------

t1compa:    
   reti

;-----------------------------------------------


t2_comp_int:                           ; t2comp
   reti

;-----------------------------------------------

t0comp:

   push r16
   push r17
   push r28

   in r28,sreg
  
   lds r16,compare
   lds r17,dir

   cpi r17,1
   breq increasing

   cpi r16,0
   brne line92

   ldi r17,1
   sts dir,r17

   ldi r16,1
   rjmp wrap_up

line92:

   dec r16

   rjmp wrap_up

increasing:

   cpi r16,255
   brne line82

   clr r17
   sts dir,r17

   ldi r16,254
   rjmp wrap_up

line82:

   inc r16

wrap_up:

   sts compare,r16
   out ocr0,r16
 
   out sreg,r28

   pop r28
   pop r17
   pop r16



   reti


;*************************************************************************************************
init_ports:		;uses no regs

   sbi ddra,pa0                        ; scope_pin
   
   sbi ddrb,pb3                        ; oc0

   ret
	
;----------------------------------------

init_timer_0:


   ldi r29, (1<<wgm00) | (1<<com01) | (1<<cs02)    ; 256 prescale, phase correct pwm
   
   ;ldi r29, (1<<wgm00) | (1<<wgm01) | (1<<com01) | (1<<cs02)    ; 256 prescale, fast pwm

   out	tccr0,r29

   ldi r16,250
   out ocr0,r16                        ; compare value

   in r29,timsk
   ldi r16,1<<ocie0                    ; compare match interrupt enabled
   or r29,r16
   out timsk,r29

	ret		


;---------------------



RESET:
	ldi	r16,high(RAMEND) 
	out	SPH,r16	         
	ldi	r16,low(RAMEND)	 
	out	SPL,r16
	
   rcall init_ports

   rcall init_timer_0
   
   sei

main_loop:

   in r16,tcnt0  

   cpi r16,33
   brlo line482

   sbi porta,pa0

   rjmp line485

line482:

   cbi porta,pa0

line485:

   rjmp main_loop




