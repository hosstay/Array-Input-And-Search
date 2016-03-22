; File: LM4F120H5QR.inc     (DO NOT MODIFY THIS FILE!!!!)
; An ARM assembly include file
; Contains Texas Instruments LM4F120H5QR hardware specific functions
; Obtained gratefully by Rajiv Bagai from Jonathan Valvano, U of Texas

; Copyright 2013 by Jonathan W. Valvano, valvano@mail.utexas.edu
;   You may use, edit, run or distribute this file
;   as long as the above copyright notice remains

        AREA    LM4F120H5QR, CODE, READONLY, ALIGN=2

SYSDIV2                EQU 7
; bus frequency is 400MHz/(SYSDIV2+1) = 400MHz/(7+1) = 50 MHz

SYSCTL_RIS_R           EQU 0x400FE050
SYSCTL_RIS_PLLLRIS     EQU 0x00000040  ; PLL Lock Raw Interrupt Status
SYSCTL_RCC_R           EQU 0x400FE060
SYSCTL_RCC_XTAL_M      EQU 0x000003C0  ; Crystal Value
SYSCTL_RCC_XTAL_6MHZ   EQU 0x000002C0  ; 6 MHz Crystal
SYSCTL_RCC_XTAL_8MHZ   EQU 0x00000380  ; 8 MHz Crystal
SYSCTL_RCC_XTAL_16MHZ  EQU 0x00000540  ; 16 MHz Crystal
SYSCTL_RCC2_R          EQU 0x400FE070
SYSCTL_RCC2_USERCC2    EQU 0x80000000  ; Use RCC2
SYSCTL_RCC2_DIV400     EQU 0x40000000  ; Divide PLL as 400 MHz vs. 200
                                       ; MHz
SYSCTL_RCC2_SYSDIV2_M  EQU 0x1F800000  ; System Clock Divisor 2
SYSCTL_RCC2_SYSDIV2LSB EQU 0x00400000  ; Additional LSB for SYSDIV2
SYSCTL_RCC2_PWRDN2     EQU 0x00002000  ; Power-Down PLL 2
SYSCTL_RCC2_BYPASS2    EQU 0x00000800  ; PLL Bypass 2
SYSCTL_RCC2_OSCSRC2_M  EQU 0x00000070  ; Oscillator Source 2
SYSCTL_RCC2_OSCSRC2_MO EQU 0x00000000  ; MOSC

;------------PLL_Init------------
; Configure the system to get its clock from the PLL.
; Input: none
; Output: none
; Modifies: R0, R1, R2, R3
PLL_Init
    ; 0) configure the system to use RCC2 for advanced features
    ;    such as 400 MHz PLL and non-integer System Clock Divisor
    LDR R3, =SYSCTL_RCC2_R          ; R3 = SYSCTL_RCC2_R (pointer)
    LDR R2, [R3]                    ; R2 = [R3] (value)
    ORR R2, R2, #SYSCTL_RCC2_USERCC2; R2 = R2|SYSCTL_RCC2_USERCC2
    STR R2, [R3]                    ; [R3] = R2
    ; 1) bypass PLL while initializing
    ORR R2, R2, #SYSCTL_RCC2_BYPASS2; R2 = R2|SYSCTL_RCC2_BYPASS2
    STR R2, [R3]                    ; [R3] = R2
    ; 2) select the crystal value and oscillator source
    LDR R1, =SYSCTL_RCC_R           ; R1 = SYSCTL_RCC_R (pointer)
    LDR R0, [R1]                    ; R0 = [R1] (value)
    BIC R0, R0, #SYSCTL_RCC_XTAL_M  ; R0 = R0&~SYSCTL_RCC_XTAL_M (clear XTAL field)
    ORR R0, R0, #SYSCTL_RCC_XTAL_16MHZ;R0 = R0|SYSCTL_RCC_XTAL_16MHZ (configure for 16 MHz crystal)
    STR R0, [R1]                    ; [R1] = R0
                                    ; R2 = R2&~SYSCTL_RCC2_OSCSRC2_M (clear oscillator source field)
    BIC R2, R2, #SYSCTL_RCC2_OSCSRC2_M
                                    ; R2 = R2|SYSCTL_RCC2_OSCSRC2_MO (configure for main oscillator source)
    ORR R2, R2, #SYSCTL_RCC2_OSCSRC2_MO
    ; 3) activate PLL by clearing PWRDN
    BIC R2, R2, #SYSCTL_RCC2_PWRDN2 ; R2 = R2&~SYSCTL_RCC2_PWRDN2
    ; 4) set the desired system divider and the system divider least significant bit
    ORR R2, R2, #SYSCTL_RCC2_DIV400 ; R2 = R2|SYSCTL_RCC2_DIV400 (use 400 MHz PLL)
                                    ;R2 = R2&~SYSCTL_RCC2_SYSDIV2_M (clear system clock divider field)
    BIC R2, R2, #SYSCTL_RCC2_SYSDIV2_M
                                    ;R2 = R2&~SYSCTL_RCC2_SYSDIV2LSB (clear bit SYSDIV2LSB)
    BIC R2, R2, #SYSCTL_RCC2_SYSDIV2LSB
    ; set Divisor by writing 7-bit constant to bits 28-22
    ADD R2, R2, #(SYSDIV2<<22)      ; R2 = R2 + (SYSDIV2<<22) (configure SYSDIV2 and SYSDIV2LSB fields in RCC2)
    STR R2, [R3]                    ; [R3] = R2
    ; 5) wait for the PLL to lock by polling PLLLRIS
    LDR R1, =SYSCTL_RIS_R           ; R1 = SYSCTL_RIS_R (pointer)
