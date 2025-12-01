; I2C (MASTER)
; JASON PERMANN
; RCET 3375
; 5th Semester
; Fall
; Program/Project
; 
    
;Device Setup
;-------------------------------------------------------------------------------

; Configuration
; PIC16F883 Configuration Bit Settings

; Assembly source line config statements

; CONFIG1
  CONFIG  FOSC = XT	   
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = OFF           ; Power-up Timer Enable bit (PWRT disabled)
  CONFIG  MCLRE = ON            ; RE3/MCLR pin function select bit (RE3/MCLR pin function is MCLR)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = OFF             ; Low Voltage Programming Enable bit (RB3 pin has digital I/O, HV on MCLR must be used for programming)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)

// config statements should precede project file includes.
#include <xc.inc>

    
; Include Statements

; Code Section
;-------------------------------------------------------------------------------
    
; Register/Variable Setup
    W_SAVE	    EQU 0x20 ;General Purpouse register for saving values during interrupt
    STAT_SAVE	    EQU 0x21 ;General Purpouse register for saving values during interrupt 
    AN1_DATA	    EQU	0x22 ;General Purpouse register for Saving AN1 data
    AN2_DATA	    EQU 0x23 ;General Purpouse register for Saving AN2 data
    AN3_DATA	    EQU	0x24 ;General Purpouse register for Saving AN3 data
 ;Asign A Value To A Variable
 
; Start Of Program
    PSECT resetVect,class=CODE,delta=2	;Reset Vector Adress
    GOTO Start 

    PSECT isrVect,class=CODE,delta=2
//    GOTO INTERUPT_HANDLER
    
    
; Setup Code That Runs Once At Power Up/Reset
    PSECT code,class=CODE,delta=2
Start:
    ;BANK 3
    BSF	    STATUS,5    ;Set RP0 to 1
    BSF	    STATUS,6    ;Set RP1 to 1
    MOVLW   0x07	;Move (0000|0111) to w
    MOVWF   ANSEL	;Enable Analog Input for AN0,AN1,AN2
    CLRF    ANSELH	;Disables Analog inputs for Higer level bits
    MOVLW   0x80	;move (1000|0000) to w
    MOVWF   OPTION_REG  ;Disable pull ups/ set timer 0 to WDT 1:1
   ;----------------
   ;BANK 2
    BSF	    STATUS,6    ;Set RP0 to 1
    BCF	    STATUS,5    ;Set RP1 to 0
    CLRF    CM2CON1     ;Disabels Comparator C2 Control Register 1
    CLRF    CM2CON0	;Disables Comparator C2 Control Register 0
    CLRF    CM1CON0	;Disables Comparator C1 Control Register 0
    ;---------------
    ;BANK 1
    BSF	    STATUS,5    ;Set RP0 to 1
    BCF	    STATUS,6    ;Set RP1 to 0
    MOVLW   0x00	;Move (0000|0000) to w
    MOVWF   IOCB	;Disable Interrupt on change PORTB
    CLRF    PSTRCON     ;Disable Pulse Sterring Control Register
    CLRF    PCON	;Disable BOR/Power-on-Reset/Brown-out reset
    CLRF    ADCON1	;Left justify ADC result, use VSS and VDD as reference voltages
    MOVLW   0x00	;move (0000|0000) to w
    MOVWF   PIE1	;Enable I2C interupt flag
    MOVLW   0x00        ;Move (0000|0000) to w
    MOVWF   WPUB        ;Disable Pull-Ups
    MOVLW   0x07	;Move (0000|0111) to w
    MOVWF   TRISA	;Bit 0,1,2 set to input for AN0,AN1,AN2 to function
    MOVLW   0x00        ;Move (0010|0000) to w
    MOVWF   TRISB       ;Enable Outputs
    MOVLW   0x18	;Move (0001|1000) to w
    MOVWF   TRISC       ;Set for I2C function (SDA and SCL)
    ;---------------
    ;BANK 0
    BCF	    STATUS,5    ;Set RP0 to 0
    BCF	    STATUS,6    ;Set RP1 to 0
    MOVLW   0x28
    MOVWF   SSPCON      ;I^2C  (Master Mode)
    CLRF    T1CON       ;Timer control disabled
    CLRF    CCP1CON     ;PWM1 control disabled
    CLRF    CCP2CON     ;PWM2 control disabled
    CLRF    ADCON0	;Set Fosc/8, Analog channel to AN0, and Enable ADC
    MOVLW   0x00	;Move (0000|0000) to w
    MOVWF   PORTA	;Set PORTA to all 0 at start up
    MOVLW   0x01	;Move (0000|0001)
    MOVWF   PORTB	;Set PORTB to all 0 at start up
    MOVLW   0x00	;Move (0000|0000) to w
    MOVWF   PORTC       ;Set PORTC to all 0 at start up
