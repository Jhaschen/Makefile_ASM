
.include "m32def.inc"




.def temp = r16
.def leds = r17
.def zaehler = r18
.def counter = r19

.equ x_10ms= 10 ; Wartezeit

.org 0x000
  rjmp main    ; Reset Handler

.org OC0addr
  rjmp timer0_compare  ;Timer Compare Handler





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

ldi temp, (1<<WGM01) | (1<<CS00) |  (1<<CS02) ; CTC Modus / Vorteiler Timer0 1024
out TCCR0, temp                 ;16MHZ/1024= 15,625 kHz, Overflow nach 256 Schritten => 15,625kHz/ 256 ~61 Hz = 16ms

ldi temp, (1<<OCIE0) ; OCIE0 : Interrupt bei Timer Compare Match
out TIMSK, temp

ldi temp, 156 ; 16Mhz x 10ms = 16MHZ/1024= 156,24 => Vergleichregister OCR0 = 156
out OCR0, temp




sei  ; Interrupts freigeben




loop:                                                     ; Endlosschleife

rechts:

        com leds      ; invertiere alle Bits, damit die LED-Anzeige stimmt (active low!)
	       out PORTC,leds ; Wert von r16 auf PORTC ausgeben
        com leds      ; wieder alle Bits invertieren, damit wir damit weiter machen können
        rcall wait_x_10ms
        dec counter       ; decrementiere counter (Hauptzähler)
	       lsr leds        ; Bit logisch rechts verschieben >>
        cpi counter,0x01  ; wenn nicht LED 1(0) erreicht
        breq links        ; Schalte die nächste LEd ein
        rjmp rechts       ; Lauf zurück


links:

        com leds       ; invertiere alle Bits, damit die LED-Anzeige stimmt (active low!)
	       out PORTC,leds ; Wert von r16 auf PORTC ausgeben
        com leds       ; wieder alle Bits invertieren, damit wir damit weiterrechnen können
        inc counter      ; incrementiere r20 (Hauptzähler)
	       lsl leds     ;Bit logisch links verschieben <<
        rcall wait_x_10ms
        cpi counter ,0x08 ; wenn nicht LED 8(07) erreicht
        breq rechts       ;Schalte die nächste Led ein
        rjmp links        ; Lauf zurück




        rjmp loop  			  ; relativer Sprung zur Marke loop



wait_x_10ms:
ldi  zaehler, x_10ms
schleife:
cpi zaehler,0x00 ; Register mit einer Konstanten vergleichen
brne schleife  ; Wenn Zähler != Kostante, Sprung zur Marke schleife
ret            ; return

timer0_compare:
dec zaehler  ; Zähler bei Überlauf dekrementieren
reti
