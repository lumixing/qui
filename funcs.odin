#+vet explicit-allocators
package qui

import "core:slice"
import rl "vendor:raylib"

div_start :: proc(dir: Direction = .Vertical) {
	elem := new(Element, state.frame_allocator)
	div := new(Div, state.frame_allocator)
	div.style.direction = dir
	//(&elem.widget.(^Div))^ = div  // a === (&a)^ (cant inline..)
	elem.widget = div  // im actually stupid
	append(&state.div_stack, elem)
	state.last_elem = elem
}

div_end :: proc() {
	context.allocator = state.frame_allocator
	assert(len(state.div_stack) != 0, "too many div_ends")
	div := pop(&state.div_stack)
	if len(state.div_stack) == 0 {
		state.last_div = div
		return
	}
	parent_div, ok := slice.last(state.div_stack[:]).widget.(^Div)
	assert(ok, "parent has to be a div")
	append(&parent_div.children, div)
}

text :: proc(text: string) {
	context.allocator = state.frame_allocator
	div, ok := slice.last(state.div_stack[:]).widget.(^Div)
	assert(ok, "parent has to be a div")
	elem := new(Element, state.frame_allocator)
	wid := new(Text, state.frame_allocator)
	wid.text = text
	wid.style.color = .black
	elem.widget = wid
	append(&div.children, elem)
	state.last_elem = elem
}

BasicColor :: enum {
	black,
	white,
	red,
	green,
	blue,
}

Color :: union {
	BasicColor,
	rl.Color,
}

_color :: proc(c: Color) -> rl.Color {
	switch c in c {
	case BasicColor:
		switch c {
		case .black: return {0, 0, 0, 255}
		case .white: return {255, 255, 255, 255}
		case .red:   return {255, 0, 0, 255}
		case .green:  return {0, 255, 0, 255}
		case .blue: return {0, 0, 255, 255}
		}
	case rl.Color:
		return c
	}

	return {}
}

_color_alpha :: #force_inline proc(c: Color, a: f32) -> Color {
	return rl.ColorAlpha(_color(c), a)
}

bg :: proc(color: Color, alpha: f32 = 1) {
	state.last_elem.style.background_color = _color_alpha(color, alpha)
}

id :: proc(idx: int) {
	state.last_elem.idx = idx
}