;-------------------------------------------------------------------------------    
   MASTER_TX:    
;--START BYTE-------------------------------------------------------------    
    BSF	    STATUS,5    ;Set RP0 to 1
    BCF	    STATUS,6    ;Set RP1 to 0
    
    BSF     SSPCON2,0	;Start Condition Set
    
    BTFSC   SSPSTAT,3	;Check start condition indicator (cleared when fisished)
    GOTO    $-1		;Loop until start indicator cleared
    
    BCF	    STATUS,5    ;Set RP0 to 0
    BCF	    STATUS,6    ;Set RP1 to 0
    
    BCF	    PIR1,3	;Clear SSPIF flag
    BTFSC   PIR1,3	;wait until SSPIF is clear
    GOTO    $-1		;GO back 1 line
;--ADRESS BYTE-------------------------------------------------------------    
    MOVLW   0x40	;Move (0010|0000)= 0x20 (bit 0 is R/W bit)
    MOVWF   SSPBUF	;Write to the MSSP buffer (Slave Adress)
    
    BCF	    PIR1,3	;Clear SSPIF flag
    BTFSC   PIR1,3	;wait until SSPIF is clear
    GOTO    $-1		;GO back 1 line
    
    BSF	    STATUS,5    ;Set RP0 to 1
    BCF	    STATUS,6    ;Set RP1 to 0
    
    BTFSC   SSPSTAT,0	;Check BF (Hardware Cleared when finished)
    GOTO    $-1		;Loop until Buffer full indicator cleared
    
    BTFSC   SSPCON2,6	;Check ACK status bit (A 0 means ACK was recived)
    GOTO    ACK_CHECK	;If no ACK was recived run ACK_CHECK sequence
    
    BTFSC   SSPSTAT,2	;Wait for Read/Write bit to clear
    GOTO    $-1		;GO back 1 line
    
    BCF	    STATUS,5    ;Set RP0 to 0
    BCF	    STATUS,6    ;Set RP1 to 0
    
    BCF	    PIR1,3	;Clear SSPIF flag
    BTFSC   PIR1,3	;wait until SSPIF is clear
    GOTO    $-1		;GO back 1 line
    
;--ANALOG_1-------------------------------------------------------------     
    CALL    ANALOG_READ1
    MOVWF   SSPBUF	;Write to the MSSP buffer ANALOG DATA
    
    BCF	    PIR1,3	;Clear SSPIF flag
    BTFSC   PIR1,3	;wait until SSPIF is clear
    GOTO    $-1		;GO back 1 line
    
    BSF	    STATUS,5    ;Set RP0 to 1
    BCF	    STATUS,6    ;Set RP1 to 0
    
    BTFSS   SSPSTAT,0	;Check BF (Hardware Cleared when finished)
    GOTO    $-1		;GO back 1 line
    
    BCF	    STATUS,5    ;Set RP0 to 0
    BCF	    STATUS,6    ;Set RP1 to 0
    
    BCF	    PIR1,3	;Clear SSPIF flag
    BTFSC   PIR1,3	;wait until SSPIF is clear
    GOTO    $-1		;GO back 1 line
    
    BSF	    STATUS,5    ;Set RP0 to 1
    BCF	    STATUS,6    ;Set RP1 to 0
    
    BTFSC   SSPSTAT,0	;Check BF (Cleared when finished)
    GOTO    $-1		;Loop until Buffer full indicator cleared
    
    BTFSC   SSPCON2,6	;Check ACK status bit (A 0 means ACK was recived)
    GOTO    ACK_CHECK	;If no ACK was recived run ACK_CHECK sequence
      
    BTFSC   SSPSTAT,2	;Wait for Read/Write bit to clear
    GOTO    $-1		;GO back 1 line
    
    BCF	    STATUS,5    ;Set RP0 to 0
    BCF	    STATUS,6    ;Set RP1 to 0
    
    BCF	    PIR1,3	;Clear SSPIF flag
    BTFSC   PIR1,3	;wait until SSPIF is clear
    GOTO    $-1		;GO back 1 line
    
