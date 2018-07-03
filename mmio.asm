.data

	get_valid_int_keyboard_msg: .asciiz "\nget_valid_int_keyboard_msg: "
	newline: .asciiz "\n"

.text

	.globl enable_keyboard, disable_keyboard, get_char_keyboard, print_string_display, get_valid_int_keyboard
	
	
	enable_keyboard:
	
		# enable keyboard
		li $t2, 2
		sw $t2, 0xffff0000

		jr $ra
		
	disable_keyboard:
	
		# disable keyboard
		sw $t0, 0xffff0000
		
		jr $ra	
	get_char_keyboard:
		lb $v0, 0xffff0004
		jr $ra
		
	print_char_display:
		sb $a0, 0xffff000c
		jr $ra
	
	print_string_display:
		# a0: & string to print
		
		addiu $sp, $sp, -24
		sw $ra, 20($sp)
		sw $s0, 16($sp)
		
		move $s0, $a0

		# ENABLES: Ready bit set (1) in the Transmitter Control register
		li $t1, 1
		sw $t1, 0xffff0008

		# null terminator \0 = NUL = 0
		print_string_display_loop:
		lb $a0, 0($s0)
		beqz $a0, end_of_string
			jal print_char_display
			addiu $s0, $s0, 1
			j print_string_display_loop
		end_of_string:
		# does not print \0
		
		lw $ra, 20($sp)
		lw $s0, 16($sp)
		
		addiu $sp, $sp, 24
		
		jr $ra
	
	get_valid_int_keyboard: # needs ringbuffer struct and functions
		# a0: ring buffer pointer
		# a1: ptr to string msg input
		# returns int
		
		sw $a0, 0($sp)
		sw $a1, 4($sp)
		
		# init ring buffer
		jal initBuffer
		
		jal enable_keyboard
		

		addiu $sp, $sp, -36
		sw $ra, 16($sp)
		sw $s0, 20($sp)
		sw $s1, 24($sp)
		sw $s2, 28($sp)
		sw $s3, 32($sp)
		
		lw $s1, 36($sp) # &rb
		lw $s2, 40($sp) # &msg
		
		get_valid_int_keyboard_loop:
		
		li $s0, 0 # counter of valid char (number: 0 to 9)
		li $s3, 0 # final integer
		
		# message input
		move $a0, $s2
		jal print_string_display
		
		get_valid_int_keyboard_loop_2:
			# read buffer
			move $a0, $s1
			jal readBuffer # if readBuffer reads nothing, returns 0
			beqz $v0, get_valid_int_keyboard_loop_2
			
			# check if end of input (enter + char number preceding)
			seq $t3, $v0, 10  # enter char input
			sgt $t4, $s0, 0 # char preceding > 0
			and $t3, $t3, $t4 # it is end of input (enter + char preceding)
			bgtz $t3, main_loop_speed_msg_out
			
			# check if number input (valid)
			sge $t1, $v0, 48 # >= 0
			sle $t2, $v0, 57 # <= 9
			and $t1, $t1, $t2 # number char input, OK
			bne $t1, 1, get_valid_int_keyboard_loop # repeat question due it is invalid input
			
			# input valid:
			addiu $s0, $s0, 1 # counter of chars ++
			
			# join chars to form int
			mul $s3, $s3, 10			
			addiu $v0, $v0, -48 # ascii to decimal
			add $s3, $s3, $v0
			
			j get_valid_int_keyboard_loop_2
		main_loop_speed_msg_out:
		
		jal disable_keyboard
		
		# print final integer for debug
			li $v0, 4
			la $a0, get_valid_int_keyboard_msg
			syscall
			li $v0, 1
			move $a0, $s3
			syscall
			li $v0, 4
			la $a0, newline
			syscall

		move $v0, $s3 # return
		
		lw $ra, 16($sp)
		lw $s0, 20($sp)
		lw $s1, 24($sp)
		lw $s2, 28($sp)
		lw $s3, 32($sp)

		addiu $sp, $sp, 36
		
		# reset rb
		lw $a0, 0($sp)
		jal initBuffer
		
		jr $ra
