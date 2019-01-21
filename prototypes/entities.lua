DIRECTIONS = {"North", "East", "South", "West"}
TYPECOLORS = {
    {nil,       {r=1, g=1, b=1, a=.6}},
    {"Input",  {g=1, a=.6}},
    {"Output", {r=1, a=.6}}
}

for _,TYPECOLOR in ipairs(TYPECOLORS) do
    local TYPE  = TYPECOLOR[1] or ""
    local COLOR = TYPECOLOR[2]

    for _,DIRECTION in ipairs(DIRECTIONS) do

        data:extend(
        {
            {
                type = "simple-entity",
                name = "TA-Arrow" .. DIRECTION .. TYPE,
                flags = {"placeable-off-grid"},
                render_layer = "arrow",
                collision_mask = {"layer-11"},
                picture =
                {
                    filename = "__throughput-analyser__/graphics/TA-Arrow" .. 
                                DIRECTION .. ".png",
                    width = 32,
                    height = 32,
                    tint = COLOR
                }
            }
        })
    end
end