package game

import "core:math/linalg"
import rl "vendor:raylib"
import "core:slice"

PIXEL_WINDOW_HEIGHT :: 180

Vec2 :: [2]f32

House :: struct {
	pos: Vec2,
}

Game_Memory :: struct {
	camera_pos: Vec2,
	run: bool,
	house_texture: rl.Texture,
	houses: [dynamic]House,
	mouse_world_pos: Vec2,
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

	input = linalg.normalize0(input)
	g.camera_pos += input * rl.GetFrameTime() * 100

	game_cam := game_camera()
	g.mouse_world_pos = rl.GetScreenToWorld2D(rl.GetMousePosition(), game_cam)

	if rl.IsMouseButtonPressed(.LEFT) {
		append(&g.houses, House {
			pos = g.mouse_world_pos,
		})
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

	sorted_houses := make([]int, len(g.houses), context.temp_allocator)

	for &s, idx in sorted_houses {
		s = idx
	}

	sort_houses :: proc(i, j: int) -> bool {
		a := g.houses[i]
		b := g.houses[j]
		return a.pos.y < b.pos.y
	}

	slice.sort_by(sorted_houses, sort_houses)

	for idx in sorted_houses {
		h := &g.houses[idx]
		rl.DrawTextureV(g.house_texture, h.pos, rl.WHITE)
	}

	rl.DrawTextureV(g.house_texture, g.mouse_world_pos, rl.WHITE)

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
		house_texture = rl.LoadTexture("assets/house.png"),
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
