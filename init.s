; File: init.s
 
; This file needs to be in a Keil version 5 project, together with file main.s,
; for all CS 238 programming Home Assignments

; BTW, the main.s file will be developed by you :)

;---------------------------------------------------------

; Some commonly used ASCII codes

CR	EQU	0x0D	; Carriage Return (to move cursor to beginning of current line)
LF	EQU	0x0A	; Line Feed (to move cursor to same column of next line)

;---------------------------------------------------------

; Texas Instruments LM4F120H5QR device-specific
; initialization & operational code for UART I/O,
; obtained from Jonathan Valvano of UTexas

	INCLUDE		LM4F120H5QR.inc

;---------------------------------------------------------

; Some utility functions for CS 238, developed by Rajiv Bagai

	AREA    CS238Utilities, CODE

	EXPORT	GetCh
	EXPORT	PutCh
	EXPORT	PutCRLF
	EXPORT	UDivMod
	EXPORT	GetDec
	EXPORT	PutDec
	EXPORT	GetStr
	EXPORT	PutStr

	ALIGN

;---------------------GetCh---------------------
; Input and echo one keyboard character from the UART #1 window
; For CR, output an extra LF
; Output: R0 = keyboard character

GetCh
	PUSH	{LR}		; save current value of LR for returning
	BL	UART_InChar	; input a character into R0
	BL	UART_OutChar	; echo the character on the UART window
    ; if input character != CR
	CMP	R0, #CR
    ; then
		POPNE	{PC}	; return immediately to caller
    ; endif
	MOV	R0, #LF
	BL	UART_OutChar	; output an extra LF for CR
	MOV	R0, #CR		; restore R0 with CR
	POP	{PC}		; return to caller

;---------------------PutCh---------------------
; Output character in R0 to the UART #1 window

PutCh
	PUSH	{LR}		; save current value of LR for returning
	BL	UART_OutChar	; display the character on the UART window
	POP	{PC}		; return to caller

;---------------------PutCRLF---------------------
; Output CR and LF to the UART #1 window, to bring cursor to beginning of next line

PutCRLF
	PUSH	{R0, LR}	; save scratch register(s) and return address
	MOV	R0, #CR
	BL	UART_OutChar	; bring cursor back on the UART window
	MOV	R0, #LF
	BL	UART_OutChar	; move cursor to next line
	POP	{R0, PC}	; restore scratch register(s) and return to caller

;---------------------UDivMod---------------------
; Perform unsigned division to return quotient and remainder
; Input: R0 = numerator, R1 = denominator
; Output: R0 = remainder, R1 = quotient
; This function can be useful because ARM lacks a division instruction

UDivMod
	PUSH	{R2, R3, LR}	; save scratch register(s) and return address
	MOV	R2, R1		; initialize R2 = denominator

	CMP	R2, R0, LSR #1	; double R2 until R2 > numerator / 2,
UDML1	MOVLS	R2, R2, LSL #1	; i.e. 2 * R2 > numerator
	CMP	R2, R0, LSR #1
	BLS	UDML1

	MOV	R3, #0		; initialize quotient
UDML2
    ; do
	; if numerator >= R2
	    CMP		R0, R2
	; then
		SUBHS	R0, R0, R2	; subtract R2 from numerator,
		ADC	R3, R3, R3	; and double quotient
	; endif
	    MOV	    R2, R2, LSR #1	; halve R2
	    CMP	    R2, R1
	    BHS	    UDML2
    ; while R2 >= denominator

	MOV	R1, R3		; R1 = quotient (R0 is already remainder)
	POP	{R2, R3, PC}	; restore scratch register(s) and return to caller

;---------------------GetDec---------------------
; Input a signed number from the UART #1 window
; Eat up all leading characters that are not digits, '+', or '-'
; Also eat up a trailing non-digit character
; Output: R0 = the input number

GetDec
	PUSH	{R1-R3, LR}	; save scratch register(s) and return address

GDL1	MOV	R1, #1		; default sign multiplier for non-negative values
	B	GDL3

GDL2	MOV	R1, #-1		; sign multiplier for -ive values

GDL3
    ; Eat up all leading characters that are not digits, '+', or '-'
	BL	GetCh		; input next character into R0

	CMP	R0, #'+'
	BEQ	GDL1		; treat '+' as no operation
	
	CMP	R0, #'-'
	BEQ	GDL2		; remember -ive sign

	CMP	R0, #'0'	; now ignore all non-digits
	BLO	GDL1
	CMP	R0, #'9'
	BHI	GDL1		; digit found, get to business
	
    ; Now R0 has first digit and R3 has multiplier
	MOV	R2, #0		; initialize answer
	MOV	R3, #10

GDL4
    ; do
	    SUB	    R0, #'0'		; convert ASCII digit to actual value
	    MLA	    R2, R3, R2, R0	; R2 = 10 * R2 + R0

	    BL	    GetCh		; input next character into R0
	    CMP	    R0, #'0'
	    BLO	    GDL5
	    CMP	    R0, #'9'
	    BLS	    GDL4
    ; while next character is still a digit

