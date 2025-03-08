package game

import "core:math/linalg"
import rl "vendor:raylib"
import "core:slice"

PIXEL_WINDOW_HEIGHT :: 180

Vec2 :: [2]f32
Rect :: rl.Rectangle

Entity_Type :: enum {
	None,
	House,
	Tree,
}

Entity :: struct {
	type: Entity_Type,
	pos: Vec2,
}

Game_Memory :: struct {
	camera_pos: Vec2,
	debug_draw: bool,
	run: bool,
	atlas: rl.Texture,
	entities: [dynamic]Entity,
	mouse_world_pos: Vec2,
	mouse_ui_pos: Vec2,
	place_entity_type: Entity_Type,
}

g: ^Game_Memory

game_camera :: proc() -> rl.Camera2D {
	w := f32(rl.GetScreenWidth())
	h := f32(rl.GetScreenHeight())

	return {
		zoom = h/PIXEL_WINDOW_HEIGHT,
		target = g.camera_pos,
		offset = { w/2, h/2 },
	}
}

ui_camera :: proc() -> rl.Camera2D {
	return {
		zoom = f32(rl.GetScreenHeight())/PIXEL_WINDOW_HEIGHT,
	}
}

update :: proc() {
	input: rl.Vector2

	if rl.IsKeyPressed(.F3) {
		g.debug_draw = !g.debug_draw
	}

	if rl.IsKeyDown(.UP) || rl.IsKeyDown(.W) {
		input.y -= 1
	}
	if rl.IsKeyDown(.DOWN) || rl.IsKeyDown(.S) {
		input.y += 1
	}
	if rl.IsKeyDown(.LEFT) || rl.IsKeyDown(.A) {
		input.x -= 1
	}
	if rl.IsKeyDown(.RIGHT) || rl.IsKeyDown(.D) {
		input.x += 1
	}

	if rl.IsKeyPressed(.ONE) {
		g.place_entity_type = .House
	}
	if rl.IsKeyPressed(.TWO) {
		g.place_entity_type = .Tree
	}

	input = linalg.normalize0(input)
	g.camera_pos += input * rl.GetFrameTime() * 100

	game_cam := game_camera()
	g.mouse_world_pos = linalg.round(rl.GetScreenToWorld2D(rl.GetMousePosition(), game_cam))
	g.mouse_ui_pos = rl.GetScreenToWorld2D(rl.GetMousePosition(), ui_camera())


	screen_rect := fullscreen_rect()
	game_rect, _ := split_rect_right(screen_rect, METRIC_SIDE_PANEL_WIDTH, 0)

	// Rest of proc is for updating game state if inside the game rect
	if !mouse_in_ui_rect(game_rect) {
		return
	}

	for idx := 0; idx< len(g.entities); {
		e := &g.entities[idx]
		r := entity_rect(e^)

		if mouse_in_rect(r) {
			if rl.IsMouseButtonPressed(.RIGHT) {
				unordered_remove(&g.entities, idx)
				continue
			}
		}

		idx += 1
	}

	if rl.IsMouseButtonPressed(.LEFT) && g.place_entity_type != .None {
		if !cursor_overlaps_entity() {
			append(&g.entities, Entity {
				type = g.place_entity_type,
				pos = g.mouse_world_pos,
			})
		}
	}
}

cursor_overlaps_entity :: proc() -> bool {
	footprint := entity_footprint_rect(g.place_entity_type, g.mouse_world_pos)
	
	for &e in g.entities {
		e_footprint := entity_footprint_rect(e.type, e.pos)

		if rl.CheckCollisionRecs(e_footprint, footprint) {
			return true
		}
	}

	return false
}

mouse_in_rect :: proc(r: Rect) -> bool {
	return rl.CheckCollisionPointRec(g.mouse_world_pos, r)
}

mouse_in_ui_rect :: proc(r: Rect) -> bool {
	return rl.CheckCollisionPointRec(g.mouse_ui_pos, r)
}

cursor_pos :: proc() -> Vec2 {
	return rl.GetScreenToWorld2D(rl.GetMousePosition(), game_camera())
}

GROUND_COLOR :: rl.Color { 26, 122, 62, 255 }

