;
; A1_micro.asm
;
; Created: 27/09/2026 09:27:50 a. m.
; Author : Alexis Romero 

; ATmega328P - Arduino Nano - 16 MHz
;
; PD3 PD2 = 00 -> 100 kHz
; PD3 PD2 = 01 -> 500 kHz
; PD3 PD2 = 10 -> 1 MHz
; PD3 PD2 = 11 -> 2 MHz
; Salida: PB5 (D13)

.include "m328pdef.inc"

.cseg
.org 0x0000
    RJMP RESET


;====================================================================
; MODULO 1: CONFIGURACION DE PUERTOS
;
; Configura PB5 como salida para generar la señal cuadrada.
; Configura PD2 y PD3 como entradas digitales para seleccionar
; una de las cuatro frecuencias.
; Se habilitan las resistencias pull-up internas en ambas entradas.
;====================================================================

RESET:

    SBI DDRB, DDB5
    CBI PORTB, PORTB5

    CBI DDRD, DDD2
    CBI DDRD, DDD3

    SBI PORTD, PORTD2
    SBI PORTD, PORTD3

    RJMP MAIN


;====================================================================
; MODULO 2: LECTURA DE ENTRADAS Y SELECCION DE FRECUENCIA
;
; Se lee el puerto D y se conservan solamente los bits PD3 y PD2.
; De acuerdo con su combinación lógica se selecciona la rutina
; correspondiente a 100 kHz, 500 kHz, 1 MHz o 2 MHz.
;====================================================================

MAIN:

    IN R16, PIND
    ANDI R16, 0b00001100

    CPI R16, 0b00000000
    BREQ FREQ_100K

    CPI R16, 0b00000100
    BREQ FREQ_500K

    CPI R16, 0b00001000
    BREQ FREQ_1M

    RJMP FREQ_2M


;====================================================================
; MODULO 3: GENERACION DE 100 kHz
;
; Se invierte periódicamente el estado de PB5.
; Se utiliza R17 como contador para generar el retardo necesario.
; Después de cada cambio se vuelven a leer las entradas para
; detectar si el usuario seleccionó una frecuencia diferente.
;====================================================================

FREQ_100K:

    SBI PINB, PINB5
    LDI R17, 24

RETARDO_100K:

    DEC R17
    BRNE RETARDO_100K

    IN R16, PIND
    ANDI R16, 0b00001100

    NOP

    CPI R16, 0b00000000
    BREQ FREQ_100K

    RJMP MAIN


;====================================================================
; MODULO 4: GENERACION DE 500 kHz
;
; Se genera la señal cuadrada mediante el cambio de estado de PB5.
; Las instrucciones NOP permiten ajustar la temporización.
; Las entradas se revisan continuamente para detectar cambios.
;====================================================================

FREQ_500K:

    SBI PINB, PINB5

    IN R16, PIND
    ANDI R16, 0b00001100

    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP

    CPI R16, 0b00000100
    BREQ FREQ_500K

    RJMP MAIN


;====================================================================
; MODULO 5: GENERACION DE 1 MHz
;
; Se genera una señal cuadrada de 1 MHz mediante el cambio de
; estado de PB5 y el ajuste del número de ciclos de instrucción.
; También se verifica si la selección de entrada permanece en 10.
;====================================================================

FREQ_1M:

    SBI PINB, PINB5

    IN R16, PIND
    ANDI R16, 0b00001100

    NOP

    CPI R16, 0b00001000
    BREQ FREQ_1M

    RJMP MAIN


;====================================================================
; MODULO 6: GENERACION DE 2 MHz
;
; Para obtener 2 MHz se requiere un número mínimo de ciclos entre
; cada cambio de PB5. Se utilizan instrucciones SBIS para revisar
; directamente PD2 y PD3 sin introducir un retardo excesivo.
;
; Si alguno de los bits deja de estar en nivel alto, el programa
; regresa a MAIN para seleccionar una nueva frecuencia.
;====================================================================

FREQ_2M:

    SBI PINB, PINB5

    SBIS PIND, 2
    RJMP MAIN

    SBI PINB, PINB5

    SBIS PIND, 3
    RJMP MAIN

    SBI PINB, PINB5

    RJMP FREQ_2M