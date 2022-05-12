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
.def zeichen=r21
.def zeichen_in =r22


.equ minimum = 1   ; Minimum und Maximum der Sprungtabelle
.equ maximum = 8



.equ x10ms = 100; Variable für die Wartezeit x10ms

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



        ldi LED_PORT,0xFF       ; 0xFF in das Register r 16 laden

        out DDRC,LED_PORT      ; alle Bits von PORTC für Ausgabe freischalten

        ldi LED_PORT,0x00    ; Alle LEDs ausschalten

        out PORTC, LED_PORT    ;



        clr zaehler            ; Register auf 0 setzen


        ldi temp, 0x00
        out TCNT0, temp         ; Register auf 0 setzen
        ldi temp, 0x9c
        out OCR0, temp           ; Register auf 156 (0-156= 157 Schritte) setzen

        sei 			; Interrupts global aktivieren


loop:                                                     ; Endlosschleife

        rcall  delay_x10ms

        rjmp loop


Sprungtabelle:
        rjmp rx_0
        rjmp rx_1
				rjmp rx_2
				rjmp rx_3
				rjmp rx_4
				rjmp rx_5
				rjmp rx_6
				rjmp rx_7






vergleiche:
        subi zeichen_in, minimum   ; Nullpunkt verschiebe
        cpi  zeichen_in, (maximum-minimum+1) ; Index auf Maximum prüfen
        brsh Fehler                 ; Index zu groß -> Fehler
        ldi ZL, LOW(Sprungtabelle)  ; Zeiger auf die Sprungtabelle laden
        ldi ZH, HIGH(Sprungtabelle)
        add ZL, zeichen_in          ; Index addieren 16 Bit
        ldi temp, 0x00
        adc ZH, temp
        ijmp                        ; indirekter Sprung in die Sprungtabelle



rx_0:
        sbic  PORTC,0x0    ; Überspringe den nächsten Befehl, wenn das Bit 0 im Port gelöscht ist
  	    rjmp  ClrBit   ; Springe zu ClrBitNow
  	    sbi   PORTC,0x0    ; Setze Bit 0 in PortC
  	     reti  ; Return from Interrupt
      ClrBit:
      cbi  PORTC, 0x0    ; Lösche Bit 0 in Port
      reti


rx_1:
        sbic  PORTC,0x1    ; Überspringe den nächsten Befehl, wenn das Bit 1 im Port gelöscht ist
  	    rjmp  ClrBit1   ; Springe zu ClrBitNow
  	    sbi   PORTC,0x1    ; Setze Bit 0 in PortC
  	    reti  ; Springe BitReady                 ; Sprung zur Marke loop
  	ClrBit1:
   	cbi  PORTC, 0x1    ; Lösche Bit 0 in Port
   	reti


 	rx_2:
				        sbic  PORTC,0x2    ; Überspringe den nächsten Befehl, wenn das Bit 2 im Port gelöscht ist
				  	    rjmp  ClrBit2   ; Springe zu ClrBitNow
				  	    sbi   PORTC,0x2    ; Setze Bit 0 in PortC
				  	    reti  ; Return from Interrupt
				  	ClrBit2:
				   	cbi  PORTC, 0x2    ; Lösche Bit 2 in Port
				   	reti  ; Return from Interrupt





						rx_3:

						        sbic  PORTC,0x3    ; Überspringe den nächsten Befehl, wenn das Bit 0 im Port gelöscht ist
						  	rjmp  ClrBit3   ; Springe zu ClrBitNow
						  	sbi   PORTC,0x3    ; Setze Bit 0 in PortC
						  	reti  ; Return from Interrupt
						  	ClrBit3:
						   	cbi  PORTC, 0x3    ; Lösche Bit 0 in Port
						   	reti  ; Return from Interrupt

						rx_4:

						        sbic  PORTC,0x4    ; Überspringe den nächsten Befehl, wenn das Bit 0 im Port gelöscht ist
						  	rjmp  ClrBit4   ; Springe zu ClrBitNow
						  	sbi   PORTC,0x4    ; Setze Bit 0 in PortC
						  	reti  ; Return from Interrupt
						  	ClrBit4:
						   	cbi  PORTC, 0x4    ; Lösche Bit 0 in Port
						   	reti  ; Return from Interrupt

						rx_5:

						        sbic  PORTC,0x5    ; Überspringe den nächsten Befehl, wenn das Bit 0 im Port gelöscht ist
						  	rjmp  ClrBit5   ; Springe zu ClrBitNow
						  	sbi   PORTC,0x5    ; Setze Bit 0 in PortC
						  	reti  ; Return from Interrupt
						  	ClrBit5:
						   	cbi  PORTC, 0x5    ; Lösche Bit 0 in Port
						   	reti  ; Return from Interrupt


						rx_6:

						        sbic  PORTC,0x6    ; Überspringe den nächsten Befehl, wenn das Bit 0 im Port gelöscht ist
						  	rjmp  ClrBit6   ; Springe zu ClrBitNow
						  	sbi   PORTC,0x6    ; Setze Bit 0 in PortC
						  	reti  ; Return from Interrupt
						  	ClrBit6:
						   	cbi  PORTC, 0x6    ; Lösche Bit 0 in Port
						   	reti  ; Return from Interrupt


						rx_7:

						    sbic  PORTC,0x7    ; Überspringe den nächsten Befehl, wenn das Bit 0 im Port gelöscht ist
						  	rjmp  ClrBit7   ; Springe zu ClrBitNow
						  	sbi   PORTC,0x7    ; Setze Bit 0 in PortC
						  	reti  ; Return from Interrupt
						  	ClrBit7:
						   	cbi  PORTC, 0x7    ; Lösche Bit 0 in Port
						   	reti  ; Return from Interrupt


Fehler:
	ldi LED_Port,0x00
	rcall led_out
	reti  ; Return from Interrupt


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
subi zeichen_in, 0x30
rjmp vergleiche



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
