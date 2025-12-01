; I2C (SLAVE)
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
    DATA1_SAVE	    EQU 0x22 ;General Purpouse register Saving SERVO1 data
    DATA2_SAVE	    EQU 0x23 ;General Purpouse register Saving SERVO2 data
    DATA3_SAVE	    EQU 0x24 ;General Purpouse register Saving SERVO3 data
    TIME	    EQU 0x25 ;General Purpouse register Pulse Width time
    ADC_SAVE	    EQU	0x26 ;General Purpouse register Moving Program Counter
    BUFFER_SAVE	    EQU 0x27 ;General Purpouse register Saving current I2C data
	    
 ;Asign A Value To A Variable
 
; Start Of Program
    PSECT resetVect,class=CODE,delta=2	;Reset Vector Adress
    GOTO Start 

    PSECT isrVect,class=CODE,delta=2
    GOTO INTERUPT_HANDLER
    
    
; Setup Code That Runs Once At Power Up/Reset
    PSECT code,class=CODE,delta=2
Start:
    ;BANK 3
    BSF	    STATUS,5    ;Set RP0 to 1
    BSF	    STATUS,6    ;Set RP1 to 1
    MOVLW   0x00	;Move (0000|0000) to w
    MOVWF   ANSEL	;Enable Analog Input for AN0
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
    MOVLW   0x40	;Move (0100|0000)
    MOVWF   SSPADD	;Slave Adress = 0x20 (the 0 bit is R/W bit)
    CLRF    PSTRCON     ;Disable Pulse Sterring Control Register
    CLRF    PCON	;Disable BOR/Power-on-Reset/Brown-out reset
    CLRF    ADCON1	;Left justify ADC result, use VSS and VDD as reference voltages
    MOVLW   0x00	;move (0000|0000) to w
    MOVWF   PIE1	;Enable I2C interupt flag
    MOVLW   0x00        ;Move (0000|0000) to w
    MOVWF   WPUB        ;Disable Pull-Ups
    MOVLW   0x00	;Move (0000|0111) to w
    MOVWF   TRISA	;Enable Outputs
    MOVLW   0x00        ;Move (0000|0000) to w
    MOVWF   TRISB       ;Enable Outputs
    MOVLW   0x18	;Move (0001|1000) to w
    MOVWF   TRISC       ;Set for I2C function (SDA and SCL)
    BSF	    SSPCON2,0	;enable clk stretching
    ;---------------
    ;BANK 0
    BCF	    STATUS,5    ;Set RP0 to 0
    BCF	    STATUS,6    ;Set RP1 to 0
    MOVLW   0x26	;Move (0010|0110) to w
    MOVWF   SSPCON      ;I^2C  (Slave 7-bit)
    CLRF    T1CON       ;Timer control disabled
    CLRF    CCP1CON     ;PWM1 control disabled
    CLRF    CCP2CON     ;PWM2 control disabled
    CLRF    ADCON0	;Disable ADC
    MOVLW   0x00	;Move (0000|0000) to w
    MOVWF   PORTA	;Set PORTA to all 0 at start up
    MOVLW   0x00	;Move (0000|0000)
    MOVWF   PORTB	;Set PORTB to all 0 at start up
    MOVLW   0x00	;Move (0000|0000) to w
    MOVWF   PORTC       ;Set PORTC to all 0 at start up
    
