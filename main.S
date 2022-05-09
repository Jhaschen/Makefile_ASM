
.include "m32def.inc"




.def temp = r16
.def leds = r17
.def zaehler = r18

.equ x_16ms= 100 ; Wartezeit

.org 0x000
  rjmp main    ; Reset Handler
.org OVF0addr
  rjmp timer0_overflow  ;Timer Overflow Handler





main:

; Stackpointer initialsieren
ldi temp, HIGH(RAMEND) ; Ramend = 0x085F
out SPH, temp
ldi temp,LOW(RAMEND)
out SPL, temp

;PORTC auf Ausgang
ldi temp, 0xFF
out DDRC,temp

;LEDS aus
ldi leds, 0xFF

ldi temp, (1<<CS00) | (1<<CS02) ; Vorteiler Timer0 1024
out TCCR0, temp                 ;16MHZ/1024= 15,625 kHz, Overflow nach 256 Schritten => 15,625kHz/ 256 ~61 Hz = 16ms

ldi temp, (1<<TOIE0) ; TOIE0 : Interrupt bei Timer Overflow
out TIMSK, temp


sei  ; Interrupts freigeben




loop:
  out PORTC,leds ; LEDS einschalten
  com leds       ; LEDS invertieren
  rcall wait_x_16ms ; Funktionsroutine wait aufrufen
  rjmp loop



wait_x_16ms:
ldi  zaehler, x_16ms
schleife:
cpi zaehler,0x00 ; Register mit einer Konstanten vergleichen
brne schleife  ; Wenn Zähler != Kostante, Sprung zur Marke schleife
ret            ; return

timer0_overflow:
dec zaehler  ; Zähler bei Überlauf dekrementieren
reti
