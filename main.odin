#+vet explicit-allocators
package qui

import "core:fmt"
import rl "vendor:raylib"

main :: proc() {
	rl.SetTraceLogLevel(.WARNING)
	rl.InitWindow(800, 600, "window")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)

	init()
	defer deinit()

	times: [dynamic]f64

	for !rl.WindowShouldClose() {
		frame()

		div_start(); bg(rl.MAGENTA, .2)
			if button("[click me]") {
				fmt.println("!!!")
				append(&times, rl.GetTime())
			}
			div_start()
			for time, idx in times {
				text(fprintf("%.4f", time)); id(idx)
				if clicked() {
					ordered_remove(&times, idx)
				}
			}
			div_end()
		div_end()

		rl.BeginDrawing()
		rl.ClearBackground(rl.RAYWHITE)

		draw(do_after = true)

		rl.EndDrawing()
	}
}

button :: proc(txt: string) -> bool {
	text(txt); bg(.blue, 0.2)
	return clicked()
}

clicked :: proc() -> bool {
	elem := state.last_elem
	if rl.IsMouseButtonPressed(.LEFT) {
		if area, ok := state.ids[elem_id(elem)]; ok {
			return rl.CheckCollisionRecs(rect(rl.GetMousePosition(), 1), area)
		}
	}
	return false
}
