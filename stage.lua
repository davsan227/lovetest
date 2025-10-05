local Enemy = require "enemy"
local Player = require "player"
local Area = require "area"
local Classic = require "libs.classic"
local Timer = require "libs.hump.timer"
local bump = require "libs.bump.bump"

local Stage = Classic:extend()

function Stage:new(input)
    -- Timer & world
    self.timer = Timer()
    self.world = bump.newWorld(50)
    self.area = Area(self)
    self.score = 0
    self.game_over = false

    -- Player
    self.player_circle = Player(self.area, 400, 300, input)
    self.area:add(self.player_circle)
    local r = self.player_circle.hitbox_radius or self.player_circle.radius
    self.world:add(self.player_circle, self.player_circle.x - r, self.player_circle.y - r, r*2, r*2)

    -- Slow motion
    self.slowmo_timer = 0
    self.slowmo_duration = 1.5
    self.slowmo_factor = 0.3

    -- Enemy spawn
    self.spawn_timer = 0
    self.spawn_interval = 0.2
    self.enemy_speed_min = 50
    self.enemy_speed_max = 100
    self.difficulty_timer = 0

    -- Explosions
    self.max_explosions = 3
    self.explosions = 3
    self.last_score_checkpoint = 0

    -- Track active explosions
    self.activeExplosions = {}
end

-- === Update Helpers ===

function Stage:update(dt)
    local effective_dt = self:getSlowMoDT(dt)
    if self.game_over then return end

    self.timer:update(dt)
    self.area:update(effective_dt)

    self:updateCollisions()
    self:updateActiveExplosions()
    self:checkGameOver()
    self:rechargeExplosions()
    self:spawnEnemies(dt)
    self:increaseDifficulty(dt)
end

function Stage:getSlowMoDT(dt)
    if self.slowmo_timer > 0 then
        local effective_dt = dt * self.slowmo_factor
        self.slowmo_timer = self.slowmo_timer - dt
        if self.slowmo_timer < 0 then self.slowmo_timer = 0 end
        return effective_dt
    end
    return dt
end

function Stage:updateCollisions()
    local r = self.player_circle.hitbox_radius or self.player_circle.radius
    local actualX, actualY, cols, len = self.world:move(
        self.player_circle,
        self.player_circle.x,
        self.player_circle.y
    )

    for i = 1, len do
        local col = cols[i]
        if col.other.isEnemy then
            self.player_circle:hit()
        end
    end
end

function Stage:updateActiveExplosions()
    self.activeExplosions = {}
    for _, obj in ipairs(self.area.game_objects) do
        if obj.exploding then
            table.insert(self.activeExplosions, obj)
        end
    end
end

function Stage:checkGameOver()
    if self.explosions <= 0 and #self.activeExplosions == 0 then
        self.game_over = true
    end
end

function Stage:rechargeExplosions()
    if self.score - self.last_score_checkpoint >= 1000 then
        self.last_score_checkpoint = self.score
        self.explosions = math.min(self.explosions + 1, self.max_explosions)
    end
end

function Stage:spawnEnemies(dt)
    self.spawn_timer = self.spawn_timer + dt
    if self.spawn_timer < self.spawn_interval then return end
    self.spawn_timer = self.spawn_timer - self.spawn_interval

    local w, h = love.graphics.getDimensions()
    local x, y = self:getSpawnPosition(w, h)

    local targetX, targetY = self.player_circle.x, self.player_circle.y
    local angle = math.atan2(targetY - y, targetX - x)
    local speed = love.math.random(self.enemy_speed_min, self.enemy_speed_max)

    local enemy = Enemy(self.area, x, y)
    enemy.vx = math.cos(angle) * speed
    enemy.vy = math.sin(angle) * speed
    self.area:add(enemy)

    local r = enemy.radius
    self.world:add(enemy, x - r, y - r, r*2, r*2)
end

function Stage:getSpawnPosition(w, h)
    local edge = love.math.random(1, 4)
    if edge == 1 then return math.random(0, w), -20 end
    if edge == 2 then return math.random(0, w), h + 20 end
    if edge == 3 then return -20, math.random(0, h) end
    return w + 20, math.random(0, h)
end

function Stage:increaseDifficulty(dt)
    self.difficulty_timer = self.difficulty_timer + dt
    if self.difficulty_timer >= 10 then
        self.difficulty_timer = 0
        self.spawn_interval = math.max(0.3, self.spawn_interval - 0.1)
        self.enemy_speed_min = self.enemy_speed_min + 5
        self.enemy_speed_max = self.enemy_speed_max + 5
    end
end

-- === Draw ===
function Stage:draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Score: " .. self.score, 10, 10)
    love.graphics.print("Ships: " .. self.explosions, 10, 30)

    self.area:draw()

    local player = self.player_circle
    if player.exploded then
        local w, h = 40, 5
        local x, y = player.x - w/2, player.y - player.radius - 10
        local t = player.explode_timer / 3
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.rectangle("fill", x, y, w, h)
        love.graphics.setColor(0, 0.5, 1)
        love.graphics.rectangle("fill", x, y, w * t, h)
        love.graphics.setColor(1, 1, 1)
    end
end

return Stage
