local CONST = require("luaclasses.Constants")

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


function Block:Scan()

   local todo = {{self.entities[1], nil}}
   local cycles = 0 -- failsave to prevent infinite loops. Probably not needed when everything is working

   while #todo > 0 and cycles < 10000 do
      cycles = cycles + 1

      currEntity = todo[1][1]
      ignorePos = todo[1][2]

      local inputEntities, outputEntities = getAdjacentInputsAndOutputs(currEntity, ignorePos)

      for _,inputEntity in ipairs(inputEntities) do
         if TypesCompatible(inputEntity.type, self.type) then
            if isInBlock(self, inputEntity) == false then
               table.insert(self.entities, 1, inputEntity)
               table.insert(todo, {inputEntity, currEntity.position})
            end

         elseif not isEntityInList(self.inputEntities, inputEntity) then
            table.insert(self.inputEntities, 1, inputEntity)    -- TODO: Store them chronologically (along item-flow-direction)
         end
      end

      for _,outputEntity in ipairs(outputEntities) do
         if TypesCompatible(outputEntity.type, self.type) then
            if isInBlock(self, outputEntity) == false then
               table.insert(self.entities, outputEntity)
               table.insert(todo, {outputEntity, currEntity.position})
            end

         elseif not isEntityInList(self.outputEntities, outputEntity) then
            table.insert(self.outputEntities, 1, outputEntity)    -- TODO: Store them chronologically (along item-flow-direction)
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

function Block:Label(visualizer)
   
   for i,entity in ipairs(self.entities) do
      visualizer:DrawOverlay(entity)
      visualizer:DrawTextOverlay(entity, i)
   end

   for _,entity in ipairs(self.inputEntities) do
      visualizer:DrawOverlay(entity, CONST.INPUT)
   end

   for _,entity in ipairs(self.outputEntities) do
      visualizer:DrawOverlay(entity, CONST.OUTPUT)
   end
end

return Block