;------------------------------------------------------------------------------- 
    TIMER2_SETUP:
    BCF	    STATUS,5    ;Set RP0 to 0
    BCF	    STATUS,6    ;Set RP1 to 0
    
    MOVLW   0x00	;move (0000|0000) to w
    MOVWF   PIR1	;Set TMR2 flag to 0 at set up
    
    MOVLW   0x00	;move (0000|0000) to w
    MOVWF   TMR2	;Start TMR2 at 0x00 at startup
    
    MOVLW   0x00	;move (0000|0000) to w
    MOVWF   T2CON	;Keep TMR2 off until ready
    
    BSF	    STATUS,5    ;Set RP0 to 1
    BCF	    STATUS,6    ;Set RP1 to 0
    
    MOVLW   0x02	;move (0000|0010) to w
    MOVWF   PIE1	;Enable TMR2 interupt flag
    
    MOVLW   0xFF	;move (1111|1111) to w
    MOVWF   PR2		;Set count so that TMR2 compares itself too at max, 0xFF
    
    BCF	    STATUS,5    ;Set RP0 to 0
    BCF	    STATUS,6    ;Set RP1 to 0
    
    MOVLW   0xC0	;move (1010|0000) to w
    MOVWF   INTCON	;Eable Global and Pereperial interupts
    
    MOVLW   0x26	;move (0010|0110) to w
    MOVWF   T2CON	;Set Prescaler to 1:16, Postscaler to 1:5, Turn on TRM2

    SLAVE_RX:   
    BSF	    STATUS,5    ;Set RP0 to 1
    BCF	    STATUS,6    ;Set RP1 to 0
    
    MOVLW   0x00	;move (0000|0000) to w
    MOVWF   PIE1	;Disable TMR2 interupt flag 
    
    BTFSS   SSPSTAT,0	;Wait until BF is set
    GOTO    $-1		;GO back 1 line
    
    BCF	    STATUS,5    ;Set RP0 to 0
    BCF	    STATUS,6    ;Set RP1 to 0
    
    BTFSS   PIR1,3	;Wait until SSPIF is set
    GOTO    $-1         ;GO back 1 line
    
    BCF	    STATUS,5    ;Set RP0 to 0
    BCF	    STATUS,6    ;Set RP1 to 0
    
    BCF	    SSPCON,4	;Turn on clk stretch
    
    BTFSC   SSPCON,4
    GOTO    $-1		;GO back 1 line
    
    MOVF    SSPBUF,0	;Move causes READ to occur
    MOVWF   BUFFER_SAVE	;Save currenct SSPBUFF value
    
    BSF	    STATUS,5    ;Set RP0 to 1
    BCF	    STATUS,6    ;Set RP1 to 0
    
    BTFSC   SSPSTAT,5	;if adrress was sent bit is 0
    CALL    DATA_SAVE	;CALL DATA_SAVE sequence
      
    BSF	    STATUS,5    ;Set RP0 to 1
    BCF	    STATUS,6    ;Set RP1 to 0
    
    BTFSC   SSPSTAT,0	;Wait unitl BF goes low
    GOTO    $-1		;GO back 1 line
    
    BCF	    STATUS,5    ;Set RP0 to 0
    BCF	    STATUS,6    ;Set RP1 to 0
    
    BCF	    PIR1,3	;Clear SSPIF
    
    BTFSC   PIR1,3	;Wait until SSPIF is set
    GOTO    $-1		;GO back 1 line
    
    BSF	    SSPCON,4	;turn off clk stretch
    
    BTFSS   SSPCON,4
    GOTO    $-1		;GO back 1 line
    
    BSF	    STATUS,5    ;Set RP0 to 1
    BCF	    STATUS,6    ;Set RP1 to 0
    
    BTFSC   SSPSTAT,4	;Wait until Stop bit is set
    CALL    TMR2_ON	;CALL TMR2_ON Sequence
    
    BCF	    STATUS,5    ;Set RP0 to 0
    BCF	    STATUS,6    ;Set RP1 to 0
    
    BTFSC   PORTA,0	;Check user flag to see if interupt occured
    GOTO    SERVO_READ	;If interupt has occured run SERVO_READ sequence
    
    GOTO    SLAVE_RX	;Loop continously
    
    TMR2_ON: 
    BSF	    STATUS,5    ;Set RP0 to 1
    BCF	    STATUS,6    ;Set RP1 to 0
    
    MOVLW   0x02	;move (0000|0010) to w
    MOVWF   PIE1	;Enable TMR2 interupt flag  
  
    RETURN		;Return to MAIN
    
    DATA_SAVE:
    BCF	    STATUS,5    ;Set RP0 to 0
    BCF	    STATUS,6    ;Set RP1 to 0
    
    MOVF    BUFFER_SAVE,0   ;Take saved data to move into Servo Data registers
    
    BTFSC   BUFFER_SAVE,5   ;Check saved data for indirect adressing (0010|0000)
    MOVWF   DATA1_SAVE	    ;If bit 5 is set load value to SERVO_1
    
    BTFSC   BUFFER_SAVE,6   ;Check saved data for indirect adressing (0100|0000)
    MOVWF   DATA2_SAVE	    ;If bit 6 is set load value to SERVO_2
	
    BTFSC   BUFFER_SAVE,7   ;Check saved data for indirect adressing (1000|0000)
    MOVWF   DATA3_SAVE	    ;If bit 7 is set load value to SERVO_3
    
    RETURN		    ;RETURN to MAIN
    
    INTERUPT_HANDLER:
    MOVWF   W_SAVE	;Move w to w_Save
    MOVF    STATUS,0	;Move Status to w
    MOVWF   STAT_SAVE	;Move w to Stat_Save
    
    BCF	    STATUS,5    ;Set RP0 to 0
    BCF	    STATUS,6    ;Set RP1 to 0
    
    BCF	    PIR1,1	;Clear TMR2 flag (20ms) 
    
    BSF	    PORTA,0	;Set user flag to run SERVO_READ 
    
    MOVF    STAT_SAVE,0	;Move STAT_SAVE to w
    MOVWF   STATUS	;Move w to STATUS
    MOVF    W_SAVE,0	;Move w_SAVE to w
    
    RETFIE		;Return From Interupt
    
    SERVO_READ:
;---SERVO_1-------------------------------------------------------------
    BTFSC   DATA1_SAVE ,5    ;Check Indirect adrress bit (0010|0000)
    BSF	    PORTB,3	     ;If adrress is correct set user flag for PWM1
    
    BTFSC   DATA1_SAVE ,0    ;Check if DATA1_SAVE bit 0 is 1 or 0
    CALL    BIT_0	     ;CALL sequence to add 1 to PCL counter
    
    BTFSC   DATA1_SAVE ,1    ;Check if DATA1_SAVE bit 1 is 1 or 0
    CALL    BIT_1	     ;CALL sequence to add 2 to PCL counter
	
    BTFSC   DATA1_SAVE ,2    ;Check if DATA1_SAVE bit 2 is 1 or 0
    CALL    BIT_2	     ;CALL sequence to add 4 to PCL counter
    
    BTFSC   DATA1_SAVE ,3    ;Check if DATA1_SAVE bit 3 is 1 or 0
    CALL    BIT_3	     ;CALL sequence to add 8 to PCL counter
	
    BTFSC   DATA1_SAVE ,4    ;Check if DATA1_SAVE bit 4 is 1 or 0
    CALL    BIT_4	     ;CALL sequence to add 10 to PCL counter
    
    MOVF    ADC_SAVE,0	     ;Move the value of DATA1_SAVE bits checked to w
	
    BTFSC   PORTB,3	     ;Check if User flag for PWM1 is set
    CALL    POSITION	     ;If servo address is correct goto look up table
    
