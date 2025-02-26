	.data

	.global prompt
	.global dividend
	.global divisor
	.global remainder

prompt:		.string "Would you like to calculate the remainder?", 0
howto_prompt .string "key in 'Y' for 'yes', enter 'N' for 'no'",0
unrecognized_message:	.string "unrecognized character", 0
terminated_message:		.string "program terminated", 0
answer_message:			.string "the remainder is: ", 0
dividend_prompt:	.string "please key in the dividend and press enter", 0
divisor_prompt:	.string "please key in the divisor and press enter", 0
dividend: 	.string "", 0
divisor:  	.string "", 0
remainder:	.string "", 0
test: 		.string	"", 0


	.text

	.global lab3
U0FR: 	.equ 0x18			; UART0 Flag Register

ptr_to_prompt:			.word prompt
ptr_to_dividend_prompt	.word dividend_prompt
ptr_to_divisor_prompt	.word divisor_prompt
ptr_to_terminated_message	.word terminated_message
ptr_to_dividend:		.word dividend
ptr_to_divisor:		.word divisor
ptr_to_remainder:		.word remainder
ptr_to_howto_prompt		.word howto_prompt
ptr_to_unrecognized_message	.word unrecognized_message
ptr_to_answer_message	.word answer_message


lab3:
	PUSH {r4-r12,lr} 		; Store any registers in the range of r4 through r12
							; that are used in your routine.  Include lr if this
							; routine calls another routine.
	BL uart_init

	ldr r4, ptr_to_prompt
	ldr r5, ptr_to_dividend
	ldr r6, ptr_to_divisor
	ldr r7, ptr_to_remainder
	ldr r8, ptr_to_dividend_prompt
	ldr r9, ptr_to_divisor_prompt

	; Your code is placed here.  This is your main routine for
		; Lab #3.  This should call your other routines such as
		; uart_init, read_string, output_string, int2string, &
		; string2int

lab3_routine:

	MOV r0, r4
	BL output_string			; output prompt asking if user wants to run program

	ldr r0, ptr_to_howto_prompt	; tell user how to run or cancel
	BL output_string

	BL check_continue

	MOV r0, r8
	BL output_string			; output prompt asking user for dividend

	MOV r0, r5
	BL read_string				; get user dividend, convert to integer
	BL string2int
	MOV r10, r0					; save integer dividend in r10

	MOV r0, r9
	BL output_string			; output prompt asking user for divisor

	MOV r0, r6
	BL read_string				; get user divisor, convert to integer
	BL string2int
	MOV r11, r0					; save converted divisor in r11

	MOV r0, r10					; move dividend into r0 for divide
	MOV r1, r11					; move divisor into r1 for divide

	BL division

	MOV r8, r1					; save remainder

	ldr r0, ptr_to_answer_message
	BL output_string

	MOV r1, r8					; put remainder back

	MOV r0, r7
	BL int2string
	BL output_string


	B lab3




lab3_end:

	POP {r4-r12,lr} 		; Restore registers all registers preserved in the
							; PUSH at the top of this routine from the stack.
	mov pc, lr





uart_init:
	PUSH {r4-r12,lr} 		; Store any registers in the range of r4 through r12
							; that are used in your routine.  Include lr if this
							; routine calls another routine.

		; Your code for your uart_init routine is placed here

	MOV r0, #0xE618
	MOVT r0, #0x400F
	MOV r1, #1				; write 1 to UART0 clock register
	STR r1, [r0]

	MOV r0, #0xE608
	MOVT r0, #0x400F
	MOV r1, #1				; write 1 to portA clock register
	STR r1, [r0]

	MOV r0, #0xC030
	MOVT r0, #0x4000
	MOV r1, #0				; write 0 to UART0 control register
	STR r1, [r0]

	MOV r0, #0xC024
	MOVT r0, #0x4000
	MOV r1, #8				; write 8 to UART0_IBRD_R for 115,200 baud
	STR r1, [r0]

	MOV r0, #0xC028
	MOVT r0, #0x4000
	MOV r1, #44				; write 44 to UART0_FBRD_R for 115,200 baud
	STR r1, [r0]

	MOV r0, #0xCFC8
	MOVT r0, #0x4000
	MOV r1, #0				; write 0 to system clock
	STR r1, [r0]

	MOV r0, #0xC02C
	MOVT r0, #0x4000
	MOV r1, #0x60			; Use 8-bit word length, 1 stop bit, no parity
	STR r1, [r0]

	MOV r0, #0xc030
	MOVT r0, #0x4000
	MOV r1, #0x301			; write 8 to UART control
	STR r1, [r0]

	MOV r0, #0x451C
	MOVT r0, #0x4000
	LDR r1, [r0]
	ORR r1, r1, #0x03		; Make PA0 and PA1 as Digital Ports
	STR r1, [r0]

	MOV r0, #0x4420
	MOVT r0, #0x4000
	LDR r1, [r0]
	ORR r1, r1, #0x03		; Change PA0,PA1 to Use an Alternate Function
	STR r1, [r0]

	MOV r0, #0x452C
	MOVT r0, #0x4000
	LDR r1, [r0]
	ORR r1, r1, #0x11		; Configure PA0 and PA1 for UART
	STR r1, [r0]




	POP {r4-r12,lr}   		; Restore registers all registers preserved in the
							; PUSH at the top of this routine from the stack.
	mov pc, lr


