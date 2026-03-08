#+vet explicit-allocators
package qui

import "core:fmt"
import "base:runtime"
import "core:mem"
import rl "vendor:raylib"

@(private)
vec2 :: [2]f32

@(private)
state: struct {
	main_allocator: mem.Allocator,

	frame_buffer: []byte,
	frame_arena: mem.Arena,
	frame_allocator: mem.Allocator,

	font: rl.Font,
	root_div: Maybe(^Element),
	prev_root_div: Maybe(^Element),
	div_stack: [dynamic]^Element,
	last_elem: Maybe(^Element),
}

get_frame_arena :: proc() -> mem.Arena {
	return state.frame_arena
}

init :: proc(
	allocator := context.allocator,
	arena_size := 4 * mem.Megabyte,
) {
	state.main_allocator = allocator

	state.frame_buffer = make([]byte, arena_size, state.main_allocator)
	mem.arena_init(&state.frame_arena, state.frame_buffer)
	state.frame_allocator = mem.arena_allocator(&state.frame_arena)

	// state.font = rl.LoadFontEx("inter.ttf", 24, nil, 0)
	state.div_stack = make([dynamic]^Element, state.main_allocator)
}

deinit :: proc() {
	delete(state.frame_buffer, state.main_allocator)
	delete(state.div_stack)
	// rl.UnloadFont(state.font)
}

begin :: proc() {
	state.root_div = nil
	clear(&state.div_stack)
	state.last_elem = nil
}

end :: proc() {
	// apply the passes
	elem_size(state.root_div.?)
	elem_size2(state.root_div.?, nil, 0)
	elem_position(state.root_div.?, 0)
	elem_id_pass(state.root_div.?)
}

draw :: proc() {
	elem_draw(state.root_div.?, rl.IsKeyDown(.GRAVE))
}

aftercare :: proc() {
	free_all(state.frame_allocator)
}

@(private)
_rect :: proc(pos, size: vec2) -> rl.Rectangle {
	return {pos.x, pos.y, size.x, size.y}
}

@(private)
elem_draw :: proc(elem: ^Element, debug := false) {
	rl.DrawRectangleV(elem.position, elem.size, elem.style.background_color)
	// rl.DrawRectangleV(elem.position-elem.style.padding, elem.size, elem.style.background_color)
	if debug {
		rl.DrawRectangleLinesEx(_rect(elem.position, elem.size), 1, rl.MAGENTA)
		rl.DrawRectangleLinesEx(_rect(elem.position+elem.style.padding, inner_size(elem)), 1, rl.MAGENTA)
	}

	switch widget in elem.widget {
	case Div:
		for &child in widget.children {
			elem_draw(&child, debug)
		}
	case Rect:  // nothing to do
	}
}

@(private)
dbgf :: proc(v: $T, vv := #caller_expression) {
	fmt.printfln("%v = %#v", vv, v)
}
