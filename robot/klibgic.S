@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
@
@        Library Name:           
@								Klib-gic  (for RealDigital Blackboard)
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

.ifndef KLIB_GIC_ARM_ASSEMBLY_
.set KLIB_GIC_ARM_ASSEMBLY_, 1

.include "../src/klibio.S"
.include "../src/klibtimer.S"
.include "../src/kHandlerDictionary.S"

.set ICCICR_BASEADDR, 0xF8F00100 @ CPU Interface Control Register
.set ICCPMR_BASEADDR, 0xF8F00104 @ Interrupt Priority Mask Register
.set ICCIAR_BASEADDR, 0xF8F0010C @ Interrupt Acknowledge Register
.set ICCEOIR_BASEADDR, 0xF8F00110 @ End of Interrupt Register
.set ICDDCR_BASEADDR, 0xF8F01000 @ Distributor Control Register
.set ICDISER_BASEADDR, 0xF8F01100 @ Interrupt Set Enable Registers
.set ICDICER_BASEADDR, 0xF8F01180 @ Interrupt Clear Enable Registers
.set ICDIPR_BASEADDR, 0xF8F01400 @ Interrupt Priority Registers
.set ICDIPTR_BASEADDR, 0xF8F01800 @ Interrupt Processor Targets Registers
.set ICDICFR_BASEADDR, 0xF8F01C00 @ Interrupt Configuration Registers

.text
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
@ configureGic
@ Configure generic-interrupt-controller
@
@	No parameters
@
@	No return value
@
@ Written by Koby Miller
@ Last modified: March 22nd, 2024
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
configureGic:
	push {r0,r1,r2,lr}

	@ 1. Disable the GIC distributor (ICDDCR)
	ldr r0, =ICDDCR_BASEADDR
	mov r1, #0b00
	str r1, [r0]

	@ 2. Drive IRQ from the GIC (ICCICR)
	ldr r0, =ICCICR_BASEADDR
	mov r1, #0b00011
	str r1, [r0]

	@ 3. Set GIC priority mask
	ldr r0, =ICCPMR_BASEADDR
	mov r1, #255
	str r1, [r0]

	@ 4. Configure the settings for specific interrupt IDs we want
	bl gicConfigure_ID27
	bl gicConfigure_ID52

	@ 5. Enable the GIC distributor (ICDDCR)
	ldr r0, =ICDDCR_BASEADDR
	mov r1, #0b11
	str r1, [r0]

	pop {r0,r1,r2,lr}

bx lr

