.data

	# RING BUFFER
	.eqv RB_SIZE 64
	rb:
		.space RB_SIZE # data
		.space 4 # rd
		.space 4 # wr
		.space 4 # size

		#rb:
	#	.space RB_SIZE # data
	#	.space 4 # rd
	#	.space 4 # wr
	#	.space 4 # size
	#
	
.text

	#.globl initBuffer, readBuffer, writeBuffer
		
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
	
		addi $a0, $a0, RB_SIZE
		
		lw $t1, 8($a0) # size
		
		beqz $t1, isBufferEmpty_empty
			li $v0, 0 # not empty, false
		isBufferEmpty_empty:
		
		jr $ra
		
	isBufferFull:
		# a0 pointer to ringbuffer
	
		li $v0, 1 # FULL, TRUE
	
		addi $a0, $a0, RB_SIZE
		
		lw $t1, 8($a0) # size
		
		beq $t1, RB_SIZE, isBufferFull_full
			li $v0, 0 # not full, false
		isBufferFull_full:
		
		jr $ra
		
	readBuffer:
		# a0 pointer to ringbuffer
		addiu $sp, $sp, -24
		sw $ra, 16($sp)
		sw $a0, 24($sp)
		
		li $v0, 0 # empty, failed
		
		jal isBufferEmpty
		
		lw $a0, 24($sp)
		
		bgt $v0, 0, readBufferEmpty
		
			addi $t3, $a0, RB_SIZE # &rd
		
			# size--
			lw $t1, 8($t3) # size
			addiu $t1, $t1, -1
			sw $t1, 8($t3)

			# get byte
			lw $t2, 0($t3) # rd
			add $t1, $a0, $t3 # ptr + rd: & byte position
			lb $v0, 0($t1) # return
			
			# read++
			addiu $t2, $t2, 1 # rd++
			li $t1, RB_SIZE
			div $t2, $t1
			mfhi $t1 # remainder (0 to RB_SIZE -1) 
			sw $t1, 0($t3)
			
		readBufferEmpty:
		
		lw $ra, 16($sp)
		addiu $sp, $sp, 24
		jr $ra
		
	writeBuffer:
		# a0 pointer to ringbuffer
		# $a1: byte to write	
		addiu $sp, $sp, -24
		sw $ra, 16($sp)
		sw $a0, 24($sp)
		sw $a1, 28($sp)
		
		li $v0, 0 # full, failed	
				
		#la $t1, isBufferFull
		#jalr $t1	
		jal isBufferFull
		
		lw $a0, 24($sp)
		lw $a1, 28($sp)
		
		bgt $v0, 0, writeBufferFull
			
			addi $t3, $a0, RB_SIZE # &rd
			
			# size++
			lw $t1, 8($t3) # size
			addiu $t1, $t1, 1
			sw $t1, 8($t3)

			
			# set byte
			lw $t1, 4($t3) # wr
			add $t2, $a0, $t1 # ptr + wr: & byte position
			sb $a1, 0($t2)
			
			# write++
			addiu $t1, $t1, 1
	
			div $t1, $t2
			mfhi $t1 # remainder (0 to RB_SIZE -1)
			sw $t1, 4($t3)
			
			#li $v0, 1 # wrote, success
			
		writeBufferFull:
		
		lw $ra, 16($sp)
		addiu $sp, $sp, 24
		jr $ra
