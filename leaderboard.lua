local json = require("objects/dkjson/dkjson")

local Leaderboard = {}
Leaderboard.__index = Leaderboard

Leaderboard.url = "https://ecgame-d742b-default-rtdb.asia-southeast1.firebasedatabase.app/leaderboard.json"
Leaderboard.scores = {}

-- Helper function to run cURL and return output
local function curl_request(cmd)
    local f = io.popen(cmd)
    if f then
        local output = f:read("*a")
        f:close()
        return output
    end
    return nil
end

-- Submit a score
function Leaderboard:submit(playerName, score)
    local payload = json.encode({ player = playerName, score = score })
    local cmd = string.format(
        'curl -s -X POST -H "Content-Type: application/json" -d "%s" "%s"',
        payload:gsub('"', '\\"'),
        self.url
    )
    local response = curl_request(cmd)
    print("Submitted:", response)
end

-- Fetch top 10 scores
function Leaderboard:getTop()
    local cmd = string.format('curl -s "%s"', self.url)
    local content = curl_request(cmd)
    if content then
        local ok, decoded = pcall(json.decode, content)
        if ok and decoded then
            local scores = {}
            for k, v in pairs(decoded) do
                if v and v.player and v.score then
                    table.insert(scores, v)
                end
            end
            table.sort(scores, function(a, b) return a.score > b.score end)
            self.scores = {}
            for i = 1, math.min(10, #scores) do
                table.insert(self.scores, scores[i])
            end
        else
            print("Failed to decode leaderboard JSON")
            self.scores = {}
        end
    else
        print("Failed to fetch leaderboard via cURL")
        self.scores = {}
    end
end

-- Draw leaderboard
function Leaderboard:draw(x, y)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Leaderboard", x, y)
    local line = 1
    for i, entry in ipairs(self.scores) do
        love.graphics.print(i .. ". " .. entry.player .. " - " .. entry.score, x, y + line * 20)
        line = line + 1
    end
end

return Leaderboard
