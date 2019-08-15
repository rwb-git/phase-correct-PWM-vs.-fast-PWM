; 8-15-2019
;
; phase_correct.asm
;
;     show on scope what it means
;
;     oc0 pb3    oc1a pd5    oc1b pd4    oc2 pd7
;
; I can't get timer 1 to do any pwm that makes sense
;
; phase_correct_1.asm has all three timers
; phase_correct_2.asm has timer 0 
; phase_correct_3.asm init_timer_0 has code for fast pwm and phase correct
; phase_correct_4.asm

;.include "m1284def.inc"
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


; begin_awk_here

.DSEG

.org SRAM_START

lcd_info_state:                                    .BYTE 1   
current_step:                                      .BYTE 1   
scope_pin:                                         .BYTE 1   
current_pps:                                       .BYTE 1   

compare:                                           .BYTE 1   
dir:                                               .BYTE 1   

; end_awk_here


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
; port c - lcd uses all bits except 2 and 3, which some of my doc says are i2c sda and scl, 
; as does i2c_inc.asm. but, weird - atmel mega8535 shows
; sda and scl on port c 0 and 1. what i think is that for the 8535, all i2c was handled with normal code, and any pins could be used. that is why
; the 8535 pdf does not show sda and scl. but the mega8535 has registers that do all the dirty work, 
; allowing simpler routines, i suppose. since i do
; not use that enhanced capability, i can use mega8535 with lcd and keep my i2c on portc pins 2 and 3 where they were all along. 


;;----- lcd pins -------------------
;
;	sbi ddrc,pc0 ; pins 0..6 outputs
;	sbi ddrc,pc1
;
;	sbi ddrc,pc4
;	sbi ddrc,pc5
;	sbi ddrc,pc6
;	sbi ddrc,pc7
;	
;	cbi portc,pc6	
;	cbi portc,pc7
;	cbi portc,pc4
;	cbi portc,pc5
;	
;	cbi portc,pc0	;enable...not sure what this does
;	cbi portc,pc1 ;register select...not sure what this does
;   	
;;----- end of lcd pins -------------------



;;--- port b motor winding pins ------------
;
;   sbi ddrb,pb0 ; pins 0..3 outputs
;   sbi ddrb,pb1 ; pins 0..3 outputs
;   sbi ddrb,pb2 ; pins 0..3 outputs
;   sbi ddrb,pb3 ; pins 0..3 outputs
;
;;--- end of port b motor winding pins -----


   sbi ddra,pa0                        ; scope_pin

   sbi ddrd,pd7                        ; oc2
   
   sbi ddrb,pb3                        ; oc0
   
   sbi ddrd,pd5                        ; oc1a


;; portb 4-7 are used by spi and usbtiny so use port d for pushbuttons
;   
;   rcall disable_all_windings
;
;;portd

;	cbi	ddrd,pd0    ; input pushbutton
;;	sbi	portd,pd0	; enable pullup	
;	
;   cbi	ddrd,pd1    ; input pushbutton on right
;	sbi	portd,pd1	; enable pullup	
;
;   cbi	ddrd,pd2    ; input pushbutton on left
;	sbi	portd,pd2	; enable pullup	

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


   in r16,tcnt0                        ; use this for timer 0 fast pwm

   cpi r16,33
   brlo line482

   sbi porta,pa0

   rjmp line485

line482:

   cbi porta,pa0

line485:

   rjmp main_loop