draw :: proc() {
	rl.BeginDrawing()
	rl.ClearBackground(GROUND_COLOR)

	game_cam := game_camera()
	rl.BeginMode2D(game_cam)

	Drawable :: struct {
		texture: Texture_Name,
		pos: Vec2,
		tint: rl.Color,
	}

	drawables := make([dynamic]Drawable, context.temp_allocator)

	for &e in g.entities {
		texture: Texture_Name

		switch e.type {
		case .None:
			continue

		case .House:
			texture = .House

		case .Tree:
			texture = .Tree
		}

		append(&drawables, Drawable {
			texture = texture,
			pos = e.pos,
			tint = rl.WHITE,
		})
	}

	if g.place_entity_type != .None {
		cursor_drawable := Drawable {
			pos = g.mouse_world_pos,
			texture = texture_from_entity_type(g.place_entity_type),
			tint = cursor_overlaps_entity() ? rl.RED : rl.WHITE, 
		}

		append(&drawables, cursor_drawable)
	}

	sort_drawbles :: proc(i, j: Drawable) -> bool {
		return i.pos.y < j.pos.y
	}

	slice.sort_by(drawables[:], sort_drawbles)

	for &d in drawables {
		rl.DrawTextureRec(g.atlas, atlas_textures[d.texture].rect, d.pos, d.tint)
	}

	if g.debug_draw {
		for &e in g.entities {
			fpr := entity_footprint_rect(e.type, e.pos)
			rl.DrawRectangleRec(fpr, {255, 0, 0, 100})
		}

		fpr := entity_footprint_rect(g.place_entity_type, g.mouse_world_pos)
		rl.DrawRectangleRec(fpr, {255, 0, 0, 100})
	}

	rl.EndMode2D()
	ui_cam := ui_camera()
	rl.BeginMode2D(ui_cam)

	{
		screen_rect := fullscreen_rect()
		side_panel := cut_rect_right(&screen_rect, METRIC_SIDE_PANEL_WIDTH, 0)
		rl.DrawRectangleRec(side_panel, COLOR_SIDE_PANEL_BG)

		pos := Vec2 { side_panel.x, side_panel.y }

		for t in Entity_Type {
			tex := texture_from_entity_type(t)
			rect := atlas_textures[tex].rect
			dest_rect := rect_from_pos_size(pos, rect_size(rect))

			rl.DrawTexturePro(g.atlas, rect, dest_rect, {}, 0, rl.WHITE)

			if rl.CheckCollisionPointRec(rl.GetScreenToWorld2D(rl.GetMousePosition(), ui_cam), dest_rect) {
				rl.DrawRectangleLinesEx(dest_rect, 1, rl.RED)

				if rl.IsMouseButtonPressed(.LEFT) {
					g.place_entity_type = t
				}
			}

			if g.place_entity_type == t {
				rl.DrawRectangleLinesEx(dest_rect, 1, rl.GREEN)
			}

			pos.x += rect.width

		}
	}

	rl.EndMode2D()
	rl.EndDrawing()
}

fullscreen_rect :: proc() -> Rect {
	zoom := f32(rl.GetScreenHeight()) / PIXEL_WINDOW_HEIGHT
	return {
		0, 0,
		f32(rl.GetScreenWidth()) / zoom, f32(rl.GetScreenHeight()) / zoom,
	}
}

METRIC_SIDE_PANEL_WIDTH :: 80

COLOR_SIDE_PANEL_BG :: rl.Color { 100, 100, 100, 255 }

entity_footprint_rect :: proc(t: Entity_Type, p: Vec2) -> Rect {
	switch t {
	case .None:
		return {}
	case .House:
		return rect_from_pos_size(p + {1, 12}, {14, 5})
	case .Tree:
		return rect_from_pos_size(p + {5, 13}, {4, 4})
	}

	return {}
}

entity_rect :: proc(e: Entity) -> Rect {
	t := texture_from_entity_type(e.type)
	r := atlas_textures[t].rect
	return rect_from_pos_size(e.pos, rect_size(r))
}

rect_from_pos_size :: proc(pos, size: Vec2) -> Rect {
	return {
		pos.x, pos.y,
		size.x, size.y,
	}
}

rect_size :: proc(r: Rect) -> Vec2 {
	return {r.width, r.height}
}

texture_from_entity_type :: proc(t: Entity_Type) -> Texture_Name {
	switch t {
	case .None: return .None
	case .House: return .House
	case .Tree: return .Tree
	}

	return .None
}

@(export)
game_update :: proc() {
	update()
	draw()
}

@(export)
game_init_window :: proc() {
	rl.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT})
	rl.InitWindow(1920, 1080, "City Buildor!")
	rl.SetWindowPosition(200, 200)
	rl.SetTargetFPS(500)
	rl.SetExitKey(nil)
}

@(export)
game_init :: proc() {
	g = new(Game_Memory)

	g^ = Game_Memory {
		run = true,
		atlas = rl.LoadTexture("assets/atlas.png"),
	}

	game_hot_reloaded(g)
}

@(export)
game_should_run :: proc() -> bool {
	when ODIN_OS != .JS {
		// Never run this proc in browser. It contains a 16 ms sleep on web!
		if rl.WindowShouldClose() {
			return false
		}
	}

	return g.run
}

@(export)
game_shutdown :: proc() {
	delete(g.entities)
	free(g)
}

@(export)
game_shutdown_window :: proc() {
	rl.CloseWindow()
}

@(export)
game_memory :: proc() -> rawptr {
	return g
}

@(export)
game_memory_size :: proc() -> int {
	return size_of(Game_Memory)
}

@(export)
game_hot_reloaded :: proc(mem: rawptr) {
	g = (^Game_Memory)(mem)
}

@(export)
game_force_reload :: proc() -> bool {
	return rl.IsKeyPressed(.F5)
}

@(export)
game_force_restart :: proc() -> bool {
	return rl.IsKeyPressed(.F6)
}

game_parent_window_size_changed :: proc(w, h: int) {
	rl.SetWindowSize(i32(w), i32(h))
}
