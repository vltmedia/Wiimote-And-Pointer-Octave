
NameGenerator = {}


Adjectives = {
    { value = "Brave", type = "adjective" },
    { value = "Tiny", type = "adjective" },
    { value = "Happy", type = "adjective" },
    { value = "Sparkly", type = "adjective" },
    { value = "Bouncy", type = "adjective" },
    { value = "Cozy", type = "adjective" },
    { value = "Cheery", type = "adjective" },
    { value = "Zany", type = "adjective" },
    { value = "Snappy", type = "adjective" },
    { value = "Fuzzy", type = "adjective" },
    { value = "Shiny", type = "adjective" },
    { value = "Wiggly", type = "adjective" },
    { value = "Jolly", type = "adjective" },
    { value = "Peppy", type = "adjective" },
    { value = "Sunny", type = "adjective" },
    { value = "Chirpy", type = "adjective" },
    { value = "Nimble", type = "adjective" },
    { value = "Playful", type = "adjective" },
    { value = "Lucky", type = "adjective" },
    { value = "Curious", type = "adjective" },
    { value = "Daring", type = "adjective" },
    { value = "Swift", type = "adjective" },
    { value = "Glowy", type = "adjective" },
    { value = "Fluffy", type = "adjective" },
    { value = "Silly", type = "adjective" },
    { value = "Whirly", type = "adjective" },
    { value = "Clever", type = "adjective" },
    { value = "Merry", type = "adjective" },
    { value = "Bright", type = "adjective" },
    { value = "Charming", type = "adjective" }
}

Nouns = {
    { value = "Star", type = "noun" },
    { value = "Cloud", type = "noun" },
    { value = "Sprout", type = "noun" },
    { value = "Pebble", type = "noun" },
    { value = "Comet", type = "noun" },
    { value = "Buddy", type = "noun" },
    { value = "Critter", type = "noun" },
    { value = "Puff", type = "noun" },
    { value = "Bloom", type = "noun" },
    { value = "Button", type = "noun" },
    { value = "Twig", type = "noun" },
    { value = "Breeze", type = "noun" },
    { value = "Doodle", type = "noun" },
    { value = "Hopper", type = "noun" },
    { value = "Wisp", type = "noun" },
    { value = "Berry", type = "noun" },
    { value = "Nook", type = "noun" },
    { value = "Puddle", type = "noun" },
    { value = "Whisker", type = "noun" },
    { value = "Glowbug", type = "noun" },
    { value = "Acorn", type = "noun" },
    { value = "Feather", type = "noun" },
    { value = "Lantern", type = "noun" },
    { value = "Meadow", type = "noun" },
    { value = "River", type = "noun" },
    { value = "Drift", type = "noun" },
    { value = "Petal", type = "noun" },
    { value = "Nest", type = "noun" },
    { value = "Trail", type = "noun" },
    { value = "Echo", type = "noun" }
}


function NameGenerator:GatherProperties()
	return {

	}
end

function NameGenerator:Create()
	self.OnRun = Signal:Create()
end

function NameGenerator:Start()


end
function NameGenerator:Tick(deltaTime)

end

function NameGenerator:getRandom(tbl)
    return tbl[math.random(#tbl)]
end

-- Utility: check if two words start with same letter
function NameGenerator:isAlliteration(a, b)
    return string.sub(a:lower(), 1, 1) == string.sub(b:lower(), 1, 1)
end

function NameGenerator:GetAdjectives()
	return Adjectives
end
function NameGenerator:GetNouns()
	return Adjectives
end

-- Main generator
-- opts = {
--   alliterationBias = 0.0 to 1.0 (chance to try matching letters)
-- }
function NameGenerator:GenerateName( opts)
    opts = opts or {}
    local bias = opts.alliterationBias or 0

    local adj = NameGenerator:getRandom(Adjectives)
    local noun = NameGenerator:getRandom(Nouns)

    -- Try to enforce alliteration if bias hits
    if bias > 0 and math.random() < bias then
        local targetLetter = string.sub(adj.value:lower(), 1, 1)

        -- find matching noun
        local matches = {}
        for _, n in ipairs(Nouns) do
            if string.sub(n.value:lower(), 1, 1) == targetLetter then
                table.insert(matches, n)
            end
        end

        if #matches > 0 then
            noun = matches[math.random(#matches)]
        end
    end

    return adj.value .. " " .. noun.value
end
function NameGenerator:GenerateNames(count, opts)
    local outputNames = {}
    local usedNames = {}
    local maxAttempts = count * 10

    local attempts = 0
    while #outputNames < count and attempts < maxAttempts do
        local name = self:GenerateName(opts)
        if not usedNames[name] then
            usedNames[name] = true
            table.insert(outputNames, name)
        end
        attempts = attempts + 1
    end

    return outputNames
end