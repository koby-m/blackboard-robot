.global main
.global functionMode

.global command
.global readCommand

.include "../src/robomal.S"
.include "../src/robotfunc.S"
.include "../src/klibio.S"
.include "../src/klibmtr.S"
.include "../src/klibwifi.S"

.data

command: .hword 1,1,1,1
readCommand: .hword 1
functionMode: .word 1

@ Autonomous mode
autoInstruct: .hword  0x1111
autoData: .hword 0x1111

@ Autonomous mode
remtInstruct: .hword  0x1111, 0x3300
remtData: .hword 0x1111

@ Line following mode
lineInstruct: .hword  0x1111
lineData: .hword 0x1111

@ Programmable mode - max 32 instructions
progInstruct: .hword  0,0,0,0,0,0
progData: .hword 0x1111

.text 
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
main:

	bl setupSevSeg
	
	bl setupWifiHost

	ldr r1, =MOTOR_0_BASEADDR
	bl setupMotor

	ldr r1, =MOTOR_1_BASEADDR
	bl setupMotor
	
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
			b mainloop
			
		@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
		
		instructSet_Ett: @ remote-control mode
			ldr r2, =readCommand
			ldr r2, [r2]
			ldr r1, =remtInstruct
			str r2, [r1]
			b continueToExecute

		@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
		
		instructSet_Tva: @ line following mode
			mov r1, #0x3
			bl outputToSevSeg
			
			ldr r1, =lineInstruct
			ldr r2, =lineData
			
			b continueToExecute
			
		@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
		
		instructSet_Tre: @ programmable mode
			mov r1, #0x4
			bl outputToSevSeg
			
			ldr r1, =progInstruct
			ldr r2, =progData
			
			b mainloop
			
		@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
		
		continueToExecute:
			bl runRobomal
		@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
	b mainloop

.end