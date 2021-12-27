(module
	(import	"host" "putc"
		(func
			$putc
			(param i32)
		)
	)
	(import	"host" "code"
		(memory
			$code
			1
		)
	)

	(func	$mem_size			;; Returns size of memory with ID = mem_id in bytes
		(param $mem_id i32)		;; ID of memory to compute size of
		(result i32)			;; Returns size in bytes

		local.get	$mem_id
		memory.size
		i32.const	0x0000ffff
		i32.mul				;; 65535 * page_count
		return				;; TODO: Remove this
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
		i32.const	48		;; ASCII '0'
		i32.add
		local.set	$b0		;; b0 = b0 + '0'
		else				;; Hex digit in letter range
		local.get	$b0
		i32.const	55		;; ASCII 'A' - 10
		i32.add
		local.set	$b0		;; b0 = h0 + ('A' - 10)
		end
		local.get	$b1
		i32.const	10
		i32.lt_u			;; b1 < 10
		if				;; Hex digit in number range
		local.get	$b1
		i32.const	48		;; ASCII '0'
		i32.add
		local.set	$b1		;; b1 = b1 + '0'
		else				;; Hex digit in letter range
		local.get	$b1
		i32.const	55		;; ASCII 'A' - 10
		i32.add
		local.set	$b1		;; b1 = b1 + ('A' - 10)
		end

		local.get	$b1
		local.get	$b0
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

		i32.const	10		;; ASCII '\n'
		call		$putc
	)

	(func	$op_0
		i32.const	97		;; ASCII 'a'
		call		$putc
	)
	(func	$op_1
		i32.const	98		;; ASCII 'b'
		call		$putc
	)
	(func	$op_2
		i32.const	99		;; ASCII 'c'
		call		$putc
	)
	(func	$op_3
		i32.const	100		;; ASCII 'd'
		call		$putc
	)

	(func	$decode				;; Decode an opcode
		(param $op i32)			;; The operation to decode
		(result i32)			;; Returns 0 on success, 1 on failure

		block		$decode_end
		local.get	$op
		i32.const	97		;; ASCII 'a'
		i32.eq
		if
		call		$op_0
		br		$decode_end
		end
		local.get	$op
		i32.const	98		;; ASCII 'b'
		i32.eq
		if
		call		$op_1
		br		$decode_end
		end
		local.get	$op
		i32.const	99		;; ASCII 'c'
		i32.eq
		if
		call		$op_2
		br		$decode_end
		end
		local.get	$op
		i32.const	100		;; ASCII 'd'
		i32.eq
		if
		call		$op_3
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
		(local $ip i32)			;; Local for pointing into code memory

		;; Init instruction pointer
		i32.const	4
		local.set	$ip		;; IP = 4 (first instruction after magic)

		;; Execute code
		block		$loop_end
		loop		$loop_start	;; @loop_start

		block		$decode_success
		local.get	$ip
		i32.load8_u			;; Load op
		call		$decode
		i32.eqz				;; Did decode succeed?
		br_if		$decode_success
		i32.const	1		;; EXIT_FAILURE
		return
		end				;; @decode_success

		;; Increment IP
		local.get	$ip
		i32.const	1
		i32.add				;; IP += 1
		local.set 	$ip

		;; Check if reached end of code memory
		local.get	$ip
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
)
