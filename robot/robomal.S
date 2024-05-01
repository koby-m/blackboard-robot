@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
@
@        Library Name:           
@								Robomal (for RealDigital Blackboard)
@        
@        Version:                
@								1.0.0 
@
@        Contributor(s):         
@								Koby Miller
@
@        Date last modified:     
@								March 7th, 2024
@
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
.ifndef ROBOMAL_S_
.set ROBOMAL_S_, 1

.set MOTOR_0_BASEADDR, 0x43C60000	@ This is the motor connected to the top row pins of PMODC port
.set MOTOR_1_BASEADDR, 0x43C80000	@ This is the motor connected to the bottom row pins of PMODC port

.include "../src/klibio.S"
.include "../src/klibmtr.S"
.include "../src/klibwifi.S"
.include "../src/robotfunc.S"

.data

@ Main operation jump-table
r_operation: .word r_dataJump, r_arithmeticJump,r_branchJump,r_controlJump
@ Suboperation jump-table

	@ Read 				0x10XX
	@ Write 				0x11XX
	@ Load 				0x12XX
	@ Store 				0x13XX
	@ Line sensors 		0x14XX
	@ Collision sensors 	0x15XX
r_dataJump: .word r_read, r_write, r_load, r_store, r_lineSensors, r_collisionSensors

	@ Add 				0x20XX
	@ Subtract 		0x21XX
	@ Multiply 		0x22XX
r_arithmeticJump: .word r_add, r_sub, r_mul

	@ Branch 						0x30XX
	@ Branch-if-equivalent 		0x31XX
	@ Branch-if-not-equivalent	0x32XX
	@ Halt 						0x33XX
	@ Wait 						0x34XX
r_branchJump: .word r_branch, r_brancheq, r_branchne, r_halt, r_wait

	@ Left 		0x40XX
	@ Right 		0x41XX
	@ Forward		0x42XX
	@ Backward 	0x43XX
	@ Brake 		0x44XX
r_controlJump: .word r_left, r_right, r_forward, r_backward, r_brake

@ ROBOMAL Register File 
@ r5 = accumulator register
@ r6 = program counter register
@ r7 = instruction register
@ r8 = opcode register
@ r9 = operand register
@ r10 = multiply top half solution register

.text 

@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
@ runRobomal
@
@		r1 -> instruction set to follow
@		r2 -> instruction data to use
@		r3 -> function mode
@
@ Last modified: March 6th, 2024
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
runRobomal:
	push {r7,r8,r9,lr}
	
	mov r6, #0
	
	runRobomalLoop:
			push {r1,r2,r3}

			bl checkFIFO
			cmp r0, #0
			bne leaveCheck

			@ See if there is a command to be read
			bl checkForCommand

			ldr r1, =readCommand
			ldrh r1, [r1]
			ldr r0, =functionMode
			ldrh r0, [r0]

			mov r3, #0xFF00
			mov r2, r1
			and r2, r2, r3
			mov r3, #0xEE00
			cmp r2, r3

			bne leaveCheck

			cmp r1, r0
			ldrne r0, =functionMode
			strneh r1, [r0]
			movne r1, #0x4400
			ldrne r0, =readCommand
			strneh r1, [r0]
			popne {r1,r2,r3}
			bne endRobomalLoop

			leaveCheck:
			pop {r1,r2,r3}
	bl simClockCycle
	cmp r8, #0x33
	bne runRobomalLoop
	endRobomalLoop:
		@push {r2}
		@ stop the motors just in case

		@ldr r1, =MOTOR_0_BASEADDR
		@mov r2, #0
		@bl setMotorSpeed

		@ldr r1, =MOTOR_1_BASEADDR
		@mov r2, #0
		@bl setMotorSpeed
		@pop {r2}
	
	pop {r7,r8,r9,lr}
bx lr

@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
@ simClockCycle
@
@	Simulate a single "fetch, decode, and execute" cycle
@
@ Last modified: March 6th, 2024
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
simClockCycle:
	push {lr}
	
	bl r_fetch
	bl r_decode
	bl r_execute

	pop {lr}
bx lr 

@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
@ r_fetch
@
@		r1 -> instruction set to follow
@		r2 -> instruction data to use
@ 		r6 -> program counter
@		r7 -> instruction register
@
@ Last modified: March 6th, 2024
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
r_fetch:
	push {r0}

	ldrh r7, [r1,r6]
	
	add r6, r6, #0x2
	
	pop {r0}
bx lr

@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
@ r_decode
@
@ 		r7 -> instruction register
@ 		r8 -> opcode register
@ 		r9 -> operand register
@
@ Last modified: March 6th, 2024
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
r_decode:

	lsr r8, r7, #8
	
	and r9, r7, #0xFF

bx lr

