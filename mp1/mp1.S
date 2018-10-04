
# mp1.S - missile-command version
# Good luck, and have fun!

.data
	
    # Constants for accessing the fields of a struct missile, 
    # struct missile is defined in rtc.h and mp1.h

	NEXT 	  = 0
	X	  = 4
	Y	  = 8
	VX	  = 12
	VY	  = 16
	DEST_X	  = 20
	DEST_Y	  = 24
	EXPLODED  = 28
	C	  = 32

    # Character to draw for an explosion - '@'

	EXPLOSION = 64
	SIGNCONSTANT = 65535		#CONSTANT USED IN movecrosshair function
	FIRSTBASE = 3876			#CONSTANT USED TO LOCATE THE FIRST BASE
	SECONDBASE = 3916			#CONSTANT USED IN LOCATE THE SECOND BASE
	THIRDBASE = 3956			#CONSTANT USED IN LOCATE THE THIRD BASE
	DRAWx = 120					#CONSTANT USED TO DRAW 'x'
	DRAWSLASH = 47				#CONSTANT USED TO DRAW '/'
	DRAWCARET = 94				#CONSTANT USED TO DRAW '^'
	DRAWBACKSLASH = 92			#CONSTANT USED TO DRAW '\'
	DRAWCROSSHAIR = 90			#CONSTANT USED TO DRAW 'Z'
	ROWFACTOR = 160				#characters need to multiply when calculating offsets
	DRAWSPACE = 32				#CONSTANT USED TO DRAW ' '
	MISSILESIZE = 36			#CONSTANT OF MISSILE STRUCT SIZE
	SHIFTCONSTANT = 16			#CONSTANT FOR SHIFT AND GET HALF SIZE OF 32 BITS
# Data shared between this file and rtc.c helper functions

# This '.globl' directive makes these symbols visible externally
.globl mp1_missile_list, base_alive, mp1_score

mp1_missile_list:	.long 0x0	# Head of list pointer
base_alive:		.long 0x0	# Array of 3 bytes, plus a padding byte
mp1_score:		.long 0x0	# Player's current score
NEWADDRESS:     .long 0x0
STOREAD:	.long 0x20
# Data private to this  file

base_pic:     	    .string "/^^^\\"	# Picture of a live base
dead_base_pic: 	    .string "xxxxx"	# Picture of a dead base
crosshairs_x:		.long 0x0	# X-position of the crosshairs
crosshairs_y:		.long 0x0	# Y-position of the crosshairs

.text

# void mp1_poke(void);
# You can use this function to write to video memory.
#
# Interface: Register-based arguments (not C-style)
#    Inputs: %cl  - The byte you wish to write
#            %eax - Offset from the start of video memory that you wish
#                   to write to
#   Outputs: Text-mode video screen is written to at location %eax with
#            the byte in %cl
# Registers: Clobbers EDX

.globl mp1_poke
mp1_poke:
		pushl %edx
		movl    vmem_base_addr(,1),%edx
		movb    %cl,(%edx,%eax,1)
		popl %edx
		ret

#   ----------------- Exported functions ---------------------

# void mp1_rtc_tasklet(unsigned long garbage);
# Performs three tasks:
#	(1) updates the list of missiles (implement this in update_missiles,
#           below, and call it from here).
#	(2) Redraw the bases - they may have been overwritten with missiles
#	(3) Redraw the crosshairs - it may have been overwritten with missiles
# Inputs   : none
# Outputs  : none
# Registers: Standard C calling convention

.globl mp1_rtc_tasklet
mp1_rtc_tasklet:
		PUSHL %EBP
		MOVL %ESP, %EBP			#setup the stack
#update_missile();
#input: none
#output: none
# This function update the real-time location of missiles after
# each RTC. And erase the missiles if they have finished exploded
# or move out of the screen bound.
# Registers: Standard C calling convention
		PUSHL %EAX
		PUSHL %ECX
		PUSHL %EDX				#caller save 3 registers
		CALL update_missiles
		POPL %EDX
		POPL %ECX
		POPL %EAX				#caller teardown 3 registers
