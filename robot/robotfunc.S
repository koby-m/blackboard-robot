.ifndef ROBOT_FUNC_S_
.set ROBOT_FUNC_S_, 1

.include "../src/klibwifi.S"
.include "../src/klibio.S"

.data

.text

checkForCommand:
	push {r0,r1,r2,lr}

	bl recieveCharUart

	cmp r0, #0x3A

	bne leaveCheckForCommand

	ldr r1, =command

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

	mov r0, #0
	ldrb r2, [r1]
	orr r0, r0, r2
	lsl r0, #4
	ldrb r2, [r1, #1]
	orr r0, r0, r2
	lsl r0, #4
	ldrb r2, [r1, #2]
	orr r0, r0, r2
	lsl r0, #4
	ldrb r2, [r1, #3]
	orr r0, r0, r2
	ldr r1, =readCommand
	str r0, [r1]

	mov r1, r0
	bl outputToSevSeg
	leaveCheckForCommand:
	pop {r0,r1,r2,lr}
bx lr

.endif

