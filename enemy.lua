-- enemy.lua
local Classic = require "objects.classic"
local Timer   = require "objects/hump/timer"

local Enemy = Classic:extend()

function Enemy:new(area, x, y)
    self.area = area
    self.x, self.y = x, y
    self.radius = 20          -- same as original
    self.dead = false

    -- random velocity
    local angle = love.math.random() * 2 * math.pi
    local speed = love.math.random(50, 100)
    self.vx = math.cos(angle) * speed
    self.vy = math.sin(angle) * speed

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

    local w, h = love.graphics.getDimensions()
    if self.x - self.radius < 0 then self.x = self.radius; self.vx = -self.vx end
    if self.x + self.radius > w then self.x = w - self.radius; self.vx = -self.vx end
    if self.y - self.radius < 0 then self.y = self.radius; self.vy = -self.vy end
    if self.y + self.radius > h then self.y = h - self.radius; self.vy = -self.vy end
end

function Enemy:explode(area)
    if self.exploding then return end

    self.exploding = true
    self.explosion_timer = 0
    self.explosion_radius = self.radius

    -- score
    if area.stage then
        area.stage.score = area.stage.score + 10
    end

    -- delayed chain reaction
    for _, obj in ipairs(area.game_objects) do
        if not obj.dead and obj ~= self and obj ~= area.stage.player_circle then
            local dx, dy = obj.x - self.x, obj.y - self.y
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist < 100 then  -- same chain distance as original
                local delay = dist / 250
                area.stage.timer:after(delay, function()
                    if obj.explode then
                        obj:explode(area)
                    else
                        obj.dead = true
                    end
                end)
            end
        end
    end
end

function Enemy:draw()
    if self.exploding then
        local t = self.explosion_timer / self.explosion_duration
        local alpha = 1 - t
        love.graphics.setColor(1, 0, 0, alpha)
        love.graphics.circle("fill", self.x, self.y, self.explosion_radius)
        love.graphics.setColor(1,1,1)
        return
    end

    love.graphics.setColor(1, 0, 0)
    love.graphics.circle("fill", self.x, self.y, self.radius)
    love.graphics.setColor(1, 1, 1)
end

return Enemy