#redraw_city();
#input: none
#output: none
# This function update the real-time situation of three bases.
# and redraw them according to their current situation.
# Registers: Standard C calling convention
		PUSHL %EAX
		PUSHL %ECX
		PUSHL %EDX				#caller save 3 registers
		CALL redraw_city
		POPL %EDX
		POPL %ECX
		POPL %EAX				#caller teardown 3 registers
#redraw_crosshair();
#input: none
#output: none
# This function update the real-time situation of crosshair.
# and redraw it according to their current location.
# Registers: Standard C calling convention
		PUSHL %EAX
		PUSHL %ECX
		PUSHL %EDX				#caller teardown 3 registers
		CALL redraw_crosshair
		POPL %EDX
		POPL %ECX
		POPL %EAX				#caller teardown 3 registers
		leave
		ret
		
.globl redraw_city								#####
redraw_city:
		PUSHL %EBP
		MOVL %ESP, %EBP			#setup the stack
		PUSHL %EBX
		PUSHL %ESI
		PUSHL %EDI				#callee save 3 registers
		MOVB base_alive, %DL
		CMPB $0, %DL
		je FDEAD				#check if first city still alive
		MOVL $FIRSTBASE, %EAX
		MOVB $DRAWSLASH, %CL	#draw '/' for first char
		CALL mp1_poke
		MOVL $FIRSTBASE + 2, %EAX
		MOVB $DRAWCARET, %CL	#draw '^' for first char
		CALL mp1_poke
		MOVL $FIRSTBASE + 4, %EAX
		MOVB $DRAWCARET, %CL	#draw '^' for first char
		CALL mp1_poke
		MOVL $FIRSTBASE + 6, %EAX
		MOVB $DRAWCARET, %CL	#draw '^' for first char
		CALL mp1_poke
		MOVL $FIRSTBASE + 8, %EAX
		MOVB $DRAWBACKSLASH, %CL	#draw '\' for first char
		CALL mp1_poke
		
SECOND:	
		MOVB base_alive+1, %DL
		CMPB $0, %DL	
		je SDEAD				#check if second city still alive
		MOVL $SECONDBASE, %EAX
		MOVB $DRAWSLASH, %CL	#draw '/' for first char
		CALL mp1_poke
		MOVL $SECONDBASE + 2, %EAX
		MOVB $DRAWCARET, %CL	#draw '^' for first char
		CALL mp1_poke
		MOVL $SECONDBASE + 4, %EAX
		MOVB $DRAWCARET, %CL	#draw '^' for first char
		CALL mp1_poke
		MOVL $SECONDBASE + 6, %EAX
		MOVB $DRAWCARET, %CL	#draw '^' for first char
		CALL mp1_poke
		MOVL $SECONDBASE + 8, %EAX
		MOVB $DRAWBACKSLASH, %CL	#draw '\' for first char
		CALL mp1_poke

THIRD:
		MOVB base_alive+2, %DL
		CMPB $0, %DL
		je TDEAD				#check if third city still alive
		MOVL $THIRDBASE, %EAX
		MOVB $DRAWSLASH, %CL	#draw '/' for first char
		CALL mp1_poke
		MOVL $THIRDBASE + 2, %EAX
		MOVB $DRAWCARET, %CL	#draw '^' for first char
		CALL mp1_poke
		MOVL $THIRDBASE + 4, %EAX
		MOVB $DRAWCARET, %CL	#draw '^' for first char
		CALL mp1_poke
		MOVL $THIRDBASE + 6, %EAX
		MOVB $DRAWCARET, %CL	#draw '^' for first char
		CALL mp1_poke
		MOVL $THIRDBASE + 8, %EAX
		MOVB $DRAWBACKSLASH, %CL	#draw '\' for first char
		CALL mp1_poke
		POPL %EDI
		POPL %ESI
		POPL %EBX
		leave
		ret						
