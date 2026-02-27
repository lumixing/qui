#+vet explicit-allocators
package qui

import "base:runtime"
import "core:fmt"
import rl "vendor:raylib"

vec2 :: [2]f32

Element :: struct {
	position: vec2,
	size: vec2,
	widget: Widget,
	style: Style,
	id: string,
	idx: int,
}

Style :: struct {
	const_size: vec2,
	padding: vec2,
	margin: vec2,
	background_color: Color,
	grow_width: bool,
}

//style_default :: proc() -> Style {
//	return {}
//}

Widget :: union #no_nil {
	^Div,
	^Text,
	^Image,
	^Input,
}

Div :: struct {
	children: [dynamic]^Element,
	style: struct {
		direction: Direction,
		gap: f32,
	},
}

Direction :: enum {
	Vertical,
	Horizontal,
}

Text :: struct {
	text: string,
	style: struct {
		color: Color,
	},
}

Image :: struct {
	path: string,
}

Input :: struct {
	text: ^string,
	placeholder: string,
	focused: bool,
}

state: struct {
	ids: map[string]rl.Rectangle,
	div_stack: [dynamic]^Element,
	last_div: Maybe(^Element),  // ik ptr is basically maybe but its safer
	islands: [dynamic]^Element,
	font: rl.Font,
	last_elem: ^Element,
	frame_arena: runtime.Arena,
	frame_allocator: runtime.Allocator,
	focused_inputs: map[string]bool,
}

init :: proc() {
	state.frame_allocator = runtime.arena_allocator(&state.frame_arena)
	state.font = rl.LoadFontEx("inter.ttf", 24, nil, 0)
}

deinit :: proc() {
	runtime.arena_destroy(&state.frame_arena)
}

frame :: proc() {
	clear(&state.div_stack)
	clear(&state.islands)
	state.last_div = nil
}

after :: proc() {
	last_div, ok := state.last_div.?
	assert(ok, "expected a last div")

	elem_size(last_div)
	elem_position(last_div, 0)
	elem_set_id(last_div)

	input_update(last_div)

	input_update :: proc(elem: ^Element) {
		#partial switch widget in elem.widget {
		case ^Div:
			for child in widget.children {
				input_update(child)
			}
		case ^Input:
			if !widget.focused {
				return
			}
			if rl.IsKeyPressed(.A) {
				widget.text^ = fmt.aprintf("%sa", widget.text^, allocator = context.allocator)  // leak
			} else if rl.IsKeyPressed(.BACKSPACE) {
				if len(widget.text) != 0 {
					widget.text^ = widget.text[:len(widget.text)-1]
				}
			}
		}
	}
}

draw :: proc(do_after := false, debug := false) {
	last_div, ok := state.last_div.?
	assert(ok, "expected a last div")

	if do_after do after()
	elem_draw(last_div, debug)

	free_all(state.frame_allocator)
}

elem_size :: proc(elem: ^Element) {
	switch widget in elem.widget {
	case ^Div:
		max, sum: f32
		switch widget.style.direction {
		case .Vertical:
			for child in widget.children {
				elem_size(child)
				if max < child.size.x {
					max = child.size.x
				}
				sum += child.size.y
			}
			elem.size.y += f32(len(widget.children)-1) * widget.style.gap
			elem.size = {max, sum}
		case .Horizontal:
			for child in widget.children {
				elem_size(child)
				if max < child.size.y {
					max = child.size.y
				}
				sum += child.size.x
			}
			elem.size.x += f32(len(widget.children)-1) * widget.style.gap
			elem.size = {sum, max}
		}

		// 2nd pass: grow_width
		for child in widget.children {
			if child.style.grow_width {
				child.size.x = elem.size.x
			}
		}
	case ^Text:
		elem.size = rl.MeasureTextEx(state.font, fcprintf(widget.text), f32(state.font.baseSize), f32(state.font.glyphPadding))
	case ^Image:  // no calc needed
	case ^Input:
		text := len(widget.text) != 0 ? widget.text^ : widget.placeholder
		elem.size = rl.MeasureTextEx(state.font, fcprintf(text), f32(state.font.baseSize), f32(state.font.glyphPadding))
	}

	elem.size += elem.style.padding * 2
}

elem_position :: proc(elem: ^Element, anchor: vec2) {
	anchor := anchor

	switch widget in elem.widget {
	case ^Div:
		elem.position = anchor
		switch widget.style.direction {
		case .Vertical:
			for child in widget.children {
				elem_position(child, anchor + elem.style.padding)
				anchor.y += child.size.y
				anchor.y += widget.style.gap
			}
		case .Horizontal:
			for child in widget.children {
				elem_position(child, anchor + elem.style.padding)
				anchor.x += child.size.x
				anchor.x += widget.style.gap
			}
		}
	case ^Text:
		elem.position = anchor + elem.style.padding
	case ^Image:
		elem.position = anchor + elem.style.padding
	case ^Input:
		elem.position = anchor + elem.style.padding
	}
}

elem_draw :: proc(elem: ^Element, debug := false) {
	rl.DrawRectangleV(elem.position-elem.style.padding, elem.size, _color(elem.style.background_color))
	if debug {
		rl.DrawRectangleLinesEx(rect(elem.position-elem.style.padding, elem.size), 1, rl.RED)
	}

	switch widget in elem.widget {
	case ^Div:
		for child in widget.children {
			elem_draw(child, debug)
		}
	case ^Text:
		rl.DrawTextEx(
			state.font, fcprintf(widget.text),
			elem.position, f32(state.font.baseSize),
			2, _color(widget.style.color),
		)
	case ^Image:
		unimplemented()
	case ^Input:
		text := len(widget.text) != 0 ? widget.text^ : widget.placeholder
		color: Color = len(widget.text) != 0 ? .blue : .black
		color = _color_alpha(color, widget.focused ? 1 : 0.5)
		rl.DrawTextEx(
			state.font, fcprintf("%s", text),
			elem.position, f32(state.font.baseSize),
			2, _color(color),
		)
	}
}

elem_id :: proc(elem: ^Element) -> string {
	switch widget in elem.widget {
	case ^Div:
		return fmt.tprintf("div.%d", elem.idx)
	case ^Text:
		return fmt.tprintf("txt.%d.%s", elem.idx, widget.text)
	case ^Image: unimplemented()
	case ^Input:
		return fmt.tprintf("inp.%d.%s", elem.idx, widget.placeholder)
	}
	return "???"
}

elem_set_id :: proc(elem: ^Element) {
	#partial switch widget in elem.widget {
	case ^Div:
		for child in widget.children {
			elem_set_id(child)
		}
	}

	state.ids[elem_id(elem)] = rect(elem.position, elem.size)
}

rect :: proc(pos, size: vec2) -> rl.Rectangle {
	return {pos.x, pos.y, size.x, size.y}
}

fprintf :: #force_inline proc(fmtstr: string, args: ..any) -> string {
	return fmt.aprintf(fmtstr, ..args, allocator = state.frame_allocator)
}

fcprintf :: #force_inline proc(fmtstr: string, args: ..any) -> cstring {
	return fmt.caprintf(fmtstr, ..args, allocator = state.frame_allocator)
}