gicConfigure_ID27:
	ldr r0, =ICDIPTR_BASEADDR
	ldr r1, =#0x3000000
	mvn r1, r1
	ldr r2, [r0, #0x18]
	and r2, r2, r1
	str r2, [r0, #0x18]
	ldr r0, =ICDICER_BASEADDR
	ldr r1, =#0x8000000
	str r1, [r0]

	@ 4b. Set Interrupt Sensitivity for ID 27
	ldr r0, =ICDICFR_BASEADDR
	ldr r1, =#0xC00000
	ldr r2, [r0, #0x04]
	orr r2, r2, r1
	str r2, [r0, #0x04]

	@ 4c. Set Interrupt Priority for ID 27
	ldr r0, =ICDIPR_BASEADDR
	ldr r1, =#0xFF000000
	mvn r1, r1
	ldr r2, [r0, #0x18]
	and r2, r2, r1
	ldr r1, =#0x50000000
	orr r2, r2, r1
	str r2, [r0, #0x18]

	@ 4d. Enable Interrupts from ID 27 now that we are done modifying settings
	ldr r0, =ICDIPTR_BASEADDR
	ldr r1, =#0x1000000
	ldr r2, [r0, #0x18]
	orr r2, r2, r1
	str r2, [r0, #0x18]
	ldr r0, =ICDISER_BASEADDR
	ldr r1, =#0x8000000
	str r1, [r0]

bx lr

gicConfigure_ID52:
	@ Interrupt ID 52 = GPIO Interrupts (i.e. from BTN4 or BTN5)
	ldr r0, =ICDIPTR_BASEADDR
	mvn r1, #0b11
	ldr r2, [r0, #0x34]
	and r2, r2, r1
	str r2, [r0, #0x34]

	ldr r0, =ICDICER_BASEADDR
	ldr r1, =#0x100000
	str r1, [r0, #0x04]

	@ 4b. Set Interrupt Sensitivity for ID 52
	ldr r0, =ICDICFR_BASEADDR
	mvn r1, #0b1100000000
	ldr r2, [r0, #0x0C]
	and r2, r2, r1
	mov r1, #0b0100000000
	orr r2, r2, r1
	str r2, [r0, #0x0C]

	@ 4c. Set Interrupt Priority for ID 52
	ldr r0, =ICDIPR_BASEADDR
	mvn r1, #0xFF
	ldr r2, [r0, #0x34]
	and r2, r2, r1
	mov r1, #0xA0
	orr r2, r2, r1
	str r2, [r0, #0x34]

	@ 4d. Enable Interrupts from ID 52 now that we are done modifying settings
	ldr r0, =ICDIPTR_BASEADDR
	mov r1, #0b01
	ldr r2, [r0, #0x34]
	orr r2, r2, r1
	str r2, [r0, #0x34]
	ldr r0, =ICDISER_BASEADDR
	ldr r1, =#0x100000
	str r1, [r0, #0x04]

bx lr

@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
@ disableInterrupts
@ Disable interrupts on CPU side
@
@	No parameters
@
@	No return value
@
@ Written by Koby Miller
@ Last modified: March 22nd, 2024
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
disableInterrupts:
	push {r0}
	
	mrs r0, cpsr
	orr r0, r0, #0b10000000
	msr cpsr_c, r0

	pop {r0}
bx lr

@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
@ enableInterrupts
@ Enable interrupts on CPU side
@
@	No parameters
@
@	No return value
@
@ Written by Koby Miller
@ Last modified: March 22nd, 2024
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
enableInterrupts:
	push {r0,r1}
	
	mrs r0, cpsr
	mvn r1, #0b10000000
	and r0, r0, r1
	msr cpsr_c, r0
	
	pop {r0,r1}
bx lr

@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
@ initializeGpioInterrupts
@ Setup buttons 4 and 5 as interrupts
@
@	No parameters
@
@	No return value
@
@ Written by Koby Miller
@ Last modified: March 22nd, 2024
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
initializeGpioInterrupts:
	push {r0,r1}
	
	@ disable interrupts
	ldr r0, =GPIO_BASEADDR
	ldr r1, =#0xFFFFFFFF
	str r1, [r0, #0x214]
	str r1, [r0, #0x254]
	
	@ setup interrupt sensitivity for buttons 4 and 5
	ldr r1, =#0xC0000
	str r1, [r0, #0x25C]
	str r1, [r0, #0x260]
	
	mov r1, #0
	str r1, [r0, #0x264]
	
	ldr r1, =#0xFFFFFFFF
	str r1, [r0, #0x258]
	
	ldr r1, =#0xC0000
	str r1, [r0, #0x250]
	
	pop {r0,r1}
bx lr

@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
@ irqHandler
@ Interrupt service request handler
@
@	No parameters
@
@	No return value
@
@ Written by Koby Miller
@ Last modified: March 22nd, 2024
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
irqHandler:
	push {r0,r1,r2,r3,lr}
	
	ldr r0, =ICCIAR_BASEADDR
	ldr r1, [r0]
	
	ldr r0, =GPIO_BASEADDR
	ldr r2, [r0, #0x258]
	lsr r2, r2, #18
	and r2, r2, #0b11
	
	cmp r1, #27 @ determine if ID for ID #27 (GTC Interrupt)
	beq irqHandle27
	cmp r1, #52 @ determine if ID for ID #52 (GPIO Interrupt)
	beq irqHandle52
	b leaveIrqHandler
	
	
	@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ Interrupt Handlers +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
	irqHandle27: @ when timer is up
	
		.ifdef KLIBGIC_IRQID27
		bl KLIBGIC_IRQID27
		.endif

	ldr r3, =GTC_BASEADDR
	mov r2, #1
	str r2, [r3,#0x0C]
	b leaveIrqHandler
	
	@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ ~~~~~~~~~~~~~~~~~~ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
	irqHandle52:
	cmp r2, #0b01
	beq irqButton4
	cmp r2, #0b10
	beq irqButton5
	b leaveIrqHandler
		irqButton4: @ if BTN4 is pressed +-+-+-+-+-+-+-+-+-+-+
		
			.ifdef KLIBGIC_IRQID52_BTN4
			bl KLIBGIC_IRQID52_BTN4
			.endif
			
			ldr r3, =0x40000
			str r3, [r0, #0x258]
		b leaveIrqHandler @ break +-+-+-+-+-+-+-+-+-+-+-+-+-+-+
		
		irqButton5: @ if BTN5 is pressed +-+-+-+-+-+-+-+-+-+-+
		
			.ifdef KLIBGIC_IRQID52_BTN5
			bl KLIBGIC_IRQID52_BTN5
			.endif
			
			ldr r3, =0x80000
			str r3, [r0, #0x258]
		@b leaveIrqHandler @ break +-+-+-+-+-+-+-+-+-+-+-+-+
	
	@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+ End Interrupt Handlers +-+-+-+-+-+-+-+-+-+-+-+-+-+-+
	leaveIrqHandler:
	ldr r0, =ICCEOIR_BASEADDR @ Acknowledge that interrupt has been serviced
	str r1, [r0]
	
	pop {r0,r1,r2,r3,lr}
bx lr

@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
@ EoF
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
.endif
