.global main
.global functionMode

.global command
.global readCommand
.global lineInstruct
.global autoInstruct

.include "../src/robomal.S"
.include "../src/robotfunc.S"
.include "../src/klibio.S"
.include "../src/klibmtr.S"
.include "../src/klibwifi.S"

.data

command: .hword 1,1,1,1
readCommand: .hword 0x4400
functionMode: .hword 0xEE00

@ Autonomous mode
autoInstruct: .hword 0x4400, 0x3412, 0x4202, 0x3412, 0x4202, 0x4304, 0x3412, 0x4204, 0x3415, 0x3300
autoData: .hword 0x1111

@ Remote control mode
remtInstruct: .hword  0x4400, 0x3300
remtData: .hword 0x1111

@ Line following mode
lineInstruct: .hword  0x1400, 0x4400, 0x1500, 0x3300
lineData: .hword 0x1111

@ Programmable mode - max 32 instructions
progInstruct: .hword  0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300
progData: .hword 0x1111
progIndex: .hword 0x0

.text 
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
main:
	mov r1, #0
	mov r2, #1
	bl setupPmod
	mov r2, #0
	bl setupPmod

	bl setupSevSeg

	bl setupWifiHost

	ldr r1, =MOTOR_0_BASEADDR
	bl setupMotor

	ldr r1, =MOTOR_1_BASEADDR
	bl setupMotor
	
	bl setupServo
	
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
	mainloop:

		@ Check to see if the FIFO has something,
		@ otherwise skip trying to get a command
		bl checkFIFO
		cmp r0, #0
		bne skipUart

		@ See if there is a command to be read
		bl checkForCommand
		

		skipUart:	

		@ get switch states and store to functionMode memory spot

		ldr r0, =readCommand
		ldrh r0, [r0]
		and r1, r0, #0xFF00
		cmp r1, #0xEE00
		bne continueMain

		ldr r1, =functionMode
		strh r0, [r1]

		continueMain:

		ldr r0, =functionMode
		ldrh r0, [r0]
	
		@ determine what instruction set to perform
		mov r1, #0xEE00
		cmp r0, r1
		beq mainloop @ no mode

		mov r1, #0xEE01
		cmp r0, r1
		beq instructSet_Noll @ autonomous mode

		mov r1, #0xEE02
		cmp r0, r1
		beq instructSet_Ett @ remote-control mode

		mov r1, #0xEE03
		cmp r0, r1
		beq instructSet_Tva @ line following mode

		mov r1, #0xEE04
		cmp r0, r1
		beq instructSet_Tre @ programmable mode

		mov r1, #0xEE05
		cmp r0, r1
		ldreq r2, =progIndex @ reset programming index
		moveq r3, #0
		streqh r3, [r2]
		beq instructSet_Fyra @ line following mode

		b mainloop
		
		@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+ Operation Modes +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
		instructSet_Noll: @ autonomous mode
			ldr r1, =autoInstruct
			
			b continueToExecute
			
		@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
		
		instructSet_Ett: @ remote-control mode
			ldr r2, =readCommand
			ldrh r2, [r2]
			ldr r1, =remtInstruct
			
			bl skipCheck
			cmp r0, #1
			beq instructSet_EttSkip
			
			strh r2, [r1]
			instructSet_EttSkip:
			
			b continueToExecute

		@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
		
		instructSet_Tva: @ line following mode-
			ldr r1, =lineInstruct
			ldr r2, =lineData
			
			b continueToExecute
			
		@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
		
		instructSet_Tre: @ programmable mode programming
			ldr r2, =readCommand
			ldrh r2, [r2]
			ldr r1, =progInstruct

			cmp r2, #0
			beq mainloop

			bl skipCheck
			cmp r0, #1
			beq instructSet_EttSkip
			ldr r4, =progIndex
			ldrh r4, [r4]
			cmp r4, #32
			beq executeProg
			lsl r4, r4, #1
			
			strh r2, [r1, r4]

			mov r5, #0
			ldr r6, =readCommand
			strh r5, [r6]

			lsr r4, r4, #1
			add r3, r4, #1
			ldr r4, =progIndex
			strh r3, [r4]

			mov r3, #0x3300
			cmp r2, r3
			bne continueToGetInstruct
			executeProg:

			ldr r0, =functionMode
			mov r1, #0xEE05
			strh r1, [r0]

			continueToGetInstruct:
			b mainloop
			

		@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

		instructSet_Fyra: @ programmable mode executing
			ldr r1, =progInstruct
			ldr r2, =progData

			b continueToExecute

		@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
		
		continueToExecute:
			bl runRobomal
		@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
	b mainloop



skipCheck:
	push {r3,r4}

	mov r3, #0x0113
	cmp r2, r3		@ skip if informational
	moveq r0, #1
	mov r3, #0x0CE7
	cmp r2, r3
	moveq r0, #1
	mov r3, #0xF1F0
	cmp r2, r3
	moveq r0, #1
	mov r3, #0x0405
	cmp r2, r3
	moveq r0, #1
	mov r3, #0x2235
	cmp r2, r3
	moveq r0, #1
	mov r3, #0x0110
	cmp r2, r3
	moveq r0, #1

	mov r4, r2
	mov r3, #0xFF00
	and r4, r4, r3
	mov r3, #0xEE00
	cmp r4, r3
	moveq r0, #1
	pop {r3,r4}

bx lr


.end
