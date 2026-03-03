#+vet explicit-allocators
package main

import "qui"
import rl "vendor:raylib"

main :: proc() {
	rl.SetTraceLogLevel(.WARNING)
	rl.SetConfigFlags({.WINDOW_RESIZABLE})
	rl.InitWindow(800, 600, "qui example")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)

	qui.init(context.allocator)
	defer qui.deinit()

	for !rl.WindowShouldClose() {
		qui.begin()

		spotify()

		qui.end()

		rl.BeginDrawing()
		rl.ClearBackground(rl.RAYWHITE)

		qui.draw()
		rl.SetWindowTitle(rl.TextFormat("%d fps, %dkb mem", rl.GetFPS(), qui.state.frame_arena.offset/1024))
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