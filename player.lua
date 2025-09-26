-- player.lua
local Classic = require "objects.classic"

local Player = Classic:extend()

function Player:new(area, x, y, input)
    self.area = area
    self.x, self.y = x, y
    self.radius = 15
    self.hitbox_radius = self.radius * 0.50
    self.dead = false

    self.input = input
    self.speed = 200

    -- explosion state
    self.exploded = false
    self.explode_timer = 0
    self.exploding = false
    self.explosion_radius = 0
    self.explosion_duration = 0.3
    self.explosion_timer = 0
end

function Player:update(dt)
    if self.area.stage.game_over then
        return
    end
    self:move(dt)

    if self.exploded then
        self.explode_timer = self.explode_timer + dt
        if self.explode_timer >= 3 then
            self.exploded, self.explode_timer = false, 0
        end
    end

    if self.exploding then
        self.explosion_timer = self.explosion_timer + dt
        local t = self.explosion_timer / self.explosion_duration
        self.explosion_radius = self.radius + t * 50
        if self.explosion_timer >= self.explosion_duration then
            self.exploding = false
        end
    end
end

function Player:move(dt)
    local dx, dy = 0, 0
    if self.input:down("left_key") then dx = dx - 1 end
    if self.input:down("right_key") then dx = dx + 1 end
    if self.input:down("up_key") then dy = dy - 1 end
    if self.input:down("down_key") then dy = dy + 1 end

    local len = math.sqrt(dx*dx + dy*dy)
    if len > 0 then
        dx, dy = dx/len, dy/len
        self.x, self.y = self.x + dx*self.speed*dt, self.y + dy*self.speed*dt
    end
end

function Player:explode(area)
    if self.exploded then return end
    if self.area.stage.explosions <= 0 then return end

    self.area.stage.explosions = self.area.stage.explosions - 1

    self.exploded, self.explode_timer = true, 0
    self.exploding, self.explosion_timer, self.explosion_radius = true, 0, self.radius

    for _, obj in ipairs(area.game_objects) do
        if not obj.dead and obj ~= self then
            local dx, dy = obj.x - self.x, obj.y - self.y
            if math.sqrt(dx*dx + dy*dy) < 100 then
                if obj.explode then
                    obj:explode(area)
                else
                    obj.dead = true
                end
            end
        end
    end
end

function Player:draw()
    if self.exploding then
        local t = self.explosion_timer / self.explosion_duration
        local alpha = 1 - t
        love.graphics.setColor(1, 0.5, 0, alpha)
        love.graphics.circle("fill", self.x, self.y, self.explosion_radius)
        love.graphics.setColor(1, 1, 1)
        return
    end

    if self.exploded then
        love.graphics.setColor(0.5, 0.5, 0.5)
    else
        love.graphics.setColor(0, 0.5, 1)
    end
    love.graphics.circle("fill", self.x, self.y, self.radius)

    love.graphics.setColor(1,1,1)
    love.graphics.circle("fill", self.x, self.y, self.hitbox_radius)
end

return Player
