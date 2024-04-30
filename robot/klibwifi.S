@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
@
@        Library Name:           
@								Klib-wifi (for RealDigital Blackboard)
@        
@        Version:                
@								1.0.0 
@
@        Contributor(s):         
@								Koby Miller
@
@        Date last modified:     
@								April 22nd, 2024
@
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

.ifndef KLIB_WIFI_S_
.set KLIB_WIFI_S_, 1

.include "../src/klibio.S"

 .set UART0_BASEADDR, 0xE0000000
 .set UART1_BASEADDR, 0xE0001000

 .data
@ Station Commands
@ Use the STA Commands below (setModeSta to startSend in order) to automate the setup process for the STA.
@ Use the STA Commands below (sendFromSta to sendDataSta in order) to send data to the AP.

setModeAP:   .ascii "AT+CWMODE=2\r\n\0"
setCWSAP:    .ascii "AT+CWSAP=\"klibwifi\",\"proguart\",1,2,4,0\r\n\0"        // Change your ssid and pw to make them unique!
setAPIP:     .ascii "AT+CIPAP=\"192.168.4.1\",\"192.168.4.1\"\r\n\0"
setMux:      .ascii "AT+CIPMUX=1\r\n\0"
setServer:     .ascii "AT+CIPSERVER=1,80\r\n\0"
sendFromAP:  .ascii "AT+CIPSEND=0,4\r\n\0"

 @ this will be the format of a message you receive from WiFi sources into your ESP32
 @ where, 0 is the user who sent it, 4 is the number of bytes in the message, and "1234" is the 4-byte message in this example
 @ you are interested in extracting the message "1234" from this data array.
 messageReceived: .ascii "+IPD,0,4:1234"

 @ 4113 - ready to connect
 @ 3EF7 - connecting
 @ F1F0 - connected successfully
 @ 0F35 - lost connection

 .text
 
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
@ setupWifiHost
@
@	Enable local WiFi netword
@
@ Last modified: April 19th, 2024
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 setupWifiHost:

	 push {r0,r1,r2,lr}

	 @ setting up UART0, which is the connection between ARM and ESP32
	 ldr r0, =UART0_BASEADDR
	 bl setupUart
	 @ldr r0, =UART1_BASEADDR
	 @bl setupUart

	 @ set MIO26 (ESP32_EN) as output, enable its output, drive the pin high
	 ldr r0, =GPIO_BASEADDR
	 ldr r1, =0x4000000 @ 0b1 << 26
	 str r1, [r0, #0x204] @ GPIO_DIRM_0; set the pin as an output
	 str r1, [r0, #0x208] @ GPIO_OUTE_0; enable the output pin
	 str r1, [r0, #0x40]  @ GPIO_MASK_DATA_0_MSW; drive the output pin high

	 @ Now the ESP32_EN should be driven high and the radio should be turned on
	 
	 ldr r2, =UART0_BASEADDR
	 
	 @ Initiate all the settings for the network
	 mov r1, #0b0000000011
	 bl outputToLEDs
	 ldr r1, =setModeAP
	 bl sendStringUart
	 bl uartDummyDelay

	 mov r1, #0b0000000111
	 bl outputToLEDs
	 ldr r1, =setCWSAP
	 bl sendStringUart
	 bl uartDummyDelay
	 
	 mov r1, #0b0000011111
	 bl outputToLEDs
	 ldr r1, =setCWSAP
	 bl sendStringUart
	 bl uartDummyDelay
	 
	 mov r1, #0b0001111111
	 bl outputToLEDs
	 ldr r1, =setMux
	 bl sendStringUart
	 bl uartDummyDelay
	 
	 mov r1, #0b0011111111
	 bl outputToLEDs
	 ldr r1, =setServer
	 bl sendStringUart
	 bl uartDummyDelay
	 
	 mov r1, #0b1111111111
	 bl outputToLEDs
	 ldr r1, =sendFromAP
	 bl sendStringUart
	 bl uartDummyDelay
	 mov r1, #0
	 bl outputToLEDs
	 

	 pop {r0,r1,r2,lr}

 bx lr

@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
@ setupUart
@
@	Individual UART enabling
@
@ Last modified: April 19th, 2024
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 setupUart:
    @ Reset the UART Controller (Control Register)
    mov r1, #0b1101011
    str r1, [r0]

    @ Set the BAUDGEN clock divider (115200 baud works well; 124 divider value)
    @ 100MHz/124 = 806.451kHz
    mov r1, #124
    str r1, [r0, #0x18]

    @ Set the Baud_Rate_Divider for bit-clock (again for 115200, 0x6 works)
    @ 806.451kHz / (6 + 1) = 115.207kHz, 115207 kbps
    mov r1, #6
    str r1, [r0, #0x34]

    @ Enable software resets, transmitter & receiver, stop transmitter break (Control Register)
    mov r1, #0b100010111
    str r1, [r0]

    @ Channel mode to normal, 1 stop bit, no parity, character length 8-bit, clock source to UART reference clock (Mode Register)
    mov r1, #0b0000100000
    str r1, [r0, #0x04]

    @ Set timeout to 1 (RXTOUT register)
    mov r1, #1
    str r1, [r0, #0x1C]

    @ Disable all interrupts (IDR register)
    mov r1, #0xFFF
    str r1, [r0, #0x0C]

bx lr


@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
@ sendStringUart
@
@	Send a null-terminated string 
@
@		r1 -> string address 
@
@ Last modified: April 19th, 2024
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
sendStringUart:
	push {r2,r3,lr}

	ldr r0, =UART0_BASEADDR
	@ Counter to keep track of which character I am on in the string
	mov r2, #0

	send_string:
		@ Grab our next character in the string
		ldrb r3, [r1, r2]

		@ Check to see if we have hit the null character
		cmp r3, #0
		beq end_send_string

		waitForTX:
			ldr r4, [r0, #0x2C]
			and r4, r4, #0b10000
			cmp r4, #0
			bne waitForTX

		@ If not at end of string, send via UART1 to PC
		push {r1}
		mov r1, r3
		bl sendCharUart
		pop {r1}

		@ Move to next character
		add r2, r2, #1

	b send_string

	end_send_string:

	pop {r2,r3,lr}
	bx lr

@ This function will send a single character to the UART1 TX buffer
@ Assume that the character to send is stored in r1 prior to calling the function
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
@ sendCharUart
@
@	Send a character via UART
@
@ Last modified: April 19th, 2024
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
sendCharUart:

	push {r0,lr}

	ldr r0, =UART0_BASEADDR
	str r1, [r0, #0x30]

	pop {r0,lr}
	bx lr
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
@ sendCharUart
@
@	Send a character via UART
@
@ Last modified: April 19th, 2024
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
sendCharPutty:
	push {r0}

	ldr r0, =UART1_BASEADDR
	str r1, [r0, #0x30]

	pop {r0}
	bx lr

@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
@ recieveCharUart
@
@	Recieve a character via UART 
@
@ Last modified: April 22nd, 2024
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
recieveCharUart:
	push {r1,r2,lr}
	ldr r0, =UART0_BASEADDR
	mov r1, #0
	@str r1, [r0, #0x30]
	waitForRX:
		ldr r2, [r0, #0x2C]
		and r2, r2, #0b10
		cmp r2, #0
		bne waitForRX

	ldr r0, [r0, #0x30]
	mov r1, r0
	@bl sendCharPutty
	pop {r1,r2,lr}
bx lr
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
@ checkFIFO
@
@	Recieve a character via UART
@
@ Last modified: April 19th, 2024
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
checkFIFO:
	push {r1}
	ldr r0, =UART0_BASEADDR
	ldr r1, [r0, #0x2C]
	and r1, r1, #0b10
	mov r0, r1
	pop {r1}
bx lr
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
@ uartDummyDelay
@
@	A delay for dummies!
@
@ Last modified: April 19th, 2024
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

uartDummyDelay:
	push {r1}
		@ waits however long it takes the stupid rock 
		@ to count down from this stupid number
		ldr r1, =#0x4FFFFFF
		uartDummyDelayLoop:
			sub r1, r1, #1
			cmp r1, #0
		bne uartDummyDelayLoop
	pop {r1}
bx lr

.endif
