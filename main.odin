#+feature dynamic-literals  // leak paradise!
package main

import "core:fmt"
import rl "vendor:raylib"

vec2 :: [2]f32

Element :: struct {
	position: vec2,
	size: vec2,
	widget: Widget,
	id: Maybe(int),
	padding: vec2,
}

Widget :: union #no_nil {
	Div,
	Text,
	Button,
}

Direction :: enum {
	Vertical,
	Horizontal,
}

Div :: struct {
	children: [dynamic]Element,  // def change to []Widget later!
	direction: Direction,
}

Text :: struct {
	text: string,
}

Button :: struct {
	text: string,
}

// pass by pointer maybe?
element_delete :: proc(element: Element) {
	switch widget in element.widget {
	case Text:
	case Button:
	case Div:
		for child in widget.children {
			element_delete(child)
		}
		delete(widget.children)
	}
}

FONT_SIZE :: 20

element_size :: proc(element: ^Element) {
	switch &widget in element.widget {
	case Div:
		switch widget.direction {
		case .Vertical:
			max_width: f32
			sum_height: f32
			for &child in widget.children {
				element_size(&child)
				if max_width < child.size.x {
					max_width = child.size.x
				}
				sum_height += child.size.y
			}
			element.size.x = max_width
			element.size.y = sum_height
		case .Horizontal:
			sum_width: f32
			max_height: f32
			for &child in widget.children {
				element_size(&child)
				if max_height < child.size.y {
					max_height = child.size.y
				}
				sum_width += child.size.x
			}
			element.size.x = sum_width
			element.size.y = max_height
		}
	case Text:
		element.size.x = f32(rl.MeasureText(fmt.ctprint(widget.text), FONT_SIZE))
		element.size.y = FONT_SIZE
	case Button:
		element.size.x = f32(rl.MeasureText(fmt.ctprint(widget.text), FONT_SIZE))
		element.size.y = FONT_SIZE
	}
}

rect :: #force_inline proc(position, size: vec2) -> rl.Rectangle {
	return {position.x, position.y, size.x, size.y}
}

element_position :: proc(element: ^Element, anchor: vec2) {
	anchor := anchor

	switch &widget in element.widget {
	case Div:
		element.position = anchor
		switch widget.direction {
		case .Vertical:
			for &child in widget.children {
				element_position(&child, anchor)
				anchor.y += child.size.y
			}
		case .Horizontal:
			for &child in widget.children {
				element_position(&child, anchor)
				anchor.x += child.size.x
			}
		}
	case Text:
		element.position = anchor
	case Button:
		element.position = anchor
	}
}

element_id :: proc(element: Element) -> (id: string) {
	switch widget in element.widget {
	case Div:
	case Text:
		id = fmt.aprintf("txt:%s", widget.text)
		
	case Button:
		id = fmt.aprintf("btn:%s", widget.text)
	}

	if eid, ok := element.id.?; ok {
		id = fmt.aprintf("%s:%d", id, eid)
	}

	return
}

element_id_w_db :: proc(element: Element) {
	id := element_id(element)
	if id != "" {
		w_db[id] = rect(element.position, element.size)
	}

	#partial switch widget in element.widget {
	case Div:
		for child in widget.children {
			element_id_w_db(child)
		}
	}
}

element_draw :: proc(element: Element) {
	rl.DrawRectangleV(element.position, element.size, {255, 0, 255, 50})
	switch widget in element.widget {
	case Div:
		for child in widget.children {
			element_draw(child)
		}
	case Text:
		rl.DrawText(fmt.ctprint(widget.text), i32(element.position.x), i32(element.position.y), FONT_SIZE, rl.BLACK)
	case Button:
		rl.DrawRectangleV(element.position, element.size, {0, 255, 0, 100})
		rl.DrawText(fmt.ctprint(widget.text), i32(element.position.x), i32(element.position.y), FONT_SIZE, rl.BLACK)
	}
}

w_db: map[string]rl.Rectangle
div_stack: [dynamic]^Div
//ediv_stack: [dynamic]Element
islands: [dynamic]Element