read_character:
	PUSH {r4-r12,lr} 		; Store any registers in the range of r4 through r12
							; that are used in your routine.  Include lr if this
							; routine calls another routine.

		; Your code for your read_character routine is placed here

read_loop:
	MOV r1, #0xC018			; load lower 16 bits of UART0 address
	MOVT r1, #0x4000		; load upper 16 bits of UART0 address
	LDRB r2, [r1]			; read the first byte of UART0 into r2
	AND r3, r2, #0x10		; mask to get 5th bit

	CMP r3, #0				; check if 5th bit is 1 or 0
	BNE read_loop			; if 5th bit is 1, flag register busy, loop again

	MOV r1, #0xC000			; load lower 16 bits of UARTDR
	MOVT r1, #0x4000		; load upper 16 bits of UARTDR
	LDRB r0, [r1]			; read first byte in r0 to UARTDR

	BL output_character		; echo back in terminal as user types

	POP {r4-r12,lr}   		; Restore registers all registers preserved in the
							; PUSH at the top of this routine from the stack.
	mov pc, lr


read_string:
	PUSH {r4-r12,lr} 		; Store any registers in the range of r4 through r12
							; that are used in your routine.  Include lr if this
							; routine calls another routine.

			; Your code for your read_string routine is placed here

	MOV r4, r0				; base address passed in as r0
	MOV r5, r0				; for testing purposes REMOVE LATER -DONT REMOVE THIS WORKED

read_string_loop:
	BL read_character		; call read character to get a single char
	CMP r0, #0x0D			; check if its enter (terminating char)
	BEQ end_read_string		; if char is enter, end the read loop
	STRB r0, [r4]			; if not enter, store character in memory
	ADD r4, r4, #1			; increment pointer by 1 byte
	B read_string_loop		; begin loop again (get another char)

end_read_string:
	MOV r6, #0				; place null terminator in r6 (0 b/c ASCII for 0 is 48)
	STRB r6, [r4]			; store null at end of string in memory


	BL print_newline

	MOV r0, r5				; for testing purposes, REMOVE LATER MAYBE- NO nevermind this worked


	POP {r4-r12,lr}   		; Restore registers all registers preserved in the
							; PUSH at the top of this routine from the stack.
	mov pc, lr


output_character:
	PUSH {r4-r12,lr} 		; Store any registers in the range of r4 through r12
							; that are used in your routine.  Include lr if this
							; routine calls another routine.

		; Your code for your output_character routine is placed here

output_loop:
	MOV r1, #0xC018			; load lower 16 bits of UART0 address
	MOVT r1, #0x4000		; load upper 16 bits of UART0 address
	LDRB r2, [r1]			; read the first byte of UART0 into r2
	AND r3, r2, #0x20		; mask to get 6th bit

	CMP r3, #0				; check if 6th bit is 1 or 0
	BNE output_loop			; if 6th bit is 1, flag register busy, loop again

	MOV r1, #0xC000			; load lower 16 bits of UARTDR
	MOVT r1, #0x4000		; load upper 16 bits of UARTDR
	STRB r0, [r1]			; write first byte in r0 to UARTDR


	POP {r4-r12,lr}   		; Restore registers all registers preserved in the
							; PUSH at the top of this routine from the stack.
	mov pc, lr


output_string:
	PUSH {r4-r12,lr} 		; Store any registers in the range of r4 through r12
							; that are used in your routine.  Include lr if this
							; routine calls another routine.

		; Your code for your output_string routine is placed here

	MOV r4, r0				; move r0 into r4 (address passed in in r0)

output_string_loop:
	LDRB r0, [r4]			; load byte from string stored in memory
	CMP r0, #0				; check if null terminator (0 b/c ASCII for 0 is 48)
	ADD r4, r4, #1			; increment pointer by 1 byte
	BEQ end_output_string	; stop extracting from memory if null terminator hit

	BL output_character		; call output char to print char
	B output_string_loop	; repeat loop for next char

