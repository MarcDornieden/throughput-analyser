local CONST = require("constants")

local Block = {}
Block.__index = Block

function Block.new(firstEntity)
   local self = setmetatable({}, Block)
   self.entities = {firstEntity}
   self.inputEntities = {}
   self.outputEntities = {}
   self.type = firstEntity.type
   self.entityName = firstEntity.name
   self:UpdateThroughput()
   self:UpdateID()

   return self
end

function Block.FromEntity(firstEntity)
   local self = Block.new(firstEntity)
   self:Scan()
   self:UpdateID()
   return self
end

function Block:UpdateID()
   self.ID = Pos2ID(self.entities[1].position)
end

function Block:UpdateThroughput()

   self.throughput = CONST.THROUGHPUT[self.entityName:gsub("-", "_")] or 0
   
   DebugAssert(self.throughput > 0)
end

function Block:Contains(entity)
   return isEntityInList(self.entities, entity)
end

function Block:Scan()

   local todo = {{self.entities[1], nil}}
   local cycles = 0 -- failsave to prevent infinite loops. Probably not needed when everything is working

   while #todo > 0 and cycles < 10000 do
      cycles = cycles + 1

      local currEntity = todo[1][1]
      local currEntityID = Pos2ID(currEntity.position)

      local ignorePos = todo[1][2]

      local inputEntities, outputEntities = getAdjacentInputsAndOutputs(currEntity, ignorePos)

      for _,inputEntity in ipairs(inputEntities) do
         if TypesCompatible(inputEntity.type, self.type) then
            if self:Contains(inputEntity) == false then
               table.insert(self.entities, 1, inputEntity)
               table.insert(todo, {inputEntity, currEntity.position})
            end

         elseif not isEntityInList(self.inputEntities, inputEntity) then

            if self.inputEntities[currEntityID] == nil then
               self.inputEntities[currEntityID] = {}
            end

            table.insert(self.inputEntities[currEntityID], inputEntity)
         end
      end

      for _,outputEntity in ipairs(outputEntities) do
         if TypesCompatible(outputEntity.type, self.type) then
            if self:Contains(outputEntity) == false then
               table.insert(self.entities, outputEntity)
               table.insert(todo, {outputEntity, currEntity.position})
            end

         elseif not isEntityInList(self.outputEntities, outputEntity) then

            if self.outputEntities[currEntityID] == nil then
               self.outputEntities[currEntityID] = {}
            end

            table.insert(self.outputEntities[currEntityID], outputEntity)
         end
      end

      table.remove(todo, 1)
   end

   if cycles == 10000 then
      game.print("Had to prevent infinite loop.")
   end

   self:UpdateID()

   return self
end

function Block:CalcSaturations()
   for index,entity in ipairs(self.entities) do
      
      local entityID = Pos2ID(entity.position)

      if self.outputEntities[entityID] then
         
         local entitySaturation = self.entities[index].saturation

         for _,outputEntity in ipairs(self.outputEntities[entityID]) do
            
            --entitySaturation = entitySaturation - outputEntity.saturation
         end

         if entitySaturation < 0 then
            game.print("Not enough items at " .. Pos2Str(entity.position))
         end
      end
   end
end

function Block:Label(visualizer)
   
   for i,entity in ipairs(self.entities) do
      visualizer:DrawOverlay(entity)
      visualizer:DrawTextOverlay(entity, i)
   end

   for entityID,inputEntities in pairs(self.inputEntities) do
      for _,entity in ipairs(inputEntities) do
         visualizer:DrawOverlay(entity, CONST.INPUT)
      end
   end

   for entityID,outputEntities in pairs(self.outputEntities) do
      for _,entity in ipairs(outputEntities) do
         visualizer:DrawOverlay(entity, CONST.OUTPUT)
      end
   end

end

return Block