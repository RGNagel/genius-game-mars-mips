.data
	
	.eqv RB_SIZE 32

	readBufferMsg: .asciiz "\nreadBuffer: "
	newline: .asciiz "\n"
			
	#rb:
	#	.space RB_SIZE # data
	#	.space 4 # rd
	#	.space 4 # wr
	#	.space 4 # size
	#
	
.text

	.globl initBuffer, readBuffer, writeBuffer
		
	initBuffer:
		# a0 pointer to ringbuffer
		addi $a0, $a0, RB_SIZE
		
		sw $t0, 0($a0) # rd = 0
		sw $t0, 4($a0) # wr = 0
		sw $t0, 8($a0) # size = 0
		
		jr $ra
				
	isBufferEmpty:
		# a0 pointer to ringbuffer
	
		li $v0, 1 # EMPTY, TRUE
	
		addiu $a0, $a0, RB_SIZE
		lw $t1, 8($a0) # size
		
		beqz $t1, isBufferEmpty_empty
			li $v0, 0 # not empty, false
		isBufferEmpty_empty:
		
		jr $ra
		
	isBufferFull:
		# a0 pointer to ringbuffer
	
		li $v0, 1 # FULL, TRUE
	
		addiu $a0, $a0, RB_SIZE
		
		lw $t1, 8($a0) # size
		
		beq $t1, RB_SIZE, isBufferFull_full
			li $v0, 0 # not full, false
		isBufferFull_full:
		
		jr $ra
		
	readBuffer:
		# a0 pointer to ringbuffer
		addiu $sp, $sp, -24
		sw $ra, 20($sp)
		sw $s0, 16($sp)
		sw $a0, 24($sp) # s0 is tmp for returned value
		
		li $s0, 0 # empty, failed
		
		jal isBufferEmpty
		
		lw $a0, 24($sp)
		
		bgtz $v0, readBufferEmpty
		
			addiu $t3, $a0, RB_SIZE # &rd
		
			# size--
			lw $t1, 8($t3) # size
			addiu $t1, $t1, -1
			sw $t1, 8($t3)

			# get byte
			lw $t2, 0($t3) # rd
			addu $t1, $a0, $t2 # ptr + rd: & byte position
			lb $s0, 0($t1) # return
			
			
			# debug: 
				li $v0, 4
				la $a0, readBufferMsg
				syscall
				li $v0, 1
				move $a0, $s0
				syscall
				li $v0, 4
				la $a0, newline
				syscall
			
			# read++
			addiu $t2, $t2, 1 # rd++
			li $t1, RB_SIZE
			div $t2, $t1
			mfhi $t1 # remainder (0 to RB_SIZE -1) 
			sw $t1, 0($t3)
			
		readBufferEmpty:
		
		move $v0, $s0
		
		lw $ra, 20($sp)
		lw $s0, 16($sp)
		
		addiu $sp, $sp, 24
		jr $ra
		
	writeBuffer:
		# a0 pointer to ringbuffer
		# $a1: byte to write	
		addiu $sp, $sp, -24
		sw $s0, 16($sp)
		sw $ra, 20($sp)
		sw $a0, 24($sp)
		sw $a1, 28($sp)
		
		li $s0, 0 # full, failed	
				
		jal isBufferFull
		
		lw $a0, 24($sp)
		lw $a1, 28($sp)

		bgtz $v0, writeBufferFull
			
			addiu $t3, $a0, RB_SIZE # &rd
			
			# size++
			lw $t1, 8($t3) # size
			addiu $t1, $t1, 1
			sw $t1, 8($t3)

			
			# set byte
			lw $t1, 4($t3) # wr
			add $t2, $a0, $t1 # ptr + wr: & byte position
			sb $a1, 0($t2)
			
			# wr++
			addiu $t1, $t1, 1
	
			li $t2, RB_SIZE
			div $t1, $t2 # wr % max size 
			mfhi $t1 # remainder: (0 to RB_SIZE -1)
			sw $t1, 4($t3)
			
			li $s0, 1 # wrote, success
			
		writeBufferFull:
		
		move $v0, $s0
		
		lw $s0, 16($sp)
		lw $ra, 20($sp)
		addiu $sp, $sp, 24
		jr $ra
