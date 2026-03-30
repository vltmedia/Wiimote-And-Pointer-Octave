ListViewTest = {}

function ListViewTest:GatherProperties()
    return {
    }
end

function ListViewTest:Create()
    self.OnRun = Signal:Create()
end

function ListViewTest:Start()
    -- Sample data with title, category, and color
    local items = {
        { title = "Fire Sword", category = "Weapon", color = Vector:Create(1.0, 0.3, 0.2, 1.0) },
        { title = "Iron Shield", category = "Armor", color = Vector:Create(0.5, 0.5, 0.6, 1.0) },
        { title = "Health Potion", category = "Consumable", color = Vector:Create(0.2, 0.8, 0.3, 1.0) },
        { title = "Magic Staff", category = "Weapon", color = Vector:Create(0.6, 0.3, 0.9, 1.0) },
        { title = "Golden Ring", category = "Accessory", color = Vector:Create(1.0, 0.85, 0.2, 1.0) },
        { title = "Mana Crystal", category = "Consumable", color = Vector:Create(0.3, 0.5, 1.0, 1.0) },
    }

    -- Set the data on the ListView
    self:SetData(items)
end

function ListViewTest:OnItemGenerate(index, data, itemWidget)
    -- Get the content widget (the instantiated template)
    local content = itemWidget:GetContentWidget()
    if content == nil then
        return
    end
    -- Find and set the title text
    content:GenerateItem(data)
end

function ListViewTest:OnItemUpdate(index, data, itemWidget)
    -- Same as generate - refresh the content
    self:OnItemGenerate(index, data, itemWidget)
end

function ListViewTest:OnItemClicked(index, data)
    Log.Debug("Clicked: " .. data.title .. " (" .. data.category .. ")")
end

function ListViewTest:OnItemHoverEnter(index, data)
    -- Optional: highlight effect
    local item = self:GetItem(index)
    if item then
        local content = item:GetContentWidget()
        if content then
            content:OnItemHoverEnter(data)
        end
    end
end

function ListViewTest:OnItemHoverExit(index, data)
    -- Restore original color
    local item = self:GetItem(index)
    if item then
        local content = item:GetContentWidget()
        if content then
            content:OnItemHoverExit(data)
        end
    end
end

function ListViewTest:OnSelectionChanged(index, data)
    if index >= 0 then
        Log.Debug("Selected: " .. data.title)
    else
        Log.Debug("Selection cleared")
    end
end

function ListViewTest:Tick(deltaTime)

end
