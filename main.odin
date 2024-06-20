package main

import "core:fmt"
import "core:c"
import "core:math/rand"

import ray "vendor:raylib"

int2 :: struct {
    x: i32,
    y: i32
}

MAP_SIZE_X :: 10
MAP_SIZE_Y :: 24

GameState :: struct {
    regularDeltaTick: f32,
    fastDeltaTick: f32,

    currentDeltaTick: f32,
    deltaTimeTotal: f32,

    isStoped: bool,
    isLost: bool,
    score: i32,

    activeShapeColor: ray.Color,
    activeShape: [dynamic]int2,
    tiles: [MAP_SIZE_Y][MAP_SIZE_X]ray.Color,
}

spawnShape :: proc(gameState: ^GameState) {
    clear(&gameState.activeShape);
    
    data: []int = { 1, 2, 3, 4 };
    randomShape := rand.choice(data[:]);

    if (randomShape == 1) {
        spawnLine(gameState);
    } else if (randomShape == 2) {
        spawnRectangle(gameState);
    } else if (randomShape == 3) {
        spawnZip(gameState);
    } else if (randomShape == 4) {
        spawnVerticalZip(gameState);
    }

    offsetX : i32 = MAP_SIZE_X / 2;
    offsetY : i32 = MAP_SIZE_Y - 4;

    for &tile in gameState.activeShape {
        tile.x += offsetX;
        tile.y += offsetY
    } 
}

spawnLine :: proc(gameState: ^GameState) {
    gameState.activeShapeColor = ray.GREEN;
    
    append(&gameState.activeShape, int2{ 0, 0 });
    append(&gameState.activeShape, int2{ 0, 1 });
    append(&gameState.activeShape, int2{ 0, 2 });
    append(&gameState.activeShape, int2{ 0, 3 });    
}

spawnRectangle :: proc(gameState: ^GameState) {
    gameState.activeShapeColor = ray.YELLOW;
    
    append(&gameState.activeShape, int2{ 0, 0 });
    append(&gameState.activeShape, int2{ 0, 1 });
    append(&gameState.activeShape, int2{ 1, 0 });
    append(&gameState.activeShape, int2{ 1, 1 });    
}

spawnZip :: proc(gameState: ^GameState) {
    gameState.activeShapeColor = ray.BLUE;
    
    append(&gameState.activeShape, int2{ 0, 0 });
    append(&gameState.activeShape, int2{ 1, 0 });
    append(&gameState.activeShape, int2{ 1, 1 });
    append(&gameState.activeShape, int2{ 2, 1 });    
}

spawnVerticalZip :: proc(gameState: ^GameState) {
    gameState.activeShapeColor = ray.VIOLET;
    
    append(&gameState.activeShape, int2{ 1, 0 });
    append(&gameState.activeShape, int2{ 1, 1 });
    append(&gameState.activeShape, int2{ 0, 1 });
    append(&gameState.activeShape, int2{ 0, 2 });    
}

