-- stage.lua
local Player = require "player"
local Area = require "area"
local Classic = require "libs.classic"
Timer = require "libs.hump.timer"
local Formations = require "formations"
local Spawner = require "spawner"

local Stage = Classic:extend()

function Stage:new(input)
    self.timer = Timer()
    self.area = Area(self)
    self.score = 0
    self.game_over = false

    -- player circle
    self.player_circle = Player(self.area, 400, 300, input)
    self.area:add(self.player_circle)

    -- slow-motion
    self.slowmo_timer = 0
    self.slowmo_duration = 1.5
    self.slowmo_factor = 0.3

    -- spawn enemies
    self.spawn_timer = 0
    self.spawn_interval = 1.25 -- Timer for line formations
    self.enemy_speed_min = 50
    self.enemy_speed_max = 70
    self.difficulty_timer = 0
    self.formations = Formations(self.area)
    self.spawner = Spawner(self.area)

    self.max_explosions = 1000
    self.explosions = 100
    self.last_score_checkpoint = 0

    self.time_since_stage_start = 0

    -- === Shooter Spawning Variables ===
    self.shooter_max = 4 -- Maximum number of shooters allowed
    self.shooter_cooldown = 5 -- Seconds between shooter *attempts*
    self.shooter_timer = self.shooter_cooldown -- Dedicated timer for shooters
    self.first_shooter_delay = 5 -- Delay before first shooter can spawn
    self.first_shooter_spawned = false -- Flag to handle the initial delay
    self.shooter_death_count = 0
    self.spreadshooter_dead_count = 0
    self.spawnShooters = true
end

function Stage:update(dt)
    local effective_dt = dt
    if self.slowmo_timer > 0 then
        effective_dt = dt * self.slowmo_factor
        self.slowmo_timer = math.max(0, self.slowmo_timer - dt)
    end

    if self.game_over then
        return
    end

    self.timer:update(dt)
    self.area:update(effective_dt)

    -- Collision check (omitted for brevity)
    local player_shape = self.player_circle.shape
    for _, c in ipairs(self.area.game_objects) do
        if c ~= self.player_circle and not c.dead and c.shape and player_shape:collidesWith(c.shape) then
            self.player_circle:hit()
            break
        end
    end

    -- Remove dead objects (omitted for brevity)
    for i = #self.area.game_objects, 1, -1 do
        local obj = self.area.game_objects[i]
        if obj.dead then
            if obj.destroy then
                obj:destroy()
            end
            table.remove(self.area.game_objects, i)
        end
    end

    -- Check for active explosions (omitted for brevity)
    local active_explosions = false
    for _, obj in ipairs(self.area.game_objects) do
        if obj.exploding then
            active_explosions = true
            break
        end
    end
    if self.explosions <= 0 and not active_explosions then
        self.game_over = true
    end

    -- Explosion recharge (omitted for brevity)
    if self.score - self.last_score_checkpoint >= 2000 then
        self.last_score_checkpoint = self.score
        self.explosions = math.min(self.explosions + 1, self.max_explosions)
    end

    -- Update game timer
    self.time_since_stage_start = self.time_since_stage_start + dt

    -- ===================================
    -- === 1. Shooter Spawning Logic ===
    -- ===================================

    -- Only start checking after the initial delay
    -- if self.time_since_stage_start >= self.first_shooter_delay then
    --     self.shooter_timer = self.shooter_timer + dt

    --     -- Check if cooldown is ready
    --     if self.shooter_timer >= self.shooter_cooldown and self.spawnShooters == true then
    --         self.spawnShooters = true
    --         -- Attempt to spawn. The Spawner checks the max limit.
    --         local spawned = self.spawner:spawnShooterWithWarning(self.shooter_max)

    --         -- If a shooter was successfully spawned (i.e., the limit wasn't reached), reset the timer.
    --         if spawned then
    --             self.shooter_timer = 0
    --         end
    --     end
    -- end

    -- 1 metaball joins
    -- if  self.shooter_death_count >= 4 then
    self.spawnShooters = false
    -- self.spawner:spawnMetaballWithWarning(1, true)
    local patterns = {"spread", "storm", "hell"}
    local pattern = patterns[self.spreadshooter_dead_count + 1] -- +1 because Lua arrays start at 1

    if pattern then
        self.spawner:spawnSpreadShooterWithWarning(1, true, pattern)
    end

    -- end

    -- ===================================
    -- === 2. Line Formation Spawning Logic ===
    -- ===================================

    self.spawn_timer = self.spawn_timer + dt

    if self.spawn_timer >= self.spawn_interval then
        self.spawn_timer = self.spawn_timer - self.spawn_interval

        -- Spawn a line formation targeting the player
        self.spawner:spawnLineFormation(self.player_circle.x, self.player_circle.y, 50, self.enemy_speed_min,
            self.enemy_speed_max)
    end

end

function Stage:draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Score: " .. self.score, 10, 10)
    love.graphics.print("Ships: " .. self.explosions, 10, 30)

    self.area:draw()

    local player = self.player_circle
    if player.exploded then
        local w = 40
        local h = 5
        local x = player.x - w / 2
        local y = player.y - player.radius - 10
        local t = player.explode_timer / 3
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.rectangle("fill", x, y, w, h)
        love.graphics.setColor(0, 0.5, 1)
        love.graphics.rectangle("fill", x, y, w * t, h)
        love.graphics.setColor(1, 1, 1)
    end
end

return Stage
