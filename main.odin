#+vet explicit-allocators
package main

import "core:mem"
import "core:fmt"
import "qui"
import rl "vendor:raylib"

main :: proc() {
	rl.SetTraceLogLevel(.WARNING)
	rl.InitWindow(800, 600, "qui example")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)

	qui.init(context.allocator)
	defer qui.deinit()

	for !rl.WindowShouldClose() {

		qui.begin()

		qui.div_start(
			gap = 1,
		)
			for _ in 0..<32 {
				qui.div_start(
					direction = .Horizontal,
					gap = 1,
				)
				for _ in 0..<32 {
					qui.rect(16)
				}
				qui.div_end()
			}
		qui.div_end()

		qui.elem_size(qui.state.root_div.?)
		qui.elem_position(qui.state.root_div.?, 0)

		rl.BeginDrawing()
		rl.ClearBackground(rl.RAYWHITE)

		qui.elem_draw(qui.state.root_div.?)
		rl.SetWindowTitle(rl.TextFormat("%d fps, %dkb mem", rl.GetFPS(), qui.state.frame_arena.offset/1024))

		free_all(qui.state.frame_allocator)

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