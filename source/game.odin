package game

import "core:math/linalg"
import rl "vendor:raylib"
import "core:slice"

PIXEL_WINDOW_HEIGHT :: 180

Vec2 :: [2]f32
Rect :: rl.Rectangle

House :: struct {
	pos: Vec2,
}

Tree :: struct {
	pos: Vec2,
}

Placement_Mode :: enum {
	House,
	Tree,
}

Game_Memory :: struct {
	camera_pos: Vec2,
	run: bool,
	atlas: rl.Texture,
	houses: [dynamic]House,
	trees: [dynamic]Tree,
	mouse_world_pos: Vec2,
	placement_mode: Placement_Mode,
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
		g.placement_mode = .House
	}
	if rl.IsKeyPressed(.TWO) {
		g.placement_mode = .Tree
	}

	input = linalg.normalize0(input)
	g.camera_pos += input * rl.GetFrameTime() * 100

	game_cam := game_camera()
	g.mouse_world_pos = rl.GetScreenToWorld2D(rl.GetMousePosition(), game_cam)

	if rl.IsMouseButtonPressed(.LEFT) {
		switch g.placement_mode {
		case .House:
			append(&g.houses, House {
				pos = g.mouse_world_pos,
			})
		case .Tree:
			append(&g.trees, Tree {
				pos = g.mouse_world_pos,
			})
		}
		
	}
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
	}

	drawables := make([dynamic]Drawable, context.temp_allocator)

	for &h in g.houses {
		append(&drawables, Drawable {
			texture = .House,
			pos = h.pos,
		})
	}

	for &t in g.trees {
		append(&drawables, Drawable {
			texture = .Tree,
			pos = t.pos,
		})
	}

	cursor_drawable := Drawable {
		pos = g.mouse_world_pos,
	}

	switch g.placement_mode {
	case .House:
		cursor_drawable.texture = .House
	case .Tree:
		cursor_drawable.texture = .Tree
	}

	append(&drawables, cursor_drawable)

	sort_drawbles :: proc(i, j: Drawable) -> bool {
		return i.pos.y < j.pos.y
	}

	slice.sort_by(drawables[:], sort_drawbles)

	for &d in drawables {
		rl.DrawTextureRec(g.atlas, atlas_textures[d.texture].rect, d.pos, rl.WHITE)
	}

	rl.EndMode2D()

	rl.BeginMode2D(ui_camera())

	rl.EndMode2D()

	rl.EndDrawing()
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
	delete(g.trees)
	delete(g.houses)
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

	// Here you can also set your own global variables. A good idea is to make
	// your global variables into pointers that point to something inside
	// `g_mem`.
}

@(export)
game_force_reload :: proc() -> bool {
	return rl.IsKeyPressed(.F5)
}

@(export)
game_force_restart :: proc() -> bool {
	return rl.IsKeyPressed(.F6)
}

// In a web build, this is called when browser changes size. Remove the
// `rl.SetWindowSize` call if you don't want a resizable game.
game_parent_window_size_changed :: proc(w, h: int) {
	rl.SetWindowSize(i32(w), i32(h))
}
