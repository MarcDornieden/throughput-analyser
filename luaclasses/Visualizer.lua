local Visualizer = {}
Visualizer.__index = Visualizer

function Visualizer.new()
   local self = setmetatable({}, Visualizer)
   self.overlayEntities = {}
   return self
end


function Visualizer:DrawOverlay(entity, inputOutput)
   inputOutput = inputOutput or ""

   direction = GetDirection(entity)
   directionStr = GetDirectionStr(direction)

   local overlayEntity = game.surfaces[1].create_entity{
      name = "TA-Arrow" .. directionStr .. inputOutput,
      position = entity.position,
      force = game.forces.player
   }

   table.insert(self.overlayEntities, overlayEntity)
   return overlayEntity
end

function Visualizer:DrawTextOverlay(entity, txt)

   local overlayEntity = game.surfaces[1].create_entity{
      name = "flying-text",
      position = entity.position,
      force = game.forces.player,
      text = txt
   }
   overlayEntity.active = false

   table.insert(self.overlayEntities, overlayEntity)
   return overlayEntity
end

function Visualizer:Clear()
   for _,entity in ipairs(self.overlayEntities) do
      entity.destroy()
   end
end

return Visualizer