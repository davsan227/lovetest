-- player.lua
local Classic = require "libs.classic"
    local HC = require "libs.HC"


local Player = Classic:extend()

function Player:new(area, x, y, input)
    self.area = area
    self.x, self.y = x, y
    self.radius = 15
    self.hitbox_radius = self.radius * 0.50
    self.shape = HC.circle(self.x, self.y, self.hitbox_radius or self.radius)
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

    -- invulnerability
    self.invulnerable = false
    self.invul_duration = 1.5
    self.invul_timer = 0
end

function Player:update(dt)
    if self.area.stage.game_over then
        return
    end

    self:move(dt)

    -- handle explosion effect
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

    -- invulnerability countdown
    if self.invulnerable then
        self.invul_timer = self.invul_timer - dt
        if self.invul_timer <= 0 then
            self.invulnerable = false
            self.invul_timer = 0
        end
    end

    if self.shape then
        self.shape:moveTo(self.x, self.y)
    end
end

function Player:destroy()
    if self.shape then
        HC.remove(self.shape)
        self.shape = nil
    end
end

function Player:move(dt)
    local dx, dy = 0, 0
    if self.input:down("left_key") then
        dx = dx - 1
    end
    if self.input:down("right_key") then
        dx = dx + 1
    end
    if self.input:down("up_key") then
        dy = dy - 1
    end
    if self.input:down("down_key") then
        dy = dy + 1
    end

    local len = math.sqrt(dx * dx + dy * dy)
    if len > 0 then
        dx, dy = dx / len, dy / len
        self.x, self.y = self.x + dx * self.speed * dt, self.y + dy * self.speed * dt
    end
end

-- called when player triggers explosion manually
function Player:explode(objects)
    if self.exploding then
        return
    end -- prevent starting another explosion during active explosion
    if self.exploded then
        return
    end -- already exploded (cooldown)

    if self.area.stage.explosions <= 0 then
        return
    end

    -- subtract 1 explosion
    self.area.stage.explosions = self.area.stage.explosions - 1

    -- start explosion
    self.exploded = true
    self.explode_timer = 0
    self.exploding = true
    self.explosion_timer = 0
    self.explosion_radius = self.radius

    -- chain reaction
    for _, obj in ipairs(objects) do
        if not obj.dead and obj ~= self then
            local dx, dy = obj.x - self.x, obj.y - self.y
            if math.sqrt(dx * dx + dy * dy) < 100 then
                if obj.explode then
                    obj:explode(objects) -- pass the same list of objects
                else
                    obj.dead = true
                end
            end
        end
    end

    return true
end

-- called when player collides with an enemy
function Player:hit()
    if self.invulnerable then
        return
    end

    if self.area.stage.explosions > 0 then
        self.area.stage.explosions = self.area.stage.explosions - 1
        self.invulnerable = true
        self.invul_timer = self.invul_duration
        -- optional: small visual explosion on hit
        self.exploding, self.explosion_timer, self.explosion_radius = true, 0, self.radius
    else
        self.area.stage.game_over = true
    end
end

function Player:draw()
    -- draw explosion if exploding
    if self.exploding then
        local t = self.explosion_timer / self.explosion_duration
        local alpha = 1 - t
        love.graphics.setColor(1, 0.5, 0, alpha)
        love.graphics.circle("fill", self.x, self.y, self.explosion_radius)
        love.graphics.setColor(1, 1, 1)
    end

    -- blinking when invulnerable
    local r, g, b, a = 0, 0.5, 1, 1
    if self.invulnerable then
        local blink = math.floor(love.timer.getTime() * 10) % 2
        if blink == 1 then
            a = 0.3
        end
    end

    if self.exploded then
        r, g, b, a = 0.5, 0.5, 0.5, 1
    end

    love.graphics.setColor(r, g, b, a)
    love.graphics.circle("fill", self.x, self.y, self.radius)

    -- draw hitbox
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", self.x, self.y, self.hitbox_radius)
end

return Player
