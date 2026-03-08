#+vet explicit-allocators
package qui

import "core:fmt"
import rl "vendor:raylib"

@(private)
main_cross_idx :: proc(swap_cond: bool) -> (Main := 0, Cross := 1) {
	if swap_cond {
		Main, Cross = 1, 0
	}
	return
}

@(private)
elem_size :: proc(elem: ^Element) {
	switch &widget in elem.widget {
	case Div:
		Main, Cross := main_cross_idx(widget.style.direction == .Horizontal)
		max, sum: f32

		for child in widget.children {
			elem_size(child)
			if max < child.size[Main] {
				max = child.size[Main]
			}
			sum += child.size[Cross]
		}
		elem.size[Main] = max
		elem.size[Cross] = sum
		elem.size[Cross] += f32(len(widget.children)-1)*widget.style.gap

		if widget.style.const_size.x != -1 {
			elem.size.x = widget.style.const_size.x
		}
		if widget.style.const_size.y != -1 {
			elem.size.y = widget.style.const_size.y
		}
	case Rect:  // size is already known
	case Text:
		SPACING :: 1
		elem.size = rl.MeasureTextEx(state.font, rl.TextFormat("%s", widget.text), f32(state.font.baseSize), SPACING)
	}

	elem.size += elem.style.padding * 2
}

@(private)
inner_size :: proc(elem: ^Element) -> vec2 {
	return elem.size - elem.style.padding * 2
}

// 2nd size pass for grow
@(private)
elem_size2 :: proc(elem: ^Element, parent_elem: ^Element, idx: int) {
	switch widget in elem.widget {
	case Div:
		if widget.style.grow_main {
			parent_div := parent_elem.widget.(Div)
			Main, Cross := main_cross_idx(parent_div.style.direction != .Horizontal)
			remaining_size := inner_size(parent_elem)[Main]
			parent_children := parent_div.children
			remaining_size -= f32(len(parent_children)-1) * parent_elem.widget.(Div).style.gap
			for child, child_idx in parent_children {
				if idx == child_idx {
					continue
				}
				remaining_size -= child.size[Main]
			}
			elem.size[Main] = remaining_size
		}

		if widget.style.grow_cross {
			parent_div := parent_elem.widget.(Div)
			Main, Cross := main_cross_idx(parent_div.style.direction != .Horizontal)
			elem.size[Cross] = inner_size(parent_elem)[Cross]
		}

		for child, child_idx in widget.children {
			elem_size2(child, elem, child_idx)
		}
	case Rect:
	case Text:
	}
}

@(private)
elem_position :: proc(elem: ^Element, anchor: vec2) {
	anchor := anchor

	switch widget in elem.widget {
	case Div:
		elem.position = anchor

		space_between_gap: f32
		Main, Cross := main_cross_idx(widget.style.direction != .Horizontal)

		switch widget.style.align_main {
		case .Start:  // dont change anchor
		case .SpaceBetween:
			main_size: f32  // no gap! took a while to debug
			for &child in widget.children {
				main_size += child.size[Main]
			}
			space_between_gap = (elem.size[Main] - main_size - elem.style.padding[Main] * 2) / f32(len(widget.children)-1)  // uh oh /0?
		case .End:
			main_size := f32(len(widget.children)-1)*widget.style.gap
			for &child in widget.children {
				main_size += child.size[Main]
			}
			anchor[Main] += elem.size[Main] - main_size - elem.style.padding[Main] * 2
		case .Center:
			main_size := f32(len(widget.children)-1)*widget.style.gap
			for &child in widget.children {
				main_size += child.size[Main]
			}
			anchor[Main] += (elem.size[Main] - main_size - elem.style.padding[Main] * 2) / 2
		}

		for child in widget.children {
			align_cross_offset: vec2
			#partial switch widget.style.align_cross {
			case .Start:  // do nothing
			case .End:
				align_cross_offset[Cross] = (inner_size(elem) - child.size)[Cross]
			case .Center:
				align_cross_offset[Cross] = (inner_size(elem) - child.size)[Cross] / 2
			case:
				dbgf(widget.style.align_cross)
				unimplemented()
			}
			elem_position(child, anchor + elem.style.padding + align_cross_offset)
			anchor[Main] += child.size[Main]
			if widget.style.align_main == .SpaceBetween {
				anchor[Main] += space_between_gap
			} else {
				anchor[Main] += widget.style.gap
			}
		}
	case Rect:
		elem.position = anchor + elem.style.padding
	case Text:
		elem.position = anchor + elem.style.padding
	}
}

//@(private)
elem_id :: proc(elem: ^Element) -> (id: string) {
	switch widget in elem.widget {
	case Div:
		id = fmt.aprintf("div.%d", elem.idx, allocator = state.frame_allocator)
	case Rect:
		id = fmt.aprintf("rect.%d", elem.idx, allocator = state.frame_allocator)
	case Text:
		// todo: store fmtstr and do text.%q{fmtstr}.%d{idx} ??
		//dbgf(elem.idx)
		id = fmt.aprintf("text.%d", elem.idx, allocator = state.frame_allocator)
	}

	return
}

@(private)
elem_id_pass :: proc(elem: ^Element) {
	elem.id = elem_id(elem)
	//dbgf(elem.id)
	#partial switch widget in elem.widget {
	case Div:
		for child in widget.children {
			elem_id_pass(child)
		}
	}
}
