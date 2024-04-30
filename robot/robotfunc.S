.ifndef ROBOT_FUNC_S_
.set ROBOT_FUNC_S_, 1

.include "../src/klibwifi.S"
.include "../src/klibio.S"

.data

.text

@ 0113 -> Ready to connect
@ 0CE7 -> Connecting
@ F1F0 -> Connected
@ 0405 -> Connection closed

@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
@ checkForCommand
@
@		Stores command from FIFO buffer into a global readCommand variable
@		Ignores connection codes
@
@ Last modified: April 27th, 2024
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
checkForCommand:
	push {r0,r1,r2,r3,lr}

	bl recieveCharUart

	cmp r0, #0x3A

	bne leaveCheckForCommand

	ldr r1, =command

	@ get each character from UART FIFO buffer
	bl recieveCharUart
	cmp r0, #0x39
	suble r0, r0, #0x30
	subgt r0, r0, #0x37

	str r0, [r1]

	bl recieveCharUart
	cmp r0, #0x39
	suble r0, r0, #0x30
	subgt r0, r0, #0x37

	str r0, [r1,#1]

	bl recieveCharUart
	cmp r0, #0x39
	suble r0, r0, #0x30
	subgt r0, r0, #0x37

	str r0, [r1,#2]

	bl recieveCharUart
	cmp r0, #0x39
	suble r0, r0, #0x30
	subgt r0, r0, #0x37

	str r0, [r1,#3]

	@ store into one command number
	mov r0, #0
	ldrh r2, [r1]
	and r2, #0xF
	orr r0, r0, r2
	lsl r0, #4

	ldrh r2, [r1, #1]
	and r2, #0xF
	orr r0, r0, r2
	lsl r0, #4

	ldrh r2, [r1, #2]
	and r2, #0xF
	orr r0, r0, r2
	lsl r0, #4

	ldrh r2, [r1, #3]
	and r2, #0xF
	orr r0, r0, r2

	ldr r1, =readCommand
	mov r2, #0xFFFF
	and r0, r0, r2
		
		
	strh r0, [r1]
	mov r1, r0
	bl outputToSevSeg
	leaveCheckForCommand:
	pop {r0,r1,r2,r3,lr}
bx lr





.endif

