#+vet explicit-allocators
package qui

import "core:fmt"
import rl "vendor:raylib"

main :: proc() {
	rl.SetTraceLogLevel(.WARNING)
	rl.InitWindow(800, 600, "httpussy v0.1d")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)

	init()
	defer deinit()

	times: [dynamic]f64
	url: string

	for !rl.WindowShouldClose() {
		frame()

		/*div_start()
		//; bg(rl.MAGENTA, .2)
			button("[click me]"); pad({12, 8})
			if clicked() {
				fmt.println("!!!")
				append(&times, rl.GetTime()*4)
			}
			div_start(); grow_width()
			for time, idx in times {
				text(fprintf("%.4f", time))
					; id(idx); bg(idx%2==0 ? .red : .green, 0.2)
					; pad({12, 8}/2); grow_width()
				if clicked() {
					ordered_remove(&times, idx)
				}
			}
			div_end()
		div_end()*/

		div_start()
			text("httpussy: an ultimate request tool made by lumix")
			if input(&url, "enter a url") {
				fmt.printfln("you submited %q", url)
			}
		div_end()

		rl.BeginDrawing()
		rl.ClearBackground(rl.RAYWHITE)

		draw(do_after = true, debug = rl.IsKeyDown(.GRAVE))

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