GDL5
    ; all digits processed, and next character eaten up
    
	MUL	R0, R1, R2	; incorporate sign multiplier

	POP	{R1-R3, PC}	; restore scratch register(s) and return to caller

;---------------------PutDec---------------------
; Output the signed number in R0 to the UART #1 window

PutDec
	PUSH	{R0-R2, LR}	; save scratch register(s) and return address

    ; if R0 is negative
	CMP	R0, #0
	BGE	PutNNeg
    ; then
		PUSH	{R0}
		MOV	R0, #'-'
		BL	UART_OutChar	; display the negative sign '-'
		POP	{R0}
		RSB	R0, R0, #0	; negate R0
    ; endif

PutNNeg
	MOV	R2, #0		; initialize R2 = # of pushed digits
PDL1
    ; do
	    MOV	    R1, #10		; divisor
	    BL	    UDivMod		; R0 = R0 % 10, and R1 = R0 / 10
	    PUSH    {R0}		; push least significant digit onwards
	    ADD	    R2, R2, #1		; increment pushed digit count
	    MOVS    R0, R1		; R0 = quotient of division
	    BNE	    PDL1
    ; while R0 != 0

PDL2
    ; do
	    POP	    {R0}		; pop most significant digit onwards
	    ADD	    R0, R0, #'0'	; obtain ASCII code of digit
	    BL	    UART_OutChar	; display digit
	    SUBS    R2, R2, #1		; decrement digit count on stack
	    BNE	    PDL2
    ; while R2 != 0

	POP	{R0-R2, PC}	; restore scratch register(s) and return to caller

;---------------------GetStr---------------------
; Read and store a CR-terminated string from the UART #1 window
; and place a NULL character at the end
; Inputs: R0 = memory buffer address, R1 = max number of bytes to read (unsigned)
; Buffer must have at least R1 + 1 bytes, due to the extra null

GetStr
	PUSH	{R0-R2, LR}	; save scratch register(s) and return address

	MOV	R2, R0		; R2 = buffer pointer
GSL1
    ; while R1 != 0 and next input character is non-CR
	CMP	R1, #0
	BEQ	GSL2
	BL	UART_InChar	; input a character into R0
	BL	UART_OutChar	; echo the character on the UART window
	CMP	R0, #CR
	BEQ	GSL2
    ; do
	    STRB    R0, [R2], #1	; store character in buffer & advance R2
	    SUB	    R1, #1		; decrement max character count
	    B	    GSL1
    ; end while

GSL2
	BL	PutCRLF
	MOV	R0, #0
	STRB	R0, [R2]	; terminate string in buffer with NULL character
	
	POP	{R0-R2, PC}	; restore scratch register(s) and return to caller

;---------------------PutStr---------------------
; Output null-terminated string pointed to by R0 to the UART #1 window

PutStr
	PUSH	{R0, R1, LR}	; save scratch register(s) and return address

	MOV	R1, R0		; R1 = string pointer
PSL1
    ; while string character is non-null
	    LDRB    R0, [R1], #1
	    CMP	    R0, #0
	    BEQ	    PSL2
    ; do
		BL	UART_OutChar	; display character
		B	PSL1
    ; end while

PSL2
	POP	{R0, R1, PC}	; restore scratch register(s) and return to caller

; End of utility functions

        ALIGN

;---------------------------------------------------------------------------------

; Allocate space for the system stack

	AREA    STACK, NOINIT, READWRITE, ALIGN=3

Stack   EQU     0x00000400		; Stack Size (in Bytes)

StackMem
        SPACE   Stack

; Place code into the reset code section

	AREA    RESET, CODE, READONLY

; The vector table.

	EXPORT  __Vectors
__Vectors
        DCD     StackMem + Stack	; Top of Stack
        DCD     Reset_Handler		; Reset Handler
	SPACE	4 * 9, 0		; more vector fields
        DCD     SVC_Handler		; SVCall Handler
	SPACE	4 * 143, 0		; rest of vector (optional)

SVC_Handler				; can be expanded later for ARM SWI instructions
	B       .			; loop forever (for now)

	ALIGN

Zeroes	SPACE	4 * 12, 0		; 4 zero-bytes each, for resetting R1 - R12
	
;******************************************************************************
;
; This is the entry point of the program when it first starts execution,
; or following a reset
;
;******************************************************************************

	ENTRY
        EXPORT	Reset_Handler
		
Reset_Handler
		
        BL      PLL_Init	; set system clock to 50 MHz
        BL      UART_Init	; initialize UART
	
	MOV	R0, #CR		; R0 = CR (<carriage return>)
	BL	UART_OutChar	; send <carriage return> to UART
	
	ADR	R0, Zeroes	; reset R0 - R12 to zeroes
	LDMIA	R0, {R1-R12}	; before starting your program
	MOV	R0, R1

        IMPORT  main
        BL	main		; call to your ARM assembly program in file main.s
	
	B	.		; loop forever, upon return
		
	ALIGN

        END			; end of source program in this file
