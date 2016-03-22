; File: main.s
 
; This file needs to be in a Keil version 5 project, together with file init.s,
; for all CS 238 programming Home Assignments

; This is a demo program, which you will need to change for each Home Assignment

; Executable code in this file should start at label main

	EXPORT	main		; this line is needed to interface with init.s

; Usable utility functions defined in file init.s
; Importing any label from another source file is necessary
; in order to use that label in this source file

	IMPORT	GetCh
	IMPORT	PutCh
	IMPORT	PutCRLF
        IMPORT	UDivMod
	IMPORT	GetDec
	IMPORT	PutDec
	IMPORT	GetStr
	IMPORT	PutStr

	AREA    MyCode, CODE

	ALIGN			; highly recommended to start and end any area with ALIGN

; Start of executable code is at following label: main

main

;-------------------- START OF MODIFIABLE CODE ----------------------

	PUSH	{LR}		; save return address of caller in init.s
	
	; loop asking for a valid array length input from user (0-100)
L1
		;body
		LDR	R0, =Prompt1	; R0 = address Prompt1 (in code area)
		BL	PutStr		; display prompt for getting array length
	
		BL 	GetDec		; get users integer input
		LDR	R2, =AryLen	; R2 = address AryLen (in data area)
		STR	R0, [R2]        ; store input in AryLen at R2
	
		LDR	R2, [R2]	; put value of R2 (AryLen) into R2
	
	; Repeat if R2 < 0
	CMP	R2, #0
	BLT L1		        ; if R2 < 0 repeat
	
	; Repeat if R2 > 100
	CMP	R2, #100
	BGT L1			; if R2 > 100 repeat
	
	; else (0 <= AryLen <= 100) 
	; fall out of loop
	
	; loop getting the integers to place in array
	LDR R3, =Array		; R3 is pointer to first item in array
	MOV R1, R2		; R2 (value of AryLen) becomes loop counter in R1
	
	; for i = AryLen down to 1, i--
L2	
	CMP R1, #0
	BLE L2Fin		; if loop counter is 0 then quit out of loop
	
		; body
		LDR R0, =Prompt2	; put prompt2 in R0
		BL PutStr		; display prompt2
		
		BL GetDec		; get users input for current integer
		STR R0, [R3]		; store input in the value of the address at R3
		
		SUB R1, R1, #1		; decrement loop counter
		ADD R3, R3, #4		; move pointer to array to the next integer slot
		
		B L2			; loop
	
	; end for
L2Fin
	
	; loop to search for values in array
L3	
	; ask for search
		;body
		LDR R0, =Prompt3
		BL PutStr		; prompt the user for character Y/N
	
		BL GetCh		; get character from user
		
	CMP R0, #'Y'		
	BLT Fin		; if R0 < Y quit, if R0 > Y next check (y > Y)
		
	CMP R0, #'y'
	BLT Fin		; if R0 > Y, and R0 < y, quit
	BGT Fin		; if R0 > Y, and R0 > y, quit
	
	; if user wants to search...
	LDR R0, =Prompt4
	BL PutStr		; prompts the user for a value to search the array for
	
	BL GetDec		; get value from user
	MOV R5, R0		; put value to look for in R5
	
	MOV R6, #0		; R6 becomes boolean register to see if value is found or not
	
	MOV R1, R2		; R2 (value of AryLen) becomes loop counter in R1
	
	; for i = AryLen down to 1, i--
L4	
	CMP R1, #0
	BLT L4Fin		; if loop counter is less than 0 then quit out of loop
	
		; body
		MOV R7, R3		; copy the address of the array pointer to R7
		LDR R7, [R7]		; put the value of the adress of the array pointer in R7
		CMP R7, R5		; compare the value of the current position of the adress and the input value
		MOVEQ R6, #1		; if they are the same, make boolean = true
		BEQ L4Fin		; if they are the same, exit the for loop
		
		;if they aren't the same
		SUB R1, R1, #1		; decrement loop counter
		SUB R3, R3, #4		; move pointer to array to the previous integer slot
		
		B L4			; loop
	
	; end for
L4Fin
	
	; at this point the boolean should be either 0 or 1 depending on if it matched the search to an input
	
	;if search found...
	CMP R6, #1
	BNE ElsePart	; if search not found, go to ElsePart
	
	LDR R0, =Msg1
	BL PutStr	; output success message
	MOV R0, R1	; put value of counter in R0
	BL PutDec	; output array slot match was found in
	LDR R0, =Msg2
	BL PutStr	; output last part of sentence.
	
	B Fin		; skip ElsePart
	
	;otherwise...
ElsePart
	LDR R0, =Msg3
	BL PutStr	; output failure message
	
Fin

	POP	{PC}		; return from main
	
; Some commonly used ASCII codes

CR	EQU	0x0D	; Carriage Return (to move cursor to beginning of current line)
LF	EQU	0x0A	; Line Feed (to move cursor to same column of next line)

; The following data items are in the CODE area, so address of any of
; these items can be loaded into a register by the ADR instruction,
; e.g. ADR   R0, Prompt1 (using LDR is possible, but not efficient)

Prompt1	DCB	"Input an array length from 0 to 100: ", 0
Prompt2	DCB	"Enter integer number: ", 0
Prompt3	DCB	"Do you want to search for a value in the array? Y/N: ", 0
Prompt4 DCB	CR, LF, "Enter search value: ", 0
Msg1	DCB	"Your search was found at position ", 0
Msg2	DCB	".", CR, LF, 0
Msg3	DCB	"Your search was not found in the array.", CR, LF, 0
	ALIGN
		
; The following data items are in the DATA area, so address of any of
; these items must be loaded into a register by the LDR instruction,
; e.g. LDR   R0, =Name (using ADR is not possible)

	AREA    MyData, DATA, READWRITE
		
	ALIGN

MaxLen	EQU	100		; array length = 100

Array	SPACE	4*MaxLen	; storage space for len (4 bytes for each num in 100 num array)
	
AryLen  SPACE	4		; 4 bytes for storing input array length	
	
Value	SPACE	4		; 4 bytes for storing input number

;-------------------- END OF MODIFIABLE CODE ----------------------

	ALIGN

	END			; end of source program in this file
