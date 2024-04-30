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
functionMode: .word 1

@ Autonomous mode
autoInstruct: .hword  0x4400, 0x3300
autoData: .hword 0x1111

@ Remote control mode
remtInstruct: .hword  0x4400, 0x3300
remtData: .hword 0x1111

@ Line following mode
lineInstruct: .hword  0x1400, 0x4400, 0x1500, 0x3300
lineData: .hword 0x1111

@ Programmable mode - max 32 instructions?
progInstruct: .hword  0x4400, 0x3300
progData: .hword 0x1111

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
		
		ldr r1, =readCommand
		ldr r1, [r1]
		
		skipUart:	

		@ get switch states and store to functionMode memory spot
		bl getSwitchStates
		ldr r1, =functionMode
		str r0, [r1]
		mov r1, r0
		bl outputToLEDs
	
		@ determine what instruction set to perform
		cmp r0, #0
		beq instructSet_Noll @ autonomous mode
		cmp r0, #1
		beq instructSet_Ett @ remote-control mode
		cmp r0, #2
		beq instructSet_Tva @ line following mode
		cmp r0, #4
		beq instructSet_Tre @ programmable mode
		
		@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+ Operation Modes +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
		instructSet_Noll: @ autonomous mode
			ldr r1, =autoInstruct
			ldr r1, =autoData
			
			b continueToExecute
			
		@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
		
		instructSet_Ett: @ remote-control mode
			ldr r2, =readCommand
			ldrh r2, [r2]
			ldr r1, =remtInstruct
			
			mov r3, #0x0113
			cmp r2, r3		@ skip if informational
			beq instructSet_EttSkip
			mov r3, #0x0CE7
			cmp r2, r3
			beq instructSet_EttSkip
			mov r3, #0xF1F0
			cmp r2, r3
			beq instructSet_EttSkip
			mov r3, #0x0405
			cmp r2, r3
			beq instructSet_EttSkip
			mov r3, #0x2235
			cmp r2, r3
			beq instructSet_EttSkip
			mov r3, #0x0110
			cmp r2, r3
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
		
		instructSet_Tre: @ programmable mode
			mov r1, #0x4
			bl outputToSevSeg
			
			ldr r1, =progInstruct
			
			b mainloop
			
		@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
		
		continueToExecute:
			bl runRobomal
		@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
	b mainloop

.end
