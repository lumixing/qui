#+vet explicit-allocators
package qui

import "core:fmt"
import "core:slice"
import "base:runtime"
import rl "vendor:raylib"

vec2 :: [2]f32

state: struct {
	allocator: runtime.Allocator,
	font: rl.Font,
	root_div: Maybe(^Element),
	prev_root_div: Maybe(^Element),
	div_stack: [dynamic]^Element,
	last_elem: Maybe(^Element),
}

// todo: cleanup
init :: proc(allocator := context.allocator) {
	state.allocator = allocator
	state.font = rl.LoadFontEx("inter.ttf", 24, nil, 0)
	state.div_stack = make([dynamic]^Element, state.allocator)
}

begin :: proc() {
	state.root_div = nil
	clear(&state.div_stack)
	state.last_elem = nil
}

Element :: struct {
	position: vec2,
	size: vec2,
	widget: Widget,
	style: Style,
}

Style :: struct {
	background_color: rl.Color,
	padding: vec2,
}

Widget :: union #no_nil {
	Div,
	Rect,
}

Div :: struct {
	children: [dynamic]Element,
	style: struct {
		direction: Direction,
		gap: f32,
	},
}

div_start :: proc(
	direction := Direction.Vertical,
	gap: f32 = 0,
	padding: f32 = 0,
	background_color := rl.BLANK,
	const_size: vec2 = -1,  // -1 means no const size (here on both axes)
) {
	elem := new(Element, state.allocator)
	div: Div
	div.children = make([dynamic]Element, state.allocator)
	div.style.direction = direction
	div.style.gap = gap
	elem.widget = div
	elem.style.padding = padding
	elem.style.background_color = background_color
	append(&state.div_stack, elem)
	state.last_elem = elem
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
	append(&last_div.children, elem^)
}

Direction :: enum {
	Vertical,
	Horizontal,
}

Rect :: struct {

}

rect :: proc(size: vec2, color := rl.MAGENTA) {
	elem := new(Element, state.allocator)
	rect: Rect
	elem.widget = rect
	elem.size = size
	elem.style.background_color = color
	// append(&state.div_stack, elem)
	last_div_elem := slice.last(state.div_stack[:])
	last_div := &last_div_elem.widget.(Div)
	append(&last_div.children, elem^)
	state.last_elem = elem
}

elem_size :: proc(elem: ^Element) {
	switch &widget in elem.widget {
	case Div:
		max, sum: f32
		switch widget.style.direction {
		case .Vertical:
			for &child in widget.children {
				elem_size(&child)
				if max < child.size.x {
					max = child.size.x
				}
				sum += child.size.y
			}
			elem.size = {max, sum}
			elem.size.y += f32(len(widget.children)-1) * widget.style.gap
		case .Horizontal:
			for &child in widget.children {
				elem_size(&child)
				if max < child.size.y {
					max = child.size.y
				}
				sum += child.size.x
			}
			elem.size = {sum, max}
			elem.size.x += f32(len(widget.children)-1) * widget.style.gap
		}
	case Rect:  // already sized
	}

	elem.size += elem.style.padding * 2
}

elem_position :: proc(elem: ^Element, anchor: vec2) {
	anchor := anchor

	switch widget in elem.widget {
	case Div:
		elem.position = anchor
		switch widget.style.direction {
		case .Vertical:
			for &child in widget.children {
				elem_position(&child, anchor + elem.style.padding)
				anchor.y += child.size.y
				anchor.y += widget.style.gap
			}
		case .Horizontal:
			for &child in widget.children {
				elem_position(&child, anchor + elem.style.padding)
				anchor.x += child.size.x
				anchor.x += widget.style.gap
			}
		}
	case Rect:
		elem.position = anchor + elem.style.padding
	}
}

_rect :: proc(pos, size: vec2) -> rl.Rectangle {
	return {pos.x, pos.y, size.x, size.y}
}

elem_draw :: proc(elem: ^Element, debug := false) {
	rl.DrawRectangleV(elem.position, elem.size, elem.style.background_color)
	// rl.DrawRectangleV(elem.position-elem.style.padding, elem.size, elem.style.background_color)
	if debug {
		rl.DrawRectangleLinesEx(_rect(elem.position-elem.style.padding, elem.size), 1, rl.RED)
	}

	switch widget in elem.widget {
	case Div:
		for &child in widget.children {
			elem_draw(&child, debug)
		}
	case Rect:  // nothing to do
	}
}