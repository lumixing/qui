package main

import "core:fmt"
import "qui"
import rl "vendor:raylib"

main :: proc() {
	rl.SetTraceLogLevel(.WARNING)
	rl.InitWindow(800, 600, "qui example")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)

	qui.init()

	for !rl.WindowShouldClose() {
		qui.begin()

		qui.div_start()
			qui.div_start(
				direction = .Horizontal,
				padding = 8,
				gap = 8,
				background_color = rl.RED,
			)
				qui.rect(64)
				qui.rect(64)
				qui.rect(64)
			qui.div_end()
		qui.div_end()

		qui.elem_size(qui.state.root_div.?)
		qui.elem_position(qui.state.root_div.?, 0)

		rl.BeginDrawing()
		rl.ClearBackground(rl.RAYWHITE)

		qui.elem_draw(qui.state.root_div.?)

		rl.EndDrawing()

		if rl.IsKeyPressed(.GRAVE) {
			dbgf(qui.state.root_div)
			break
		}
	}
}

dbgf :: proc(v: $T, vv := #caller_expression) {
	fmt.printfln("%v = %#v", vv, v)
}