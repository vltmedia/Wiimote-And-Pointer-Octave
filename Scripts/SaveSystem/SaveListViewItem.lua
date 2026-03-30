SaveListViewItem = {}

function SaveListViewItem:GatherProperties()
	return {
		{name="icon", type=DatumType.Quad },
		{name="nameText", type=DatumType.Widget },
		{name="coinsText", type=DatumType.Widget },
		{name="starsText", type=DatumType.Widget },
		{name="playtimeText", type=DatumType.Widget },
		{name="dateText", type=DatumType.Widget },
		{name="locationText", type=DatumType.Widget },
	}
end

function SaveListViewItem:Create()
	self.OnRun = Signal:Create()
end

function SaveListViewItem:Start()

    

end
function SaveListViewItem:GenerateItem(data)
	if data.isEmpty then
        -- Empty slot display
        if self.nameText then self.nameText:SetText("Empty Slot") end
        if self.coinsText then self.coinsText:SetText("") end
        if self.levelText then self.levelText:SetText("") end
        if self.starsText then self.starsText:SetText("") end
        if self.playtimeText then self.playtimeText:SetText("") end
        if self.dateText then self.dateText:SetText("") end
        if self.locationText then self.locationText:SetText("") end
        if self.icon then self.icon:SetColor({0.3, 0.3, 0.3, 0.5}) end
    else
        -- Populated slot display
        if self.nameText then self.nameText:SetText(data.name) end
        if self.coinsText then self.coinsText:SetText(tostring(data.coins) .. " coins") end
        if self.levelText then self.levelText:SetText("Lv." .. tostring(data.level)) end
        if self.starsText then self.starsText:SetText(tostring(data.stars) .. " stars") end
        if self.playtimeText then self.playtimeText:SetText(self.saveManager:FormatPlaytime(data.playtimeSeconds)) end
        if self.dateText then self.dateText:SetText(self.saveManager:FormatDate(data.saveTimestamp)) end
        if self.locationText then self.locationText:SetText(data.sceneName or "") end

        -- Set icon texture if specified
        if self.icon and data.iconPath and data.iconPath ~= "" then
            local tex = Asset.Load(data.iconPath)
            if tex then
                self.icon:SetTexture(tex)
                self.icon:SetColor({1, 1, 1, 1})
            end
        elseif self.icon then
            self.icon:SetColor({1, 1, 1, 1})
        end
    end

end


function SaveListViewItem:OnItemHoverEnter(data)
		local c = data.color
		self.background:SetColor(Vector:Create(
			math.min(c.x + 0.2, 1.0),
			math.min(c.y + 0.2, 1.0),
			math.min(c.z + 0.2, 1.0),
			c.w
		))
end

function SaveListViewItem:OnItemHoverExit(data)
	self.background:SetColor(data.color)
end



function SaveListViewItem:Tick(deltaTime)

end