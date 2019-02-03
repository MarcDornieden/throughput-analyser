local Visualizer = {}
Visualizer.__index = Visualizer

function Visualizer.new()
   local self = setmetatable({}, Visualizer)
   self.overlayEntities = {}
   return self
end


function Visualizer:DrawOverlay(entity, inputOutput)
   inputOutput = inputOutput or ""

   local overlayEntity = Entity.new(game.surfaces[1].create_entity{
      name = "TA-Arrow" .. self:GetDirectionStr(entity.direction) .. inputOutput,
      position = entity.position,
      force = game.forces.player
   })

   table.insert(self.overlayEntities, overlayEntity)
   return overlayEntity
end

function Visualizer:DrawTextOverlay(entity, txt)

   local overlayEntity = Entity.new(game.surfaces[1].create_entity{
      name = "flying-text",
      position = entity.position,
      force = game.forces.player,
      text = txt
   })
   overlayEntity.obj.active = false

   table.insert(self.overlayEntities, overlayEntity)
   return overlayEntity
end

function Visualizer:Clear()
   for _,entity in ipairs(self.overlayEntities) do
      entity.obj.destroy()
   end
end



function Visualizer:GetDirectionStr(direction)
   if     direction == CONST.DIRECTIONS.EAST  then return "East"
   elseif direction == CONST.DIRECTIONS.SOUTH then return "South"
   elseif direction == CONST.DIRECTIONS.WEST  then return "West" end
   return "North"
end

return Visualizer