FDEAD:
		MOVL $FIRSTBASE, %EAX
		MOVB $DRAWx, %CL			#draw 'x' for first char
		CALL mp1_poke
		MOVL $FIRSTBASE + 2, %EAX
		MOVB $DRAWx, %CL			#draw 'x' for first char
		CALL mp1_poke
		MOVL $FIRSTBASE + 4, %EAX
		MOVB $DRAWx, %CL			#draw 'x' for first char
		CALL mp1_poke
		MOVL $FIRSTBASE + 6, %EAX
		MOVB $DRAWx, %CL			#draw 'x' for first char
		CALL mp1_poke
		MOVL $FIRSTBASE + 8, %EAX
		MOVB $DRAWx, %CL			#draw 'x' for first char
		CALL mp1_poke
		JMP SECOND
SDEAD:
		MOVL $SECONDBASE, %EAX
		MOVB $DRAWx, %CL			#draw 'x' for first char
		CALL mp1_poke
		MOVL $SECONDBASE + 2, %EAX
		MOVB $DRAWx, %CL			#draw 'x' for first char
		CALL mp1_poke
		MOVL $SECONDBASE + 4, %EAX
		MOVB $DRAWx, %CL			#draw 'x' for first char
		CALL mp1_poke
		MOVL $SECONDBASE + 6, %EAX
		MOVB $DRAWx, %CL			#draw 'x' for first char
		CALL mp1_poke
		MOVL $SECONDBASE + 8, %EAX
		MOVB $DRAWx, %CL			#draw 'x' for first char
		CALL mp1_poke
		JMP THIRD
		
TDEAD:
		MOVL $THIRDBASE, %EAX
		MOVB $DRAWx, %CL			#draw 'x' for first char
		CALL mp1_poke
		MOVL $THIRDBASE + 2, %EAX
		MOVB $DRAWx, %CL			#draw 'x' for first char
		CALL mp1_poke
		MOVL $THIRDBASE + 4, %EAX
		MOVB $DRAWx, %CL			#draw 'x' for first char
		CALL mp1_poke
		MOVL $THIRDBASE + 6, %EAX
		MOVB $DRAWx, %CL			#draw 'x' for first char
		CALL mp1_poke
		MOVL $THIRDBASE + 8, %EAX
		MOVB $DRAWx, %CL			#draw 'x' for first char
		CALL mp1_poke
		POPL %EDI
		POPL %ESI
		POPL %EBX					#callee tear down 3 registers
		leave
		ret					
		
.globl redraw_crosshair							
redraw_crosshair:
		PUSHL %EBP
		MOVL %ESP, %EBP						#setup the stack
		PUSHL %EBX
		PUSHL %ESI
		PUSHL %EDI							#callee save
		MOVL crosshairs_x, %EBX				#load crosshair value to EDX and EAX
		MOVL crosshairs_y, %EAX
		IMUL $ROWFACTOR, %EAX
		IMUL $2, %EBX
		ADDL %EBX, %EAX
		MOVB $DRAWCROSSHAIR, %CL
		CALL mp1_poke						#draw new crosshair
		POPL %EDI
		POPL %ESI
		POPL %EBX							#callee teardown
		leave	
		ret										
.globl clear_crosshair
clear_crosshair:
		PUSHL %EBP
		MOVL %ESP, %EBP						#setup the stack
		PUSHL %EBX
		PUSHL %ESI
		PUSHL %EDI							#callee save
		MOVL crosshairs_x, %EBX
		MOVL crosshairs_y, %EAX
		IMUL $ROWFACTOR, %EAX
		IMUL $2, %EBX
		ADDL %EBX, %EAX
		MOVB $DRAWSPACE, %CL
		CALL mp1_poke						#clear current crosshair
		POPL %EDI
		POPL %ESI
		POPL %EBX							#callee teardown
		leave
		ret										

