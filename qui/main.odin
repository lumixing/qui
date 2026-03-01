#+vet explicit-allocators
package qui

import "base:runtime"
import "core:mem"
import "core:slice"
import rl "vendor:raylib"

vec2 :: [2]f32

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
		const_size: vec2,
		align_main: Align,
		align_cross: Align,
		grow: bool,
	},
}

Align :: enum {
	Start,
	End,
	Center,
	SpaceBetween,
}

div_start :: proc(
	direction := Direction.Vertical,
	gap: f32 = 0,
	padding: f32 = 0,
	background_color := rl.BLANK,
	const_size: vec2 = -1,  // -1 means no const size (here on both axes)
	align_main := Align.Start,
	grow := false,
) {
	elem := new(Element, state.frame_allocator)
	div: Div
	div.children = make([dynamic]Element, state.frame_allocator)
	div.style.direction = direction
	div.style.gap = gap
	div.style.const_size = const_size
	div.style.align_main = align_main
	div.style.grow = grow
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
	elem := new(Element, state.frame_allocator)
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

		if widget.style.const_size.x != -1 {
			elem.size.x = widget.style.const_size.x
		}
		if widget.style.const_size.y != -1 {
			elem.size.y = widget.style.const_size.y
		}
	case Rect:  // already sized
	}

	elem.size += elem.style.padding * 2
}

// 2nd size pass for grow
elem_size2 :: proc(elem: ^Element, parent_size: vec2) {
	switch widget in elem.widget {
	case Div:
		for &child in widget.children {
			elem_size2(&child, elem.size)
		}
		if widget.style.grow {
			switch widget.style.direction {
			case .Vertical:
				elem.size.y = parent_size.y
			case .Horizontal:
				elem.size.x = parent_size.x
			}
		}
	case Rect:
	}
}

elem_position :: proc(elem: ^Element, anchor: vec2) {
	anchor := anchor

	switch widget in elem.widget {
	case Div:
		elem.position = anchor

		space_between_gap: f32

		#partial switch widget.style.align_main {
		case .Start:  // dont change anchor
		case .SpaceBetween:
			main_size: f32  // no gap! took a while to debug
			switch widget.style.direction {
			case .Vertical:
				for &child in widget.children {
					main_size += child.size.y
				}
				// anchor.y += elem.size.y - main_size - elem.style.padding.y * 2
			case .Horizontal:
				for &child in widget.children {
					main_size += child.size.x
				}
				space_between_gap = (elem.size.x - main_size - elem.style.padding.x * 2) / f32(len(widget.children)-1)  // uh oh /0?
			}
		case .End:
			main_size := f32(len(widget.children)-1)*widget.style.gap
			switch widget.style.direction {
			case .Vertical:
				for &child in widget.children {
					main_size += child.size.y
				}
				anchor.y += elem.size.y - main_size - elem.style.padding.y * 2
			case .Horizontal:
				for &child in widget.children {
					main_size += child.size.x
				}
				anchor.x += elem.size.x - main_size - elem.style.padding.x * 2
			}
		case .Center:
			main_size := f32(len(widget.children)-1)*widget.style.gap
			switch widget.style.direction {
			case .Vertical:
				for &child in widget.children {
					main_size += child.size.y
				}
				anchor.y += (elem.size.y - main_size - elem.style.padding.y * 2) / 2
			case .Horizontal:
				for &child in widget.children {
					main_size += child.size.x
				}
				anchor.x += (elem.size.x - main_size - elem.style.padding.x * 2) / 2
			}
		}

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
				if widget.style.align_main == .SpaceBetween {
					anchor.x += space_between_gap
				} else {
					anchor.x += widget.style.gap
				}
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