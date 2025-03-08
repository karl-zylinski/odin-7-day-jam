package game

cut_rect_top :: proc(r: ^Rect, y: f32, m: f32) -> Rect {
	res := r^
	res.y += m
	res.height = y
	r.y += y + m
	r.height -= y + m
	return res
}

cut_rect_bottom :: proc(r: ^Rect, h: f32, m: f32) -> Rect {
	res := r^
	res.height = h
	res.y = r.y + r.height - h - m
	r.height -= h + m
	return res
}

cut_rect_left :: proc(r: ^Rect, x, m: f32) -> Rect {
	res := r^
	res.x += m
	res.width = x
	r.x += x + m
	r.width -= x + m
	return res
}

cut_rect_right :: proc(r: ^Rect, w, m: f32) -> Rect {
	res := r^
	res.width = w
	res.x = r.x + r.width - w - m
	r.width -= w + m
	return res
}

split_rect_top :: proc(r: Rect, y: f32, m: f32) -> (top, bottom: Rect) {
	top = r
	bottom = r
	top.y += m
	top.height = y
	bottom.y += y + m
	bottom.height -= y + m
	return
}

split_rect_left :: proc(r: Rect, x: f32, m: f32) -> (left, right: Rect) {
	left = r
	right = r
	left.width = x
	right.x += x + m
	right.width -= x +m
	return
}

split_rect_bottom :: proc(r: Rect, y: f32, m: f32) -> (top, bottom: Rect) {
	top = r
	top.height -= y + m
	bottom = r
	bottom.y = top.y + top.height + m
	bottom.height = y
	return
}

split_rect_right :: proc(r: Rect, x: f32, m: f32) -> (left, right: Rect) {
	left = r
	right = r
	right.width = x
	left.width -= x + m
	right.x = left.x + left.width
	return
}