# int mp1_ioctl(unsigned long arg, unsigned int cmd)
# The dispatch function for the MP1 ioctls - should use the cmd argument
# and a jumptable to execute one of the specific ioctls implemented below.
# Inputs   : unsigned long arg - parameter to the mp1_ioctl_....
#          : unsigned int cmd  - specifies which mp1_ioctl_... function 
#          :                     to execute
# Outputs  : Returns an integer - depends on which ioctl() function is called
# Registers: Standard C calling convention

.globl mp1_ioctl
mp1_ioctl:
		MOVL 4(%ESP), %EDX		#store arg to EDX
		MOVL 8(%ESP), %ECX		#store cmd number to ECX
		CMPL $4, %ECX
		ja ERRORR				#when cmd number > 4, then go to ERRORR
		CMPL $0, %ECX
		jb ERRORR				#when cmd number < 0, then go to ERRORR
		JMP *jumptable(,%ECX, 4)
ERRORR:
		MOVL $-1, %EAX			#set retuen value as -1
		ret

# ----------------- Functions private to this file -------------------
#update_missile();
#Input:None
#output:None
#This function updates the real_time situation of missiles in
#missile linked list. And remove them if necessary
# Registers: Standard C calling convention
update_missiles:
		PUSHL %EBP
		MOVL %ESP, %EBP		#setup stack
		PUSHL %EBX		#callee_save EBX
		PUSHL %ESI		#callee_save ESI
		PUSHL %EDI		#callee_save EDI
		MOVL mp1_missile_list, %EBX		#load head pointer to EBX
		LEAL mp1_missile_list, %EDI		#load previous pointer to EDI
LOOP:
		CMPL $0, %EBX
		je NOMISSILE					#CHECK IF THERE'S NO MISSILE IN THE LIST
		MOVL EXPLODED(%EBX), %ESI		#ESI as a temporary register
		CMPL $0, %ESI			#compare exploded to 0
		ja EXPLODEDD				#check if it's exploding
#clear current position
		MOVL X(%EBX), %ESI			#ESI as x
		SHRL $SHIFTCONSTANT, %ESI
		MOVL Y(%EBX), %EAX		#EBX as y
		SHRL $SHIFTCONSTANT, %EAX
		IMUL $ROWFACTOR, %EAX
		MOVL %EAX, %ECX
		MOVL %ESI, %EAX
		IMUL $2, %EAX
		ADDL %ECX, %EAX
		XORL %ECX, %ECX
		MOVB $DRAWSPACE, %CL
		CALL mp1_poke			#clear the current missile position
#update current location
		MOVL VX(%EBX), %EDX	#load vx to EDI
		MOVL X(%EBX), %ESI
		ADDL %EDX, %ESI
		MOVL %ESI, X(%EBX)	#update x value
		MOVL VY(%EBX), %EDX	#load vy to EDI
		MOVL Y(%EBX), %ESI
		ADDL %EDX, %ESI
		MOVL %ESI, Y(%EBX)	#update y value
#check if out the bound
		MOVL X(%EBX), %ESI
		SHRL $SHIFTCONSTANT, %ESI
		CMPL $79, %ESI		#compare x location with upperbound 79
		ja REMOVE			#check if x > 79
		MOVL X(%EBX), %ESI
		SHRL $SHIFTCONSTANT, %ESI
		CMPL $0, %ESI
		jb REMOVE			#check if x < 0
		MOVL Y(%EBX), %ESI
		SHRL $SHIFTCONSTANT, %ESI
		CMPL $24, %ESI		#compare y location with upperbound 24
		ja REMOVE			#check if y > 24
		MOVL Y(%EBX), %ESI
		SHRL $SHIFTCONSTANT, %ESI
		CMPL $0, %ESI
		jb REMOVE			#check if y < 0
#check if reach destination
		MOVL DEST_X(%EBX), %EDX	
		MOVL X(%EBX), %ESI
		SHRL $SHIFTCONSTANT, %ESI
		CMPL %EDX, %ESI		#check if x reaches destination
		je EXPLODEDD
		MOVL DEST_Y(%EBX), %EDX
		MOVL Y(%EBX), %ESI
		SHRL $SHIFTCONSTANT, %ESI
		CMPL %EDX, %ESI		#check if y reaches destination
		je EXPLODEDD