;--ANALOG_2-------------------------------------------------------------    
    CALL    ANALOG_READ2
    MOVWF   SSPBUF	;Write to the MSSP buffer ANALOG DATA
    
    BCF	    PIR1,3	;Clear SSPIF flag
    BTFSC   PIR1,3	;wait until SSPIF is clear
    GOTO    $-1		;GO back 1 line
    
    BSF	    STATUS,5    ;Set RP0 to 1
    BCF	    STATUS,6    ;Set RP1 to 0
    
    BTFSS   SSPSTAT,0	;Check BF (Hardware Cleared when finished)
    GOTO    $-1		;GO back 1 line
    
    BCF	    STATUS,5    ;Set RP0 to 0
    BCF	    STATUS,6    ;Set RP1 to 0
    
    BCF	    PIR1,3	;Clear SSPIF flag
    BTFSC   PIR1,3	;wait until SSPIF is clear
    GOTO    $-1		;GO back 1 line
    
    BSF	    STATUS,5    ;Set RP0 to 1
    BCF	    STATUS,6    ;Set RP1 to 0
    
    BTFSC   SSPSTAT,0	;Check BF (Cleared when finished)
    GOTO    $-1		;Loop until Buffer full indicator cleared
	
    BTFSC   SSPCON2,6	;Check ACK status bit (A 0 means ACK was recived)
    GOTO    ACK_CHECK	;If no ACK was recived run ACK_CHECK sequence
       
    BTFSC   SSPSTAT,2	;Wait for Read/Write bit to clear
    GOTO    $-1		;GO back 1 line
    
    BCF	    STATUS,5    ;Set RP0 to 0
    BCF	    STATUS,6    ;Set RP1 to 0
    
    BCF	    PIR1,3	;Clear SSPIF flag
    BTFSC   PIR1,3	;wait until SSPIF is clear
    GOTO    $-1		;GO back 1 line
    
;--ANALOG_3-------------------------------------------------------------
    CALL    ANALOG_READ3
    MOVWF   SSPBUF	;Write to the MSSP buffer ANALOG DATA
    
    BCF	    PIR1,3	;Clear SSPIF flag
    BTFSC   PIR1,3	;wait until SSPIF is clear
    GOTO    $-1		;GO back 1 line
    
    BSF	    STATUS,5    ;Set RP0 to 1
    BCF	    STATUS,6    ;Set RP1 to 0
        
    BTFSS   SSPSTAT,0	;Check BF (Hardware Cleared when finished)
    GOTO    $-1		;GO back 1 line
    
    BCF	    STATUS,5    ;Set RP0 to 0
    BCF	    STATUS,6    ;Set RP1 to 0
    
    BCF	    PIR1,3	;Clear SSPIF flag
    BTFSC   PIR1,3	;wait until SSPIF is clear
    GOTO    $-1		;GO back 1 line
    
    BSF	    STATUS,5    ;Set RP0 to 1
    BCF	    STATUS,6    ;Set RP1 to 0
    
    BTFSC   SSPSTAT,0	;Check BF (Cleared when finished)
    GOTO    $-1		;Loop until Buffer full indicator cleared
    
    BTFSC   SSPCON2,6	;Check ACK status bit (A 0 means ACK was recived)
    GOTO    ACK_CHECK	;If no ACK was recived run ACK_CHECK sequence
      
    BTFSC   SSPSTAT,2	;Wait for Read/Write bit to clear 
    GOTO    $-1		;GO back 1 line
    
    BCF	    STATUS,5    ;Set RP0 to 0
    BCF	    STATUS,6    ;Set RP1 to 0
    
    BCF	    PIR1,3	;Clear SSPIF flag
    BTFSC   PIR1,3	;wait until SSPIF is clear
    GOTO    $-1		;GO back 1 line
    
    GOTO    STOP	;Run STOP sequence
    
