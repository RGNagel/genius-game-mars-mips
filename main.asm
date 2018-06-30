.data
	# cartesian plan with origin at upper left corner
	
	.eqv DISPLAY_WIDTH 128 # = display width / unit width
	.eqv DISPLAY_HEIGHT 128 # = display height / unit height

	.eqv BAR_WIDTH 32
	
	#.eqv DISPLAY_ADDR 0x10010000
	.eqv DISPLAY_ADDR 0x10040000
				
	draw_bar_jump_table: .word TOP, RIGHT, BOTTOM, LEFT
	
	speed: .space 4 # period of each beep number in ms
	num_sequence_max: .space 4 # number max of sequences to win the game
	

	keyboard_sequence: .space 32
	keyboard_sequence_index: .space 4

	.eqv WHITE 0x00ffffff
	.eqv BLACK 0x00000000
	.eqv RED 0x00ff2d00
	.eqv RED_LIGHT 0x00f9927c
	.eqv GREEN 0x003aff00
	.eqv GREEN_LIGHT 0x0099fa7c
	.eqv YELLOW 0x00ffff00
	.eqv YELLOW_LIGHT 0x00fffd7e
	.eqv BLUE_LIGHT 0x00b8c9fe
	.eqv BLUE 0x003eff
	
	menu_msg: 
		.ascii  "\n1 - iniciar o jogo\n" 
		.asciiz "2 - terminar o jogo\n"
	speed_msg: .asciiz "\ninsira a velocidade do jogo em milisegundos:\n"
	seq_msg: .asciiz "\ninsira o número de ativações:\n"
