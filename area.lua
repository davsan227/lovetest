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