#redraw missile if it's still flying
		MOVL X(%EBX), %ESI			#ESI as x 
		SHRL $SHIFTCONSTANT, %ESI
		MOVL Y(%EBX), %EAX		#EBX as y
		SHRL $SHIFTCONSTANT, %EAX
		IMUL $ROWFACTOR, %EAX
		MOVL %EAX, %ECX
		MOVL %ESI, %EAX
		IMUL $2, %EAX
		ADDL %ECX, %EAX
		XORL %ECX, %ECX
		MOVB C(%EBX), %CL
		CALL mp1_poke			#redraw the missile if it's still moving normally
#update current and previous pointer in the stack
UPDATELIST:
		MOVL %EBX, %EDI			#load current to next
		MOVL NEXT(%EBX), %EBX	#load current->next to current
		CMPL $0, %EBX
		jne LOOP				#check if reach the end of the linked list
		POPL %EDI
		POPL %ESI
		POPL %EBX				#callee tear down
		leave
		ret
#exploded function
EXPLODEDD:
		PUSHL %ECX
		PUSHL %EDX				#caller save
		PUSHL %EBX				#push argument for missile_explode
		CALL missile_explode
		POPL %EBX				#pop back EBX
		POPL %EDX
		POPL %ECX				#caller teardown
		CMPL $0, %EAX			#check if this missile causes other explosion
		je DECREMENTE
		CALL mp1_notify_user	#call notify user function 
DECREMENTE:
#decrement exploded
		MOVL EXPLODED(%EBX), %ESI
		ADDL $-1, %ESI
		MOVL %ESI, EXPLODED(%EBX)	#decrement the exploded constant in this missile
		CMPL $0, %ESI
		je ERASE				#if it's 0, remove this missile
#draw the exploded missile
		MOVL X(%EBX), %ESI			#ESI as x 
		SHRL $SHIFTCONSTANT, %ESI
		MOVL Y(%EBX), %EAX		#EBX as y
		SHRL $SHIFTCONSTANT, %EAX
		IMUL $ROWFACTOR, %EAX
		IMUL $2, %ESI
		ADDL %ESI, %EAX
		MOVB $EXPLOSION, %CL
		CALL mp1_poke			#draw the missile on the screen
		JMP UPDATELIST
#erase the exploded missile
ERASE:
		MOVL X(%EBX), %ESI			#ESI as x 
		SHRL $SHIFTCONSTANT, %ESI
		MOVL Y(%EBX), %EAX		#EBX as y
		SHRL $SHIFTCONSTANT, %EAX
		IMUL $ROWFACTOR, %EAX
		MOVL %EAX, %ECX
		MOVL %ESI, %EAX
		IMUL $2, %EAX
		ADDL %ECX, %EAX
		XORL %ECX, %ECX
		MOVB $DRAWSPACE, %CL
		CALL mp1_poke			#first clear the missile from the screen
#remove missile from linked list
REMOVE:
		
		MOVL NEXT(%EBX), %ESI		#load current->next to a temporary register named ESI
		MOVL %ESI, NEXT(%EDI)		#load ESI to previous->next
		PUSHL %EBX					#push current for mp1_free
		CALL mp1_free
		ADDL $4, %ESP				#pop back the stack
		MOVL NEXT(%EDI), %EBX		#let EBX point to current
		JMP LOOP

NOMISSILE:
		POPL %EDI
		POPL %ESI
		POPL %EBX					#callee tear down
		leave
		ret			
		
# int mp1_ioctl_startgame(unsigned long arg)
# Inputs   : unsigned long arg - parameter to the mp1_ioctl_....
#          : %EDX is the argument that comes from the ioctl jumptable
# Outputs  : No output
# Introduction: This function initializes all the variables used in this function such as crosshair location
# score and base_alive arrays. Then it returns and let the game start.
# Registers: Standard C calling convention

