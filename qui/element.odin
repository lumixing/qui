#+vet explicit-allocators
package qui

import "core:fmt"
import "core:slice"
import rl "vendor:raylib"

Element :: struct {
	position: vec2,
	size: vec2,  // includes padding
	widget: Widget,
	style: Style,
	id: string,
	idx: int,
}

idx :: proc(idx: int) {
	state.last_elem.?.idx = idx
}

Style :: struct {
	background_color: rl.Color,
	padding: vec2,
}

Widget :: union #no_nil {
	Div,
	Rect,
	Text,
}

Div :: struct {
	children: [dynamic]^Element,
	style: struct {
		direction: Direction,
		gap: f32,
		const_size: vec2,
		align_main: Align,
		align_cross: Align,

		// these depend on *parent* (not current) direction
		grow_main: bool,
		grow_cross: bool,
	},
}

Align :: enum {
	Start,
	End,
	Center,
	SpaceBetween,
}

Direction :: enum {
	Vertical,
	Horizontal,
}

@(require_results)  // guard for not in if
@(deferred_none=div_end)
// use this is an if statement like
// if div_start() { rect() }
// so it does div_end automatically
div_start :: proc(
	direction := Direction.Vertical,
	gap: f32 = 0,
	padding: f32 = 0,
	background_color := rl.BLANK,
	const_size: vec2 = -1,  // -1 means no const size (here on both axes)
	align_main := Align.Start,
	align_cross := Align.Start,
	grow_main := false,
	grow_cross := false,
) -> bool {
	elem := new(Element, state.frame_allocator)
	div: Div
	div.children = make([dynamic]^Element, state.frame_allocator)
	div.style.direction = direction
	div.style.gap = gap
	div.style.const_size = const_size
	div.style.align_main = align_main
	div.style.align_cross = align_cross
	div.style.grow_main = grow_main
	div.style.grow_cross = grow_cross
	elem.widget = div
	elem.style.padding = padding
	elem.style.background_color = background_color
	append(&state.div_stack, elem)
	state.last_elem = elem
	return true
}

div_end :: proc() {
	assert(len(state.div_stack) != 0)
	elem := pop(&state.div_stack)
	if len(state.div_stack) == 0 {
		state.root_div = elem
		return
	}
	last_div_elem := slice.last(state.div_stack[:])
	last_div := &last_div_elem.widget.(Div)
	append(&last_div.children, elem)
}

Rect :: struct {

}

rect :: proc(size: vec2, color := rl.BLACK) {
	elem := new(Element, state.frame_allocator)
	rect: Rect
	elem.widget = rect
	elem.size = size
	elem.style.background_color = color
	last_div_elem := slice.last(state.div_stack[:])
	last_div := &last_div_elem.widget.(Div)
	append(&last_div.children, elem)
	state.last_elem = elem
}

Text :: struct {
	text: string,
	style: struct {
		color: rl.Color,
	},
}

text :: proc(
	fmtstr: string,
	args: ..any,
	color := rl.BLACK,
	background_color := rl.BLANK,
	padding: vec2 = 0,
) {
	elem := new(Element, state.frame_allocator)
	text: Text
	text.text = fmt.aprintf(fmtstr, ..args, allocator = state.frame_allocator)
	text.style.color = color
	elem.widget = text
	elem.style.background_color = background_color
	elem.style.padding = padding
	last_div_elem := slice.last(state.div_stack[:])
	last_div := &last_div_elem.widget.(Div)
	append(&last_div.children, elem)
	state.last_elem = elem
}
