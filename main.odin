#+vet explicit-allocators
package main

import "qui"
import rl "vendor:raylib"

clicked :: proc() -> bool {
	if rl.IsMouseButtonPressed(.LEFT) {
		return hovered()
	}
	return false
}

hovered :: proc() -> bool {
	id := qui.elem_id(qui.state.last_elem.?)
	prev_root_div := qui.state.prev_root_div.? or_return
	elem := qui.find_elem_by_id(prev_root_div, id).? or_return
	mouse_rect := qui._rect(rl.GetMousePosition(), 1)
	elem_rect := qui._rect(elem.position, elem.size)
	return rl.CheckCollisionRecs(mouse_rect, elem_rect)
}

// example user-space widget
button :: proc(text: string) -> bool {
	qui.text(
		text,
		padding = {16, 8},
		background_color = {0, 0, 0, 20},
	)
	qui.idx(69)  // temp
	return clicked()
}

main :: proc() {
	rl.SetTraceLogLevel(.WARNING)
	rl.SetConfigFlags({.WINDOW_RESIZABLE})
	rl.InitWindow(800, 600, "qui example")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)

	qui.init(context.allocator)
	defer qui.deinit()

	times: [dynamic]f64

	for !rl.WindowShouldClose() {
		qui.begin()

		//spotify()
		if qui.div_start() {
			if button("Add time") {
				append(&times, rl.GetTime())
			}
			if hovered() {
				qui.background_color({0, 0, 0, 30})
			}
			
			for time, time_idx in times {
				qui.text("%f", time, padding={8, 4})
				qui.idx(time_idx)
				if clicked() {
					ordered_remove(&times, time_idx)
				}
				if hovered() {
					qui.color(rl.RED)
					qui.background_color({0, 0, 0, 20})
				}
			}
		}

		qui.end()

		rl.BeginDrawing()
		rl.ClearBackground(rl.RAYWHITE)

		qui.draw()
		//rl.SetWindowTitle(rl.TextFormat("%d fps, %dkb mem", rl.GetFPS(), qui.get_frame_arena().offset/1024))
		rl.SetWindowTitle(rl.TextFormat(
			"%d fps, %dkb+%dkb mem (%v)",
			rl.GetFPS(),
			qui.state.a_frame_arena.offset/1024,
			qui.state.b_frame_arena.offset/1024,
			qui.state.using_a,
		))
		qui.aftercare()

		rl.EndDrawing()
	}
}

spotify :: proc() {
	top :: proc() {
		if qui.div_start(
			background_color = rl.RED,
			direction = .Horizontal,
			padding = 8,
			grow_cross = true,
			align_main = .SpaceBetween,
		) {
			if qui.div_start(gap=8, direction=.Horizontal) {
				qui.rect(32)
				qui.rect(32)
				qui.rect(32)
			}
			if qui.div_start(gap=8, direction=.Horizontal) {
				qui.rect(32)
				qui.rect({256, 32})
			}
			if qui.div_start(gap=8, direction=.Horizontal) {
				qui.rect(32)
				qui.rect(32)
				qui.rect(32)
			}
		}
	}

	middle :: proc() {
		if qui.div_start(
			// padding = 8,
			gap = 8,
			// background_color = rl.GREEN,
			direction = .Horizontal,
			grow_cross = true,
			grow_main = true,
			align_main = .SpaceBetween,
		) {
			if qui.div_start(
				background_color = rl.PINK,
				padding = 8,
				grow_cross = true,
				align_main = .Center,
			) {
				qui.rect(64)
			}
			if qui.div_start(
				background_color = rl.YELLOW,
				padding = 8,
				grow_main = true,
				align_cross = .Center,
				grow_cross = true,
				align_main = .Center,
			) {
				qui.rect(64)
			}
			if qui.div_start(
				background_color = rl.GOLD,
				padding = 8,
				grow_cross = true,
				align_main = .Center,
			) {
				qui.rect(64)
			}
		}
	}

	bottom :: proc() {
		if qui.div_start(
			background_color = rl.BLUE,
			direction = .Horizontal,
			padding = 8,
			grow_cross = true,
			align_main = .SpaceBetween,
			align_cross = .Center,
		) {
			if qui.div_start(
				gap = 8,
				direction = .Horizontal,
				align_cross = .Center,
			) {
				qui.rect(64)
				if qui.div_start(
					align_main = .SpaceBetween,
					grow_cross = true,
				) {
					qui.rect({128, 24})
					qui.rect({128, 16})
					qui.rect({128, 16})
				}
				qui.rect(32)
			}
			if qui.div_start(
				gap = 8,
				align_cross = .Center,
			) {
				if qui.div_start(
					direction = .Horizontal,
					gap = 8,
					align_cross = .Center,
				) {
					qui.rect(32)
					qui.rect(32)
					qui.rect(48)
					qui.rect(32)
					qui.rect(32)
				}
				if qui.div_start() {
					qui.rect({256, 4})
				}
			}
			if qui.div_start(gap=8, direction=.Horizontal) {
				qui.rect(32)
				qui.rect(32)
				qui.rect(32)
			}
		}
	}

	if qui.div_start(
		// const_size = {800, 600},
		const_size = window_size(),
		gap = 8,
	) {
		top()
		middle()
		bottom()
	}
}

window_size :: proc() -> [2]f32 {
	return {
		f32(rl.GetScreenWidth()),
		f32(rl.GetScreenHeight()),
	}
}