mp1_ioctl_startgame:		
		PUSHL %EBP
		MOVL %ESP, %EBP				#setup the stack
		PUSHL %ESI
		PUSHL %EDI
		PUSHL %EBX					#callee save
		MOVL $40, crosshairs_x			#reset crosshair_x
		MOVL $12, crosshairs_y			#reset crosshair_y
		MOVL $0, mp1_score			#reset score
		MOVL $0xFFFFFFFF, base_alive			#initiate base_alive as 0xFFFFFFFF
		POPL %EBX
		POPL %EDI
		POPL %ESI					#callee tear down
		leave
		ret								
		
# int mp1_ioctl_addmissile(unsigned long arg)
# Inputs   : unsigned long arg - parameter to the mp1_ioctl_....
#          : %EDX is the argument that comes from the ioctl jumptable
# Outputs  : No output
# Introduction: This function add missile to the missile list. It firsts malloc space
# with size of 36 bytes. And then add it to the head of the missile linked list.
# in the end, I update new address to the label mp1_missile_list
# Registers: Standard C calling convention	
		
mp1_ioctl_addmissile:					
		PUSHL %EBP
		MOVL %ESP, %EBP			#setup the stack
		PUSHL %ESI				#callee save
		PUSHL %EDI				#callee save
		PUSHL %EBX				#callee save
		MOVL %EDX, %ESI			#save argument to a callee saved register
		PUSHL $MISSILESIZE				#push argument for malloc
#mp1_malloc(int);
#Input: size of memory that want to allocate
#output: a pointer to the allocated memory
# This function is used to create memory in kernel
# so there's memory space to add missile to the linked list
# Registers: Standard C calling convention
		CALL mp1_malloc
		ADDL $4, %ESP			#pop back stack pointer
		MOVL %EAX, %EBX			#save return pointer to a callee saved register
		CMPL $0, %EAX			#check if allocate fails
		je FAILMALLOC
		PUSHL $MISSILESIZE				#push n
		PUSHL %ESI				#push *from
		PUSHL %EBX				#push *to
# mp1_copy_from_user(*address1, *address2, int);
# Input: one kernel address pointer EBX, one user memory pointer ESI, size of copy memory which is 36 bytes
# output: number of bytes that faile to copy. 0 when succeed.
# this function copies user memory to kernel space with specific size which is decide by the input argument.
# Registers: Standard C calling convention
		CALL mp1_copy_from_user
		ADDL $12, %ESP
		CMPL $0, %EAX			#check if copy fails
		ja FAILCOPY
		MOVL mp1_missile_list, %ECX
		MOVL %ECX, NEXT(%EBX)
		MOVL %EBX, mp1_missile_list	#load new address to head pointer
		MOVL $0, %EAX			#et return value to 0
		POPL %EBX
		POPL %EDI
		POPL %ESI				#callee tear down
		leave
		ret								
FAILMALLOC:
		MOVL $-1, %EAX			#set return value to -1
		POPL %EBX
		POPL %EDI
		POPL %ESI				#callee tear down
		leave
		ret
FAILCOPY:
		PUSHL %EBX				#push pointer for free
#mp1_free(*pointer);
#Input: pointer to a memory address
#output: none
#this function free the memory where is pointed by the input pointer.
# Registers: Standard C calling convention
		CALL mp1_free
		ADD $4, %ESP			#pop back stack
		MOVL $-1, %EAX			#set return value to 1
		POPL %EBX
		POPL %EDI
		POPL %ESI				#callee tear down
		leave
		ret								

# int mp1_ioctl_movexhairs(unsigned long arg)
# Inputs   : unsigned long arg - parameter to the mp1_ioctl_....
#          : %EDX is the argument that comes from the ioctl jumptable
# Outputs  : No output
# Introduction: This function reads the change of x and y movecross cordinate and
# redraw it. I first clear current crosshair and then update them and redraw them.
# when crosshair is out of the bound, it returns to the center of the screen.
# Registers: Standard C calling convention		
mp1_ioctl_movexhairs:			#######
		PUSHL %EBP
		MOVL %ESP, %EBP			#setup the stack
		PUSHL %ESI
		PUSHL %EDI
		PUSHL %EBX				#callee save 3 registers
		PUSHL %EDX				
		PUSHL %EAX				#caller save 2 registers
