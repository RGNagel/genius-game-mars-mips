.text

	#.globl enable_keyboard, disable_keyboard, get_char_keyboard, print_char_display, print_string_display
	
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
		lw $v0, 0xffff0004
		jr $ra
		
	print_char_display:
		sb $a0, 0xffff000c
		jr $ra
	
	print_string_display:
		# a0: & string to print
		
		lb $a0, 0($a0)
		
		# null terminator \0 = NUL = 0
		
		beqz $a0, end_of_string
			jal print_char_display
		end_of_string:
		# does not print \0
		
		jr $ra
	
	get_valid_int_keyboard: # needs ringbuffer struct and functions
		# a0: ring buffer pointer
		# a1: ptr to string msg input
		# returns int
		
		# init ring buffer
		jal initBuffer
		
		sw $a0, 0($sp)
		sw $a1, 4($sp)
		addiu $sp, $sp, -36
		sw $ra, 16($sp)
		sw $s0, 20($sp)
		sw $s1, 24($sp)
		sw $s2, 28($sp)
		sw $s3, 32($sp)
		
		move $s1, $a0 # &rb
		move $s2, $a1 # &msg
		
		get_valid_int_keyboard_loop:
		
		li $s0, 0 # counter of valid char (number: 0 to 9)
		li $s3, 0 # final integer
		
		# message input
		move $a0, $s2
		jal print_string_display
		
		get_valid_int_keyboard_loop_2:
			# read buffer
			move $a0, $s1
			jal readBuffer
			# if readBuffer reads nothing, returns 0
			beqz $v0, get_valid_int_keyboard_loop_2
			
			# check if end of input (enter + char number preceding)
			seq $t3, $v0, 13  # enter char input
			and $t3, $t3, $s0 # it is end of input (enter + char preceding)
			bgtz $t3, main_loop_speed_msg_out
			
			# check if number input (valid)
			sge $t1, $v0, 48
			sle $t2, $v0, 57
			and $t1, $t1, $t2 # number char input, OK
			bne $t1, 1, get_valid_int_keyboard_loop # repeat question due it is invalid input
			
			# input valid:
			addiu $s0, $s0, 1 # counter of chars ++
			
			# join chars to form int
			mul $s3, $s3, 10
			add $s3, $s3, $v0
			
			j get_valid_int_keyboard_loop_2
		main_loop_speed_msg_out:
		
		move $v0, $s3
		
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
