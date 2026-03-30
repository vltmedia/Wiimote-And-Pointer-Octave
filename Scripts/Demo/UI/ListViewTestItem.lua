ListViewTestItem = {}

function ListViewTestItem:GatherProperties()
	return {
		{name="background", type=DatumType.Quad },
		{name="titleText", type=DatumType.Widget },
		{name="categoryText", type=DatumType.Widget },
	}
end

function ListViewTestItem:Create()
	self.OnRun = Signal:Create()
end

function ListViewTestItem:Start()

    

end
function ListViewTestItem:GenerateItem(data)
	if self.titleText then
        self.titleText:SetText(data.title)
    end

	if self.categoryText then
        self.categoryText:SetText(data.category)
    end
    if self.background then
        self.background:SetColor(data.color)
    end


end


function ListViewTestItem:OnItemHoverEnter(data)
		local c = data.color
		self.background:SetColor(Vector:Create(
			math.min(c.x + 0.2, 1.0),
			math.min(c.y + 0.2, 1.0),
			math.min(c.z + 0.2, 1.0),
			c.w
		))
end

function ListViewTestItem:OnItemHoverExit(data)
	self.background:SetColor(data.color)
end



function ListViewTestItem:Tick(deltaTime)

end