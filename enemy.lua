-- enemy.lua
local Classic = require "libs.classic"
local Timer = require "libs.hump.timer"
local HC = require "libs.HC"

local Enemy = Classic:extend()

function Enemy:new(area, x, y)
    self.area = area
    self.x, self.y = x, y
    self.radius = 20 -- same as original
    self.hitbox_radius = self.radius * 0.75
    self.dead = false
    self.shape = HC.circle(self.x, self.y, self.hitbox_radius)

    -- default velocity (can be overwritten later)
    self.vx = 0
    self.vy = 0

    -- explosion
    self.exploding = false
    self.explosion_radius = 0
    self.explosion_duration = 0.3
    self.explosion_timer = 0

    self.timer = Timer()
end

function Enemy:update(dt)
    -- handle explosion
    if self.exploding then
        self.explosion_timer = self.explosion_timer + dt
        local t = self.explosion_timer / self.explosion_duration
        self.explosion_radius = self.radius + t * 50
        if self.explosion_timer >= self.explosion_duration then
            self.dead = true
            self.exploding = false
        end
        return
    end

    -- move
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt

    -- Remove if out of bounds (no rebound)
    local w, h = love.graphics.getDimensions()
    local buffer = 200 -- big enough so enemies spawn far outside
    if self.x < -buffer or self.x > w + buffer or self.y < -buffer or self.y > h + buffer then
        self.dead = true
        print("Enemy died immediately at:", self.x, self.y) 
    end

    -- move the hitbox
    if self.shape then
        self.shape:moveTo(self.x, self.y)
    end
end

function Enemy:explode()
    if self.exploding then
        return
    end
    self.exploding = true
    self.explosion_timer = 0
    self.explosion_radius = self.radius

    -- score
    if self.area.stage then
        self.area.stage.score = self.area.stage.score + 10
    end

    -- delayed chain reaction
    for _, obj in ipairs(self.area.game_objects) do
        if not obj.dead and obj ~= self and obj ~= self.area.stage.player_circle then
            local dx, dy = obj.x - self.x, obj.y - self.y
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist < 100 then
                local delay = dist / 250
                self.area.stage.timer:after(delay, function()
                    if obj.explode then
                        obj:explode() -- pass no area needed, objects list can be accessed inside explode()
                    else
                        obj.dead = true
                    end
                end)
            end
        end
    end

end

function Enemy:destroy()
    if self.shape then
        HC.remove(self.shape)
        self.shape = nil
    end
end

function Enemy:draw()
    if self.exploding then
        local t = self.explosion_timer / self.explosion_duration
        local alpha = 1 - t
        love.graphics.setColor(1, 0, 0, alpha)
        love.graphics.circle("fill", self.x, self.y, self.explosion_radius)
        love.graphics.setColor(1, 1, 1)
        return
    end

    -- Calculate darkness based on speed
    local speed = math.sqrt(self.vx * self.vx + self.vy * self.vy)
    local min_speed, max_speed = 50, 200 -- adjust max_speed if needed
    local darkness = (speed - min_speed) / (max_speed - min_speed)
    darkness = math.max(0, math.min(darkness, 1)) -- clamp between 0 and 1

    -- Stronger red: keep red at 1, reduce green/blue as speed increases
    love.graphics.setColor(1, 0.3 * (1 - darkness), 0.3 * (1 - darkness))
    love.graphics.circle("fill", self.x, self.y, self.radius)
    love.graphics.setColor(1, 1, 1)

end

return Enemy
