.macro print_str (%str)
	.data
		print_str_label: .asciiz %str
	.text
		li $v0, 4
		la $a0, print_str_label
		syscall
.end_macro

.macro print_int (%x)
	li $v0, 1
	add $a0, $zero, %x
	syscall
.end_macro

.data

	speed: .space 4 # period of each beep number in ms
	num_sequence_max: .space 4 # number max of sequences to win the game
	
	keyboard_sequence: .space 32
	keyboard_sequence_index: .space 4
	
	menu_msg: 
		.ascii  "\n1 - iniciar o jogo" 
		.asciiz "\n2 - terminar o jogo\n"
	speed_msg: .asciiz "\nvelocidade do jogo (ms): "
	seq_msg: .asciiz "\ninsira o numero de ativacoes: "
	player_turn_msg: .asciiz "\nSua vez de jogar: "
	champion_msg: .asciiz "\nParabens! Voce foi campeao."
	correct_msg: .asciiz "\nSequencia correta."
	wrong_msg: .asciiz "\nSequencia errada."
	wrong_typed_msg: .asciiz "\nTecla invalida. De novo (w,d,s,a):"
	
	# STACK
	.eqv STACK_SIZE 128
	.align 2
	stack: 
		.space STACK_SIZE # data
		.space 4 # top
		
	.align 2
	stack_keyboard:
		.space STACK_SIZE # data
		.space 4 # top

	# RING BUFFER
	.eqv RB_SIZE 32
	.align 2
	rb:
		.space RB_SIZE # data
		.space 4 # rd
		.space 4 # wr
		.space 4 # size
	

	