;---SERVO_2---------------------------------------------------------------------  
    MOVLW   0x00	     ;Move (0000|0000) to w
    MOVWF   ADC_SAVE	     ;Clear ADC_SAVE for next check
 
    BTFSC   DATA2_SAVE,6     ;Check Indirect adrress bit (0100|0000)
    BSF	    PORTB,4	     ;If adrress is correct set user flag for PWM2
    
    BTFSC   DATA2_SAVE ,0    ;Check if DATA2_SAVE bit 0 is 1 or 0
    CALL    BIT_0	     ;CALL sequence to add 1 to PCL counter
    
    BTFSC   DATA2_SAVE ,1    ;Check if DATA2_SAVE bit 1 is 1 or 0
    CALL    BIT_1	     ;CALL sequence to add 2 to PCL counter
	
    BTFSC   DATA2_SAVE ,2    ;Check if DATA2_SAVE bit 2 is 1 or 0
    CALL    BIT_2	     ;CALL sequence to add 4 to PCL counter
    
    BTFSC   DATA2_SAVE ,3    ;Check if DATA2_SAVE bit 3 is 1 or 0
    CALL    BIT_3	     ;CALL sequence to add 8 to PCL counter
	
    BTFSC   DATA2_SAVE ,4    ;Check if DATA2_SAVE bit 4 is 1 or 0
    CALL    BIT_4	     ;CALL sequence to add 10 to PCL counter
    
    MOVF    ADC_SAVE,0	     ;Move the value of DATA2_SAVE bits checked to w
    
    BTFSC   PORTB,4	     ;Check if User flag for PWM2 is set
    CALL    POSITION	     ;If servo address is correct goto look up table
    
