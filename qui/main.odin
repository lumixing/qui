#+vet explicit-allocators
package qui

import "core:fmt"
import "base:runtime"
import "core:mem"
import rl "vendor:raylib"

@(private)
vec2 :: [2]f32

//@(private)
state: struct {
	main_allocator: mem.Allocator,

	a_frame_buffer: []byte,
	a_frame_arena: mem.Arena,
	a_frame_allocator: mem.Allocator,

	b_frame_buffer: []byte,
	b_frame_arena: mem.Arena,
	b_frame_allocator: mem.Allocator,

	using_a: bool,
	frame_allocator: mem.Allocator,

	font: rl.Font,
	root_div: Maybe(^Element),
	prev_root_div: Maybe(^Element),
	div_stack: [dynamic]^Element,
	last_elem: Maybe(^Element),
}

print_elem_tree :: proc(elem: ^Element, depth := 0) {
	for _ in 0..<depth {
		fmt.print("_   ")
	}
	switch widget in elem.widget {
	case Div:  fmt.print("Div")
	case Rect: fmt.print("Rect")
	case Text: fmt.print("Text")
	}
	fmt.printfln("(%q)", elem.id)
	#partial switch widget in elem.widget {
	case Div:
		for child in widget.children {
			print_elem_tree(child, depth+1)
		}
	}
}

find_elem_by_id :: proc(elem: ^Element, id: string) -> Maybe(^Element) {
	if elem_id(elem) == id {
		return elem
	}

	#partial switch &widget in elem.widget {
	case Div:
		for child in widget.children {
			e := find_elem_by_id(child, id).? or_continue
			return e
		}
	}

	return nil
}

get_frame_arena :: proc() -> mem.Arena {
	return state.using_a ? state.a_frame_arena : state.b_frame_arena
}

init :: proc(
	allocator := context.allocator,
	arena_size := 4 * mem.Megabyte,
) {
	state.main_allocator = allocator

	state.a_frame_buffer = make([]byte, arena_size, state.main_allocator)
	mem.arena_init(&state.a_frame_arena, state.a_frame_buffer)
	state.a_frame_allocator = mem.arena_allocator(&state.a_frame_arena)

	state.b_frame_buffer = make([]byte, arena_size, state.main_allocator)
	mem.arena_init(&state.b_frame_arena, state.b_frame_buffer)
	state.b_frame_allocator = mem.arena_allocator(&state.b_frame_arena)

	state.using_a = true
	state.frame_allocator = state.a_frame_allocator

	state.font = rl.LoadFontEx("inter.ttf", 24, nil, 0)
	state.div_stack = make([dynamic]^Element, state.main_allocator)
}

deinit :: proc() {
	delete(state.a_frame_buffer, state.main_allocator)
	delete(state.b_frame_buffer, state.main_allocator)
	delete(state.div_stack)
	rl.UnloadFont(state.font)
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
	state.prev_root_div = state.root_div
	if state.using_a {
		free_all(state.b_frame_allocator)
		state.frame_allocator = state.b_frame_allocator
	} else {
		free_all(state.a_frame_allocator)
		state.frame_allocator = state.a_frame_allocator
	}
	state.using_a = !state.using_a
}

//@(private)
_rect :: proc(pos, size: vec2) -> rl.Rectangle {
	return {pos.x, pos.y, size.x, size.y}
}

@(private)
elem_draw :: proc(elem: ^Element, debug := false) {
	// hack
	//#partial switch widget in elem.widget {
	//case Text:
	//	rl.DrawRectangleV(elem.position-elem.style.padding, elem.size, elem.style.background_color)
	//case:
		rl.DrawRectangleV(elem.position, elem.size, elem.style.background_color)
	//}

	if debug {
		rl.DrawRectangleLinesEx(_rect(elem.position, elem.size), 1, rl.MAGENTA)
		rl.DrawRectangleLinesEx(_rect(elem.position+elem.style.padding, inner_size(elem)), 1, rl.MAGENTA)
	}

	switch widget in elem.widget {
	case Div:
		for child in widget.children {
			elem_draw(child, debug)
		}
	case Rect:  // nothing to do
	case Text:
		SPACING :: 1
		rl.DrawTextEx(
			state.font, rl.TextFormat("%s", widget.text),
			elem.position+elem.style.padding, f32(state.font.baseSize),
			SPACING, widget.style.color,
		)
	}
}

//@(private)
dbgf :: proc(v: $T, vv := #caller_expression) {
	fmt.printfln("%v = %#v", vv, v)
}
