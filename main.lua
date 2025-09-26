Classic = require "objects.classic"
Input   = require "objects/boipushy/Input"
local Stage = require "stage"

function love.load()
    love.window.setTitle("Exploding Circles")
    love.graphics.setBackgroundColor(0.1, 0.1, 0.1)

    input = Input()
    input:bind("left", "left_key")
    input:bind("right", "right_key")
    input:bind("up", "up_key")
    input:bind("down", "down_key")
    input:bind("a", "left_key")
    input:bind("d", "right_key")
    input:bind("w", "up_key")
    input:bind("s", "down_key")
    input:bind("mouse1", "explode")

    stage = Stage(input)
end

function love.update(dt)
    stage:update(dt)

    if input:pressed("explode") then
        if stage.game_over then
            -- restart game
            stage = Stage(input)   -- create a new stage, resets everything
        else
            -- trigger player explosion
            stage.player_circle:explode(stage.area.game_objects)
            stage.slowmo_timer = stage.slowmo_duration
        end
    end
end

function love.draw()
    if stage.game_over then
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("GAME OVER", 0, love.graphics.getHeight() / 2 - 20,
            love.graphics.getWidth(), "center")
    end
    stage:draw()
end