
/* 	r2: data to write and data read from JTAG
	r3: used in WRITE_BYTE, READ_BYTE
	r7: JTAG base address
	r8: z component storage
*/
.equ JTAG_UART, 0xFF211020
.equ GOOD_SPEED, 0x2d			/* 45, Try to always keep GOOD_SPEED, subject to change*/
.equ STRAIGHT, 0x0
.equ LEFT, 0b10110000
.equ RIGHT, 0b01010000
.equ HARD_LEFT, 0b10000001
.equ HARD_RIGHT, 0b01111111

.global	_start

_start:
ldr 	r7, =JTAG_UART	/* r7 has JTAG base address */
bl 		READ_POSN_Z
mov 	r8, r2 			/* r8 has starting z coord */

main:
STEER_CTRL:
bl		READ_SENSOR
mov		r5, r2					/* r5 has value of sensors */

STRAIGHT_COND:
ldr		r6, =0b00011111
cmp 	r5, r6
bne		RIGHT_COND
ldr		r2, =STRAIGHT
bl  	SET_STEER
b 		SPEED_CTRL
RIGHT_COND:
ldr		r6, =0b00011110
cmp 	r5, r6
bne 	HARD_RIGHT_COND
ldr		r2, =RIGHT
bl  	SET_STEER
//ldr		r2, =0x0 		 		/* set zero accel*/
//bl 		SET_ACCEL	
b 		SPEED_CTRL
HARD_RIGHT_COND:
ldr		r6, =0b00011100
cmp 	r5, r6
bne		LEFT_COND
ldr		r2, =HARD_RIGHT
bl  	SET_STEER
ldr		r2, =0b10000000 		 		/* quickly decel -128*/
bl 		SET_ACCEL	
b 		SPEED_CTRL
LEFT_COND:
ldr		r6, =0b00001111
cmp 	r5, r6
bne		HARD_LEFT_COND
ldr		r2, =LEFT
bl  	SET_STEER
//ldr		r2, =0x0 		 		/* set zero accel*/
//bl 		SET_ACCEL
b 		SPEED_CTRL
HARD_LEFT_COND:
ldr		r6, =0b00000111
cmp 	r5, r6
ldr		r2, =HARD_LEFT
bne		SPEED_CTRL
bl  	SET_STEER
ldr		r2, =0b10000000 				/* quickly decel -128*/
bl 		SET_ACCEL
b 		SPEED_CTRL

SPEED_CTRL:
bl		READ_SPEED
ldr 	r5, =GOOD_SPEED
subs	r5, r5, r2			/* compare current speed with GOOD_SPEED */	
beq		SPEED_CTRL_END			/* speed = GOOD_SPEED */
ldr 	r2, =0x0c  				
mul 	r2, r5, r2 				/* multiply speed diff by 11 */ 
ldr 	r9, =0x0a				/* 0x0a = 10 dec */
ldr 	r10, =0x80
ands	r10, r5, r10
bne		TOO_FAST
cmp 	r5, r9					/* if GOOD_SPEED > 10 over current speed */
ldrgt 	r2, =0x78				/* 64 hex = 120 dec */
b 		ACCEL_COND
TOO_FAST:
ldr 	r10, =0xFF
eor		r5, r5, r10
ldr 	r10, =0x1
add 	r5, r5, r10
cmp 	r5, r9 					/* if GOOD_SPEED < -10 below current speed */
ldrgt 	r2, =0x88				/* 88 hex = -120 dec */
ACCEL_COND:
bl		SET_ACCEL				/* accel = 12*(GOOD_SPEED - speed) if current speed within +-10 GOOD_SPEED, accel = +-100 otherwise*/
/* TRY TO MAKE ACCELERATION MORE WHEN THE CAR IS NOT AT TARGET VELOCITY */
/* MAKE ACCEL PRETTY MUCH MAX WHEN CAR IS ~20 SPEED AWAY, FOR EXAMPLE */
b 		SPEED_CTRL_HILL
SPEED_CTRL_END:					/* if speed is GOOD_SPEED, set accel to 0 */
ldr 	r2, =0x0
bl		SET_ACCEL
SPEED_CTRL_HILL:
bl 		READ_POSN_Z
cmp 	r2, r8
beq 	main
mov 	r8, r2
ldrgt 	r2, =0b01111111 		/* if going up, max accel */
ldrlt 	r2, =0b10000000 		/* if going down, max decel */
bl 		SET_ACCEL
/* INSERT A SHOR TIMER OVER HERE (TRY QUARTER SECOND) */
b  		main


READ_SENSOR:					/* r2 gets sensor readings */
push 	{LR}
ldr		r2, =0x02
bl		WRITE_BYTE				/* request sensor/speed data */
READ_SENSOR_POLL:
bl		READ_BYTE
ldr 	r4 , =0x00
cmp		r2, r4
bne		READ_SENSOR_POLL				/* if packet is not sensor and speed data */
bl		READ_BYTE				/* get sensor data */
push	{r2}
bl		READ_BYTE				/* "burn" speed data */
pop 	{r2}
pop		{PC}

READ_SPEED:						/* r2 gets speed reading */
push 	{LR}
ldr		r2, =0x02
bl		WRITE_BYTE				/* request sensor/speed data */
READ_SPEED_POLL:
bl		READ_BYTE
ldr 	r4 , =0x00				/* check if sensor/speed data */
cmp		r2, r4
bne		READ_SPEED_POLL				/* if packet is not sensor and speed data */
bl		READ_BYTE				/* "burn" sensor data */
bl		READ_BYTE				/*get speed data */
pop		{PC}

SET_STEER:						/* set steering to value in r2 */
push 	{r2, LR}
ldr 	r2, =0x05
bl		WRITE_BYTE
pop		{r2}
bl		WRITE_BYTE
pop		{PC}

SET_ACCEL:						/* set accel to value in r2 */
push 	{r2, LR}
ldr		r2, =0x04
bl		WRITE_BYTE
pop		{r2}
bl		WRITE_BYTE
pop		{PC}

READ_POSN_Z: 					/* r2 gets z position */
push 	{LR}
ldr 	r2, =0x03
bl 		WRITE_BYTE				/*request posn data */
READ_POSN_Z_POLL:
bl 		READ_BYTE
ldr		r4, =0x01				
cmp 	r2, r4					/* check if posn data */
bne 	READ_POSN_Z_POLL		/* if packet is not posn data */
bl 		READ_BYTE				/* "burn" x coord data */
bl 		READ_BYTE				/* "burn" y coord data */
bl 		READ_BYTE 				/*get z coord data */
pop 	{PC}

WRITE_BYTE:				/* r3 gets control register */
ldr		r3, [r7, #4] 	/* Load from the JTAG */
lsrs	r3, r3, #16 	/* Check only the write available bits */
beq		WRITE_BYTE 		/* If this is 0, data cannot be sent */
str		r2, [r7] 		/* Write r2 to data register */
mov		PC, LR

READ_BYTE:
ldr 	r3, [r7] 		/* Load from the JTAG */
ands 	r2, r3, #0x8000 /* Mask other bits */
beq 	READ_BYTE 		/* If this is 0, data is not valid */
and 	r2, r3, #0x00FF /* Data read is now in r2 */
mov		PC, LR
