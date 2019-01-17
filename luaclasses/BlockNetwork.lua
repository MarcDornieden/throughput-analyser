local BlockNetwork = {}
BlockNetwork.__index = BlockNetwork

function BlockNetwork.new()
   local self = setmetatable({}, BlockNetwork)
   self.blocks = {}
   self.inputBlocks = {}
   self.outputBlocks = {}
   return self
end

function BlockNetwork:Scan(blockNetwork, currEntity)
   
   local block = FindBlock(currEntity)

   if DEBUG then DebugPrint("Block: " .. #block.entities .. " entities, " .. #block.inputEntities .. " inputs, " .. #block.outputEntities .. " outputs") end

   table.insert(blockNetwork.blocks, block)

   for i=1,#block.outputEntities do
      
      FindBlockNetwork2(blockNetwork, block.outputEntities[i])
   end

   return blockNetwork
end

function BlockNetwork:Label()
   for i,block in ipairs(self.blocks) do
	   -- for i,entity in ipairs(block.entities) do
	   --    table.insert(overlayEntities, DrawOverlay(entity))
	   -- end

	   block:Label()

   -- if self.inputNodes and #self.inputNodes > 0 then
   --    for i,entity in ipairs(self.inputNodes) do
   --       table.insert(overlayEntities, DrawOverlay(entity, "Input"))
   --    end
   -- end
   -- if self.outputNodes and #self.outputNodes > 0 then
   --    for i,entity in ipairs(self.outputNodes) do
   --       table.insert(overlayEntities, DrawOverlay(entity, "Output"))
   --    end
   -- end
	end
end

return BlockNetwork