PLL_Init_loop
    LDR R0, [R1]                    ; R0 = [R1] (value)
    ANDS R0, R0, #SYSCTL_RIS_PLLLRIS; R0 = R0&SYSCTL_RIS_PLLLRIS
    BEQ PLL_Init_loop               ; if(R0 == 0), keep polling
    ; 6) enable use of PLL by clearing BYPASS
    BIC R2, R2, #SYSCTL_RCC2_BYPASS2; R2 = R2&~SYSCTL_RCC2_BYPASS2
    STR R2, [R3]                    ; [R3] = R2
    BX  LR                          ; return

NVIC_EN0_INT5      EQU 0x00000020   ; Interrupt 5 enable
NVIC_EN0_R         EQU 0xE000E100   ; IRQ 0 to 31 Set Enable Register
NVIC_PRI1_R        EQU 0xE000E404   ; IRQ 4 to 7 Priority Register
GPIO_PORTA_AFSEL_R EQU 0x40004420
GPIO_PORTA_DEN_R   EQU 0x4000451C
GPIO_PORTA_AMSEL_R EQU 0x40004528
GPIO_PORTA_PCTL_R  EQU 0x4000452C
UART0_DR_R         EQU 0x4000C000
UART0_FR_R         EQU 0x4000C018
UART0_IBRD_R       EQU 0x4000C024
UART0_FBRD_R       EQU 0x4000C028
UART0_LCRH_R       EQU 0x4000C02C
UART0_CTL_R        EQU 0x4000C030
UART0_IFLS_R       EQU 0x4000C034
UART0_IM_R         EQU 0x4000C038
UART0_RIS_R        EQU 0x4000C03C
UART0_ICR_R        EQU 0x4000C044
UART_FR_RXFF       EQU 0x00000040   ; UART Receive FIFO Full
UART_FR_TXFF       EQU 0x00000020   ; UART Transmit FIFO Full
UART_FR_RXFE       EQU 0x00000010   ; UART Receive FIFO Empty
UART_LCRH_WLEN_8   EQU 0x00000060   ; 8 bit word length
UART_LCRH_FEN      EQU 0x00000010   ; UART Enable FIFOs
UART_CTL_UARTEN    EQU 0x00000001   ; UART Enable
UART_IFLS_RX1_8    EQU 0x00000000   ; RX FIFO >= 1/8 full
UART_IFLS_TX1_8    EQU 0x00000000   ; TX FIFO <= 1/8 full
UART_IM_RTIM       EQU 0x00000040   ; UART Receive Time-Out Interrupt
                                    ; Mask
UART_IM_TXIM       EQU 0x00000020   ; UART Transmit Interrupt Mask
UART_IM_RXIM       EQU 0x00000010   ; UART Receive Interrupt Mask
UART_RIS_RTRIS     EQU 0x00000040   ; UART Receive Time-Out Raw
                                    ; Interrupt Status
UART_RIS_TXRIS     EQU 0x00000020   ; UART Transmit Raw Interrupt
                                    ; Status
UART_RIS_RXRIS     EQU 0x00000010   ; UART Receive Raw Interrupt
                                    ; Status
UART_ICR_RTIC      EQU 0x00000040   ; Receive Time-Out Interrupt Clear
UART_ICR_TXIC      EQU 0x00000020   ; Transmit Interrupt Clear
UART_ICR_RXIC      EQU 0x00000010   ; Receive Interrupt Clear
SYSCTL_RCGCGPIO_R  EQU 0x400FE608
SYSCTL_RCGCUART_R  EQU 0x400FE618

