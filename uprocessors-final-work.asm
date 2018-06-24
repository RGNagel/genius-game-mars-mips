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
	
	.eqv STACK_SIZE 128
	stack: 
		.space STACK_SIZE # data
		.space 4 # top
	

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


.text
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
		li $a3, 127 # volume
		syscall
		
		jr $ra
	
	# noise when played wrong (missed number)
	beep_wrong:
	
	# noise when played right
	beep_right:
	
	# print message for the player
	message:
	
	# prompt the player
	ask:
	
	# wait period of time before continuing
	# useful for waiting sometime so the player can visualize the sorted number
	wait:
	
	# stack functions
	
	stack_init:
		# a0: pointer to stack (la)
		sw $t0, STACK_SIZE($a0) # top = 0
		jr $ra
	stack_push:
		# a0: ptr
		# a1: value
		lw $t1, STACK_SIZE($a0) # top, index
		
		sll $t2, $t1, 2 # x4
		addu $t2, $t2, $a0
		sw $a1, 0($t2)
		
		addiu $t1, $t1, 1 # top++
		sw $t1, STACK_SIZE($a0)
		
		li $v0, 1 # success
		jr $ra
	stack_pop:
		lw $t1, STACK_SIZE($a0) # top, index
		li $v0, 0
		beqz $t1, pop_empty
			sll $t2, $t1, 2 # x4
			addu $t2, $t2, $a0
			lw $v0, -4($t2)
			addiu $t1, $t1, -1 # top--
			sw $t1, STACK_SIZE($a0)
		pop_empty:
		jr $ra
	stack_size:
		lw $v0, STACK_SIZE($a0)
		jr $ra
	stack_get_value_at_index:
		# a0: pointer to stack (la)
		# $a1 = index of array (0 to STACK_SIZE / 4)
		sll $a1, $a1, 2 # x4
		addu $a1, $a1, $a0
		lw $v0, 0($a1)

		jr $ra
	main:
			
		addiu $sp, $sp, -24
		
		# do not to save $s0, $s1, ... used here
		
		
		jal draw_game
		
		# stack used
		la $s3, stack
		move $a0, $s3
		jal stack_init
		
		# number of sequences (max)
		li $t1, 10
		sw $t1, num_sequence_max
		
		# speed
		li $t1, 1000
		sw $t1, speed
		
		# starting in 3 sequences
		li $s1, 3
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
		
		
		# check stack
			check_stack: beq $s2, $s1, check_stack_out
			move $a0, $s3
			move $a1, $s2 # index of arr
			jal stack_get_value_at_index
			move $a0, $v0
			li $v0, 1
			syscall
			addiu $s2, $s2, 1
			j check_stack
		check_stack_out:
		# end checking
		
		# player turn
		
		
		li $s2, 0
		loop_play_sequence: beq $s2, $s1, out_loop_play_sequence
			
			# ...
			addiu $s2, $s2, 1
			j loop_play_sequence
			
		out_loop_play_sequence:
		

		addiu $sp, $sp 24
		
		break