main :: proc() {
	rl.SetTraceLogLevel(.WARNING)
	rl.InitWindow(800, 600, "window")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)

	good := 0
	shit := 0

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground(rl.RAYWHITE)

		//clear(&w_db)
		clear(&div_stack)
		clear(&islands)
		//root_div: Div
		//append(&div_stack, &root_div)

		div_start()
			if button("click me") {
				good += 1
			}
			text("clicked %d times", good)

			div_start(.Horizontal); pad(16)
				if button("type") {
					shit += 1
				}
				hover("u tope %d shytes", shit)
				for i in 0..<shit {
					text("shit"); id(i)
					if clicked() {
						shit -= 1
					}
					hover("i am fish #%d", i+1)
				}
			div_end()

			text("psst! (hover me)")
			hover("heyaaaaa!")
		dd := div_end()

		//if !true {
		//	append(&root_div.children, Element{
		//		widget = Text{text = "hello world!"}
		//	})
		//	append(&root_div.children, Element{
		//		widget = Text{text = "HOWS IT GOIN?"}
		//	})
		//	for g in 0..<good {
		//		append(&root_div.children, Element{
		//			widget = Text{text = "good"}
		//		})
		//	}
		//	if rl.IsMouseButtonPressed(.LEFT) {
		//		if "HOWS IT GOIN?" in w_db {
		//			if rl.CheckCollisionRecs(rect(rl.GetMousePosition(), 1), w_db["HOWS IT GOIN?"]) {
		//				good += 1
		//			}
		//		}
		//	}
		//	append(&root_div.children, Element{
		//		widget = Text{text = "hehe :3"}
		//	})
		//	if rl.IsMouseButtonPressed(.LEFT) {
		//		if "hehe :3" in w_db {
		//			if rl.CheckCollisionRecs(rect(rl.GetMousePosition(), 1), w_db["hehe :3"]) {
		//				fmt.println("~~~")
		//			}
		//		}
		//	}
		//	append(&root_div.children, Element{
		//		widget = Div{
		//			direction = .Horizontal,
		//			children = {
		//				Element{
		//					widget = Text{text = "first!!!"}
		//				},
		//				Element{
		//					widget = Text{text = "second!!"}
		//				},
		//				Element{
		//					widget = Text{text = "third!"}
		//				},
		//			},
		//		},
		//	})
		//	append(&root_div.children, Element{
		//		widget = Text{text = "wtf!?"}
		//	})
		//	append(&root_div.children, Element{
		//		widget = Text{text = fmt.aprintf("%.4f", rl.GetTime())}
		//	})
		//}

		root_element := dd.?
		//defer element_delete(root_element)

		element_size(&root_element)
		element_position(&root_element, 0)
		element_id_w_db(root_element)
		element_draw(root_element)

		for &island, i in islands {
			element_size(&island)
			element_position(&island, island.position)
			element_draw(island)
		}

		rl.EndDrawing()
	}
}

div_start :: proc(direction: Direction = .Vertical) {
	div := new(Div)
	div.direction = direction
	append(&div_stack, div)
}

div_end :: proc() -> Maybe(Element) {
	if len(div_stack) == 1 {
		return Element{widget = pop(&div_stack)^}
	}

	// i inlined this before so it first calced last then popped..
	LOOL := Element{widget = pop(&div_stack)^}
	append(&div_stack[len(div_stack)-1].children, LOOL)
	return nil
}

text :: proc(fmtstr: string, args: ..any) {
	append(&div_stack[len(div_stack)-1].children, Element{
		widget = Text{fmt.aprintf(fmtstr, ..args)},
	})
}

last_ptr :: proc(a: []$T) -> ^T {
	return &a[len(a)-1]
}

id :: proc(id: int) {
	current_div := last_ptr(div_stack[:])
	prev_elem := last_ptr(current_div^.children[:])
	prev_elem.id = id
}

hover :: proc(fmtstr: string, args: ..any) {
	txt := fmt.aprintf(fmtstr, ..args)
	current_div := last_ptr(div_stack[:])
	prev_elem := last_ptr(current_div^.children[:])
	if rct, ok := w_db[element_id(prev_elem^)]; ok {
		if rl.CheckCollisionRecs(rect(rl.GetMousePosition(), 1), rct) {
			append(&islands, Element{
				position = rl.GetMousePosition()+{0, -20},
				widget = Div{children={Element{widget=Text{txt}}}},  // WTFF
			})
		}
	}
}

button :: proc(txt: string) -> bool {
	el := Element{
		widget = Button{text = txt},
	}
	append(&div_stack[len(div_stack)-1].children, el)
	if rl.IsMouseButtonPressed(.LEFT) {
		if rct, ok := w_db[element_id(el)]; ok {
			if rl.CheckCollisionRecs(rect(rl.GetMousePosition(), 1), rct) {
				return true  // /shrug
			}
		}
	}
	return false
}

clicked :: proc() -> bool {
	current_div := last_ptr(div_stack[:])
	prev_elem := last_ptr(current_div^.children[:])
	txt := prev_elem.widget.(Text).text
	if rl.IsMouseButtonPressed(.LEFT) {
		if rct, ok := w_db[element_id(prev_elem^)]; ok {
			if rl.CheckCollisionRecs(rect(rl.GetMousePosition(), 1), rct) {
				return true
			}
		}
	}
	return false
}

pad :: proc(px: f32) {
	current_div := last_ptr(div_stack[:])
	prev_elem := last_ptr(current_div^.children[:])
	prev_elem.padding = px
}