;--STOP BYTE-------------------------------------------------------------    
    STOP:
    BSF	    STATUS,5    ;Set RP0 to 1
    BCF	    STATUS,6    ;Set RP1 to 0

    MOVLW   0x04	;Move (0000|0100)
    MOVWF   SSPCON2	;Stop Condistion set
    
    BTFSC   SSPSTAT,4	;Check Stop condition indicator (Cleared when finished)
    GOTO    $-1		;Loop until Stop indicator is cleared
    
    BCF	    STATUS,5    ;Set RP0 to 0
    BCF	    STATUS,6    ;Set RP1 to 0
    
    BCF	    PIR1,3	;Clear SSPIF flag
    BTFSC   PIR1,3	;wait until SSPIF is clear
    GOTO    $-1		;GO back 1 line
    
    GOTO    MASTER_TX	;Loop continously     
    
    ACK_CHECK:
    NOP	;	    No Operation
    NOP		    ;No Operation
    NOP		    ;No Operation
    NOP		    ;No Operation
    NOP		    ;No Operation
    NOP		    ;No Operation
    NOP		    ;No Operation
    NOP		    ;No Operation
    NOP		    ;No Operation
    NOP		    ;No Operation
    GOTO    STOP    ;Run Stop sequence
    
    ANALOG_READ1:
    MOVLW   0x41	;Move (0100|0001) to w
    MOVWF   ADCON0	;Set Fosc/8, Analog channel to AN0, and Enable ADC
    BSF	    ADCON0,0	;Enable ADC
    BSF	    ADCON0,1	;Start Conversion 
    MOVF    ADRESH,0	;Take ADC value and move to w
    MOVWF   AN1_DATA	;Move ADC value to AN1_Data register
    
    RRF	    AN1_DATA,1	;Shift AN1_DATA to the Right by 1
    BCF	    STATUS,0	;Clear Carry bit so the next shift loads a 0
    RRF	    AN1_DATA,1	;Shift AN1_DATA to the Right by 1
    BCF	    STATUS,0	;Clear Carry bit so the next shift loads a 0
    RRF	    AN1_DATA,1	;Shift AN1_DATA to the Right by 1
    BCF	    STATUS,0	;Clear Carry bit so the next shift loads a 0
    
    MOVLW   0x20	;Move (0010|0000) to W
    ADDWF   AN1_DATA,1	;Add W to F for Indirect addressing of AN1_DATA
    
    MOVF    AN1_DATA,0	;Move Indirect addresse + Analog data AN1 for TX
    
    RETURN		;RETURN
    
    ANALOG_READ2:
    MOVLW   0x45	;Move (0100|0101) to w
    MOVWF   ADCON0	;Set Fosc/8, Analog channel to AN1, and Enable ADC
    BSF	    ADCON0,0	;Enable ADC
    BSF	    ADCON0,1	;Start Conversion 
    MOVF    ADRESH,0	;Take ADC value and move to w
    MOVWF   AN2_DATA	;Move ADC value to AN2_Data register
    
    RRF	    AN2_DATA,1	;Shift AN2_DATA to the Right by 1
    BCF	    STATUS,0	;Clear Carry bit so the next shift loads a 0
    RRF	    AN2_DATA,1	;Shift AN2_DATA to the Right by 1
    BCF	    STATUS,0	;Clear Carry bit so the next shift loads a 0
    RRF	    AN2_DATA,1	;Shift AN2_DATA to the Right by 1
    BCF	    STATUS,0	;Clear Carry bit so the next shift loads a 0
	
    MOVLW   0x40	;Move (0100|0000) to W
    ADDWF   AN2_DATA,1	;Add W to F for Indirect addressing of AN2_DATA
    
    MOVF    AN2_DATA,0	;Move Indirect addresse + Analog data AN1 for TX
    
    RETURN		;RETURN
    
    ANALOG_READ3:
    MOVLW   0x49	;Move (0100|1001) to w
    MOVWF   ADCON0	;Set Fosc/8, Analog channel to AN2, and Enable ADC
    BSF	    ADCON0,0	;Enable ADC
    BSF	    ADCON0,1	;Start Conversion 
    MOVF    ADRESH,0	;Take ADC value and move to w
    MOVWF   AN3_DATA	;Move ADC value to AN3_Data register
    
    RRF	    AN3_DATA,1	;Shift AN3_DATA to the Right by 1
    BCF	    STATUS,0	;Clear Carry bit so the next shift loads a 0
    RRF	    AN3_DATA,1	;Shift AN3_DATA to the Right by 1
    BCF	    STATUS,0	;Clear Carry bit so the next shift loads a 0
    RRF	    AN3_DATA,1	;Shift AN3_DATA to the Right by 1
    BCF	    STATUS,0	;Clear Carry bit so the next shift loads a 0
    
    MOVLW   0x80	;Move (1000|0000) to W
    ADDWF   AN3_DATA,1	;Add W to F for Indirect addressing of AN3_DATA
    
    MOVF    AN3_DATA,0	;Move Indirect addresse + Analog data AN1 for TX
    
    RETURN		;RETURN
    
    END			;End OF Code. This Is Required