end_output_string:

	BL print_newline

	POP {r4-r12,lr}   		; Restore registers all registers preserved in the
							; PUSH at the top of this routine from the stack.
	mov pc, lr


int2string:
	PUSH {r4-r12,lr} 		; Store any registers in the range of r4 through r12
							; that are used in your routine.  Include lr if this
							; routine calls another routine.

		; Your code for your int2string routine is placed here

	MOV r4, r0				; get address to store from r0
	MOV r5, r0				; also store address for use at end for reverse

int2string_loop:
	CMP r1, #10				; compare dividend with 10
	BLT end_int2string		; if yes, end loop

	MOV r0, r1				; set dividend to current number
	MOV r1, #10				; store divisor
	BL division				; branch to division

	ADD r1, r1, #0x30		; convert remainder from div routine to ASCII digit
	STRB r1, [r4]			; store ASCII remainder in memory
	ADD r4, r4, #1			; increment pointer

	MOV r1, r0				; update next num to process to quotient from div routine
	B int2string_loop		; repeat loop

end_int2string
	ADD r1, r1, #0x30		; convert final digit (remainder) to ASCII
	STRB r1, [r4]			; store final ASCII in memory
	ADD r4, r4, #1			; increment pointer for null terminator
	MOV r0, #0				; prepare null terminator
	STRB r0, [r4]			; store null terminator at end

	MOV r0, r5				; place start address in r0 to pass to reverse
	BL reverse_string





	POP {r4-r12,lr}   		; Restore registers all registers preserved in the
							; PUSH at the top of this routine from the stack.
	mov pc, lr


string2int:
	PUSH {r4-r12,lr} 		; Store any registers in the range of r4 through r12
							; that are used in your routine.  Include lr if this
							; routine calls another routine.

			; Your code for your string2int routine is placed here

	MOV r5, #0				; Initialize total sum
	MOV r4, r0				; Get input address from r0

string2int_loop:
	LDRB r6, [r4]			; load first byte from string
	ADD r4, r4, #1			; increment address pointer
	CMP r6, #0				; check if loaded byte is null terminator
	BEQ end_string2int		; if null terminator, end loop

	CMP r6, #0x2C			; check if loaded byte is a comma
	BEQ string2int_loop		; if comma, skip and loop again

	SUB r6, r6, #0x30		; convert ASCII digit to numeric

	MOV r0, r5				; move total sum into r0 to be passed as multiplicand
	MOV r1, #10				; muve multiplier into r1

	BL multiplication		; multiply those two values, result will be in r0

	CMP r0, #0				; check if total sum is 0
	BEQ add_digit
	BEQ string2int_loop

	MOV r5, r0				; move result value back into r5
	ADD r5, r5, r6			; add new digit to the result
	B string2int_loop		; loop again to get next byte

add_digit:
	ADD r5, r6, r0
	B string2int_loop

end_string2int
	MOV r0, r5				; move final value into r0 for caller



	POP {r4-r12,lr}   		; Restore registers all registers preserved in the
							; PUSH at the top of this routine from the stack.
	mov pc, lr


			; Additional subroutines may be included here


multiplication:
	PUSH {r4-r12,lr}			; Store registers r4 through r12 and lr on the
								; stack. Do NOT modify this line of code.  It
    			     			; ensures that the return address is preserved
 		            			; so that a proper return to the C wrapped can be
			      				; executed.



								; r0 is multiplicand
								; r1 is multiplier
								; r2 is product
								; r3 is where we store LSB of multiplier

								;is it guaranteed higher bits will be 0, or do we need a counter?
								; if not guaranteed, need counter from 15 down, loop 15 times regardless

	MOV r2, #0                  ; inintialize product to 0

MULT_LOOP:
	AND r3, r1, #1              ; get LSB of the multiplier
	CMP r3, #0                  ; check LSB of multiplier
	BEQ SKIP_MULT_ADD           ; if LSB of multiplier is 1
                           		; do NOT add multiplicand to product
                            	;(skip next add step)
	ADD r2, r2, r0              ; if LSB of multiplier is 1, add multiplicand to r1

SKIP_MULT_ADD:
	CMP r1, #0                  ; check if multiplier is 0, if so, end process
	BEQ END_MULT                ; branch to end of process

	LSL r0, r0, #1              ; left shift multiplicand one (multiplies by 2)
	LSR r1, r1, #1              ; left shift divisor one (divides by 2)

	B MULT_LOOP                 ; branch back to beginning

