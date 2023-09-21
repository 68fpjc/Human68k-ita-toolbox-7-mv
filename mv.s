* mv - move file
*
* Itagaki Fumihiko 30-Aug-92  Create.
* 1.2
* Itagaki Fumihiko 06-Nov-92  Human68k��fatchk�̃o�O�΍�D
*                             strip_excessive_slashes�̃o�Ofix�ɔ������ŁD
*                             ���ׂȃ��b�Z�[�W�ύX�D
* 1.3
* Itagaki Fumihiko 16-Dec-92  ������ 2�imv a b�j�̂Ƃ��Cb �����݂���f�B
*                             ���N�g���ł����Ă��Ca �� b �������G���g����
*                             �w���p�X���ł���ꍇ�ɂ͓��ʂ� mv d1 d2 �̌`
*                             ���Ƃ��ď�������悤�ɂ����D����Ńf�B���N�g
*                             ���ɑ΂��Ă� CASE.X �Ɠ������Ɓi�����Ԃ�̂�
*                             �ܑ啶���^��������ύX����j���\�ɂȂ����D
* Itagaki Fumihiko 27-Dec-92  -I �I�v�V�����̒ǉ��D
* Itagaki Fumihiko 27-Dec-92  -m �I�v�V�����̒ǉ��D
* 1.4
* Itagaki Fumihiko 10-Jan-93  GETPDB -> lea $10(a0),a0
* Itagaki Fumihiko 12-Jan-93  -e �I�v�V�����̒ǉ��D
* Itagaki Fumihiko 20-Jan-93  ���� - �� -- �̈����̕ύX
* Itagaki Fumihiko 22-Jan-93  �X�^�b�N���g��
* Itagaki Fumihiko 24-Jan-93  v1.4 �ł� identical check ������ɍs���Ȃ�
*                             �G���o�O���C��
* Itagaki Fumihiko 25-Jan-93  �G���[�E���b�Z�[�W�̏C��
* 1.5
* Itagaki Fumihiko 27-Nov-93  -m-w+x �i-m �� mode ���������Ďw��j������
* Itagaki Fumihiko 27-Nov-93  -m 644 �i8�i���l�\���j������
* Itagaki Fumihiko 28-Nov-93  �ꕔ�̏����̍�����
* Itagaki Fumihiko 30-Dec-93  �e�h���C�u�̃J�����g�E�f�B���N�g���̈ړ����֎~
* Itagaki Fumihiko 30-Dec-93  �f�B���N�g�����ړ������� .. �̃����N����C������
* 1.6
* Itagaki Fumihiko 11-Sep-94  �ړ����悤�Ƃ���f�B���N�g�����e�h���C�u�̃J�����g�E�f�B���N�g��
*                             �łȂ����ǂ������`�F�b�N������@��ύX
* 1.7
* Itagaki Fumihiko 10-Jun-95  ���dmount�Ή�
* Itagaki Fumihiko 10-Jun-95  �G���[�`�F�b�N����
* 1.8
* Itagaki Fumihiko 18-Jun-95  v1.8�ł̃G���o�O���C��
* 1.9
*
* Usage: mv [ -Ifiuvx ] [ -m mode ] [ -- ] <�t�@�C��1> <�t�@�C��2>
*        mv [ -Ifiuvx ] [ -m mode ] [ -- ] <�f�B���N�g��1> <�f�B���N�g��2>
*        mv [ -Iefiuvx ] [ -m mode ] [ -- ] <�t�@�C��> ... <�f�B���N�g��>

.include doscall.h
.include error.h
.include limits.h
.include stat.h
.include chrcode.h

.xref DecodeHUPAIR
.xref getlnenv
.xref issjis
.xref strlen
.xref strfor1
.xref memcmp
.xref memmovd
.xref memmovi
.xref headtail
.xref cat_pathname
.xref strip_excessive_slashes
.xref fclose

REQUIRED_OSVER	equ	$200			*  2.00�ȍ~

STACKSIZE	equ	16384			*  �X�[�p�[�o�C�U���[�h�ł�15KB�ȏ�K�v
GETSLEN		equ	32

FLAG_f			equ	0
FLAG_i			equ	1
FLAG_I			equ	2
FLAG_u			equ	3
FLAG_v			equ	4
FLAG_x			equ	5
FLAG_e			equ	6
FLAG_identical		equ	7
FLAG_assign_cleared	equ	8

LNDRV_O_CREATE		equ	4*2
LNDRV_O_OPEN		equ	4*3
LNDRV_O_DELETE		equ	4*4
LNDRV_O_MKDIR		equ	4*5
LNDRV_O_RMDIR		equ	4*6
LNDRV_O_CHDIR		equ	4*7
LNDRV_O_CHMOD		equ	4*8
LNDRV_O_FILES		equ	4*9
LNDRV_O_RENAME		equ	4*10
LNDRV_O_NEWFILE		equ	4*11
LNDRV_O_FATCHK		equ	4*12
LNDRV_realpathcpy	equ	4*16
LNDRV_LINK_FILES	equ	4*17
LNDRV_OLD_LINK_FILES	equ	4*18
LNDRV_link_nest_max	equ	4*19
LNDRV_getrealpath	equ	4*20

.text
start:
		bra.s	start1
		dc.b	'#HUPAIR',0
start1:
		lea	stack_bottom(pc),a7		*  A7 := �X�^�b�N�̒�
		DOS	_VERNUM
		cmp.w	#REQUIRED_OSVER,d0
		bcs	dos_version_mismatch

		lea	$10(a0),a0			*  A0 : PDB�A�h���X
		move.l	a7,d0
		sub.l	a0,d0
		move.l	d0,-(a7)
		move.l	a0,-(a7)
		DOS	_SETBLOCK
		addq.l	#8,a7
	*
	*  �������ъi�[�G���A���m�ۂ���
	*
		lea	1(a2),a0			*  A0 := �R�}���h���C���̕�����̐擪�A�h���X
		bsr	strlen				*  D0.L := �R�}���h���C���̕�����̒���
		addq.l	#1,d0
		bsr	malloc
		bmi	insufficient_memory

		movea.l	d0,a1				*  A1 := �������ъi�[�G���A�̐擪�A�h���X
	*
	*  �o�b�t�@���m�ۂ���
	*
		move.l	#$00ffffff,d0
		bsr	malloc
		sub.l	#$81000000,d0
		cmp.l	#1024,d0
		blo	insufficient_memory

		move.l	d0,copy_buffer_size
		bsr	malloc
		bmi	insufficient_memory

		move.l	d0,copy_buffer_top
	*
	*  lndrv ���g�ݍ��܂�Ă��邩�ǂ�������������
	*
		bsr	getlnenv
		move.l	d0,lndrv
	*
	*  �������f�R�[�h���C���߂���
	*
		bsr	DecodeHUPAIR			*  �������f�R�[�h����
		movea.l	a1,a0				*  A0 : �����|�C���^
		move.l	d0,d7				*  D7.L : �����J�E���^
		move.b	#$ff,mode_mask
		clr.b	mode_plus
		moveq	#0,d5				*  D5.L : flags
decode_opt_loop1:
		tst.l	d7
		beq	decode_opt_done

		cmpi.b	#'-',(a0)
		bne	decode_opt_done

		tst.b	1(a0)
		beq	decode_opt_done

		subq.l	#1,d7
		addq.l	#1,a0
		move.b	(a0)+,d0
		cmp.b	#'-',d0
		bne	decode_opt_loop2

		tst.b	(a0)+
		beq	decode_opt_done

		subq.l	#1,a0
decode_opt_loop2:
		cmp.b	#'f',d0
		beq	set_option_f

		cmp.b	#'i',d0
		beq	set_option_i

		cmp.b	#'I',d0
		beq	set_option_I

		moveq	#FLAG_u,d1
		cmp.b	#'u',d0
		beq	set_option

		moveq	#FLAG_v,d1
		cmp.b	#'v',d0
		beq	set_option

		moveq	#FLAG_x,d1
		cmp.b	#'x',d0
		beq	set_option

		moveq	#FLAG_e,d1
		cmp.b	#'e',d0
		beq	set_option

		cmp.b	#'m',d0
		beq	decode_mode

		moveq	#1,d1
		tst.b	(a0)
		beq	bad_option_1

		bsr	issjis
		bne	bad_option_1

		moveq	#2,d1
bad_option_1:
		move.l	d1,-(a7)
		pea	-1(a0)
		move.w	#2,-(a7)
		lea	msg_illegal_option(pc),a0
		bsr	werror_myname_and_msg
		DOS	_WRITE
		lea	10(a7),a7
		bra	usage

set_option_I:
		bset	#FLAG_I,d5
set_option_i:
		bset	#FLAG_i,d5
		bclr	#FLAG_f,d5
		bra	set_option_done

set_option_f:
		bset	#FLAG_f,d5
		bclr	#FLAG_i,d5
		bclr	#FLAG_I,d5
		bra	set_option_done

set_option:
		bset	d1,d5
set_option_done:
		move.b	(a0)+,d0
		bne	decode_opt_loop2
		bra	decode_opt_loop1

decode_mode:
		tst.b	(a0)
		bne	decode_mode_0

		subq.l	#1,d7
		bcs	too_few_args

		addq.l	#1,a0
decode_mode_0:
		move.b	(a0),d0
		cmp.b	#'0',d0
		blo	decode_symbolic_mode

		cmp.b	#'7',d0
		bhi	decode_symbolic_mode

	*  numeric mode

		moveq	#0,d1
scan_numeric_mode_loop:
		move.b	(a0)+,d0
		beq	scan_numeric_mode_done

		sub.b	#'0',d0
		blo	bad_arg

		cmp.b	#7,d0
		bhi	bad_arg

		lsl.w	#3,d1
		or.b	d0,d1
		bra	scan_numeric_mode_loop

scan_numeric_mode_done:
		move.w	d1,d0
		lsr.w	#3,d0
		or.w	d0,d1
		lsr.w	#3,d0
		or.w	d0,d1
		moveq	#0,d0
		btst	#1,d1
		beq	decode_numeric_mode_w_ok

		bset	#MODEBIT_RDO,d0
decode_numeric_mode_w_ok:
		btst	#0,d1
		beq	decode_numeric_mode_x_ok

		bset	#MODEBIT_EXE,d0
decode_numeric_mode_x_ok:
		move.b	d0,mode_plus
		move.b	#(MODEVAL_VOL|MODEVAL_DIR|MODEVAL_LNK|MODEVAL_ARC|MODEVAL_SYS|MODEVAL_HID),mode_mask
		bra	decode_opt_loop1

	*  symbolic mode

decode_symbolic_mode:
		move.b	#$ff,mode_mask
		clr.b	mode_plus
decode_symbolic_mode_loop1:
		move.b	(a0)+,d0
		beq	decode_opt_loop1

		cmp.b	#',',d0
		beq	decode_symbolic_mode_loop1

		subq.l	#1,a0
decode_symbolic_mode_loop2:
		move.b	(a0)+,d0
		cmp.b	#'u',d0
		beq	decode_symbolic_mode_loop2

		cmp.b	#'g',d0
		beq	decode_symbolic_mode_loop2

		cmp.b	#'o',d0
		beq	decode_symbolic_mode_loop2

		cmp.b	#'a',d0
		beq	decode_symbolic_mode_loop2
decode_symbolic_mode_loop3:
		cmp.b	#'+',d0
		beq	decode_symbolic_mode_plus

		cmp.b	#'-',d0
		beq	decode_symbolic_mode_minus

		cmp.b	#'=',d0
		bne	bad_arg

		move.b	#(MODEVAL_VOL|MODEVAL_DIR|MODEVAL_LNK),mode_mask
		clr.b	mode_plus
decode_symbolic_mode_plus:
		bsr	decode_symbolic_mode_sub
		or.b	d1,mode_plus
		bra	decode_symbolic_mode_continue

decode_symbolic_mode_minus:
		bsr	decode_symbolic_mode_sub
		not.b	d1
		and.b	d1,mode_mask
		and.b	d1,mode_plus
decode_symbolic_mode_continue:
		tst.b	d0
		beq	decode_opt_loop1

		cmp.b	#',',d0
		beq	decode_symbolic_mode_loop1
		bra	decode_symbolic_mode_loop3

decode_symbolic_mode_sub:
		moveq	#0,d1
decode_symbolic_mode_sub_loop:
		move.b	(a0)+,d0
		moveq	#MODEBIT_ARC,d2
		cmp.b	#'a',d0
		beq	decode_symbolic_mode_sub_set

		moveq	#MODEBIT_SYS,d2
		cmp.b	#'s',d0
		beq	decode_symbolic_mode_sub_set

		moveq	#MODEBIT_HID,d2
		cmp.b	#'h',d0
		beq	decode_symbolic_mode_sub_set

		cmp.b	#'r',d0
		beq	decode_symbolic_mode_sub_loop

		moveq	#MODEBIT_RDO,d2
		cmp.b	#'w',d0
		beq	decode_symbolic_mode_sub_set

		moveq	#MODEBIT_EXE,d2
		cmp.b	#'x',d0
		beq	decode_symbolic_mode_sub_set

		rts

decode_symbolic_mode_sub_set:
		bset	d2,d1
		bra	decode_symbolic_mode_sub_loop

decode_opt_done:
		subq.l	#2,d7
		bcs	too_few_args
	*
	*  �W�����͂��[���ł��邩�ǂ����𒲂ׂĂ���
	*
		moveq	#0,d0				*  �W�����͂�
		bsr	is_chrdev			*  �L�����N�^�f�o�C�X
		sne	stdin_is_terminal
	*
	*  �����J�n
	*
		moveq	#0,d6				*  D6.W : �G���[�E�R�[�h
	*
	*  target�𒲂ׂ�
	*
		movea.l	a0,a1				*  A1 : 1st arg
		move.l	d7,d0
find_target:
		bsr	strfor1
		subq.l	#1,d0
		bcc	find_target
							*  A0 : target arg
		bsr	strip_excessive_slashes		*  target arg �� strip����
		exg	a0,a1				*  A0 : 1st arg, A1 : target arg
		movea.l	a0,a2
		bsr	strfor1
		exg	a0,a2				*  A2 : 2nd arg (if any)
		bsr	strip_excessive_slashes		*  1st arg �� strip����

		exg	a0,a1
		bsr	is_directory
		exg	a0,a1
		bmi	exit_program
		bne	mv_into_dir

	*  target�̓f�B���N�g���ł͂Ȃ�

		tst.l	d7
		bne	not_directory			*  �t�@�C�������� 3�ȏ� .. �G���[
mv_source_to_target:
		bsr	move_file
exit_program:
		move.w	d6,-(a7)
		DOS	_EXIT2

	*  target�̓f�B���N�g��
mv_into_dir:
		tst.l	d7
		bne	mv_into_dir_loop

		bsr	is_identical
		bne	mv_into_dir_loop

		*  ������ 2�œ��� .. rename
		bset	#FLAG_identical,d5
		bra	mv_source_to_target

mv_into_dir_loop:
		movem.l	a1-a2,-(a7)
		bsr	move_into_dir
		movem.l	(a7)+,a1-a2
		subq.l	#1,d7
		bcs	exit_program

		movea.l	a2,a0
		bsr	strfor1
		exg	a0,a2
		bsr	strip_excessive_slashes
		bra	mv_into_dir_loop
****************************************************************
not_directory:
		*  target�����݂���Ȃ�uNot a directory�v
		*  target�����݂��Ȃ��Ȃ�uNo directory�v
		movea.l	a1,a0
		bsr	lgetmode
		lea	msg_not_a_directory(pc),a2
		bpl	mv_error_exit

		lea	msg_nodir(pc),a2
mv_error_exit:
		bsr	werror_myname_word_colon_msg
		bra	exit_program

bad_arg:
		lea	msg_bad_arg(pc),a0
		bra	arg_error

too_few_args:
		lea	msg_too_few_args(pc),a0
arg_error:
		bsr	werror_myname_and_msg
usage:
		lea	msg_usage(pc),a0
		bsr	werror
		moveq	#1,d6
		bra	exit_program

dos_version_mismatch:
		lea	msg_dos_version_mismatch(pc),a0
		bra	mv_error_exit_3

insufficient_memory:
		lea	msg_no_memory(pc),a0
mv_error_exit_3:
		bsr	werror_myname_and_msg
		moveq	#3,d6
		bra	exit_program
*****************************************************************
* move_into_dir
*
*      A0 �Ŏ������G���g���� A1 �Ŏ������f�B���N�g�����Ɉړ�����
*
* RETURN
*      D0-D3/A0-A3   �j��
*****************************************************************
move_into_dir_done:
		rts

move_into_dir:
		movea.l	a1,a2
		bsr	headtail
		exg	a1,a2				*  A2 : tail of source
		move.l	a0,-(a7)
		lea	new_pathname(pc),a0
		bsr	cat_pathname_x
		movea.l	(a7)+,a1
		bmi	move_into_dir_done

		exg	a0,a1
		bclr	#FLAG_identical,d5
		*bra	move_file
*****************************************************************
* move_file - �t�@�C�����ړ�����
*
* CALL
*      A0     source path
*      A1     target path
*
* RETURN
*      D0-D3/A0-A3   �j��
*****************************************************************
move_file:
		*  source �𒲂ׂ�
		bsr	lgetmode
		bmi	perror

		move.b	d0,source_mode

		exg	a0,a1				*  A0:target, A1:source
		btst	#FLAG_identical,d5
		bne	move_file_new			*  rename(src,target) ���Ă��܂�Ȃ�

		*  target �𒲂ׂ�
		bsr	lgetmode
		move.l	d0,d2				*  D2.L : target �� mode
		bpl	move_file_target_exists

		cmp.l	#ENOFILE,d0
		beq	move_file_new

		cmp.l	#ENODIR,d0
		bne	perror

		bsr	headtail
		clr.b	(a1)
		bsr	strip_excessive_slashes
		lea	msg_nodir(pc),a2
		bra	werror_myname_word_colon_msg

move_file_target_exists:
		bset	#FLAG_identical,d5
		bsr	is_identical			*  src �� target ������Ȃ�
		beq	move_file_new			*  rename(src,target) ���Ă��܂�Ȃ�

		bclr	#FLAG_identical,d5
		lea	msg_directory_exists(pc),a2
		btst	#MODEBIT_DIR,d2			*  target���f�B���N�g������
		bne	move_error_x			*  �㏑���ł��Ȃ��̂ŃG���[

		btst.b	#MODEBIT_DIR,source_mode
		bne	update_ok

		btst	#FLAG_u,d5
		beq	update_ok

		bsr	lgetdate
		beq	update_ok

		move.l	d0,d3				*  D3.L : target �̃^�C���E�X�^���v
		exg	a0,a1
		bsr	lgetdate			*  D0.L : source �̃^�C���E�X�^���v
		exg	a0,a1
		beq	update_ok

		cmp.l	d3,d0
		bls	move_file_return
update_ok:
		bsr	confirm_replace
		bne	move_file_return

		*  target ���폜����
		move.b	d2,d0
		bsr	unlink
			* �G���[�����ȗ�
		bra	move_file_new_ok

move_file_new:
		btst	#FLAG_I,d5
		beq	move_file_new_ok

		bsr	confirm_move
		bne	move_file_return
move_file_new_ok:
		btst	#FLAG_v,d5
		beq	verbose_done

		move.l	a1,-(a7)
		DOS	_PRINT
		pea	msg_arrow(pc)
		DOS	_PRINT
		move.l	a0,(a7)
		DOS	_PRINT
		pea	msg_newline(pc)
		DOS	_PRINT
		lea	12(a7),a7
verbose_done:
		exg	a0,a1				*  A0:source, A1:target
		*
		*  source���f�B���N�g���Ȃ�
		*
		btst.b	#MODEBIT_DIR,source_mode
		beq	source_dir_ok

		*  mounted point �łȂ����ǂ������ׂ�

		lea	source_fatchkbuf(pc),a2
		bsr	fatchk
		bmi	source_dir_ok

		DOS	_CURDRV				*
		move.w	d0,-(a7)			*
		DOS	_CHGDRV				*  �h���C�u���𓾂�
		addq.l	#2,a7				*
		move.b	d0,d2				*  D2.L : �h���C�u��
check_mount_loop:
		move.b	d2,d0
		bsr	get_drive_assign
		not.l	d0
		bpl	check_mount_next

		tst.b	assign_pathname+3
		beq	check_mount_next

		bsr	trace_assign_pathname
		bmi	perror

		lea	target_fatchkbuf(pc),a2
		move.l	a0,-(a7)
		lea	assign_pathname(pc),a0
		bsr	fatchk
		move.l	(a7)+,a0
		bmi	check_mount_next

		lea	source_fatchkbuf(pc),a3
		cmpm.w	(a2)+,(a3)+
		bne	check_mount_next

		cmpm.l	(a2)+,(a3)+
		beq	cannot_mv_current_directory
check_mount_next:
		subq.b	#1,d2
		bne	check_mount_loop
source_dir_ok:
		*
		*  source��
		*    �������݋֎~
		*    �V�X�e���t�@�C��
		*    �f�B���N�g��
		*  �Ȃ�ʏ�̃t�@�C����chmod����
		*
		move.b	source_mode,d0
		move.b	d0,d3
		and.b	#(MODEVAL_RDO|MODEVAL_SYS|MODEVAL_DIR),d0
		beq	source_mode_ok

		moveq	#MODEVAL_ARC,d0
		move.b	d0,d3
		bsr	lchmod
		bmi	perror
source_mode_ok:
		*  �����ŁCD3.B : �����݂�source��mode

		*  source���f�B���N�g���Ȃ�target��target��rename���Ă݂�
		*  ���� ENODIR ���Ԃ����Ȃ�A�f�B���N�g�������̃T�u�f�B���N�g����
		*  �ړ����悤�Ƃ��Ă��邱�ƂɂȂ�
		btst.b	#MODEBIT_DIR,source_mode
		beq	do_move_file

		move.l	a1,-(a7)
		move.l	a1,-(a7)
		DOS	_RENAME
		addq.l	#8,a7
		move.l	d0,d2
		cmp.l	#ENODIR,d2
		beq	simple_move_failed
do_move_file:
		*  �ړ�����
		move.l	a1,-(a7)
		move.l	a0,-(a7)
		DOS	_RENAME
		addq.l	#8,a7
		move.l	d0,d2
		bmi	simple_move_failed

		*  mode��ݒ肷��
		movea.l	a1,a0
		moveq	#0,d0
		move.b	source_mode,d0
		bsr	newmode
		bsr	chmodx
		bmi	perror
		*
		*  �f�B���N�g����ʂ̐e�f�B���N�g���Ɉړ������̂Ȃ�
		*  .. ���w���e���C������
		*
		btst.b	#MODEBIT_DIR,source_mode
		beq	move_file_return

		btst	#FLAG_identical,d5
		bne	move_file_return

		lea	target_fatchkbuf(pc),a2
		bsr	fatchk
		bmi	move_file_return		*  target��FAT�Ǘ�����Ă��Ȃ� -> '..'�̏C���͂��Ȃ�

		movea.l	a2,a3
		lea	nameck_buffer(pc),a0
		move.l	a0,-(a7)
		move.l	a1,-(a7)
		DOS	_NAMECK				*  �e�f�B���N�g���̃p�X���𓾂�
		addq.l	#8,a7
		tst.l	d0
		bmi	resume_dotdot_fail

		moveq	#0,d1
		bsr	strlen
		cmp.l	#3,d0
		bls	parent_ok			*  �e�f�B���N�g���̓��[�g�E�f�B���N�g��

		clr.b	-1(a0,d0.l)
		lea	source_fatchkbuf(pc),a2
		bsr	fatchk
		bmi	parent_ok			*  �e�f�B���N�g����FAT�Ǘ�����Ă��Ȃ� -> ���[�g�E�f�B���N�g���Ƃ������Ƃɂ��Ă���

		move.w	(a2),d0
		cmp.w	(a3),d0
		bne	parent_ok			*  �e�f�B���N�g����target�̃h���C�u���Ⴄ -> �e�f�B���N�g���̓��[�g�E�f�B���N�g��

		bsr	readdir				*  �e�f�B���N�g����ǂ�
		bmi	resume_dotdot_fail

		bsr	resume_drive_assign
		movem.l	a0-a1,-(a7)
		movea.l	a3,a0
		lea	dot_entry(pc),a1
		moveq	#16,d0
		bsr	memcmp
		movem.l	(a7)+,a0-a1
		bne	parent_ok			*  �e�f�B���N�g���̍ŏ��̃G���g���� . �łȂ� .. ���[�g�E�f�B���N�g���Ƃ������Ƃɂ��Ă���

		move.w	26(a3),d1			*  D1.W : �e�f�B���N�g����FAT�ԍ�
parent_ok:
		lea	target_fatchkbuf(pc),a2
		bsr	readdir				*  target��ǂ�
		bmi	resume_dotdot_fail

		movem.l	a0-a1,-(a7)
		lea	32(a3),a0
		lea	dotdot_entry(pc),a1
		moveq	#16,d0
		bsr	memcmp
		movem.l	(a7)+,a0-a1
		bne	resume_dotdot_done

		cmp.w	58(a3),d1
		beq	resume_dotdot_done

		move.w	d1,58(a3)
		move.l	#1,-(a7)
		move.l	2(a2),-(a7)
		move.w	0(a2),-(a7)
		move.l	a3,d0
		bset	#31,d0
		move.l	d0,-(a7)
		DOS	_DISKWRT
		lea	14(a7),a7
resume_dotdot_done:
		bsr	resume_drive_assign
		tst.l	d0
		bne	resume_dotdot_fail
move_file_return:
		rts

resume_dotdot_fail:
		movea.l	a1,a0
		lea	msg_resume_dotdot_fail(pc),a2
		bra	werror_myname_word_colon_msg

cannot_mv_current_directory:
		lea	msg_cannot_move_current_dir(pc),a2
		bra	move_error

simple_move_failed:
	*
	*  �G���[
	*
		moveq	#0,d0
		move.b	source_mode,d0
		bsr	chmodx
		bmi	perror
	*
	*  �l�����錴�� :-
	*    �f�B���N�g�������̃T�u�f�B���N�g���Ɉړ����悤�Ƃ��� ... ENODIR
	*    �t�@�C�������݂��� ... EMVEXISTS
	*    �f�B���N�g������t ... EDIRFULL
	*    �h���C�u���قȂ� ... EBADDRV
	*
		lea	msg_cannot_move_dir_to_its_sub(pc),a2
		cmp.l	#ENODIR,d2
		beq	move_error

		lea	msg_semicolon_file_exists(pc),a2
		cmp.l	#EMVEXISTS,d2
		beq	move_error

		lea	msg_semicolon_directory_full(pc),a2
		cmp.l	#EDIRFULL,d2
		beq	move_error

		lea	msg_nul(pc),a2
		cmp.l	#EBADDRV,d2
		bne	move_error

		lea	msg_cannot_move_dirvol_across(pc),a2
		btst.b	#MODEBIT_VOL,source_mode
		bne	move_error

		btst.b	#MODEBIT_DIR,source_mode
		bne	move_error
	*
	*  �h���C�u���قȂ�
	*
		lea	msg_drive_differ(pc),a2
		btst	#FLAG_x,d5
		bne	move_error
		*
		*  source �� open ����
		*
		move.b	source_mode,d0
		bsr	lopen				*  source ���I�[�v������
		bmi	perror

		move.l	d0,d2				*  D2.L : source �̃t�@�C���E�n���h��
		*
		*  target �� create ����
		*
		moveq	#0,d0
		move.b	source_mode,d0
		bsr	newmode
		move.w	d0,-(a7)
		move.l	a1,-(a7)			*  target file ��
		DOS	_CREATE				*  �쐬����
		addq.l	#6,a7				*  �i�h���C�u�̌����͍ς�ł���j
		move.l	d0,d1				*  D1.L : target �̃t�@�C���E�n���h��
		bmi	copy_file_perror_2
		*
		*  �t�@�C���̓��e���R�s�[����
		*
copy_loop:
		move.l	copy_buffer_size,-(a7)
		move.l	copy_buffer_top,-(a7)
		move.w	d2,-(a7)
		DOS	_READ
		lea	10(a7),a7
		tst.l	d0
		bmi	copy_file_perror_3
		beq	copy_file_contents_done

		move.l	d0,d3
		move.l	d0,-(a7)
		move.l	copy_buffer_top,-(a7)
		move.w	d1,-(a7)
		DOS	_WRITE
		lea	10(a7),a7
		tst.l	d0
		bmi	copy_file_perror_4

		cmp.l	d3,d0
		blt	copy_file_disk_full

		bra	copy_loop

copy_file_contents_done:
		*
		*  �t�@�C���̃^�C���X�^���v���R�s�[����
		*
		move.w	d2,d0
		bsr	fgetdate
		beq	copy_timestamp_done

		move.l	d0,-(a7)
		move.w	d1,-(a7)
		DOS	_FILEDATE
		addq.l	#6,a7
			* �G���[�����ȗ� (����)
copy_timestamp_done:
		move.w	d1,d0
		bsr	fclose
			* �G���[�����ȗ�
		move.w	d2,d0
		bsr	fclose
			* �G���[�����ȗ�
		*
		*  source ���폜����
		*
		move.b	source_mode,d0
		bra	unlink

move_error_x:
		exg	a0,a1
move_error:
		bsr	werror_myname_and_msg
		lea	msg_wo(pc),a0
		bsr	werror
		movea.l	a1,a0
		bsr	werror
		lea	msg_cannot_move(pc),a0
		bsr	werror
		movea.l	a2,a0
		bsr	werror
		bra	werror_newline_and_set_error

copy_file_perror_2:
		movea.l	a1,a0
copy_file_perror_1:
		move.l	d0,-(a7)
		move.w	d2,d0				*  source ��
		bsr	fclose				*  close ����
		move.l	(a7)+,d0
		bra	perror

copy_file_disk_full:
		moveq	#EDISKFULL,d0
copy_file_perror_4:
		movea.l	a1,a0
copy_file_perror_3:
		move.l	d0,-(a7)
		move.w	d1,d0				*  target ��
		bsr	fclose				*  close ����
		move.l	(a7)+,d0
		bra	copy_file_perror_1
*****************************************************************
chmodx:
		cmp.b	d3,d0
		bne	lchmod
		rts
*****************************************************************
confirm_replace:
		*  �W�����͂��[���Ȃ�΁C�{�����[���E���x���C�V���{���b�N�E�����N�C
		*  �ǂݍ��ݐ�p�C�B���C�V�X�e���̂ǂꂩ�̑����r�b�g��ON�ł���ꍇ�C
		*  �₢���킹��

		tst.b	stdin_is_terminal
		beq	confirm_i

		move.b	d2,d0
		and.b	#(MODEVAL_VOL|MODEVAL_LNK|MODEVAL_RDO|MODEVAL_HID|MODEVAL_SYS),d0
		bne	confirm
confirm_i:
		btst	#FLAG_i,d5
		beq	confirm_yes
confirm:
		btst	#FLAG_f,d5
		bne	confirm_yes

		bsr	werror_myname
		move.l	a0,-(a7)
		move.l	a1,a0
		bsr	werror
		lea	msg_destination(pc),a0
		bsr	werror
		movea.l	(a7),a0
		bsr	werror
		lea	msg_ni(pc),a0
		bsr	werror

		lea	msg_vollabel(pc),a0
		btst	#MODEBIT_VOL,d2
		bne	confirm_5

		lea	msg_symlink(pc),a0
		btst	#MODEBIT_LNK,d2
		bne	confirm_5

		btst	#MODEBIT_RDO,d2
		beq	confirm_2

		lea	msg_readonly(pc),a0
		bsr	werror
confirm_2:
		btst	#MODEBIT_HID,d2
		beq	confirm_3

		lea	msg_hidden(pc),a0
		bsr	werror
confirm_3:
		btst	#MODEBIT_SYS,d2
		beq	confirm_4

		lea	msg_system(pc),a0
		bsr	werror
confirm_4:
		lea	msg_file(pc),a0
confirm_5:
		bsr	werror
		lea	msg_confirm_replace(pc),a0
do_confirm:
		bsr	werror
		lea	getsbuf(pc),a0
		move.b	#GETSLEN,(a0)
		move.l	a0,-(a7)
		DOS	_GETS
		addq.l	#4,a7
		bsr	werror_newline
		move.b	1(a0),d0
		beq	confirm_6

		move.b	2(a0),d0
confirm_6:
		movea.l	(a7)+,a0
confirm_return:
		cmp.b	#'y',d0
		rts

confirm_yes:
		moveq	#'y',d0
		bra	confirm_return

confirm_move:
		bsr	werror_myname
		exg	a0,a1
		bsr	werror
		exg	a0,a1
		move.l	a0,-(a7)
		lea	msg_wo(pc),a0
		bsr	werror
		move.l	(a7),a0
		bsr	werror
		lea	msg_confirm_move(pc),a0
		bra	do_confirm
*****************************************************************
newmode:
		bchg	#MODEBIT_RDO,d0
		and.b	mode_mask,d0
		or.b	mode_plus,d0
		bchg	#MODEBIT_RDO,d0
		rts
*****************************************************************
malloc:
		move.l	d0,-(a7)
		DOS	_MALLOC
		addq.l	#4,a7
		tst.l	d0
		rts
*****************************************************************
* lopen - �ǂݍ��݃��[�h�Ńt�@�C�����I�[�v������
*         �V���{���b�N�E�����N�̓����N���̂��I�[�v������
*
* CALL
*      A0     �I�[�v������t�@�C���̃p�X��
*      D0.B   �t�@�C����mode�i�\�ߎ擾���Ă����j
*
* RETURN
*      D0.L   �I�[�v�������t�@�C���n���h���D�܂���DOS�G���[�E�R�[�h
*****************************************************************
lopen:
		movem.l	d1/a2-a3,-(a7)
		btst	#MODEBIT_LNK,d0
		beq	lopen_normal			*  SYMLINK�ł͂Ȃ� -> �ʏ�� OPEN

		move.l	lndrv,d0			*  lndrv���풓���Ă��Ȃ��Ȃ�
		beq	lopen_normal			*  �ʏ�� OPEN

		movea.l	d0,a2
		movea.l	LNDRV_realpathcpy(a2),a3
		clr.l	-(a7)
		DOS	_SUPER				*  �X�[�p�[�o�C�U�E���[�h�ɐ؂芷����
		addq.l	#4,a7
		move.l	d0,-(a7)			*  �O�� SSP �̒l
		movem.l	d2-d7/a0-a6,-(a7)
		move.l	a0,-(a7)
		pea	pathname_buf(pc)
		jsr	(a3)
		addq.l	#8,a7
		movem.l	(a7)+,d2-d7/a0-a6
		moveq	#ENOFILE,d1
		tst.l	d0
		bmi	lopen_link_done

		movem.l	d2-d7/a0-a6,-(a7)
		lea	pathname_buf(pc),a0
		bsr	strip_excessive_slashes
		clr.w	-(a7)
		move.l	a0,-(a7)
		movea.l	a7,a6
		movea.l	LNDRV_O_OPEN(a2),a3
		jsr	(a3)
		addq.l	#6,a7
		movem.l	(a7)+,d2-d7/a0-a6
		move.l	d0,d1
lopen_link_done:
		DOS	_SUPER				*  ���[�U�E���[�h�ɖ߂�
		addq.l	#4,a7
		move.l	d1,d0
		bra	lopen_return

lopen_normal:
		clr.w	-(a7)
		move.l	a0,-(a7)
		DOS	_OPEN
		addq.l	#6,a7
		tst.l	d0
lopen_return:
		movem.l	(a7)+,d1/a2-a3
		rts
*****************************************************************
fclosex:
		bpl	fclose
		rts
*****************************************************************
* unlink - �t�@�C�����폜����
*
* CALL
*      A0     �t�@�C���̃p�X��
*      D0.B   �t�@�C����mode�i�\�ߎ擾���Ă����j
*****************************************************************
unlink:
		move.w	#MODEVAL_ARC,-(a7)
		move.l	a0,-(a7)
		and.b	#(MODEVAL_RDO|MODEVAL_SYS|MODEVAL_DIR),d0
		beq	unlink_1

		DOS	_CHMOD
unlink_1:
		DOS	_DELETE
		addq.l	#6,a7
		rts
*****************************************************************
lgetmode:
		moveq	#-1,d0
lchmod:
		move.w	d0,-(a7)
		move.l	a0,-(a7)
		DOS	_CHMOD
		addq.l	#6,a7
		tst.l	d0
		rts
*****************************************************************
fgetdate:
		clr.l	-(a7)
		move.w	d0,-(a7)
		DOS	_FILEDATE
		addq.l	#6,a7
fgetdate_done:
		tst.l	d0
		beq	fgetdate_return

		cmp.l	#$ffff0000,d0
		blo	fgetdate_return
fgetdate_fail:
		moveq	#0,d0
fgetdate_return:
		rts
*****************************************************************
lgetdate:
		bsr	lgetmode
		bmi	fgetdate_fail

		bsr	lopen
		bmi	fgetdate_fail

		move.l	d1,-(a7)
		move.l	d0,d1
		bsr	fgetdate
		exg	d0,d1
		bsr	fclose
		move.l	d1,d0
		move.l	(a7)+,d1
		bra	fgetdate_done
*****************************************************************
* is_identical - 2�̃t�@�C�������ꂩ�ǂ������ׂ�
*
* CALL
*      A0     pathname of file 1
*      A1     pathname of file 2
*
* RETURN
*      CCR    ����Ȃ�� EQ
*      D0/A2-A3  �j��
*****************************************************************
is_identical:
		lea	target_fatchkbuf(pc),a2
		bsr	fatchk
		bmi	is_identical_return		* NE

		movea.l	a2,a3
		lea	source_fatchkbuf(pc),a2
		exg	a0,a1
		bsr	fatchk
		exg	a0,a1
		bmi	is_identical_return		*  NE

		cmpm.w	(a2)+,(a3)+
		bne	is_identical_return		*  NE

		cmpm.l	(a2)+,(a3)+
is_identical_return:
		rts
*****************************************************************
fatchk:
		move.l	a2,d0
		bset	#31,d0
		move.w	#14,-(a7)
		move.l	d0,-(a7)
		move.l	a0,-(a7)
		DOS	_FATCHK
		lea	10(a7),a7
		cmp.l	#EBADPARAM,d0
		bne	fatchk_return

		moveq	#0,d0
fatchk_return:
		tst.l	d0
		rts
*****************************************************************
* get_drive_assign
*
* CALL
*      D0.B   �h���C�u�ԍ�(1='A:', 2='B:', 3='C:', ...)
*      A0     curdir�i�[�o�b�t�@
*
* RETURN
*      D0.L   DOS _ASSIGN ���^�[���R�[�h
*
* DESCRIPTION
*      drivename_buffer �Ƀh���C�u�����Z�b�g����.
*      assign_pathname �ɂ��̃h���C�u��assign pathname���擾����.
*****************************************************************
get_drive_assign:
		move.l	a0,-(a7)
		lea	drivename_buffer(pc),a0
		add.b	#'A'-1,d0
		move.b	d0,(a0)+
		move.b	#':',(a0)+
		clr.b	(a0)
		movea.l	(a7)+,a0
		pea	assign_pathname(pc)		*
		pea	drivename_buffer(pc)		*
		clr.w	-(a7)				*
		DOS	_ASSIGN				*  assign�擾
		lea	10(a7),a7			*
		rts
*****************************************************************
trace_assign_pathname:
		movem.l	d1/a0-a3,-(a7)
		lea	assign_pathname(pc),a2
		lea	pathname_buf(pc),a3
trace_assign_loop:
		clr.b	2(a2)
		move.l	a3,-(a7)			*
		move.l	a2,-(a7)			*
		clr.w	-(a7)				*
		DOS	_ASSIGN				*  assign�擾
		lea	10(a7),a7			*
		move.b	#'\',2(a2)
		cmp.l	#$60,d0
		bne	trace_assign_pathname_done

		move.b	(a3),d0
		cmp.b	(a2),d0
		beq	trace_assign_pathname_error

		tst.b	3(a3)
		bne	trace_assign_1

		move.b	d0,(a2)
		bra	trace_assign_loop

trace_assign_1:
		movea.l	a2,a0
		bsr	strfor1
		movea.l	a0,a1
		movea.l	a3,a0
		bsr	strlen
		move.l	d0,d1
		subq.l	#2,d0
		lea	(a1,d0.l),a0
		move.l	a0,d0
		sub.l	a2,d0
		cmp.l	#MAXPATH+1,d0
		bhi	trace_assign_pathname_error

		move.l	a1,d0
		sub.l	a2,d0
		subq.l	#2,d0
		bsr	memmovd
		movea.l	a3,a1
		movea.l	a2,a0
		move.l	d1,d0
		bsr	memmovi
		bra	trace_assign_loop

trace_assign_pathname_done:
		moveq	#0,d0
trace_assign_pathname_return:
		movem.l	(a7)+,d1/a0-a3
		tst.l	d0
		rts

trace_assign_pathname_error:
		moveq	#EBADDRV,d0
		bra	trace_assign_pathname_return
*****************************************************************
readdir:
		bclr	#FLAG_assign_cleared,d5
		move.w	(a2),d0
		bsr	get_drive_assign
		cmp.l	#$60,d0
		bne	do_readdir

		bsr	trace_assign_pathname
		bmi	readdir_fail

		pea	drivename_buffer(pc)		*
		move.w	#4,-(a7)			*
		DOS	_ASSIGN				*  assign����
		addq.l	#6,a7				*
		tst.l	d0
		bmi	readdir_fail

		bset	#FLAG_assign_cleared,d5
do_readdir:
		lea	dpb_buffer(pc),a3
		move.l	a3,-(a7)
		move.w	0(a2),-(a7)
		DOS	_GETDPB
		addq.l	#6,a7
		tst.l	d0
		bmi	readdir_fail

		moveq	#0,d0
		move.w	2(a3),d0
		cmp.l	copy_buffer_size,d0
		bhi	readdir_fail

		move.l	#1,-(a7)
		move.l	2(a2),-(a7)
		move.w	0(a2),-(a7)
		movea.l	copy_buffer_top,a3
		move.l	a3,d0
		bset	#31,d0
		move.l	d0,-(a7)
		DOS	_DISKRED
		lea	14(a7),a7
		tst.l	d0
		bmi	readdir_fail

		moveq	#0,d0
		rts

readdir_fail:
		moveq	#-1,d0
resume_drive_assign:
		btst	#FLAG_assign_cleared,d5
		beq	resume_drive_assign_done

		move.l	d0,-(a7)
		move.w	#$60,-(a7)
		pea	assign_pathname(pc)		*
		pea	drivename_buffer(pc)		*
		move.w	#1,-(a7)			*
		DOS	_ASSIGN				*  assign���s
		lea	12(a7),a7			*
		tst.l	d0
		bpl	resume_drive_assign_ok

		movem.l	a0/a2,-(a7)
		lea	drivename_buffer(pc),a0
		lea	msg_could_not_remount(pc),a2
		bsr	werror_myname_word_colon_msg
		movem.l	(a7)+,a0/a2
resume_drive_assign_ok:
		move.l	(a7)+,d0
resume_drive_assign_done:
		tst.l	d0
		rts
*****************************************************************
is_chrdev:
		movem.l	d0,-(a7)
		move.w	d0,-(a7)
		clr.w	-(a7)
		DOS	_IOCTRL
		addq.l	#4,a7
		tst.l	d0
		bpl	is_chrdev_1

		moveq	#0,d0
is_chrdev_1:
		btst	#7,d0
		movem.l	(a7)+,d0
		rts
****************************************************************
* cat_pathname_x - concatinate head and tail
*
* CALL
*      A0     result buffer (MAXPATH+1�o�C�g�K�v)
*      A1     points head
*      A2     points tail
*
* RETURN
*      A1     next word
*      A2     �j��
*      A3     tail pointer of result buffer
*      D0.L   positive if success.
*      CCR    TST.L D0
*****************************************************************
cat_pathname_x:
		bsr	cat_pathname
		bpl	cat_pathname_x_return

		lea	msg_too_long_pathname(pc),a2
		bsr	werror_myname_word_colon_msg
		tst.l	d0
cat_pathname_x_return:
		rts
*****************************************************************
* is_directory - ���O���f�B���N�g���ł��邩�ǂ����𒲂ׂ�
*
* CALL
*      A0     ���O
*
* RETURN
*      D0.L   ���O/*.* ����������Ȃ�� -1�D
*             ���̂Ƃ��G���[���b�Z�[�W���\������CD6.L �ɂ� 2 ���Z�b�g�����D
*
*             �����łȂ���΁C���O���f�B���N�g���Ȃ�� 1�C�����Ȃ��� 0
*
*      CCR    TST.L D0
*****************************************************************
is_directory:
		movem.l	a0-a3,-(a7)
		tst.b	(a0)
		beq	is_directory_false

		movea.l	a0,a1
		lea	pathname_buf(pc),a0
		lea	dos_wildcard_all(pc),a2
		bsr	cat_pathname_x
		bmi	is_directory_return

		move.w	#MODEVAL_ALL,-(a7)		*  ���ׂẴG���g������������
		move.l	a0,-(a7)
		pea	filesbuf(pc)
		DOS	_FILES
		lea	10(a7),a7
		tst.l	d0
		bpl	is_directory_true

		cmp.l	#ENOFILE,d0
		beq	is_directory_true
is_directory_false:
		moveq	#0,d0
		bra	is_directory_return

is_directory_true:
		moveq	#1,d0
is_directory_return:
		movem.l	(a7)+,a0-a3
		rts
*****************************************************************
werror_myname:
		move.l	a0,-(a7)
		lea	msg_myname(pc),a0
		bsr	werror
		movea.l	(a7)+,a0
		rts
*****************************************************************
werror_myname_and_msg:
		bsr	werror_myname
werror:
		movem.l	d0/a1,-(a7)
		movea.l	a0,a1
werror_1:
		tst.b	(a1)+
		bne	werror_1

		subq.l	#1,a1
		suba.l	a0,a1
		move.l	a1,-(a7)
		move.l	a0,-(a7)
		move.w	#2,-(a7)
		DOS	_WRITE
		lea	10(a7),a7
		movem.l	(a7)+,d0/a1
		rts
*****************************************************************
werror_newline:
		move.l	a0,-(a7)
		lea	msg_newline(pc),a0
		bsr	werror
		movea.l	(a7)+,a0
		rts
*****************************************************************
werror_myname_word_colon_msg:
		bsr	werror_myname_and_msg
		move.l	a0,-(a7)
		lea	msg_colon(pc),a0
		bsr	werror
		movea.l	a2,a0
		bsr	werror
		movea.l	(a7)+,a0
werror_newline_and_set_error:
		bsr	werror_newline
		moveq	#2,d6
		btst	#FLAG_e,d5
		bne	exit_program

		rts
*****************************************************************
perror:
		movem.l	d0/a2,-(a7)
		not.l	d0		* -1 -> 0, -2 -> 1, ...
		cmp.l	#25,d0
		bls	perror_2

		moveq	#0,d0
perror_2:
		lea	perror_table(pc),a2
		lsl.l	#1,d0
		move.w	(a2,d0.l),d0
		lea	sys_errmsgs(pc),a2
		lea	(a2,d0.w),a2
		bsr	werror_myname_word_colon_msg
		movem.l	(a7)+,d0/a2
		tst.l	d0
		rts
*****************************************************************
.data

	dc.b	0
	dc.b	'## mv 1.9 ##  Copyright(C)1992-95 by Itagaki Fumihiko',0

.even
perror_table:
	dc.w	msg_error-sys_errmsgs			*   0 ( -1)
	dc.w	msg_nofile-sys_errmsgs			*   1 ( -2)
	dc.w	msg_nofile-sys_errmsgs			*   2 ( -3)
	dc.w	msg_too_many_openfiles-sys_errmsgs	*   3 ( -4)
	dc.w	msg_dirvol-sys_errmsgs			*   4 ( -5)
	dc.w	msg_error-sys_errmsgs			*   5 ( -6)
	dc.w	msg_error-sys_errmsgs			*   6 ( -7)
	dc.w	msg_error-sys_errmsgs			*   7 ( -8)
	dc.w	msg_error-sys_errmsgs			*   8 ( -9)
	dc.w	msg_error-sys_errmsgs			*   9 (-10)
	dc.w	msg_error-sys_errmsgs			*  10 (-11)
	dc.w	msg_error-sys_errmsgs			*  11 (-12)
	dc.w	msg_bad_name-sys_errmsgs		*  12 (-13)
	dc.w	msg_error-sys_errmsgs			*  13 (-14)
	dc.w	msg_bad_drive-sys_errmsgs		*  14 (-15)
	dc.w	msg_error-sys_errmsgs			*  15 (-16)
	dc.w	msg_error-sys_errmsgs			*  16 (-17)
	dc.w	msg_error-sys_errmsgs			*  17 (-18)
	dc.w	msg_write_disabled-sys_errmsgs		*  18 (-19)	CREATE
	dc.w	msg_error-sys_errmsgs			*  19 (-20)
	dc.w	msg_error-sys_errmsgs			*  20 (-21)
	dc.w	msg_file_exists-sys_errmsgs		*  21 (-22)
	dc.w	msg_disk_full-sys_errmsgs		*  22 (-23)
	dc.w	msg_directory_full-sys_errmsgs		*  23 (-24)
	dc.w	msg_error-sys_errmsgs			*  24 (-25)
	dc.w	msg_error-sys_errmsgs			*  25 (-26)

sys_errmsgs:
msg_error:			dc.b	'�G���[',0
msg_nofile:			dc.b	'���̂悤�ȃt�@�C����f�B���N�g���͂���܂���',0
msg_dirvol:			dc.b	'�f�B���N�g�����{�����[���E���x���ł�',0
msg_too_many_openfiles:		dc.b	'�I�[�v�����Ă���t�@�C�����������܂�',0
msg_bad_name:			dc.b	'���O�������ł�',0
msg_bad_drive:			dc.b	'�h���C�u�̎w�肪�����ł�',0
msg_write_disabled:		dc.b	'�������݂�������Ă��܂���',0
msg_semicolon_directory_full:	dc.b	'; '
msg_directory_full:		dc.b	'�f�B���N�g�������t�ł�',0
msg_semicolon_file_exists:	dc.b	'; '
msg_file_exists:		dc.b	'�t�@�C�������݂��Ă��܂�',0
msg_disk_full:			dc.b	'�f�B�X�N�����t�ł�',0

msg_myname:			dc.b	'mv'
msg_colon:			dc.b	': ',0
msg_dos_version_mismatch:	dc.b	'�o�[�W����2.00�ȍ~��Human68k���K�v�ł�',CR,LF,0
msg_no_memory:			dc.b	'������������܂���',CR,LF,0
msg_illegal_option:		dc.b	'�s���ȃI�v�V���� -- ',0
msg_bad_arg:			dc.b	'����������������܂���',0
msg_too_few_args:		dc.b	'����������܂���',0
msg_too_long_pathname:		dc.b	'�p�X�������߂��܂�',0
msg_nodir:			dc.b	'�f�B���N�g��������܂���',0
msg_not_a_directory:		dc.b	'�f�B���N�g���ł͂���܂���',0
msg_destination:		dc.b	' �̈ړ��� ',0
msg_ni:				dc.b	' ��',0
msg_readonly:			dc.b	'�������݋֎~',0
msg_hidden:			dc.b	'�B��',0
msg_system:			dc.b	'�V�X�e��',0
msg_file:			dc.b	'�t�@�C��',0
msg_vollabel:			dc.b	'�{�����[���E���x��',0
msg_symlink:			dc.b	'�V���{���b�N�E�����N',0
msg_confirm_replace:		dc.b	'�����݂��Ă��܂��D�������Ĉړ����܂����H ',0
msg_wo:				dc.b	' �� ',0
msg_confirm_move:		dc.b	' �Ɉړ����܂����H ',0
msg_cannot_move:		dc.b	' �Ɉړ��ł��܂���',0
msg_directory_exists:		dc.b	'; �ړ���Ƀf�B���N�g�������݂��Ă��܂�',0
msg_cannot_move_dir_to_its_sub:	dc.b	'; �f�B���N�g�������̃T�u�f�B���N�g�����Ɉړ����邱�Ƃ͂ł��܂���',0
msg_cannot_move_dirvol_across:	dc.b	'; �f�B���N�g����{�����[���E���x����ʂ̃h���C�u�Ɉړ����邱�Ƃ͂ł��܂���',0
msg_cannot_move_current_dir:	dc.b	'; �e�h���C�u�̃J�����g�E�f�B���N�g�����ړ����邱�Ƃ͂ł��܂���',0
msg_drive_differ:		dc.b	'; �h���C�u���قȂ�܂�',0
msg_resume_dotdot_fail:		dc.b	'.. ���C���ł��܂���ł���',0
msg_could_not_remount:		dc.b	'umount����܂����i�����ł��܂���ł����j',0

msg_usage:			dc.b	CR,LF
	dc.b	'�g�p�@:  mv [-Ifiuvx] [-m <�����ύX��>] [--] <���p�X��> <�V�p�X��>',CR,LF
	dc.b	'         mv [-Iefiuvx] [-m <�����ύX��>] [--] <�t�@�C��> ... <�ړ���>',CR,LF,CR,LF
	dc.b	'         �����ύX��: {[ugoa]{{+-=}[ashrwx]}...}[,...] �܂��� 8�i���l�\��'
msg_newline:			dc.b	CR,LF
msg_nul:			dc.b	0
msg_arrow:			dc.b	' -> ',0
dos_wildcard_all:		dc.b	'*.*',0
dot_entry:			dc.b	'.          ',$10,0,0,0,0,0,0,0,0,0,0
dotdot_entry:			dc.b	'..         ',$10,0,0,0,0,0,0,0,0,0,0
*****************************************************************
.bss

.even
lndrv:			ds.l	1
copy_buffer_top:	ds.l	1
copy_buffer_size:	ds.l	1
.even
source_fatchkbuf:	ds.b	14+8			*  +8 : fatchk�o�O�΍�
.even
target_fatchkbuf:	ds.b	14+8			*  +8 : fatchk�o�O�΍�
.even
dpb_buffer:		ds.b	94
.even
filesbuf:		ds.b	STATBUFSIZE
.even
getsbuf:		ds.b	2+GETSLEN+1
pathname_buf:		ds.b	128
new_pathname:		ds.b	MAXPATH+1
assign_pathname:	ds.b	MAXPATH+1
nameck_buffer:		ds.b	91
drivename_buffer:	ds.b	3
stdin_is_terminal:	ds.b	1
source_mode:		ds.b	1
mode_mask:		ds.b	1
mode_plus:		ds.b	1
.even
			ds.b	STACKSIZE
.even
stack_bottom:
*****************************************************************

.end start
