-- SaveManager.lua
-- Handles save/load operations using Octave's Stream-based serialization

SaveManager = {}
SaveManager.Instance = nil

function SaveManager:GatherProperties()
    return {
        {name="savePrefix", type=DatumType.String, default = "save_slot_" },
        {name="maxSlots", type=DatumType.Integer, default = 5 },
    }
end

function SaveManager:Start()
    SaveManager.Instance = self
end
-- Read save data from a slot
-- Returns nil if slot is empty
function SaveManager:GetSaveInfo(slotIndex)
    local saveName = self.savePrefix .. tostring(slotIndex)
    if not System.DoesSaveExist(saveName) then
        return nil
    end

    local stream = Stream()
    System.ReadSave(saveName, stream)
    stream:SetPos(0)

    return {
        name = stream:ReadString(),
        coins = stream:ReadInt32(),
        level = stream:ReadInt32(),
        stars = stream:ReadInt32(),
        iconPath = stream:ReadString(),
        playtimeSeconds = stream:ReadInt32(),
        saveTimestamp = stream:ReadInt64(),
        sceneName = stream:ReadString()
    }
end

-- Write save data to a slot
function SaveManager:WriteSave(slotIndex, data)
    local saveName = self.savePrefix .. tostring(slotIndex)
    local stream = Stream()

    stream:WriteString(data.name or "Player")
    stream:WriteInt32(data.coins or 0)
    stream:WriteInt32(data.level or 1)
    stream:WriteInt32(data.stars or 0)
    stream:WriteString(data.iconPath or "")
    stream:WriteInt32(data.playtimeSeconds or 0)
    stream:WriteInt64(os.time())  -- Current timestamp
    stream:WriteString(data.sceneName or "")

    System.WriteSave(saveName, stream)
end

-- Delete a save slot
function SaveManager:DeleteSave(slotIndex)
    local saveName = self.savePrefix .. tostring(slotIndex)
    if System.DoesSaveExist(saveName) then
        System.DeleteSave(saveName)
    end
end


function SaveManager:Create()
    self.selectedSlot = nil
end


-- Check if a save slot exists
function SaveManager:DoesSaveExist(slotIndex)
    local saveName = self.savePrefix .. tostring(slotIndex)
    return System.DoesSaveExist(saveName)
end

-- Get all save slots (empty or populated)
function SaveManager:GetAllSaveSlots()
    local slots = {}
    for i = 1, self.maxSlots do
        local info = self:GetSaveInfo(i)
        if info then
            info.slotIndex = i
            info.isEmpty = false
        else
            info = { slotIndex = i, isEmpty = true, name = "Empty Slot" }
        end
        table.insert(slots, info)
    end
    return slots
end

function SaveManager:SetSelectedSlot(slot)
    self.selectedSlot = slot
end

-- Format playtime in seconds to "Xh Xm" string
function SaveManager:FormatPlaytime(seconds)
    if not seconds or seconds == 0 then
        return "0h 0m"
    end
    local hours = math.floor(seconds / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    return string.format("%dh %dm", hours, mins)
end

-- Format timestamp to readable date string
function SaveManager:FormatDate(timestamp)
    if not timestamp or timestamp == 0 then
        return ""
    end
    return os.date("%b %d, %Y", timestamp)
end

-- Format timestamp to readable time string
function SaveManager:FormatTime(timestamp)
    if not timestamp or timestamp == 0 then
        return ""
    end
    return os.date("%H:%M", timestamp)
end

-- Format timestamp to full datetime string
function SaveManager:FormatDateTime(timestamp)
    if not timestamp or timestamp == 0 then
        return ""
    end
    return os.date("%b %d, %Y %H:%M", timestamp)
end