END_MULT:
	MOV r0, r2


	POP {r4-r12,lr}				; Restore registers r4 through r12 and lr from
    							; the stack. Do NOT modify this line of code.
    			      			; It ensures that the return address is preserved
 		            			; so that a proper return to the C wrapped can be
			      				; executed.

								; The following line is used to return from the subroutine
								; and should be the last line in your subroutine.

	MOV pc, lr

division:
	PUSH {r4-r12,lr}			; Store registers r4 through r12 and lr on the
								; stack. Do NOT modify this line of code.  It
    			     		 	; ensures that the return address is preserved
 		            			; so that a proper return to the C wrapped can be
			      				; executed.


; r0 is dividend
; r1 is divisor
; r2 is quotient
; r3 is remainder
; r4 is counter


	MOV r4, #15            		 ; initialize counter
	MOV r2, #0             		 ; store 0 in quotient
	LSL r1, r1, #15        		 ; shift divisor 15 places left (x 2^15)
	MOV r3, r0             		 ; initialize dividend in remainder

DIV_LOOP:
	SUB r3, r3, r1          	; remainder = remainder - divisor
	CMP r3, #0             	 	; is remainder 0?
	BLT GOTO_ADD           		; if remainder < 0, add divisor to remainder

	LSL r2, r2, #1          	; shift quotient left 1 (x 2)
	ORR r2, r2, #1         		; set LSB of quotient to 1
	B JOIN_BRANCHES

GOTO_ADD:
	ADD r3, r3, r1         		; remainder = remainder + divisor
	LSL r2, r2, #1          	; shift quotient left 1 (x 2)

JOIN_BRANCHES:
	LSR r1, r1, #1           	; shift divisor right 1 (/ 2)

	CMP r4, #0					; is counter > 0?
	BLE END_DIV					; if so, end division

	SUB r4, r4, #1
	B DIV_LOOP            		; branch back to loop start



END_DIV:

	MOV r0, r2					; move quotient into r0
	MOV r1, r3					; move remainder into r1


	POP {r4-r12,lr}				; Restore registers r4 through r12 and lr from
    							; the stack. Do NOT modify this line of code.
    			      			; It ensures that the return address is preserved
 		            			; so that a proper return to the C wrapped can be
			      				; executed.

								; The following line is used to return from the subroutine
								; and should be the last line in your subroutine.

	MOV pc, lr



print_newline:
	PUSH {r4-r12,lr}

	MOV r0, #0x0D				; move ASCII for carriage return into r0
	BL output_character			; print carriage return
	MOV r0, #0x0A				; move ASCII for newline into r0
	BL output_character			; print newline

	POP {r4-r12,lr}   			; Restore registers all registers preserved in the
								; PUSH at the top of this routine from the stack.
	mov pc, lr

reverse_string:
	PUSH {r4-r12,lr}

	MOV r4, r0					; set r4 as starting pointer
	MOV r5, r0					; set r5 as end of string pointer

find_end:
	LDRB r3, [r5]				; load byte from memory at r5
	CMP r3, #0					; check for null terminator
	BEQ set_end					; if null, branch to end
	ADD r5, r5, #1				; increment end pointer
	B find_end					; keep looping until null terminator

set_end:
	SUB r5, r5, #1				; point r5 at last valid char (non null)

reverse_loop:
	CMP r4, r5					; compare start and end pointers
	BGE reverse_done			; if start pointer > end, finished
	LDRB r2, [r4]				; load byte from start
	LDRB r3, [r5]				; load byte from end
	STRB r3, [r4]				; store end byte at start pointer
	STRB r2, [r5]				; store start byte and end pointer
	ADD r4, r4, #1				; increment start pointer
	SUB r5, r5, #1				; increment end pointer
	B reverse_loop				; branch til pointers meet

reverse_done:

	POP {r4-r12,lr}   			; Restore registers all registers preserved in the
								; PUSH at the top of this routine from the stack.
	mov pc, lr


check_continue:
	PUSH {r4-r12, lr}

	BL read_character
	MOV r5, r0					; write r0 to r5 so newline doesnt overwrite it
	BL print_newline
	CMP r5,	#121				; compare user input with y
	BEQ continue_routine
	CMP r5, #89				; compare user input with Y
	BEQ continue_routine		; if user input y or Y, continue with lab3 subroutine

	CMP r5, #110				; compare user input with n
	BEQ exit_routine
	CMP r5, #78				; compare user input with N
	BEQ exit_routine			; if user input is n or N, exit program

	BL print_newline
	ldr r0, ptr_to_unrecognized_message	; if input is not y or n, inform user
	BL output_string
	BL print_newline

	POP {r4-r12, lr}
	B lab3_routine

continue_routine:
	POP {r4-r12, lr}

	mov pc, lr

exit_routine:

	ldr r0, ptr_to_terminated_message
	BL output_string


	.end
