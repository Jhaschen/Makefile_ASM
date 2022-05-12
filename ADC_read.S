.include "m32def.inc"

.org 0x0000
	rjmp main		  ; Reset Handler

.org OC0addr
	rjmp timer0_compare	  ; Timer Overflow Handler

.org URXCaddr          ;  USART Rx Complete Handler
	rjmp uart_int_rx


.def LED_Port = r16                 ;Makrodefintion LED_PORT

.def zaehler = r17
.def temp = r18
.def adclow =r19
.def adchigh =r20
.def zeichen=r21
.def zeichen_in =r22


.equ minimum = 1   ; Minimum und Maximum der Sprungtabelle
.equ maximum = 8



.equ x10ms = 1000; Variable für die Wartezeit x10ms

.equ F_CPU = 16000000 ; Systemtakt
.equ BAUD= 9600	; Baudrate

; Berechnungen
.equ UBRR_V =((F_CPU+BAUD*8)/(16*BAUD)-1) ; Baudrate





main:                              ; Start (reset)

	; Stackpointer initialisieren

	ldi temp, HIGH(RAMEND)    ; Die oberen 8 Bit der Stackpointeradresse (0x085F) in das Register r20 schreiben
	out SPH, temp		; Die oberen 8 Adressbits in das SPH Stackpointer high Register schreiben
	ldi temp, LOW(RAMEND)    ; Die unteren 8 Bit der Stackpointeradresse (0x085F) in das Register r20 schreiben
	out SPL, temp		; Die unteren 8 Adressbits in das SPL Stackpointer low Register schreiben

	;Init Timer 0 Overflow

	ldi temp, (1<<WGM01)|(1<<CS00)|(1<< CS02) ; CS00 und CS02 setzen : Vorteiler = 1024
	out TCCR0, temp      	; TimerControlRegister schreiben ; 16Mhz/ 1024 = 15625Hz / 256 = 61,3 Hz => 1/61,3Hz = ~ 16ms

	ldi temp, (1<<OCIE0)	; OCIE0 Interrupt bei Timer Compare match
	out TIMSK, temp		; Timer/Counter Interrupt Mask Register setzen

	; Init UART Schnittstelle 9600 Baus , 8 Zeichenbits, ! Stoppbit, keine Paritätsbits

	;UCSRC Register Frame-Format setzen 8but, 1 Stoppbit, keine Paritätsbits

	ldi temp, (1<<URSEl)|(1<<UCSZ0)|(1<< UCSZ1)
	out UCSRC, temp

	; UCSRB TX und RX und RX Interrupt einschalten

	ldi temp, (1<<TXEN)|(1<< RXEN) |(1<< RXCIE)
	out UCSRB, temp

	; Baudrate einstellen
	ldi temp, HIGH(UBRR_V)
	out UBRRH, temp

	ldi temp, lOW(UBRR_V)
	out UBRRL, temp

  ; ADC Init
	ldi temp, (1<<MUX0)|(1<<MUX1)|(1<< MUX2) ; Kanal 7 PINA7 auswählen
	out ADMUX,temp
	ldi temp, (1<<ADPS0)|(1<<ADPS1)|(1<< ADPS2) |(1<<ADEN)|(1<< ADSC)  ; Vorteiler == 128 => 16Mhz/128= 125kHz / ADC enable , Single Conversation
  out ADCSRA,temp



        ldi LED_PORT,0xFF       ; 0xFF in das Register r 16 laden

        out DDRC,LED_PORT      ; alle Bits von PORTC für Ausgabe freischalten

        ldi LED_PORT,0xFF    ; Alle LEDs ausschalten

        out PORTC, LED_PORT    ;

				ldi temp, 0x00  ; PORTA auf Eingang setzen
				out DDRA, temp

				ldi temp, 0xFF ; Pullup Widerstände aktivieren
				out PORTA, temp



        clr zaehler            ; Register auf 0 setzen


        ldi temp, 0x00
        out TCNT0, temp         ; Register auf 0 setzen
        ldi temp, 0x9c
        out OCR0, temp           ; Register auf 156 (0-156= 157 Schritte) setzen

        sei 			; Interrupts global aktivieren


loop:                                                     ; Endlosschleife

       ldi ZL, LOW(my_string *2)
			 ldi ZH, HIGH(my_string *2)
			 rcall string_out
			 rcall adc_read
			 mov LED_PORT, adclow
			 rcall led_out

			  rcall  delay_x10ms
				mov LED_PORT, adchigh
				rcall led_out
 				rcall  delay_x10ms
        rjmp loop


adc_read:
		sbi ADCSRA,ADSC   ; ADC-Wandlung starten
	adc_wait:
		sbic ADCSRA, ADSC  ; Prüfe, ob Wandlung beendet ist(ADSC Bit wird gelöscht)
		rjmp adc_wait

		in adclow, ADCL  ; ADC Wert einlesen
		in adchigh, ADCH ; immer zuerst das LOW Byte, dann das gesperrte High Byte
		ret


string_out:
		lpm         ; Byte aus dem Flash-Speicher in das Z-Register laden, Zugriff erfolgt über Register r0
		and r0,r0   ; =Null ? => Ende
		breq string_out_ende
	string_wait:
		sbis UCSRA,UDRE ; Prüfe, ob UDR Register leer ist
		rjmp string_wait
		out UDR, r0
    adiw ZH:ZL, 1    ; Zeiger erhöhen ( auf das nächste Byte); Reihenfolge beachten erst ZH dann ZL.
		rjmp string_out
	string_out_ende:
		ret


led_out:
	   com LED_Port
	   out     PORTC, LED_Port           ; LEDs einschalten bzw. ausschalten
	   com LED_Port
     ret

uart_out:
			sbis UCSRA, UDRE                ; Prüfe, ob UDR Register leer ist
			rjmp uart_out 			; Wenn Register nicht leer ist: warten
			out UDR, zeichen	        ; Zeichen senden
			ret

uart_in:
			sbis UCSRA,RXC
			rjmp uart_in
			in zeichen_in, UDR
			ret

uart_int_rx:
in zeichen_in,UDR   ; Zeichen einlesen
;subi zeichen_in, 0x30
reti



delay_x10ms:
			ldi zaehler, x10ms 		; Zaehler mit der Anzahl der Durchlaeufe laden x mal 16ms
			ldi temp, 0x00                 ; Timer Zählrefgister auf 0 setzen
			out TCNT0, temp

schleife_1:
			cpi zaehler,0x00 ;		; prüfe, ob Zaehler ==0
			brne schleife_1			; wenn nicht erneuet prüfen
			ret				; Springe zurück ins Hauptprogramm




timer0_compare:
			dec zaehler ; Bei Timer Overflow Zähler incrementieren
			reti

my_string: .db "Assembler ist toll !!",10,13,0 ; String definieren und in den Flash-Speicher ; 13 10 => CR LF Zeilenumbruch ;
