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

		if qui.div_start(const_size = {800, 600}) {
			if qui.div_start(
				background_color = rl.RED,
				direction = .Horizontal,
				padding = 8,
				grow_main = true,
				align_main = .SpaceBetween,
			) {
				if qui.div_start(gap=8, direction=.Horizontal) {
					qui.rect(32)
					qui.rect(32)
					qui.rect(32)
				}
				if qui.div_start(gap=8, direction=.Horizontal) {
					qui.rect(32)
					qui.rect(32)
					qui.rect(32)
				}
				if qui.div_start(gap=8, direction=.Horizontal) {
					qui.rect(32)
					qui.rect(32)
					qui.rect(32)
				}
			}

			if qui.div_start(
				padding = 8,
				background_color = rl.GREEN,
				direction = .Horizontal,
				grow_main = true,
				// grow_cross = true,
			) {
				if qui.div_start(
					background_color = rl.PINK,
					padding = 8,
				) {
					qui.rect(64)
				}
				if qui.div_start(
					background_color = rl.YELLOW,
					padding = 8,
					grow_cross = true,
					align_cross = .Center,
				) {
					qui.rect(64)
				}
				if qui.div_start(
					background_color = rl.GOLD,
					padding = 8,
				) {
					qui.rect(64)
				}
			}

			if qui.div_start(
				background_color = rl.BLUE,
				direction = .Horizontal,
				padding = 8,
				grow_main = true,
				align_main = .SpaceBetween,
			) {
				if qui.div_start(gap=8, direction=.Horizontal) {
					qui.rect(32)
					qui.rect(32)
					qui.rect(32)
				}
				if qui.div_start(gap=8, direction=.Horizontal) {
					qui.rect(32)
					qui.rect(32)
					qui.rect(32)
				}
				if qui.div_start(gap=8, direction=.Horizontal) {
					qui.rect(32)
					qui.rect(32)
					qui.rect(32)
				}
			}
		}

		qui.elem_size(qui.state.root_div.?)
		qui.elem_size2(qui.state.root_div.?, nil, 0)
		qui.elem_position(qui.state.root_div.?, 0)

		rl.BeginDrawing()
		rl.ClearBackground(rl.RAYWHITE)

		qui.elem_draw(qui.state.root_div.?, rl.IsKeyDown(.GRAVE))
		rl.SetWindowTitle(rl.TextFormat("%d fps, %dkb mem", rl.GetFPS(), qui.state.frame_arena.offset/1024))

		free_all(qui.state.frame_allocator)

		rl.EndDrawing()

		// if rl.IsKeyPressed(.GRAVE) {
		// 	dbgf(qui.state.root_div)
		// 	break
		// }
	}
}

dbgf :: proc(v: $T, vv := #caller_expression) {
	fmt.printfln("%v = %#v", vv, v)
}