(module
	(import "host" "putc" (func $putc (param i32)))
	(import "host" "code" (memory $code 1))

	(table $ops 16 funcref)

	(func $main (export "main") (result i32)
		(call $putc (i32.const 65))
		(i32.const 0)
	)
)