.text

	.globl main, enable_keyboard, disable_keyboard, get_char_keyboard, print_char_display, print_string_display, initBuffer, readBuffer, writeBuffer, stack_init, stack_push, stack_pop, stack_size, stack_get_value_at_index

	j main
		
	draw_game:
	
		addiu $sp, $sp, -24
		sw $ra, 20($sp)
	
		li $a0, 0
		li $a1, GREEN
		jal draw_bar
		
		li $a0, 1
		li $a1, RED
		jal draw_bar
		
		li $a0, 2
		li $a1, BLUE
		jal draw_bar
		
		li $a0, 3
		li $a1, YELLOW
		jal draw_bar
		
		lw $ra, 20($sp)
		addiu $sp, $sp, 24
		jr $ra
		

	draw_bar:
		#a0: position: 0: top, 1: right, 2: bottom, 3: right
		#a1: color
		
		sw $a0 0($sp)
		sw $a1, 4($sp)
		
		addiu $sp, $sp, -24
		sw $ra, 20($sp)
		
		# switch
		sll $a0, $a0, 2
		la $t1, draw_bar_jump_table
		add $t1, $t1, $a0
		lw $t1, 0($t1)
		jr $t1
		
		TOP:
			# point 1
			li $a0, BAR_WIDTH
			addiu $a0, $a0, 1 # avoid overlay on left
			li $a1, 0
			# point 2
			li $a2, DISPLAY_WIDTH
			addiu $a2, $a2, -BAR_WIDTH
			addiu $a2, $a2, -1 # avoid overlay on right
			li $a3, BAR_WIDTH
			addiu $a3, $a3, -1 # avoid overlay on right
			
			
			j COLOR		
		RIGHT:
			# point 1
			li $a0, DISPLAY_WIDTH
			addiu $a0, $a0, -BAR_WIDTH
			li $a1, BAR_WIDTH
			# point 2
			li $a2, DISPLAY_WIDTH
			li $a3, DISPLAY_HEIGHT
			addiu $a3, $a3, -BAR_WIDTH
			
			j COLOR
		BOTTOM:
			# point 1
			li $a0, BAR_WIDTH
			addiu $a0, $a0, 1 # avoid overlay on left
			li $a1, DISPLAY_HEIGHT
			addiu $a1, $a1, -BAR_WIDTH
			addiu $a1, $a1, 1 # avoid overlay on right
		
			# point 2
			li $a2, DISPLAY_WIDTH
			addiu $a2, $a2, -BAR_WIDTH
			addiu $a2, $a2, -1 # avoid overlay on right
			li $a3, DISPLAY_HEIGHT
			addiu $a3, $a3, -1 # avoid overlay on right
			
			j COLOR		
		LEFT:
			# point 1
			li $a0, 0
			li $a1, BAR_WIDTH
			# point 2
			li $a2, BAR_WIDTH
			li $a3, DISPLAY_HEIGHT
			sub $a3, $a3, BAR_WIDTH
		COLOR:

		lw $t1, 28($sp) # load color
		sw $t1, 16($sp) # set color for draw rectangle
		jal drawRectangle
		
		lw $ra, 20($sp)
		addiu $sp, $sp, 24
		jr $ra
	
	setPixel:
		# a0: x
		# a1: y
		# a2: color
				
		# memory address offset = (y*display_width + x)*4
		mul $t4, $a1, DISPLAY_WIDTH # y*display_width
		add $t4, $t4, $a0 # + x
		sll $t4, $t4, 2 # memory offset (x4)
		
		addi $t4, $t4, DISPLAY_ADDR # sum with memory origin
		
		sw $a2, 0($t4) # set color
		
		jr $ra
		
	drawRectangle:
		# additional arguments (more than 4) go onto stack
		# a0: x0
		# a1: y0
		# a2: x1
		# a3: y1
		# 16($sp): color
		
		sw $a0, 0($sp)
		sw $a1, 4($sp)
		sw $a2, 8($sp)
		# unnecessary to save a3, a4, color if not overwriting them here 
		
		addiu $sp, $sp, -40
		# 0($sp) a0 setPixel
		# 4($sp) a1 setPixel		
		# 8($sp) a2 setPixel
		sw $s0, 12($sp)
		sw $s1, 16($sp)
		sw $s2, 20($sp)
		sw $s3, 24($sp)
		sw $s4, 28($sp)
		sw $s5, 32($sp)
		sw $ra, 36($sp)
		
		move $s0, $a0 # x0
		move $s1, $a1 # y0
		move $s2, $a2 # x1
		move $s3, $a3 # y1
		
		move $s4, $s0 # x
		move $s5, $s1 # y
		loop_y:
		bgt $s5, $s3, loop_y_out # while y <= y1
			loop_x:
			bgt $s4, $s2, loop_x_out # while x <= x1
				move $a0, $s4 # x
				move $a1, $s5 # y
				lw $a2, 56($sp) # color
				jal setPixel
				addiu $s4, $s4, 1 # increment column
				j loop_x
			loop_x_out:
			move $s4, $s0 # reset column index
			addiu $s5, $s5, 1 # increment row
			j loop_y
		 loop_y_out:
		
		# epilogue
		lw $s0, 12($sp)
		lw $s1, 16($sp)
		lw $s2, 20($sp)
		lw $s3, 24($sp)
		lw $s4, 28($sp)
		lw $s5, 32($sp)
		lw $ra, 36($sp)
		addiu $sp, $sp, 40
		jr $ra
	
	
	# generate a number between (including) 0 and 3
	generate_number:

		li $a1, 4 # upper bound
		li $v0, 42
		syscall
		
		# $a0 hold the random int
		move $v0, $a0
		
		jr $ra
	
	
	# bright the color draft
	light:
	
		# $a0: number: 0 to 3
		

		addiu $sp, $sp, -24
		sw $ra, 16($sp)
		sw $a0, 24($sp)
		
		# looks cleaner than a switch :D
		beqz $a0, light_top
		beq $a0, 1, light_right
		beq $a0, 2, light_bottom
		beq $a0, 3, light_left
		
		light_top:	
			li $a1, GREEN_LIGHT
			jal draw_bar
			
			# we will beep here because we can delay (sync) x ms by system call 33. 
			# thus we dont need separate beep function being called in main loop
			jal beep_number
			
			# redraw default color
			lw $a0, 24($sp)
			li $a1, GREEN
			jal draw_bar
			
			j light_out	
		light_right:
			li $a1, RED_LIGHT
			jal draw_bar
			
			jal beep_number
			
			lw $a0, 24($sp)
			li $a1, RED
			jal draw_bar
			
			j light_out
		light_bottom:
			li $a1, BLUE_LIGHT
			jal draw_bar
			
			jal beep_number
			
			lw $a0, 24($sp)
			li $a1, BLUE
			jal draw_bar
			
			j light_out
		light_left:
			li $a1, YELLOW_LIGHT
			jal draw_bar
			
			jal beep_number
			
			lw $a0, 24($sp)
			li $a1, YELLOW
			jal draw_bar
			
		light_out:
		
		

		lw $ra, 16($sp)
		addiu $sp, $sp, 24
		jr $ra
	
	# noise when a number generated
	beep_number:
	
		li $v0, 33
		
		li $a0, 60 # pitch
		lw $a1, speed
		li $a2, 90 # instrument
		li $a3, 80 # volume
		syscall
		
		jr $ra
	
	# noise when played wrong (missed number)
	beep_wrong:
	
		li $v0, 33
		
		li $a0, 60 # pitch
		lw $a1, speed
		li $a2, 30 # instrument
		li $a3, 127 # volume
		syscall
		
		jr $ra
	
	# noise when played right
	beep_right:

		li $v0, 33
		
		li $a0, 60 # pitch
		lw $a1, speed
		li $a2, 60 # instrument
		li $a3, 127 # volume
		syscall
		
		jr $ra

	beep_champion:

		li $v0, 33
		
		li $a0, 120 # pitch
		lw $a1, 4000
		li $a2, 10 # instrument
		li $a3, 127 # volume
		syscall
		
		jr $ra


	# print message for the player
	message:
	
	# prompt the player
	ask:
	
	# wait period of time before continuing
	# useful for waiting sometime so the player can visualize the sorted number
	wait:
		
	main:
			
		addiu $sp, $sp, -24
		
		# do not to save $s0, $s1, ... used here
		
		start_game:
		
		la $a0, menu_msg
		jal print_string_display
		
		# while user input != (1 || 2)
		main_loop_menu_msg:
			jal readBuffer
			beq $v0, 1, main_loop_menu_msg_out # keep playing
			beq $v0, 2, main_end 		   # break
			j main_loop_menu_msg	   	   # loop
		main_loop_menu_msg_out:
		
		jal draw_game
		
		# stack used
		la $s3, stack
		move $a0, $s3
		jal stack_init
		
		# init ring buffer
		la $a0, rb
		jal initBuffer
		
		# number of sequences (max)
		la $a0, rb
		la $a1, seq_msg
		jal get_valid_int_keyboard
		sw $v0, num_sequence_max		
		
		# speed
		la $a0, rb
		la $a1, speed_msg
		jal get_valid_int_keyboard
		sw $v0, speed
		
		# starting in 3 sequences
		li $s1, 1
		
		# points
		li $s6, 0
		
		
		keep_going:
		
		# i 
		li $s2, 0
		loop_generate_sequence: beq $s2, $s1, out_loop_generate_sequence 
			
			jal generate_number
			move $s4, $v0 # temp num
			
			move $a0, $s4
			jal light
			
			move $a0, $s3 # stack ptr
			move $a1, $s4 # num generated
			jal stack_push
			beq $v0, 1, pushed_ok
				break
			pushed_ok:
			
			addiu $s2, $s2, 1
		j loop_generate_sequence
		out_loop_generate_sequence:
		
		
		li $s2, 0
		
		# player turn
		
		jal enable_keyboard

		la $a0, stack_keyboard
		jal stack_init
		
		# while player did not play all sequences in keyboard
		loop_play_sequence:
			jal stack_size
			
			bne $s1, $v0, loop_play_sequence
		
		jal disable_keyboard
		
		
		# all sequence played by player
		li $s2, 0
		check_sequence: beq $s2, $s1, check_sequence_out
			la $a0, stack_keyboard
			move $a1, $s2
			jal stack_get_value_at_index
			move $s4, $v0 # player: 0 to 3
			
			la $a0, stack
			move $a1, $s2
			jal stack_get_value_at_index
			move $s5, $v0 # generated: 0 to 3
			and $t1, $s4, $s5
			bnez $t1, correct_typed
			
			wrong_typed:
				jal beep_wrong
				li $v0, 1
				li $a0, 666
				syscall
				j start_game
				
			correct_typed:
			li $v0, 1
			li $a0, 555
			syscall
			addiu $s2, $s2, 1
			j check_sequence
		check_sequence_out:
		
		jal beep_right
		
		# add points
		addiu $s6, $s6, 1
		# increase sequence size
		addiu $s1, $s1, 1
		
		lw $t1, num_sequence_max
		beq $s1, $t1, champion
		jal keep_going
		
		champion:
			jal beep_champion

		main_end:
		addiu $sp, $sp 24
		

		break