;---SERVO_3--------------------------------------------------------------------- 
    MOVLW   0x00	     ;Move (0000|0000) to w
    MOVWF   ADC_SAVE	     ;Clear ADC_SAVE for next check
 
    BTFSC   DATA3_SAVE,7     ;Check Indirect adrress bit (1000|0000)
    BSF	    PORTB,5	     ;If adrress is correct set user flag for PWM3

    BTFSC   DATA3_SAVE ,0    ;Check if DATA3_SAVE bit 0 is 1 or 0
    CALL    BIT_0	     ;CALL sequence to add 1 to PCL counter
    
    BTFSC   DATA3_SAVE ,1    ;Check if DATA3_SAVE bit 1 is 1 or 0
    CALL    BIT_1	     ;CALL sequence to add 2 to PCL counter
	
    BTFSC   DATA3_SAVE ,2    ;Check if DATA3_SAVE bit 2 is 1 or 0
    CALL    BIT_2	     ;CALL sequence to add 4 to PCL counter
    
    BTFSC   DATA3_SAVE ,3    ;Check if DATA3_SAVE bit 3 is 1 or 0
    CALL    BIT_3	     ;CALL sequence to add 8 to PCL counter
	
    BTFSC   DATA3_SAVE ,4    ;Check if DATA3_SAVE bit 4 is 1 or 0
    CALL    BIT_4	     ;CALL sequence to add 10 to PCL counter
    
    MOVF    ADC_SAVE,0	     ;Move the value of DATA3_SAVE bits checked to w
	
    BTFSC   PORTB,5	     ;Check if User flag for PWM3 is set
    CALL    POSITION	     ;If servo address is correct goto look up table
    
    GOTO    END_READ	     ;All 3 Servos read and PWM set, run end sequence
   
    END_READ:
    BCF	    PORTB,0	;Clear flag to give servo Pulse space for rest of 20ms period
    BCF	    PORTB,1	;Clear flag to give servo Pulse space for rest of 20ms period
    BCF	    PORTB,2	;Clear flag to give servo Pulse space for rest of 20ms period
    
    BCF	    PORTB,3	;Clear flag to reset for next Pulse Width
    BCF	    PORTB,4	;Clear flag to reset for next Pulse Width 
    BCF	    PORTB,5	;Clear flag to reset for next Pulse Width 
    
    BCF	    PORTA,0	;Clear flag to reset for next Pulse Width
    
    MOVLW   0x00	;Move (0000|0000) to w
    MOVWF   ADC_SAVE	;Clear ADC_SAVE for next check
    
    MOVLW   0x00	;Move (0000|0000) to w
    MOVWF   DATA1_SAVE 	;Clear BUFFER_SAVE for next check
    
    MOVLW   0x00	;Move (0000|0000) to w
    MOVWF   DATA2_SAVE 	;Clear BUFFER_SAVE for next check
    
    MOVLW   0x00	;Move (0000|0000) to w
    MOVWF   DATA3_SAVE 	;Clear BUFFER_SAVE for next check
    
    GOTO    SLAVE_RX	;Loop back to MAIN program
    
    BIT_0:
    MOVLW   0x01	;Decimal 1
    ADDWF   ADC_SAVE	;ADD w to ADC_SAVE
    RETURN		;RETURN
    
    BIT_1:
    MOVLW   0x02	;Decimal 2
    ADDWF   ADC_SAVE	;ADD w to ADC_SAVE
    RETURN		;RETURN
    
    BIT_2:
    MOVLW   0x04	;Decimal 4
    ADDWF   ADC_SAVE	;ADD w to ADC_SAVE
    RETURN		;RETURN
    
    BIT_3:
    MOVLW   0x08	;Decimal 8
    ADDWF   ADC_SAVE	;ADD w to ADC_SAVE
    RETURN		;RETURN
    
    BIT_4:
    MOVLW   0x10	;Decimal 16
    ADDWF   ADC_SAVE	;ADD w to ADC_SAVE
    RETURN		;RETURN
    
    POSITION:
    ADDWF   PCL,1   ;ADD working register to program counter  
    GOTO    P5	;0
    GOTO    P6	;1
    GOTO    P6	;2
    GOTO    P7	;3
    GOTO    P8	;4
    GOTO    P8	;5
    GOTO    P9	;6
    GOTO    P10	;7
    GOTO    P10	;8
    GOTO    P11	;9
    GOTO    P12	;10
    GOTO    P12	;11
    GOTO    P13	;12
    GOTO    P14	;13
    GOTO    P14	;14
    GOTO    P15	;15
    GOTO    P16	;16
    GOTO    P16 ;17
    GOTO    P17	;18
    GOTO    P18	;19
    GOTO    P18	;20
    GOTO    P19	;21
    GOTO    P20	;22
    GOTO    P20	;23
    GOTO    P21	;24
    GOTO    P22	;25
    GOTO    P22	;26
    GOTO    P23	;27
    GOTO    P24	;28
    GOTO    P24	;29
    GOTO    P25	;30
    GOTO    P25	;31
    GOTO    P25	;Extra in case 
    
    P5:
    MOVLW   0x32    ;Decimal 50
    MOVWF   TIME    ;Set Delay value for desired Pulse Width
    BTFSC   PORTB,3 ;Check PWM1 User flag
    BSF	    PORTB,0 ;Set PWM1 bit
    BTFSC   PORTB,4 ;Check PWM2 User flag
    BSF	    PORTB,1 ;Set PWM2 bit
    BTFSC   PORTB,5 ;Check PWM3 User flag
    BSF	    PORTB,2 ;Set PWM3 bit
    GOTO    DELAY   ;GOTO Pulse Width Delay
    
    P6:
    MOVLW   0x3C    ;Decimal 60
    MOVWF   TIME    ;Set Delay value for desired Pulse Width
    BTFSC   PORTB,3 ;Check PWM1 User flag
    BSF	    PORTB,0 ;Set PWM1 bit
    BTFSC   PORTB,4 ;Check PWM2 User flag
    BSF	    PORTB,1 ;Set PWM2 bit
    BTFSC   PORTB,5 ;Check PWM3 User flag
    BSF	    PORTB,2 ;Set PWM3 bit
    GOTO    DELAY   ;GOTO Pulse Width Delay
    
    P7:
    MOVLW   0x46    ;Decimal 70
    MOVWF   TIME    ;Set Delay value for desired Pulse Width
    BTFSC   PORTB,3 ;Check PWM1 User flag
    BSF	    PORTB,0 ;Set PWM1 bit
    BTFSC   PORTB,4 ;Check PWM2 User flag
    BSF	    PORTB,1 ;Set PWM2 bit
    BTFSC   PORTB,5 ;Check PWM3 User flag
    BSF	    PORTB,2 ;Set PWM3 bit
    GOTO    DELAY   ;GOTO Pulse Width Delay
    
    P8:
    MOVLW   0x50    ;Decimal 80
    MOVWF   TIME    ;Set Delay value for desired Pulse Width
    BTFSC   PORTB,3 ;Check PWM1 User flag
    BSF	    PORTB,0 ;Set PWM1 bit
    BTFSC   PORTB,4 ;Check PWM2 User flag
    BSF	    PORTB,1 ;Set PWM2 bit
    BTFSC   PORTB,5 ;Check PWM3 User flag
    BSF	    PORTB,2 ;Set PWM3 bit
    GOTO    DELAY   ;GOTO Pulse Width Delay
    
    P9:
    MOVLW   0x5A    ;Decimal 90
    MOVWF   TIME    ;Set Delay value for desired Pulse Width
    BTFSC   PORTB,3 ;Check PWM1 User flag
    BSF	    PORTB,0 ;Set PWM1 bit
    BTFSC   PORTB,4 ;Check PWM2 User flag
    BSF	    PORTB,1 ;Set PWM2 bit
    BTFSC   PORTB,5 ;Check PWM3 User flag
    BSF	    PORTB,2 ;Set PWM3 bit
    GOTO    DELAY   ;GOTO Pulse Width Delay
    
    P10:
    MOVLW   0x64    ;Decimal 100
    MOVWF   TIME    ;Set Delay value for desired Pulse Width
    BTFSC   PORTB,3 ;Check PWM1 User flag
    BSF	    PORTB,0 ;Set PWM1 bit
    BTFSC   PORTB,4 ;Check PWM2 User flag
    BSF	    PORTB,1 ;Set PWM2 bit
    BTFSC   PORTB,5 ;Check PWM3 User flag
    BSF	    PORTB,2 ;Set PWM3 bit
    GOTO    DELAY   ;GOTO Pulse Width Delay
    
    P11:
    MOVLW   0x6E    ;Decimal 110
    MOVWF   TIME    ;Set Delay value for desired Pulse Width
    BTFSC   PORTB,3 ;Check PWM1 User flag
    BSF	    PORTB,0 ;Set PWM1 bit
    BTFSC   PORTB,4 ;Check PWM2 User flag
    BSF	    PORTB,1 ;Set PWM2 bit
    BTFSC   PORTB,5 ;Check PWM3 User flag
    BSF	    PORTB,2 ;Set PWM3 bit
    GOTO    DELAY   ;GOTO Pulse Width Delay
    
    P12:
    MOVLW   0x78    ;Decimal 120
    MOVWF   TIME    ;Set Delay value for desired Pulse Width
    BTFSC   PORTB,3 ;Check PWM1 User flag
    BSF	    PORTB,0 ;Set PWM1 bit
    BTFSC   PORTB,4 ;Check PWM2 User flag
    BSF	    PORTB,1 ;Set PWM2 bit
    BTFSC   PORTB,5 ;Check PWM3 User flag
    BSF	    PORTB,2 ;Set PWM3 bit
    GOTO    DELAY   ;GOTO Pulse Width Delay
    
    P13:
    MOVLW   0x82    ;Decimal 130
    MOVWF   TIME    ;Set Delay value for desired Pulse Width
    BTFSC   PORTB,3 ;Check PWM1 User flag
    BSF	    PORTB,0 ;Set PWM1 bit
    BTFSC   PORTB,4 ;Check PWM2 User flag
    BSF	    PORTB,1 ;Set PWM2 bit
    BTFSC   PORTB,5 ;Check PWM3 User flag
    BSF	    PORTB,2 ;Set PWM3 bit
    GOTO    DELAY   ;GOTO Pulse Width Delay
	
    P14:
    MOVLW   0x8C    ;Decimal 140
    MOVWF   TIME    ;Set Delay value for desired Pulse Width
    BTFSC   PORTB,3 ;Check PWM1 User flag
    BSF	    PORTB,0 ;Set PWM1 bit
    BTFSC   PORTB,4 ;Check PWM2 User flag
    BSF	    PORTB,1 ;Set PWM2 bit
    BTFSC   PORTB,5 ;Check PWM3 User flag
    BSF	    PORTB,2 ;Set PWM3 bit
    GOTO    DELAY   ;GOTO Pulse Width Delay
    
    P15:
    MOVLW   0x96    ;Decimal 150
    MOVWF   TIME    ;Set Delay value for desired Pulse Width
    BTFSC   PORTB,3 ;Check PWM1 User flag
    BSF	    PORTB,0 ;Set PWM1 bit
    BTFSC   PORTB,4 ;Check PWM2 User flag
    BSF	    PORTB,1 ;Set PWM2 bit
    BTFSC   PORTB,5 ;Check PWM3 User flag
    BSF	    PORTB,2 ;Set PWM3 bit
    GOTO    DELAY   ;GOTO Pulse Width Delay
    
    P16:
    MOVLW   0xA0    ;Decimal 160
    MOVWF   TIME    ;Set Delay value for desired Pulse Width
    BTFSC   PORTB,3 ;Check PWM1 User flag
    BSF	    PORTB,0 ;Set PWM1 bit
    BTFSC   PORTB,4 ;Check PWM2 User flag
    BSF	    PORTB,1 ;Set PWM2 bit
    BTFSC   PORTB,5 ;Check PWM3 User flag
    BSF	    PORTB,2 ;Set PWM3 bit
    GOTO    DELAY   ;GOTO Pulse Width Delay
    
    P17:
    MOVLW   0xAA    ;Decimal 170
    MOVWF   TIME    ;Set Delay value for desired Pulse Width
    BTFSC   PORTB,3 ;Check PWM1 User flag
    BSF	    PORTB,0 ;Set PWM1 bit
    BTFSC   PORTB,4 ;Check PWM2 User flag
    BSF	    PORTB,1 ;Set PWM2 bit
    BTFSC   PORTB,5 ;Check PWM3 User flag
    BSF	    PORTB,2 ;Set PWM3 bit
    GOTO    DELAY   ;GOTO Pulse Width Delay
    
    P18:
    MOVLW   0xB4    ;Decimal 180
    MOVWF   TIME    ;Set Delay value for desired Pulse Width
    BTFSC   PORTB,3 ;Check PWM1 User flag
    BSF	    PORTB,0 ;Set PWM1 bit
    BTFSC   PORTB,4 ;Check PWM2 User flag
    BSF	    PORTB,1 ;Set PWM2 bit
    BTFSC   PORTB,5 ;Check PWM3 User flag
    BSF	    PORTB,2 ;Set PWM3 bit
    GOTO    DELAY   ;GOTO Pulse Width Delay
    
    P19:
    MOVLW   0xBE    ;Decmial 190
    MOVWF   TIME    ;Set Delay value for desired Pulse Width
    BTFSC   PORTB,3 ;Check PWM1 User flag
    BSF	    PORTB,0 ;Set PWM1 bit
    BTFSC   PORTB,4 ;Check PWM2 User flag
    BSF	    PORTB,1 ;Set PWM2 bit
    BTFSC   PORTB,5 ;Check PWM3 User flag
    BSF	    PORTB,2 ;Set PWM3 bit
    GOTO    DELAY   ;GOTO Pulse Width Delay
    
    P20:
    MOVLW   0xC8    ;Decmial 200
    MOVWF   TIME    ;Set Delay value for desired Pulse Width
    BTFSC   PORTB,3 ;Check PWM1 User flag
    BSF	    PORTB,0 ;Set PWM1 bit
    BTFSC   PORTB,4 ;Check PWM2 User flag
    BSF	    PORTB,1 ;Set PWM2 bit
    BTFSC   PORTB,5 ;Check PWM3 User flag
    BSF	    PORTB,2 ;Set PWM3 bit
    GOTO    DELAY   ;GOTO Pulse Width Delay
    
    P21:
    MOVLW   0xD2    ;Decimal 210
    MOVWF   TIME    ;Set Delay value for desired Pulse Width
    BTFSC   PORTB,3 ;Check PWM1 User flag
    BSF	    PORTB,0 ;Set PWM1 bit
    BTFSC   PORTB,4 ;Check PWM2 User flag
    BSF	    PORTB,1 ;Set PWM2 bit
    BTFSC   PORTB,5 ;Check PWM3 User flag
    BSF	    PORTB,2 ;Set PWM3 bit
    GOTO    DELAY   ;GOTO Pulse Width Delay
    
    P22:
    MOVLW   0xDC    ;Decimal 220
    MOVWF   TIME    ;Set Delay value for desired Pulse Width
    BTFSC   PORTB,3 ;Check PWM1 User flag
    BSF	    PORTB,0 ;Set PWM1 bit
    BTFSC   PORTB,4 ;Check PWM2 User flag
    BSF	    PORTB,1 ;Set PWM2 bit
    BTFSC   PORTB,5 ;Check PWM3 User flag
    BSF	    PORTB,2 ;Set PWM3 bit
    GOTO    DELAY   ;GOTO Pulse Width Delay
    
    P23:
    MOVLW   0xE6    ;Decimal 230
    MOVWF   TIME    ;Set Delay value for desired Pulse Width
    BTFSC   PORTB,3 ;Check PWM1 User flag
    BSF	    PORTB,0 ;Set PWM1 bit
    BTFSC   PORTB,4 ;Check PWM2 User flag
    BSF	    PORTB,1 ;Set PWM2 bit
    BTFSC   PORTB,5 ;Check PWM3 User flag
    BSF	    PORTB,2 ;Set PWM3 bit
    GOTO    DELAY   ;GOTO Pulse Width Delay
    
    P24:
    MOVLW   0xF2    ;Decimal 242
    MOVWF   TIME    ;Set Delay value for desired Pulse Width
    BTFSC   PORTB,3 ;Check PWM1 User flag
    BSF	    PORTB,0 ;Set PWM1 bit
    BTFSC   PORTB,4 ;Check PWM2 User flag
    BSF	    PORTB,1 ;Set PWM2 bit
    BTFSC   PORTB,5 ;Check PWM3 User flag
    BSF	    PORTB,2 ;Set PWM3 bit
    GOTO    DELAY   ;GOTO Pulse Width Delay
    
    P25:
    MOVLW   0xFF    ;Decimal 255
    MOVWF   TIME    ;Set Delay value for desired Pulse Width
    BTFSC   PORTB,3 ;Check PWM1 User flag
    BSF	    PORTB,0 ;Set PWM1 bit
    BTFSC   PORTB,4 ;Check PWM2 User flag
    BSF	    PORTB,1 ;Set PWM2 bit
    BTFSC   PORTB,5 ;Check PWM3 User flag
    BSF	    PORTB,2 ;Set PWM3 bit
    GOTO    DELAY   ;GOTO Pulse Width Delay
    
    DELAY:
    NOP		    ;No Operation
    NOP		    ;No Operation
    NOP		    ;No Operation
    NOP		    ;No Operation
    NOP		    ;No Operation
    NOP		    ;No Operation
    NOP		    ;No Operation
    DECFSZ  TIME    ;Decrement "Time" register skip if 0
    GOTO    DELAY   ;Loop until Pulse Width Time has finished
    RETURN	    ;RETURN
	
    END		    ;End OF Code. This Is Required