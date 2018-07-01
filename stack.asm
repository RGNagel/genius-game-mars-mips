.data

	.eqv STACK_SIZE 128

.text	

	.globl stack_init, stack_push, stack_pop, stack_size, stack_get_value_at_index
	
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
