local Classic = require "libs.classic"

local Area = Classic:extend()

function Area:new(stage)
    self.stage = stage
    self.game_objects = {}
end

function Area:add(obj)
    table.insert(self.game_objects, obj)
end

function Area:update(dt)
    for i = #self.game_objects, 1, -1 do
        local obj = self.game_objects[i]
        obj:update(dt)
        if obj.dead then
            table.remove(self.game_objects, i)
        end
    end
end

-- Handles pending chain explosions
function Area:processPending(chain)
    if not chain then return end
    local changed = true

    while changed do
        changed = false
        local i = 1
        while i <= #chain.pending do
            local obj = chain.pending[i]

            -- Clean up invalid objects
            if not obj or obj.dead or obj.exploded then
                table.remove(chain.pending, i)

            else
                print("isSpreadShooter;", obj.isSpreadShooter)
                print(obj.chainThreshold)
                local threshold = obj.chainThreshold or 1
                -- ✅ Check against total chain explosions (not nearby!)
                print("Checking pending object against threshold: " .. tostring(chain.count) .. " / " .. tostring(threshold))
                if chain.count >= threshold then
                    table.remove(chain.pending, i)
                    chain.pending_lookup[obj] = nil
                    obj:explode(chain)  -- will increment chain.count
                    changed = true
                else
                    print("Pending object did not meet threshold: " .. tostring(chain.count) .. " / " .. tostring(threshold))
                    chain.halted = true
                    self.stage.treshold_required = threshold
                    return
                end
            end
        end
    end
end


function Area:draw()
    for i, obj in ipairs(self.game_objects) do
        if obj and type(obj.draw) == "function" then
            obj:draw()
        else
            print("Error: object at index " .. i .. " missing draw method or is nil", obj)
        end
    end
end

return Area
