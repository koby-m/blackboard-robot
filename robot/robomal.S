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

.data

@ Main operation jump-table
r_operation: .word r_dataJump, r_arithmeticJump,r_branchJump,r_controlJump
@ Suboperation jump-table

	@ Read 			0x10XX
	@ Write 			0x11XX
	@ Load 			0x12XX
	@ Store 			0x13XX
r_dataJump: .word r_read, r_write, r_load, r_store	

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
	push {lr}
	
	mov r6, #0
	
	runRobomalLoop:
			push {r1}
			ldr r1, =functionMode
			ldr r1, [r1]
			bl getSwitchStates @ check to see if switches match function mode
			cmp r0, r1
			pop {r1}
		bne endRobomalLoop @ if switches don't match functionMode, leave
	bl simClockCycle
	cmp r8, #0x33
	bne runRobomalLoop
	endRobomalLoop:
	push {r2}
		@ stop the motors just in case
		
		ldr r1, =MOTOR_0_BASEADDR
		mov r2, #0
		bl setMotorSpeed
		
		ldr r1, =MOTOR_1_BASEADDR
		mov r2, #0
		bl setMotorSpeed
		pop {r2}
	
	pop {lr}
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
		push {r2}
		@ first stop the motor in case its running
		ldr r1, =MOTOR_0_BASEADDR
		mov r2, #0
		bl setMotorSpeed
		@ set its direction
		mov r2, #0
		bl setMotorDirection
		@ set its speed slower than the left motor so it turns right
		mov r2, #2047
		bl setMotorSpeed
		
		@ first stop the motor in case its running
		ldr r1, =MOTOR_1_BASEADDR
		mov r2, #0
		bl setMotorSpeed
		@ set its direction
		mov r2, #0
		bl setMotorDirection
		@ set its speed
		mov r2, #4095
		bl setMotorSpeed
		pop {r2}
		
	b leave_r_execute
	
	
	r_right:
		push {r2}
		
		@ first stop the motor in case its running
		ldr r1, =MOTOR_0_BASEADDR
		mov r2, #0
		bl setMotorSpeed
		@ set its direction
		mov r2, #0
		bl setMotorDirection
		@ set its speed
		mov r2, #4095
		bl setMotorSpeed
		
		@ first stop the motor in case its running
		ldr r1, =MOTOR_1_BASEADDR
		mov r2, #0
		bl setMotorSpeed
		@ set its direction
		mov r2, #0
		bl setMotorDirection
		@ set its speed slower than the right motor so it turns left
		mov r2, #2047
		bl setMotorSpeed
		pop {r2}
		
	b leave_r_execute
	
	
	r_forward:
		push {r2}
	
		@ first stop the motor in case its running
		ldr r1, =MOTOR_0_BASEADDR
		mov r2, #0
		bl setMotorSpeed
		@ set its direction
		mov r2, #0
		bl setMotorDirection
		@ set its speed
		mov r2, #4095
		bl setMotorSpeed
		
		@ first stop the motor in case its running
		ldr r1, =MOTOR_1_BASEADDR
		mov r2, #0
		bl setMotorSpeed
		@ set its direction
		mov r2, #0
		bl setMotorDirection
		@ set its speed
		mov r2, #4095
		bl setMotorSpeed
		pop {r2}
		
	b leave_r_execute
	
	
	r_backward:
		push {r2}
		
		@ first stop the motor in case its running
		ldr r1, =MOTOR_0_BASEADDR
		mov r2, #0
		bl setMotorSpeed
		@ set its direction
		mov r2, #1
		bl setMotorDirection
		@ set its speed
		mov r2, #4095
		bl setMotorSpeed
		
		@ first stop the motor in case its running
		ldr r1, =MOTOR_1_BASEADDR
		mov r2, #0
		bl setMotorSpeed
		@ set its direction
		mov r2, #1
		bl setMotorDirection
		@ set its speed
		mov r2, #4095
		bl setMotorSpeed
		pop {r2}
	
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