.text
	.globl main, beep_number

	main:
			
		addiu $sp, $sp, -24
		
		# do not to save $s0, $s1, ... used here
		
		start_game:
		
		la $a0, menu_msg
		jal print_string_display

		# init ring buffer
		la $a0, rb
		jal initBuffer
		
		# while user input != ('1' || '2')
		jal enable_keyboard
		main_loop_menu_msg:
			la $a0, rb
			jal readBuffer
			beq $v0, 49, main_loop_menu_msg_out # typed '1': keep playing
			beq $v0, 50, main_end 		   # typed '2': break
			j main_loop_menu_msg	   	   # loop
		main_loop_menu_msg_out:
		
		jal disable_keyboard
		
		jal draw_game 
	
		# get_valid_int_keyboard enables keyboard within it
		# get_valid_int_keyboard prepares ringbuffer
		
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
					
		# starting in 1 sequences
		li $s1, 1
		
		# points
		li $s6, 0
			
		print_str("\nSequence number: ")
		print_int($s1)
		print_str("\nPoints: ")
		print_int($s6)

		# prepare stacks
		# stack sequence is prapared only first time since sequence continuous from previous one
		la $a0, stack
		jal stack_init

		keep_going:
		
		# before generating, iterate through stack to light previous generated values in stack
		la $a0, stack
		jal stack_size
		# $s2, $s4 can be used for temp here
		move $s2, $v0 # temp
		li $s4, 0 # i = 0
		beqz $v0, iterate_through_previous_stack_out
			print_str("\nprevious generated: ")
			iterate_through_previous_stack:
				la $a0, stack
				move $a1, $s4
				jal stack_get_value_at_index
				move $a0, $v0
				jal light
				addiu $s4, $s4, 1 # i++
				bne $s4, $s2, iterate_through_previous_stack # else it iterated all previous values 
		iterate_through_previous_stack_out:
		
		# now generate new values
		jal generate_seed # seed for pseudo-random values
		loop_generate_sequence:
		print_str("\ngenerated: ")
		la $a0, stack
		jal stack_size
		beq $s1, $v0, out_loop_generate_sequence # $s1 = current sequence position
			jal generate_number
			move $s4, $v0 # temp num
			
			print_int($s4)
			print_str(" ")
			
			move $a0, $s4
			jal light
			
			la $a0, stack
			move $a1, $s4 # num generated
			jal stack_push
			beq $v0, 1, loop_generate_sequence
			break # if push failed
		out_loop_generate_sequence:
		print_str("\n")
		
		li $s2, 0 # i
		
		## player turn ##
		
		# prepare rb
		la $a0, rb
		jal initBuffer
		# prepare stack
		la $a0, stack_keyboard
		jal stack_init
		
		jal enable_keyboard
		# while player did not play all sequences in keyboard
		
		la $a0, player_turn_msg
		jal print_string_display
		
		loop_play_sequence:
			la $a0, rb
			jal readBuffer # if 0 it is empty
			beqz $v0, loop_play_sequence
			
			# player played
			
			# convert a,w,d,s -> 0,1,2,3 OR invalid			
				
			beq $v0, 119, loop_play_sequence_w
			beq $v0, 100, loop_play_sequence_d
			beq $v0, 115, loop_play_sequence_s
			beq $v0, 97, loop_play_sequence_a
			
			# played invalid
			la $a0, wrong_typed_msg
			jal print_string_display
			print_str("\ninvalid typed")
			j loop_play_sequence
			
			loop_play_sequence_w:
				li $a0, 0
				jal light
				li $t1, 0
				j loop_play_sequence_out
			loop_play_sequence_d:
				li $a0, 1
				jal light
				li $t1, 1
				j loop_play_sequence_out
			loop_play_sequence_s:
				li $a0, 2
				jal light
				li $t1, 2
				j loop_play_sequence_out
			loop_play_sequence_a:
				li $a0, 3
				jal light
				li $t1, 3
			loop_play_sequence_out:
			
			#print_str("player played: ")
			#print_int($t1)
			#print_str("\n")

			la $a0, stack_keyboard
			move $a1, $t1
			jal stack_push

			la $a0, stack_keyboard	
			jal stack_size
			bne $s1, $v0, loop_play_sequence # $s1 = current sequence number
		jal disable_keyboard
		
		## check sequence played ##
		
		# all sequence played by player
		li $s2, 0 # i
		print_str("\nChecking sequence:")
		check_sequence: beq $s2, $s1, check_sequence_out # $s1 = current sequence length (start at 3)
			la $a0, stack_keyboard
			move $a1, $s2 # i
			jal stack_get_value_at_index
			move $s4, $v0 # player: 0 to 3
			
			la $a0, stack
			move $a1, $s2 # I
			jal stack_get_value_at_index
			move $s5, $v0 # generated: 0 to 3
			
			beq $s4, $s5, correct_typed # played = generated?
			wrong_typed:
				print_str("\nwrong typed.")
				la $a0, wrong_msg
				jal print_string_display
				jal beep_wrong
				j start_game		
			correct_typed:
				print_str("\ncorrect typed")
			addiu $s2, $s2, 1
			j check_sequence
		check_sequence_out:
		la $a0, correct_msg
		jal print_string_display
		print_str("\nSequence right!")
		jal beep_right
		
		# add points
		addiu $s6, $s6, 1
		# increase sequence size
		addiu $s1, $s1, 1
		
		lw $t1, num_sequence_max
		addiu $t1, $t1, 1
		beq $s1, $t1, champion
		jal keep_going
		
		champion:
			print_str("\nchampion!!!")
			la $a0, champion_msg
			jal print_string_display
			jal beep_champion
			jal start_game
		main_end:
		addiu $sp, $sp 24
		
		break


	# generate a number between (including) 0 and 3
	
	generate_seed:
	
		li $v0, 30 # System Time syscall
		syscall                  # $a0 will contain the 32 LS bits of the system time
		move $t1, $a0
		
		li $v0, 40 # random seed
		li $a0, 1 # id
		move $a1, $t1
		syscall
	
		jr $ra
	
	generate_number:
	
		li $a0, 1 # same id in generate_seed
		li $a1, 4 # upper bound
		li $v0, 42
		syscall
		# $a0 hold the random int

		move $v0, $a0
		
		jr $ra
	
	# noise when a number generated
	beep_number:
	
		li $v0, 33
		
		li $a0, 60 # pitch
		lw $a1, speed
		li $a2, 32 # instrument
		li $a3, 105 # volume
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
		lw $a1, 5000
		li $a2, 10 # instrument
		li $a3, 127 # volume
		syscall
		
		jr $ra

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
	# $13 has cause
	mfc0 $t1, $13
	sra $t1, $t1, 2
	and $t1, $t1, 0xF # exception code
	
	# if break does not handle
	bne $t1, 9, dont_exit # break exception; do not return to program
		li $v0, 17
		syscall
	dont_exit:
	
	# print exception code
	#print_str("\nexception: ")
	print_int($t1)
	#print_str("\n")
	
	bnez $t1, not_hw_int
		# deal with hw int
		
		# when keyboard interrupts, it sets to 1 the 9th bit ($13)
		mfc0 $t0, $13
		li $t2, 0x100
		and $t2, $t2, $t0
		beqz $t2, not_keyboard_int
			
			# treat interrup. from keyboard
			
			# just save to ringbuffer and go back - we must not be long here since it is kernel
			
			la $t1, get_char_keyboard
			jalr $t1
			
			la $a0, rb
			move $a1, $v0
			la $t1, writeBuffer
			jalr $t1
			
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