@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
@ r_execute
@
@ 		r5 -> accumulator register
@ 		r6 -> program counter register (if we are doing a branch)
@ 		r8 -> opcode register
@ 		r9 -> operand register
@		r10 -> multiply top half solution register
@
@ Last modified: March 7th, 2024
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
r_execute:
	push {r0,r1,lr}

	@ determine first hex digit of opcode
	mov r1, r8 @ create copy
	and r1, #0xF0 @ mask off first digit
	sub r1, r1, #0x10
	lsr r1, #2 @ make appropriate size to index a word array (right shift because must first be shifted 4 due to hex, then multiplied by 4 for index)
	ldr r0, =r_operation @ load operation jump-table
	ldr r0, [r0, r1] @ index jump-table by first digit, which should store sub-jump-table in r0

	@ determine second hex digit of opcode
	mov r1, r8 @ create copy
	and r1, #0xF @ mask off second digit
	lsl r1, #2 @ make appropriate size to index a word array
	ldr r0, [r0, r1] @ index sub-jump-table by second digit
	bx r0
	
	@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+ Operations +-+-+-+-+-+-+-+-+-+-+-+-+-+-+
	r_read:
		mov r1, #1 @ read from bottom row
		bl pmodRead @ get pmod value returned in r0
		mov r1, r2 @ get address of dataSet start
		strh r0, [r1, r9] @ store pmod value in r1 offset r9
	b leave_r_execute
	
	
	r_write:
		mov r0, r2 @ get address of dataSet start
		push {r2}
		ldrh r1, [r0, r9] @ store pmod value in r1 offset r9
		mov r2, r1 @ set data to write
		mov r1, #0 @ write to top row
		bl pmodWrite @ get pmod value returned in r0
		pop {r2}
	b leave_r_execute
	
	
	r_load:
		mov r0, r2 @ get address of dataSet start
		ldrh r5, [r0, r9] @ load from value in dataSet offset r9
	b leave_r_execute
	
	
	r_store:
		mov r0, r2 @ get address of dataSet start
		strh r5, [r0, r9] @ set r5 to value in dataSet offset r9
	b leave_r_execute
	
	r_lineSensors: @ change drive instruction based on sensor status
		push {r2}
		mov r1, #1
		bl pmodRead @ read bottom row
		
		pop {r1} @ pop to get original address
		mov r3, r1
		sub r3, r3, #0x8
		push {r1} @ re-push
		
		cmp r0, #0b0011
		mov r2, #0x4204
		streqh r2, [r3, r6]

		cmp r0, #0b0001
		mov r2, #0x4003
		streqh r2, [r3, r6]

		cmp r0, #0b0010
		mov r2, #0x4103
		streqh r2, [r3, r6]

		cmp r0, #0
		mov r2, #0x4204
		streqh r2, [r3, r6]

		pop {r2}
	
	b leave_r_execute
	
	r_collisionSensors: 
		
		mov r1, #0
		bl pmodRead
		
			cmp r0, #0b1111
			beq noCollide
		
			cmp r0, #0b1100
			beq colReverseLeft
		
			cmp r0, #0b1110
			beq colReverseLeft
		
			cmp r0, #0b0011
			beq colReverseRight
		
			cmp r0, #0b0111
			beq colReverseRight
			
			b colReverseRight
			
			
		
		colReverseLeft:
				push {r2}
		
				mov r1, #2200
				bl setServoAngle
		
				ldr r1, =MOTOR_0_BASEADDR
				@ set its direction
				mov r2, #0
				bl setMotorDirection
				@ set its speed
				mov r2, #3295
				bl setMotorSpeed

				ldr r1, =MOTOR_1_BASEADDR
				@ set its direction
				mov r2, #0
				bl setMotorDirection
				@ set its speed
				mov r2, #4095
				bl setMotorSpeed
				pop {r2}
			bl dummyTimer
			b noCollide
			
		
		colReverseRight:
				push {r2}
		
				mov r1, #3500
				bl setServoAngle
				
				ldr r1, =MOTOR_0_BASEADDR
				@ set its direction
				mov r2, #0
				bl setMotorDirection
				@ set its speed
				mov r2, #4095
				bl setMotorSpeed

				ldr r1, =MOTOR_1_BASEADDR
				@ set its direction
				mov r2, #0
				bl setMotorDirection
				@ set its speed
				mov r2, #3295
				bl setMotorSpeed
				pop {r2}
			bl dummyTimer
			b noCollide
		
		noCollide:
		
	b leave_r_execute
	
	r_add:
		mov r0, r2 @ get address of dataSet start
		ldrh r0, [r0, r9] @ load from value in dataSet offset r9
		add r5, r5, r0
	b leave_r_execute
	
	
	r_sub:
		mov r0, r2 @ get address of dataSet start
		ldrh r0, [r0, r9] @ load from value in dataSet offset r9
		sub r5, r5, r0
	b leave_r_execute
	
	
	r_mul:
		mov r0, r2 @ get address of dataSet start
		ldrh r0, [r0, r9] @ load from value in dataSet offset r9
		mul r5, r5, r0
	b leave_r_execute
	
	
	r_branch:
		mov r6, r9 @ set program counter to argument
	b leave_r_execute
	
	
	r_brancheq:
		cmp r5, #0 @ compare to zero
		moveq r6, r9 @ set program counter to argument if zero
	b leave_r_execute
	
	
	r_branchne:
		cmp r5, #0 @ compare to zero
		movne r6, r9 @ set program counter to argument if NOT zero
	b leave_r_execute
	
	
	r_halt:
		@ end of program
	b leave_r_execute


	r_wait:
		@ hard sleep

		@ waits however long it takes the stupid rock
		@ to count down from this stupid number
		ldr r1, =#0x4FFFFFFF
		r_wait_loop:
			sub r1, r1, #1
			cmp r1, #0
		bne r_wait_loop

	b leave_r_execute
	
	
	r_left:
		push {r2,r3,r4}
		
		mov r3, #75
		mul r3, r3, r9
		mov r4, #2875
		sub r4, r4, r3
		mov r1, r4 @ 2600 at r9 is 3
		bl setServoAngle
		
		mov r3, r9
		and r3, r3, #0xF
		mov r4, #93
		mul r3, r3, r4
		mov r4, #2700
		add r3, r3, r4

		ldr r1, =MOTOR_0_BASEADDR
		@ set its direction
		mov r2, #1
		bl setMotorDirection
		@ set its speed slower than the left motor so it turns right
		mov r2, #0@3047
		bl setMotorSpeed

		ldr r1, =MOTOR_1_BASEADDR
		@ set its direction
		mov r2, #1
		bl setMotorDirection
		@ set its speed
		mov r2, r3
		bl setMotorSpeed
		pop {r2,r3,r4}

	b leave_r_execute
	
	
	r_right:
		push {r2,r3,r4}
		
		mov r3, #75
		mul r3, r3, r9
		mov r4, #2875
		add r3, r3, r4
		mov r1, r3 @ 3100 at r9 is 3
		bl setServoAngle

		mov r3, r9
		and r3, r3, #0xF
		mov r4, #93
		mul r3, r3, r4
		mov r4, #2700
		add r3, r3, r4

		ldr r1, =MOTOR_0_BASEADDR
		@ set its direction
		mov r2, #1
		bl setMotorDirection
		@ set its speed
		mov r2, r3
		bl setMotorSpeed

		ldr r1, =MOTOR_1_BASEADDR
		@ set its direction
		mov r2, #1
		bl setMotorDirection
		@ set its speed slower than the right motor so it turns left
		mov r2, #0@3047
		bl setMotorSpeed
		pop {r2,r3,r4}

	b leave_r_execute
	
	
	r_forward:
		push {r2,r3,r4}
		
		mov r1, #2900
		bl setServoAngle
		
		mov r3, r9
		and r3, r3, #0xF
		mov r4, #93
		mul r3, r3, r4
		mov r4, #2700
		add r3, r3, r4

		ldr r1, =MOTOR_0_BASEADDR
		@ set its direction
		mov r2, #1
		bl setMotorDirection
		@ set its speed
		mov r2, r3
		bl setMotorSpeed

		ldr r1, =MOTOR_1_BASEADDR
		@ set its direction
		mov r2, #1
		bl setMotorDirection
		@ set its speed
		mov r2, r3
		bl setMotorSpeed
		
		pop {r2,r3,r4}

	b leave_r_execute
	
	
	r_backward:
		push {r2,r3,r4}
		
		mov r1, #2900
		bl setServoAngle
		
		mov r3, r9
		and r3, r3, #0xF
		mov r4, #93
		mul r3, r3, r4
		mov r4, #2700
		add r3, r3, r4

		ldr r1, =MOTOR_0_BASEADDR
		@ set its direction
		mov r2, #0
		bl setMotorDirection
		@ set its speed
		mov r2, r3
		bl setMotorSpeed

		ldr r1, =MOTOR_1_BASEADDR
		@ set its direction
		mov r2, #0
		bl setMotorDirection
		@ set its speed
		mov r2, r3
		bl setMotorSpeed
		
		pop {r2,r3,r4}

	b leave_r_execute
	
	
	r_brake:
		push {r2}
		@ stop that bitch

		ldr r1, =MOTOR_0_BASEADDR
		mov r2, #0
		bl setMotorSpeed

		ldr r1, =MOTOR_1_BASEADDR
		mov r2, #0
		bl setMotorSpeed
		pop {r2}
	@b leave_r_execute
	
	@ +-+-+-+-+-+-+-+-+-+-+-+-+-+ End Operations +-+-+-+-+-+-+-+-+-+-+-+-+-+
	leave_r_execute:
	pop {r0,r1,lr}
bx lr
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
@ EoF
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
.endif
