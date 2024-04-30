@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
@
@        Library Name:           
@								Klib-timer  (for RealDigital Blackboard)
@        
@        Version:                
@								1.0.0 
@
@        Contributor(s):         
@								Koby Miller
@
@        Date last modified:     
@								March, 22nd 2024
@
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

.ifndef KLIB_TIMER_ARM_ASSEMBLY_
.set KLIB_TIMER_ARM_ASSEMBLY_, 1

@.include "../src/klibio.S"

.set GTC_BASEADDR, 0xF8F00200
.set GTC_COMPARATOR_ONESEC, 1302082

@ Adjust this value to determine the timer period
.set GTC_COMPARATOR, 1302082 
 
@ set comparator to make desired timer interrupt
	@
	@ f_CPU3x2x = f_CPU/2
	@		where f_CPU = 666.666 MHz
	@		:. f_CPU3x2x = 333.333 MHz
	@
	@ Using prescaler:
	@ f_GTC = f_CPU3x2x / (P + 1)
	@ 		where P = 255 arbitrarily
	@		:. f_GTC = 1.302 MHz
	@
	@ To determine time period:
	@	t * f_GTC - 1 = C
	@		where t is desired time period
	@ 		where C is comparator value
	@		:. C = 2,604,163 for two-second period (t = 2)

.text
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
@ configureGlobalTimerCounter
@ Configure the global timer counter
@
@	No parameters
@
@	No return value
@
@ Written by Koby Miller
@ Last modified: March 22nd, 2024
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
configureGtc:
	push {r0,r1}
	
	ldr r0, =GTC_BASEADDR
	
	@ set comparator to make desired timer interrupt
	@
	@ f_CPU3x2x = f_CPU/2
	@		where f_CPU = 666.666 MHz
	@		:. f_CPU3x2x = 333.333 MHz
	@
	@ Using prescaler:
	@ f_GTC = f_CPU3x2x / (P + 1)
	@ 		where P = 255 arbitrarily
	@		:. f_GTC = 1.302 MHz
	@
	@ To determine time period:
	@	t * f_GTC - 1 = C
	@		where t is desired time period
	@ 		where C is comparator value
	@		:. C = 2,604,163 for two-second period
	
	@ https://www.desmos.com/calculator/o3wtunx1el
	
	ldr r1, =GTC_COMPARATOR
	str r1, [r0,#0x10] @ comparator register
	str r1, [r0,#0x18] @ autoincrement register
	mov r1, #0
	str r1, [r0,#0x14]
	
	ldr r1, =#0xFF0F @ prescaler, timer is on at start
	@ prescaler, timer is off at start with value 0xFF0E, :. set bit 0 to 1
	str r1, [r0, #0x8]
	
	pop {r0,r1}
bx lr

@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
@ EoF
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
.endif 
