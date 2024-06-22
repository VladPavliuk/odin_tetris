package main

import "core:c"

import ray "vendor:raylib"

int2 :: struct {
    x: i32,
    y: i32,
}

main :: proc() {
    gameState := GameState {
        regularDeltaTick = 0.3,
        fastDeltaTick = 0.1,
    }

    spawnShape(&gameState)

    ray.SetWindowState({ ray.ConfigFlag.MSAA_4X_HINT })
    
    windowSize := int2{ x = 400, y = 800 }
    ray.InitWindow(windowSize.x, windowSize.y, "TETRIS")
    defer ray.CloseWindow()

    //ray.SetTargetFPS(144);
    
    visibleVerticalTilesCount : i32 = MAP_SIZE_Y - 4

    tileSize := int2{ windowSize.x / MAP_SIZE_X, windowSize.y / visibleVerticalTilesCount }
    for !ray.WindowShouldClose()
    {
        deltaTime := ray.GetFrameTime()

        checkFilledLines(&gameState)
        updateGameState(&gameState, deltaTime)

        ray.ClearBackground(ray.DARKGRAY)
        ray.BeginDrawing()

        // draw tiles
        for y : i32 = 0; y < visibleVerticalTilesCount; y += 1 {
            for x : i32 = 0; x < MAP_SIZE_X; x += 1 {
                drawTile(windowSize, { x = x, y = y }, tileSize, gameState.tiles[y][x], 4)
            }
        }

        // draw active shape
        for tile in gameState.activeShape {
            drawTile(windowSize, tile, tileSize, gameState.activeShapeColor, 2)
        }

        drawUI(&gameState, windowSize)

        ray.EndDrawing()
    }
}