updateGameState :: proc(gameState: ^GameState, deltaTime: f32) {
    if (ray.IsKeyPressed(ray.KeyboardKey.S)) {
        gameState.isStoped = !gameState.isStoped;
    }

    if (gameState.isStoped) { return; }

    if gameState.isLost {
        if (ray.IsKeyPressed(ray.KeyboardKey.R)) {
            gameState.isLost = false;
            gameState.score = 0;
            
            for y : i32 = 0; y < MAP_SIZE_Y; y += 1 {
                for x : i32 = 0; x < MAP_SIZE_X; x += 1 {
                    gameState.tiles[y][x] = 0;
                }
            }
        }
        return; 
    }

    moveDirection : i32 = 0;
    if (ray.IsKeyPressed(ray.KeyboardKey.A)) {
        moveDirection = -1;
    }
    if (ray.IsKeyPressed(ray.KeyboardKey.D)) {
        moveDirection = 1;
    }

    if (moveDirection != 0) {           
        isOusideOfMap := false;   
        for &tile in gameState.activeShape {
            tile.x += moveDirection;

            if (tile.x < 0 || tile.x >= MAP_SIZE_X || gameState.tiles[tile.y][tile.x] != 0) {
                isOusideOfMap = true;
            }
        }

        if (isOusideOfMap) {
            for &tile in gameState.activeShape {
                tile.x -= moveDirection;
            }
        }
    }

    if (ray.IsKeyDown(ray.KeyboardKey.SPACE)) {
        gameState.currentDeltaTick = gameState.fastDeltaTick;
    } else {
        gameState.currentDeltaTick = gameState.regularDeltaTick;
    }

    gameState.deltaTimeTotal += deltaTime;
    if (gameState.deltaTimeTotal < gameState.currentDeltaTick) {
        return;
    }
    gameState.deltaTimeTotal = 0.0;

    // update position
    for &tile in gameState.activeShape {
        tile.y -= 1;
    }

    hitOtherShape := false;
    hitFloor := false;
    for tile in gameState.activeShape {
        if (gameState.tiles[tile.y][tile.x] != 0) {
            hitOtherShape = true;
        }

        if (tile.y == 0) {
            hitFloor = true;
        }
    }

    if (hitOtherShape) {
        for &tile in gameState.activeShape {
            tile.y += 1;
        }
    }

    if (hitOtherShape || hitFloor) {
        for tile in gameState.activeShape {
            gameState.tiles[tile.y][tile.x] = gameState.activeShapeColor;
        }

        spawnShape(gameState);

        for tile in gameState.activeShape {
            if (gameState.tiles[tile.y][tile.x] != 0) {
                gameState.isLost = true;
                break;
            }
        }
    }
}

checkFilledLines :: proc(gameState: ^GameState) {
    for y : i32 = 0; y < MAP_SIZE_Y; y += 1 {
        filledLineIndex : i32 = y;

        for x : i32 = 0; x < MAP_SIZE_X; x += 1 {
            if (gameState.tiles[y][x] == 0) {
                filledLineIndex = -1;
                break;
            }
        }
        
        if (filledLineIndex != -1) {
            gameState.score += MAP_SIZE_X;

            for y := filledLineIndex; y < MAP_SIZE_Y - 1; y += 1 {
                for x : i32 = 0; x < MAP_SIZE_X; x += 1 {
                    gameState.tiles[y][x] = gameState.tiles[y + 1][x];
                }
            }
        }
    }
}

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

main :: proc() {
    gameState := GameState {
        regularDeltaTick = 0.3,
        fastDeltaTick = 0.1,
    };

    spawnShape(&gameState);

    // traceCallback :: proc "c" (logLevel: ray.TraceLogLevel, text: cstring, args: c.va_list) {};
    ray.SetTraceLogCallback(proc "c" (logLevel: ray.TraceLogLevel, text: cstring, args: c.va_list) {});
    ray.SetWindowState({ ray.ConfigFlag.MSAA_4X_HINT });
    
    windowSize := int2{ x = 400, y = 800 };
    ray.InitWindow(windowSize.x, windowSize.y, "TETRIS");
    defer ray.CloseWindow();

    ray.SetTargetFPS(144);
    
    visibleVerticalTilesCount : i32 = MAP_SIZE_Y - 4;

    tileSize := int2{ windowSize.x / MAP_SIZE_X, windowSize.y / visibleVerticalTilesCount };
    for !ray.WindowShouldClose()
    {
        deltaTime := ray.GetFrameTime();

        checkFilledLines(&gameState);
        updateGameState(&gameState, deltaTime);

        ray.ClearBackground(ray.DARKGRAY);
        ray.BeginDrawing();

        // draw tiles
        for y : i32 = 0; y < visibleVerticalTilesCount; y += 1 {
            for x : i32 = 0; x < MAP_SIZE_X; x += 1 {
                drawTile(windowSize, { x = x, y = y }, tileSize, gameState.tiles[y][x], 4);
            }
        }

        // draw active shape
        for tile in gameState.activeShape {
            drawTile(windowSize, tile, tileSize, gameState.activeShapeColor, 2);
        }

        if (gameState.isLost) {
            textWidth := ray.MeasureText("LOST", 50);
            ray.DrawText("LOST", windowSize.x / 2 - textWidth / 2, windowSize.y / 2, 50, ray.WHITE);    
        }

        ray.DrawText(fmt.ctprintf("SCORE: %d", gameState.score), 0, 0, 20, ray.WHITE);    

        ray.EndDrawing();
    }
}