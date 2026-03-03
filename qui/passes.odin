#+vet explicit-allocators
package qui

main_cross_idx :: proc(swap_cond: bool) -> (Main := 0, Cross := 1) {
	if swap_cond {
		Main, Cross = 1, 0
	}
	return
}

elem_size :: proc(elem: ^Element) {
	switch &widget in elem.widget {
	case Div:
		Main, Cross := main_cross_idx(widget.style.direction == .Horizontal)
		max, sum: f32

		for &child in widget.children {
			elem_size(&child)
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
	case Rect:
	}

	elem.size += elem.style.padding * 2
}

inner_size :: proc(elem: ^Element) -> vec2 {
	return elem.size - elem.style.padding * 2
}

// 2nd size pass for grow
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

		for &child, child_idx in widget.children {
			elem_size2(&child, elem, child_idx)
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

		// yes yes, dry this code out
		#partial switch widget.style.align_cross {
		case .Start:  // dont change anchor
		case .End:
			main_size := f32(len(widget.children)-1)*widget.style.gap
			switch widget.style.direction {
			case .Vertical:
				for &child in widget.children {
					main_size += child.size.x
				}
				anchor.x += elem.size.x - main_size - elem.style.padding.x * 2
			case .Horizontal:
				for &child in widget.children {
					main_size += child.size.y
				}
				anchor.y += elem.size.y - main_size - elem.style.padding.y * 2
			}
		case .Center:
			main_size := f32(len(widget.children)-1)*widget.style.gap
			switch widget.style.direction {
			case .Vertical:
				for &child in widget.children {
					main_size += child.size.x
				}
				anchor.x += (elem.size.x - main_size - elem.style.padding.y * 2) / 2
			case .Horizontal:
				for &child in widget.children {
					main_size += child.size.y
				}
				anchor.y += (elem.size.y - main_size - elem.style.padding.y * 2) / 2
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