;------------UART_Init------------
; Initialize UART0, i.e. debugger window UART #1
; Baud rate is 115200 bits/sec
; Input: none
; Output: none
; Modifies: R0, R1
; Assumes: 50 MHz system clock
UART_Init
    PUSH {LR}                       ; save current value of LR
    ; activate clock for UART0
    LDR R1, =SYSCTL_RCGCUART_R      ; R1 = &SYSCTL_RCGCUART_R
    LDR R0, [R1]                    ; R0 = [R1]
    ORR R0, R0, #0x01               ; enable UART0
    STR R0, [R1]                    ; [R1] = R0
    ; activate clock for port A
    LDR R1, =SYSCTL_RCGCGPIO_R      ; R1 = &SYSCTL_RCGCGPIO_R
    LDR R0, [R1]                    ; R0 = [R1]
    ORR R0, R0, #0x01               ; enable Port A
    STR R0, [R1]                    ; [R1] = R0

    ; disable UART
    LDR R1, =UART0_CTL_R            ; R1 = &UART0_CTL_R
    LDR R0, [R1]                    ; R0 = [R1]
    BIC R0, R0, #UART_CTL_UARTEN    ; R0 = R0&~UART_CTL_UARTEN (disable UART)
    STR R0, [R1]                    ; [R1] = R0
    ; set the baud rate (equations on p845 of datasheet)
    LDR R1, =UART0_IBRD_R           ; R1 = &UART0_IBRD_R
    MOV R0, #27                     ; R0 = IBRD = int(50,000,000 / (16 * 115,200)) = int(27.1267)
    STR R0, [R1]                    ; [R1] = R0
    LDR R1, =UART0_FBRD_R           ; R1 = &UART0_FBRD_R
    MOV R0, #8                      ; R0 = FBRD = int(0.1267 * 64 + 0.5) = 8
    STR R0, [R1]                    ; [R1] = R0
    ; configure Line Control Register settings
    LDR R1, =UART0_LCRH_R           ; R1 = &UART0_LCRH_R
    LDR R0, [R1]                    ; R0 = [R1]
    BIC R0, R0, #0xFF               ; R0 = R0&~0xFF (clear all fields)
                                    ; 8 bit word length, no parity bits, one stop bit, FIFOs
    ADD R0, R0, #(UART_LCRH_WLEN_8+UART_LCRH_FEN)
    STR R0, [R1]                    ; [R1] = R0
    ; enable UART
    LDR R1, =UART0_CTL_R            ; R1 = &UART0_CTL_R
    LDR R0, [R1]                    ; R0 = [R1]
    ORR R0, R0, #UART_CTL_UARTEN    ; R0 = R0|UART_CTL_UARTEN (enable UART)
    STR R0, [R1]                    ; [R1] = R0
    ; enable alternate function
    LDR R1, =GPIO_PORTA_AFSEL_R     ; R1 = &GPIO_PORTA_AFSEL_R
    LDR R0, [R1]                    ; R0 = [R1]
    ORR R0, R0, #0x03               ; R0 = R0|0x03 (enable alt funct on PA1-0)
    STR R0, [R1]                    ; [R1] = R0
    ; enable digital port
    LDR R1, =GPIO_PORTA_DEN_R       ; R1 = &GPIO_PORTA_DEN_R
    LDR R0, [R1]                    ; R0 = [R1]
    ORR R0, R0, #0x03               ; R0 = R0|0x03 (enable digital I/O on PA1-0)
    STR R0, [R1]                    ; [R1] = R0
    ; configure as UART
    LDR R1, =GPIO_PORTA_PCTL_R      ; R1 = &GPIO_PORTA_PCTL_R
    LDR R0, [R1]                    ; R0 = [R1]
    BIC R0, R0, #0x000000FF         ; R0 = R0&~0x000000FF (clear port control field for PA1-0)
    ADD R0, R0, #0x00000011         ; R0 = R0+0x00000011 (configure PA1-0 as UART)
    STR R0, [R1]                    ; [R1] = R0
    ; disable analog functionality
    LDR R1, =GPIO_PORTA_AMSEL_R     ; R1 = &GPIO_PORTA_AMSEL_R
    MOV R0, #0                      ; R0 = 0 (disable analog functionality on PA)
    STR R0, [R1]                    ; [R1] = R0
    POP {PC}                        ; restore previous value of LR into PC (return)

;------------UART_InChar------------
; input ASCII character from UART
; spin if no data available i
; Input: none
; Output: R0  character in from UART
UART_InChar
       PUSH {R1}
       LDR  R1,=UART0_FR_R
InLoop LDR  R0,[R1]    ; read FR
       ANDS R0,#0x0010
       BNE  InLoop     ; wait until RXFE is 0
       LDR  R1,=UART0_DR_R
       LDR  R0,[R1]    ; read DR
       POP  {R1}
       BX   LR

;------------UART_OutChar------------
; output ASCII character to UART
; spin if UART transmit FIFO is full
; Input: R0  character out to UART
; Output: none
; Modifies: R0, R1
UART_OutChar
       PUSH {R1, R2}
       LDR  R1,=UART0_FR_R
OLoop  LDR  R2,[R1]    ; read FR
       ANDS R2,#0x0020
       BNE  OLoop      ; wait until TXFF is 0
       LDR  R1,=UART0_DR_R
       STR  R0,[R1]    ; write DR
       POP  {R1, R2}
       BX   LR

       ALIGN

       END
		