#clear_crosshair();
#This help function clear the current crosshair.
#input: None
#output: None
# Registers: Standard C calling convention
		CALL clear_crosshair
		POPL %EAX				
		POPL %EDX				#caller tear down 2 registers
		MOVL %EDX, %EDI			#copy parameter to EDI
		ANDL $0xFFFF0000, %EDI	#take first 16 bits Y
		CMPL $0, %EDI			#check if change should be negative
		jl CHANGESIGN
		SHRL $SHIFTCONSTANT, %EDI			#shift right 16 bits if it's positive
AFTERCHANGE:
		ANDL $0x0000FFFF, %EDX	#take second 16 bits X
		SHLL $SHIFTCONSTANT, %EDX
		CMPL $0, %EDX			#check if change should be negative
		jl CHANGESIGNY			
		SHRL $SHIFTCONSTANT, %EDX
AFTERCHANGEY:
		MOVL crosshairs_x, %EBX
		ADDL %EBX, %EDX			#new crosshair_x location 
		CMPL $79, %EDX			#compare x location with upperbound 79
		jg OUTCROSSX			#go to the branch outcrossx
		CMPL $0, %EDX
		jl OUTCROSSX			#go to the branch outcrossx
STOREXVALUE:
		MOVL %EDX, crosshairs_x		#store new crosshair_x value to label
		MOVL crosshairs_y, %EBX		#new crosshair_y location
		ADDL %EBX, %EDI
		CMPL $24, %EDI			#compare y location with upperbound 24
		jg OUTCROSSY			#go to the branch outcrossy
		CMPL $0, %EDI
		jl OUTCROSSY			#go to the branch outcrossy
STOREYVALUE:
		MOVL %EDI, crosshairs_y	#store new crosshair_x value to label
		JMP REDRAWCROSSHAIR
OUTCROSSX:
		MOVL $40, %EDX			#set crosshairs_x back to center : X = 40
		JMP STOREXVALUE
OUTCROSSY:
		MOVL $12, %EDI			#set crosshairs_y back to center : Y = 12
		JMP STOREYVALUE
CHANGESIGN:
		ADDL $SIGNCONSTANT, %EDI		#return this unsigned number to signed number
		JMP AFTERCHANGE
CHANGESIGNY:
		ADDL $SIGNCONSTANT, %EDX		#return this unsigned number to signed number
		JMP AFTERCHANGEY
REDRAWCROSSHAIR:
#redraw_crosshair();
#This function is also used in tasklet function which is to redraw
#the crosshair.
#input: none
#output:none
# Registers: Standard C calling convention
		CALL redraw_crosshair	#call redraw cross_hair function
		POPL %EBX
		POPL %EDI
		POPL %ESI				#callee tear down
		leave
		ret						

# int mp1_ioctl_getstatus(unsigned long arg)
# Inputs   : unsigned long arg - parameter to the mp1_ioctl_....
#          : %EDX is the argument that comes from the ioctl jumptable
# Outputs  : -1 if fails, otherwise 0.
# Introduction: This function first load score and base situation into an address called 
# NEWADDRESS. Then I call malloc and copy_to_user to get status from kernel. If either fails, it returns
# -1, else it returns 0.
# Registers: Standard C calling convention	
		
mp1_ioctl_getstatus:
		PUSHL %EBP
		MOVL %ESP, %EBP		#setup the stack
		PUSHL %ESI
		PUSHL %EDI
		PUSHL %EBX			#callee save 3 registers
		MOVL $0, NEWADDRESS		#reset address NEWADDRESS
		XORL %EDI, %EDI			
		MOVL mp1_score, %ESI	#load score to ESI
		MOVB base_alive, %BL	#load base array to BL
		CMPB $0xFF, %BL
		je FFLIVE				#go to the branch first alive
