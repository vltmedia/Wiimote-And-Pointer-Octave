SaveListViewItem = {}

function SaveListViewItem:GatherProperties()
	return {
		{name="emptyWidget", type=DatumType.Widget },
		{name="dataWidget", type=DatumType.Widget },
		{name="background", type=DatumType.Widget },
		{name="icon", type=DatumType.Quad },
		{name="nameText", type=DatumType.Widget },
		{name="coinsText", type=DatumType.Widget },
		{name="starsText", type=DatumType.Widget },
		{name="playtimeText", type=DatumType.Widget },
		{name="dateText", type=DatumType.Widget },
		{name="locationText", type=DatumType.Widget },
		{name="normalColor", type=DatumType.Color },
		{name="selectedColor", type=DatumType.Color },
	}
end

function SaveListViewItem:Create()
	self.OnRun = Signal:Create()
	self.OnSelected = Signal:Create()
    self.index = 0
    self.isSelected = false
    self.isEmpty = false
end

function SaveListViewItem:Start()

    

end

function SaveListViewItem:SetIndex(index)

    self.index = index

end
function SaveListViewItem:SetSelected(empty)
    self.isSelected = true
    self.isEmpty = empty
    self.OnSelected:Emit(self)
end

function SaveListViewItem:GenerateItem(data)

    self.isEmpty = data.isEmpty

	if data.isEmpty then
        self.dataWidget:SetActive(false)
        self.dataWidget:SetVisible(false)
        self.emptyWidget:SetActive(true)
        self.emptyWidget:SetVisible(true)
    else
        self.dataWidget:SetActive(true)
        self.dataWidget:SetVisible(true)
        self.emptyWidget:SetActive(false)
        self.emptyWidget:SetVisible(false)
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
    if not self.background then return end
    local baseColor = self.isSelected and (self.selectedColor or Vector:Create(0.3, 0.5, 0.8, 1.0))
                                       or (self.normalColor or Vector:Create(0.2, 0.2, 0.2, 1.0))
    self.background:SetColor(Vector:Create(
        math.min(baseColor.x + 0.15, 1.0),
        math.min(baseColor.y + 0.15, 1.0),
        math.min(baseColor.z + 0.15, 1.0),
        baseColor.w
    ))
end

function SaveListViewItem:OnItemHoverExit(data)
    if not self.background then return end
    if self.isSelected then
        self.background:SetColor(self.selectedColor or Vector:Create(0.3, 0.5, 0.8, 1.0))
    else
        self.background:SetColor(self.normalColor or Vector:Create(0.2, 0.2, 0.2, 1.0))
    end
end



function SaveListViewItem:Tick(deltaTime)

end