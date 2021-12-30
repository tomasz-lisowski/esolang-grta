(module
	(import	"host" "putc"
		(func	$putc
			(param i32)
		)
	)
	(import	"host" "getc"
		(func	$getc
			(result i32)
		)
	)
	(import	"host" "code"
		(memory	$code
			1
		)
	)

	;; GRTA state
	(global $ip (mut i32) (i32.const 0))
	(global $dp (mut i32) (i32.const 0x0000ffff))
	(global $dr (mut i32) (i32.const 0))
	(global $ln (mut i32) (i32.const 0))

	;; Encoding of every instruction
	(global $op_invb_enc i32 (i32.const 97))
	(global $op_andb_enc i32 (i32.const 98))
	(global $op_addb_enc i32 (i32.const 99))
	(global $op_getc_enc i32 (i32.const 49))
	(global $op_putc_enc i32 (i32.const 57))
	(global $op_frnt_enc i32 (i32.const 51))
	(global $op_back_enc i32 (i32.const 53))
	(global $op_cpuc_enc i32 (i32.const 55))

	(func	$mem_size			;; Returns size of memory with ID = mem_id in bytes
		(param $mem_id i32)		;; ID of memory to compute size of
		(result i32)			;; Returns size in bytes

		local.get	$mem_id
		memory.size
		i32.const	0x0000ffff
		i32.mul				;; 65535 * page_count
		return				;; TODO: Remove this
	)

	(func	$op_invb_ex
		global.get	$dp
		global.get	$dp
		i32.load8_u			;; cell_get(0)
		i32.const 	-1
		i32.xor				;; n ^ (-1) == ~n
		i32.store8
	)
	(func	$op_andb_ex
		global.get	$dp
		global.get	$dp
		i32.load8_u			;; cell_get(0)
		global.get	$dp
		i32.const	1
		i32.add
		i32.load8_u			;; cell_get(1)
		i32.and
		i32.store8
	)
	(func	$op_addb_ex
		global.get	$dp
		global.get	$dp
		i32.load8_s			;; cell_get(0)
		global.get	$dp
		i32.const	1
		i32.add
		i32.load8_s			;; cell_get(1)
		i32.add
		i32.store8
	)
	(func	$op_getc_ex
		global.get	$dp
		call		$getc
		i32.store8
	)
	(func	$op_putc_ex
		global.get	$dp
		i32.load8_u
		call		$putc
	)
	(func	$op_frnt_ex
		global.get	$dp
		i32.const	1
		i32.sub
		global.set	$dp
	)
	(func	$op_back_ex
		global.get	$dp
		i32.const	1
		i32.add
		global.set	$dp
	)
	(func	$op_cpuc_ex
		global.get 	$dp
		i32.load8_u
		i32.const	2
		i32.rem_u
		global.set	$dr		;; dr = cell_get(0) % 2

		global.get 	$dp
		i32.load8_u
		i32.const	8
		i32.rem_u			;; cell_get(0) % 8
		i32.const	2
		i32.div_u
		global.set	$ln		;; ln = (cell_get(0) % 8) / 2 and it's int div so is rounded down
	)

	(func	$decode_ex			;; Decode an opcode and execute it
		(param $op i32)			;; The operation to decode
		(result i32)			;; Returns 0 on success, 1 on failure

		block		$decode_end
		local.get	$op
		global.get	$op_invb_enc
		i32.eq
		if
		call		$op_invb_ex
		br		$decode_end
		end
		local.get	$op
		global.get	$op_andb_enc
		i32.eq
		if
		call		$op_andb_ex
		br		$decode_end
		end
		local.get	$op
		global.get	$op_addb_enc
		i32.eq
		if
		call		$op_addb_ex
		br		$decode_end
		end
		local.get	$op
		global.get	$op_getc_enc
		i32.eq
		if
		call		$op_getc_ex
		br		$decode_end
		end
		local.get	$op
		global.get	$op_putc_enc
		i32.eq
		if
		call		$op_putc_ex
		br		$decode_end
		end
		local.get	$op
		global.get	$op_frnt_enc
		i32.eq
		if
		call		$op_frnt_ex
		br		$decode_end
		end
		local.get	$op
		global.get	$op_back_enc
		i32.eq
		if
		call		$op_back_ex
		br		$decode_end
		end
		local.get	$op
		global.get	$op_cpuc_enc
		i32.eq
		if
		call		$op_cpuc_ex
		br		$decode_end
		end
		;; Bad instruction
		i32.const	1		;; ERROR_FAILURE
		return
		end				;; @decode_end
		i32.const	0
	)

	(func	$execute			;; Execute all instructions in code memory
		(result i32)			;; 0 on success, 1 on failure

		;; Init instruction pointer
		i32.const	5
		global.set	$ip		;; IP = 5 (first instruction after magic + '\n')

		;; Execute code
		block		$loop_end
		loop		$loop_start	;; @loop_start

		;; call		$breakpoint	;; Breakpoint before executing instruction

		block		$decode_success
		global.get	$ip
		global.get	$ln
		i32.add				;; IP + LN gives the op from selected lane
		i32.load8_u			;; Load op
		call		$decode_ex
		i32.eqz				;; Did decode succeed?
		br_if		$decode_success
		i32.const	1		;; EXIT_FAILURE
		return
		end				;; @decode_success

		;; Update IP
		block		$ip_updated
		block		$ip_not_updated
		global.get	$dr
		i32.eqz
		if				;; Direction is FORWARD
		global.get	$ip
		i32.const	9		;; '\n' expected at end of next line
		i32.add
		i32.load8_u
		i32.const	10		;; '\n'
		i32.ne				;; Validate that last char of line is '\n'
		br_if		$ip_not_updated
		global.get	$ip
		i32.const	5
		i32.add
		global.set 	$ip		;; IP += 5 (4 ops and '\n')
		br		$ip_updated
		else				;; Direction is BACKWARD
		global.get	$ip
		i32.const	1		;; '\n' expected before start of current line (end of previous line)
		i32.sub
		i32.load8_u
		i32.const	10		;; '\n'
		i32.ne				;; Validate that last char of line is '\n'
		br_if		$ip_not_updated
		global.get	$ip
		i32.const	5
		i32.sub
		global.set 	$ip		;; IP -= 5 (4 ops and '\n')
		br		$ip_updated
		end
		end				;; @ip_not_updated
		i32.const	1		;; ERROR_FAILURE
		return
		end				;; @ip_updated

		;; Check if reached end of code memory
		global.get	$ip
		i32.const	0		;; TODO: How to push $code here instead of the ID equivalent to it?
		call		$mem_size
		i32.le_u			;; IP <= code.size
		br_if		$loop_start	;; Did not reach end?
		end
		end				;; @loop_end
		i32.const	0
	)

	(func	$main
		(export "main")
		(result i32)

		;; Check magic number
		block		$magic_good
		block		$magic_bad
		i32.const	0
		i32.load			;; Load magic number
		i32.const	0x41545247	;; Magic number "GRTA"
		i32.eq				;; Magic == "GRTA"
		br_if		$magic_good	;; Is magic valid?
		end				;; @magic_bad
		i32.const	1		;; EXIT_FAILURE
		return
		end				;; @magic_good

		call		$execute
	)

	;; DEBUG ;; DEBUG ;; DEBUG ;; DEBUG ;; DEBUG ;; DEBUG ;; DEBUG ;; DEBUG ;;
	;; BELOW ;; BELOW ;; BELOW ;; BELOW ;; BELOW ;; BELOW ;; BELOW ;; BELOW ;;
	;; DEBUG ;; DEBUG ;; DEBUG ;; DEBUG ;; DEBUG ;; DEBUG ;; DEBUG ;; DEBUG ;;
	;; BELOW ;; BELOW ;; BELOW ;; BELOW ;; BELOW ;; BELOW ;; BELOW ;; BELOW ;;

	(func	$pause				;; Pause GRTA
		call		$getc		;; Unpause by pressing enter
		drop				;; Drop user input
	)

	(func	$breakpoint			;; Pause and print out debug info
		i32.const	58		;; ':'
		i32.const	112		;; 'p'
		i32.const	111		;; 'o'
		call		$putc
		call		$putc
		call		$putc

		global.get	$ip
		global.get	$ln
		i32.add
		i32.load8_u			;; OP being executed now
		call		$decode_print

		i32.const	32		;; ' '
		call		$putc

		i32.const	58		;; ':'
		i32.const	108		;; 'l'
		i32.const	108		;; 'l'
		i32.const	101		;; 'e'
		i32.const	99		;; 'c'
		call		$putc
		call		$putc
		call		$putc
		call		$putc
		call		$putc

		global.get	$dp
		i32.load8_u			;; Cell selected now
		call		$byte2hex
		call		$putc
		call		$putc

		i32.const	32		;; ' '
		call		$putc

		i32.const	58		;; ':'
		i32.const	112		;; 'p'
		i32.const	105		;; 'i'
		call		$putc
		call		$putc
		call		$putc

		global.get	$ip
		call		$print_i32

		i32.const	32		;; ' '
		call		$putc

		i32.const	58		;; ':'
		i32.const	112		;; 'p'
		i32.const	100		;; 'd'
		call		$putc
		call		$putc
		call		$putc

		global.get	$dp
		call		$print_i32

		i32.const	32		;; ' '
		call		$putc

		i32.const	58		;; ':'
		i32.const	114		;; 'r'
		i32.const	100		;; 'd'
		call		$putc
		call		$putc
		call		$putc

		global.get	$dr
		call		$print_i32

		i32.const	32		;; ' '
		call		$putc

		i32.const	58		;; ':'
		i32.const	110		;; 'n'
		i32.const	108		;; 'l'
		call		$putc
		call		$putc
		call		$putc

		global.get	$ln
		call		$print_i32


		;; call		$pause
		call		$print_lf	;; Uncomment and comment call to non-blocking debug run
	)

        (func	$decode_print			;; Decode an opcode and print it
		(param $op i32)			;; The operation to decode

		block		$decode_end
		local.get	$op
		global.get	$op_invb_enc
		i32.eq
		if
		i32.const	66		;; 'B'
		i32.const	86		;; 'V'
		i32.const	78		;; 'N'
		i32.const	73		;; 'I'
		call		$putc
		call		$putc
		call		$putc
		call		$putc
		br		$decode_end
		end
		local.get	$op
		global.get	$op_andb_enc
		i32.eq
		if
		i32.const	66		;; 'B'
		i32.const	68		;; 'D'
		i32.const	78		;; 'N'
		i32.const	65		;; 'A'
		call		$putc
		call		$putc
		call		$putc
		call		$putc
		br		$decode_end
		end
		local.get	$op
		global.get	$op_addb_enc
		i32.eq
		if
		i32.const	66		;; 'B'
		i32.const	68		;; 'D'
		i32.const	68		;; 'D'
		i32.const	65		;; 'A'
		call		$putc
		call		$putc
		call		$putc
		call		$putc
		br		$decode_end
		end
		local.get	$op
		global.get	$op_getc_enc
		i32.eq
		if
		i32.const	67		;; 'C'
		i32.const	84		;; 'T'
		i32.const	69		;; 'E'
		i32.const	71		;; 'G'
		call		$putc
		call		$putc
		call		$putc
		call		$putc
		br		$decode_end
		end
		local.get	$op
		global.get	$op_putc_enc
		i32.eq
		if
		i32.const	67		;; 'C'
		i32.const	84		;; 'T'
		i32.const	85		;; 'U'
		i32.const	80		;; 'P'
		call		$putc
		call		$putc
		call		$putc
		call		$putc
		br		$decode_end
		end
		local.get	$op
		global.get	$op_frnt_enc
		i32.eq
		if
		i32.const	84		;; 'T'
		i32.const	78		;; 'N'
		i32.const	82		;; 'R'
		i32.const	70		;; 'F'
		call		$putc
		call		$putc
		call		$putc
		call		$putc
		br		$decode_end
		end
		local.get	$op
		global.get	$op_back_enc
		i32.eq
		if
		i32.const	75		;; 'K'
		i32.const	67		;; 'C'
		i32.const	65		;; 'A'
		i32.const	66		;; 'B'
		call		$putc
		call		$putc
		call		$putc
		call		$putc
		br		$decode_end
		end
		local.get	$op
		global.get	$op_cpuc_enc
		i32.eq
		if
                i32.const	67		;; 'C'
		i32.const	85		;; 'U'
		i32.const	80		;; 'P'
		i32.const	67		;; 'C'
		call		$putc
		call		$putc
		call		$putc
		call		$putc
		br		$decode_end
		end
		;; Bad instruction
		local.get	$op
		call		$byte2hex
		i32.const	48		;; '0'
		i32.const	48		;; '0'
		call		$putc
		call		$putc
		call		$putc
		call		$putc
		end				;; @decode_end
	)

        (func	$byte2hex			;; Convert byte to a hex string 0x??
		(param $byte i32)		;; Byte to convert (does not need to have leading bytes as 0's)
		(result i32 i32)		;; Two hex digits
		(local $b0 i32)			;; Temporary for hex digit 0
		(local $b1 i32)			;; Temporary for hex digit 1

		local.get	$byte
		i32.const	0x0000000ff
		i32.and
		local.set	$b0

		local.get	$b0
		i32.const	16
		i32.div_u			;; Get value of first digit
		local.get	$b0
		i32.const	16
		i32.rem_u			;; Get value of second digit
		local.set	$b1
		local.set	$b0

		;; Compute hex digit chars
		local.get	$b0
		i32.const	10
		i32.lt_u			;; b0 < 10
		if				;; Hex digit in number range
		local.get	$b0
		i32.const	48		;; '0'
		i32.add
		local.set	$b0		;; b0 = b0 + '0'
		else				;; Hex digit in letter range
		local.get	$b0
		i32.const	55		;; 'A' - 10
		i32.add
		local.set	$b0		;; b0 = b0 + ('A' - 10)
		end
		local.get	$b1
		i32.const	10
		i32.lt_u			;; b1 < 10
		if				;; Hex digit in number range
		local.get	$b1
		i32.const	48		;; '0'
		i32.add
		local.set	$b1		;; b1 = b1 + '0'
		else				;; Hex digit in letter range
		local.get	$b1
		i32.const	55		;; 'A' - 10
		i32.add
		local.set	$b1		;; b1 = b1 + ('A' - 10)
		end

		local.get	$b1
		local.get	$b0
	)

	(func	$print_lf			;; Print newline char
		i32.const	10		;; '\n'
		call		$putc
	)

	(func	$print_i32			;; Function index
		(param $n i32)			;; Number to print

		local.get	$n
		i32.const	24
		i32.rotr
		call		$byte2hex
		call		$putc
		call		$putc

		local.get	$n
		i32.const	16
		i32.rotr
		call		$byte2hex
		call		$putc
		call		$putc

		local.get	$n
		i32.const	8
		i32.rotr
		call		$byte2hex
		call		$putc
		call		$putc

		local.get	$n
		call		$byte2hex
		call		$putc
		call		$putc
	)
)
