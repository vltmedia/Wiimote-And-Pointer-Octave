function GetProperties()
    return {
        {name="targetName", type=DatumType.String, default="Untitled" },
		{name="health", type=DatumType.Integer, default=1 },
		{name="score", type=DatumType.Integer, default=1 },
		{name="description", type=DatumType.String },
        { name = "hitSound", type = DatumType.Asset },
    }
end

