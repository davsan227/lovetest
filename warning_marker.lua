-- warning_marker.lua
local Classic = require "libs.classic"
local Timer = require "libs.hump.timer"
local WarningMarker = Classic:extend()

-- Configuration for the warning marker
local WARNING_RADIUS = 30
local WARNING_DURATION = 2.0 

function WarningMarker:new(area, x, y, on_timeout_func)
    self.area = area
    self.x, self.y = x, y
    self.dead = false
    self.radius = WARNING_RADIUS
    self.shape = nil -- No collision needed
    
    -- The function to run when the timer is done (e.g., spawn the enemy)
    self.on_timeout_func = on_timeout_func 
    
    -- Start the countdown
    self.timer = Timer()
    self.timer:after(WARNING_DURATION, function()
        self:execute_timeout()
    end)
end

function WarningMarker:execute_timeout()
    -- Run the function that was passed in (e.g., spawn the shooter)
    if self.on_timeout_func then
        self.on_timeout_func(self.area, self.x, self.y)
    end
    
    -- Mark the warning for removal
    self.dead = true
end

function WarningMarker:update(dt)
    self.timer:update(dt) 

    -- Optional: Pulse the radius for a visual effect
    self.radius = WARNING_RADIUS + 3 * math.sin(love.timer.getTime() * 10)
end

function WarningMarker:draw()
    -- Pulsing color (e.g., Orange/Yellow)
    local alpha = 0.5 + 0.5 * math.abs(math.sin(love.timer.getTime() * 8))
    love.graphics.setColor(1, 0.5, 0, alpha) 
    love.graphics.setLineWidth(2)
    
    -- Draw a line circle (outline)
    love.graphics.circle("line", self.x, self.y, self.radius) 

    love.graphics.setLineWidth(1) 
    love.graphics.setColor(1, 1, 1) -- Reset color
end

function WarningMarker:destroy()
    self.timer:clear()
end

return WarningMarker