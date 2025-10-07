local Enemy = require "enemy"
local Classic = require "libs.classic"

local Formations = Classic:extend()

function Formations:new(area)
    self.area = area
end

function Formations:line(count, startX, startY, targetX, targetY, spacing, speedMin, speedMax)
    count = math.max(2, count)
    print("Spawning formation with count:", count)
    
    spacing = spacing or 100
    if spacing < 1 then spacing = 100 end

    local angle = math.atan2(targetY - startY, targetX - startX)
    local perpAngle = angle + math.pi / 2
    local speed = love.math.random(speedMin, speedMax) -- shared speed

    for i = 1, count do
        local offset = (i - (count + 1) / 2) * spacing
        local x = startX + math.cos(perpAngle) * offset
        local y = startY + math.sin(perpAngle) * offset

        -- stagger middle enemy slightly forward
        if count % 2 == 1 and i == math.ceil(count / 2) then
            local stagger = spacing * 0.3
            x = x + math.cos(angle) * stagger
            y = y + math.sin(angle) * stagger
        end

        local enemy = Enemy(self.area, x, y)
        enemy.vx = math.cos(angle) * speed
        enemy.vy = math.sin(angle) * speed
        self.area:add(enemy)
    end
end

return Formations
