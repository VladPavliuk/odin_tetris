package main

import "core:fmt"

import ray "vendor:raylib"

drawTile :: proc(windowSize: int2, tile: int2, size: int2, color: ray.Color, darkerScale: u8) {
    backgroundColor := color;
    backgroundColor[3] /= darkerScale;

    ray.DrawRectangleRounded(ray.Rectangle{
        x = (f32)(tile.x * size.x),
        y = (f32)(windowSize.y - (tile.y + 1) * size.y),
        width = (f32)(size.x),
        height = (f32)(size.y)
    }, 0.3, 1.0, backgroundColor);

    ray.DrawRectangleRoundedLines(ray.Rectangle{
        x = (f32)(tile.x * size.x) + 1,
        y = (f32)(windowSize.y - (tile.y + 1) * size.y) + 1,
        width = (f32)(size.x) - 2,
        height = (f32)(size.y) - 2
    }, 0.3, 3.0, 2.0, color);
}

drawUI :: proc(gameState: ^GameState, windowSize: int2) {
    if (gameState.isLost) {
        textWidth := ray.MeasureText("LOST", 50);
        ray.DrawText("LOST", windowSize.x / 2 - textWidth / 2, windowSize.y / 2, 50, ray.WHITE);    
    }

    ray.DrawText(fmt.ctprintf("SCORE: %d", gameState.score), 0, 0, 20, ray.WHITE);    

    if (ray.IsKeyPressed(ray.KeyboardKey.H)) {
        gameState.hideHints = !gameState.hideHints;
    }

    menuItems := [?]cstring{
        "H - Hide Hints",
        "Q - Rotate",
        "S - Stop",
        "SPACE - Fast"
    };

    if (!gameState.hideHints) {
        startLocationY : i32 = 0;
        for menuItem in menuItems {
            textWidth := ray.MeasureText(menuItem, 18);
            ray.DrawText(menuItem, windowSize.x - textWidth, startLocationY, 18, ray.WHITE);
            startLocationY += 20;
        }        
    }
}
