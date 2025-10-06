-- bullet.lua
local Classic = require "libs.classic"
local HC = require "libs.HC"

local Bullet = Classic:extend()

function Bullet:new(area, x, y, vx, vy)
    self.area = area
    self.x, self.y = x, y
    self.vx, self.vy = vx, vy
    self.radius = 5
    self.dead = false
    self.shape = HC.circle(self.x, self.y, self.radius)
end

function Bullet:update(dt)
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt

    -- remove if out of screen
    local w, h = love.graphics.getDimensions()
    if self.x < -self.radius*2 or self.x > w+self.radius*2 or
       self.y < -self.radius*2 or self.y > h+self.radius*2 then
        self.dead = true
    end

    if self.shape then
        self.shape:moveTo(self.x, self.y)
    end

    -- check collision with player
    local player = self.area.stage.player_circle
    if player and not player.dead and self.shape:collidesWith(player.shape) then
        player:hit()
        self.dead = true
    end
end

function Bullet:draw()
    love.graphics.setColor(1, 1, 0)
    love.graphics.circle("fill", self.x, self.y, self.radius)
    love.graphics.setColor(1, 1, 1)
end

return Bullet
