local Enemy = require "enemy"

local Formations = {}

function Formations.line(area, count, ...)
    count = math.max(2, count)
    print("Spawning formation with count:", count)
    local startX, startY, targetX, targetY, spacing, speedMin, speedMax = ...
    spacing = spacing or 50
    if spacing < 1 then spacing = 50 end
    local angle = math.atan2(targetY - startY, targetX - startX)
    local perpAngle = angle + math.pi / 2
    local speed = love.math.random(speedMin, speedMax) -- one speed for all

    for i = 1, count do
        local offset = (i - (count + 1) / 2) * spacing
        local x = startX + math.cos(perpAngle) * offset
        local y = startY + math.sin(perpAngle) * offset

        local enemy = Enemy(area, x, y)
        enemy.vx = math.cos(angle) * speed
        enemy.vy = math.sin(angle) * speed
        area:add(enemy)
    end
end

-- Only line formation remains

return Formations