.kdata
	_regs: .space 32
.ktext 0x80000180

	move $k0, $at # it should execute first since other inst. may change $at
	la $k1, _regs
	sw $k0, 0($k1)
	sw $v0, 4($k1)
	sw $a0, 8($k1)
	sw $a1, 12($k1)
	sw $t0, 16($k1)
	sw $t1, 20($k1)
	sw $ra, 24($k1)
	
	# check what exception occurred
	# $13 contem causa
	mfc0 $t1, $13
	sra $t1, $t1, 2
	and $t1, $t1, 0xF # exception code
	
	# if break does not handle
	bne $t1, 9, dont_exit # break exception; do not return to program
		li $v0, 17
		syscall
	dont_exit:
	# print exception code
	li $v0, 1
	move $a0, $t1
	syscall
	
	bnez $t1, not_hw_int
		# deal with hw int
		
		# when keyboard interrupts, it sets to 1 the 9th bit ($13)
		mfc0 $t0, $13
		li $t2, 0x100
		and $t2, $t2, $t0
		beqz $t2, not_keyboard_int
			
			# treat interrup. from keyboard
			
			# just save to ringbuffer and go back - we must not be long here since it is kernel

			jal get_char_keyboard
			la $a0, rb
			move $a1, $v0
			jal writeBuffer
			
			# does not go to the next instruction when back to main loop
			mfc0 $k0, $14
			addiu $k0, $k0, -4
			mtc0 $k0, $14
			
		not_keyboard_int:
			
	not_hw_int:


	la $k1, _regs
	lw $at, 0($k1)
	lw $v0, 4($k1)
	lw $a0, 8($k1)
	lw $a1, 12($k1)
	lw $t0, 16($k1)
	lw $t1, 20($k1)
	lw $ra, 24($k1)
	
	mfc0 $k0, $14
	addiu $k0, $k0, 4
	mtc0 $k0, $14
	
	eret