SECONDCHECK:
		MOVB base_alive + 1, %BL	#load base array + 1 to BL
		CMPB $0xFF, %BL
		je SSLIVE					#go to the branch second alive
THIRDCHECK:
		MOVB base_alive + 2, %BL	#load base array + 1 to BL
		CMPB $0xFF, %BL
		je TTLIVE					#go to the branch third alive
FINISHCHECK:
		ADDL %ESI, %EDI				#add score and base situation to EDI
		MOVL $NEWADDRESS, %EBX
		MOVL %EDI, (%EBX)			#load EDI to the address that EBX pointed to, which is NEWADDRESS
		PUSHL $4
		PUSHL %EBX
		PUSHL %EDX					#push 3 arguments for copy_to_user function	
# mp1_copy_to_user(*address1, *address2, int);
# Input: one kernel address pointer EBX, one user memory pointer EDX, size of copy memory which is 4 bytes
# output: number of bytes that faile to copy. 0 when succeed.
# this function copies kernel memory to user space with specific size which is decide by the input argument.
# Registers: Standard C calling convention
		CALL mp1_copy_to_user
		ADDL $12, %ESP				#pop back the stack pointer
		CMPL $0, %EAX
		jne FAILGET					#jump to the branch FAILGET
		MOVL $0, %EAX				#set return value to 0
		POPL %EBX
		POPL %EDI
		POPL %ESI					#callee tear down
		leave
		ret
FFLIVE:
		MOVL $0x00010000, %EDI		#if first base alive, its bit is 1.
		JMP SECONDCHECK
SSLIVE:
		MOVL $0x00020000, %EBX		#if second base alive, its bit is 1.
		ADDL %EBX, %EDI
		JMP THIRDCHECK
TTLIVE:
		MOVL $0x00040000, %EBX		#if third base alive, its bit is 1.
		ADDL %EBX, %EDI
		JMP FINISHCHECK
FAILGET:
		MOVL $-1, %EAX				#set return value to -1
		POPL %EBX
		POPL %EDI
		POPL %ESI					#callee tear down
		leave
		ret

# int mp1_ioctl_endgame(unsigned long arg)
# Inputs   : unsigned long arg - parameter to the mp1_ioctl_....
#          : %EDX is the argument that comes from the ioctl jumptable
# Outputs  : returns 0 when succeed.
# Introduction: This function clear all the missile linked list elements
# and return succeed if it doesn't leave any unfreed memory.
# Registers: Standard C calling convention	
		
mp1_ioctl_endgame:
		PUSHL %EBP
		MOVL %ESP, %EBP				#setup the stack
		PUSHL %ESI
		PUSHL %EDI
		PUSHL %EBX					#callee_save
		MOVL mp1_missile_list, %ECX	#load head pointer of missile to ECX
		CMPL $0, %ECX
		je FINALLY
ENDLOOP:
		MOVL NEXT(%ECX), %EBX		#store current->next to EBX
#mp1_free(*pointer);
#Input: pointer to a memory address
#output: none
#this function free the memory where is pointed by the input pointer.
# Registers: Standard C calling convention
		PUSHL %ECX
		CALL mp1_free	
		ADDL $4, %ESP				#pop back the stac pointer
		MOVL %EBX, %ECX				#let current = current->next
		CMPL $0, %ECX
		jne ENDLOOP					#if not reach the end of linked list, back to the loop
FINALLY:
		MOVL $0, %EAX		#return success for free linked list
		POPL %EBX
		POPL %EDI
		POPL %ESI			#callee tear down 3 registers
		leave
		ret
#This is the jumptable for ioctl function.		
jumptable:
		.long mp1_ioctl_startgame, mp1_ioctl_addmissile, mp1_ioctl_movexhairs, mp1_ioctl_getstatus, mp1_ioctl_endgame	