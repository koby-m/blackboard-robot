@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
@
@        Library Name:           
@								Klib-mtr (for RealDigital Blackboard)
@        
@        Version:                
@								1.0.0 
@
@        Contributor(s):         
@								Koby Miller
@
@        Date last modified:     
@								April 16th, 2024
@
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

.ifndef KLIB_MTR_S_
.set KLIB_MTR_S_, 1

.set MOTOR_0_BASEADDR, 0x43C60000	@ This is the motor connected to the top row pins of PMODC port
.set MOTOR_1_BASEADDR, 0x43C80000	@ This is the motor connected to the bottom row pins of PMODC port

.set TTC0_BASEADDR, 0xF8001000

.text
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
@ setupMotor
@
@ 		r1 -> address of motor to set up
@
@		No return values
@
@ Last modified: April 16th, 2024
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
setupMotor:
	
	@ Setup initial motor speed (hence duty cycle) to 0; (Make sure H-bridge enable starts with motors off)
	mov r0, #0
	str r0, [r1, #0x08]

	@ Setup initial motor direction
	mov r0, #0
	str r0, [r1, #0x04]

	@ Setup the motor PWM freq. of 100MHz / 4095 = 24.42kHz
	mov r0, #4095
	str r0, [r1, #0x14]

	@ Enable the H-Bridge
	mov r0, #1
	str r0, [r1]

bx lr

@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
@ setMotorSpeed
@
@ 		r1 -> address of motor to set
@ 		r2 -> motor speed
@
@		No return values
@
@ Last modified: April 16th, 2024
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
setMotorSpeed:
	push {r3,r4}
	mov r3, r2
	mov r4, #0xFFF
	and r3, r3, r4
	str r3, [r1, #0x08]
	pop {r3,r4}
bx lr
	
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
@ setMotorDirection
@
@ 		r1 -> address of motor to set
@ 		r2 -> 0 for clockwise, 1 for counter-clockwise
@
@		No return values
@
@ Last modified: April 16th, 2024
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
setMotorDirection:
	str r2, [r1, #0x04]
bx lr

@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
@ setMotorDirection
@
@ 		r1 -> address of motor to set
@ 		r2 -> 0 for clockwise, 1 for counter-clockwise
@
@		No return values
@
@ Last modified: April 16th, 2024
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
setupServo:
	push {r0, r1}
	@ setup clock_control_1
	@ pclk = 111.111MHz
	@ choose a prescaler = 5
	@ f_ttc = 111.111MHz / (2^(1+prescaler)) = 111.111MHz / 64 = 1.7361MHz
	@ bit 0 = prescale enable
	@ bit 1 - 4 = prescale value
	ldr r0, =TTC0_BASEADDR
	ldr r1, =0b0001011
	str r1, [r0]

	@ setup interval_value_1
	@ bit 0 - 15 = interval value
	@ interval = f_ttc * time
	@ 1.7361MHz * 20ms = 34,722

	ldr r1, =34722
	str r1, [r0, #0x24]

	@ setup match_value_1
	@ match = interval / 20 = 1736
	@ for servo at 0 degrees = 1.5 ms
	@ 1736*1.5 = 2604
	@ bit 0 - 15 = match value
	mov r1, #2900
	str r1, [r0, #0x30]

	@ setup counter_control_1
	@ waveform high to low on match (bit 6 = 1)
	@ enable the waveform (bit 5 = 0)
	@ don't need to clear counter (bit 4 = 0)
	@ match mode on (bit 3 = 1)
	@ increment (count up) (bit 2 = 0)
	@ interval mode on (bit 1 = 1)
	@ turn counter on (bit 0 = 0)
	ldr r1, =0b1001010
	str r1, [r0, #0x0C]

	pop {r0, r1}

bx lr

setServoAngle:
	push {r0, r2}

	ldr r0, =TTC0_BASEADDR
	str r1, [r0, #0x30]

	pop {r0, r2}
bx lr



.endif
