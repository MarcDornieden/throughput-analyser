local Block = {}
Block.__index = Block

function Block.new(firstEntity)
   local self = setmetatable({}, Block)
   self.entities = {firstEntity}
   self.inputEntities = {}
   self.outputEntities = {}
   self.inputNodes = {}
   self.outputNodes = {}
   self.throughput = 0 --TODO get throughput from firstEntity
   self.type = firstEntity.type
   self.ID = self:UpdateID()
   return self
end

function Block:UpdateID()
   self.ID = Pos2ID(self.entities[1].position)
end

function Block:Label()
   
   for i,entity in ipairs(self.entities) do
      table.insert(overlayEntities, DrawOverlay(entity))
      table.insert(overlayEntities, DrawTextOverlay(entity, i))
   end

   for i,entity in ipairs(self.inputEntities) do
      table.insert(overlayEntities, DrawOverlay(entity, INPUT))
   end

   for i,entity in ipairs(self.outputEntities) do
      table.insert(overlayEntities, DrawOverlay(entity, OUTPUT))
   end
end

return Block