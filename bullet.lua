local Classic = require "libs.classic"
local HC = require "libs.HC"

local Bullet = Classic:extend()

function Bullet:new(area, x, y, vx, vy, opts)
    self.area = area
    self.x, self.y = x, y
    self.vx, self.vy = vx, vy
    self.radius = opts and opts.radius or 5
    self.dead = false
    self.shape = HC.circle(self.x, self.y, self.radius)
    
    -- optional bullet-hell parameters
    self.drag = opts and opts.drag or 1    -- slows bullet over time (0.9 = fast deceleration)
    self.life = opts and opts.life or 5        -- seconds until auto-destroy
end

function Bullet:update(dt)
    -- apply velocity
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt

    -- apply drag (slowing)
    self.vx = self.vx * self.drag
    self.vy = self.vy * self.drag

    -- reduce life
    self.life = self.life - dt
    if self.life <= 0 then
        self.dead = true
    end

    -- remove if out of screen (optional redundancy)
    local w, h = love.graphics.getDimensions()
    if self.x < -self.radius*2 or self.x > w+self.radius*2 or
       self.y < -self.radius*2 or self.y > h+self.radius*2 then
        self.dead = true
    end

    -- update collision shape
    if self.shape then
        self.shape:moveTo(self.x, self.y)
    end

    -- check collision with player
    local player = self.area.stage.player_circle
    if player and not player.dead and self.shape:collidesWith(player.shape) then
        player:hit()
        self.dead = true
    end

    -- if player is exploding, bullet dies
    if player and (player.exploding or player.exploded) then
        self.dead = true
    end
end

function Bullet:draw()
    love.graphics.setColor(1, 1, 0) -- yellow
    love.graphics.circle("fill", self.x, self.y, self.radius)
    love.graphics.setColor(1, 1, 1) -- reset color
end

return Bullet
