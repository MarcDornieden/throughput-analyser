local Graph = require("luaclasses.Graph")

local BlockNetwork = {}
BlockNetwork.__index = BlockNetwork

function BlockNetwork.new()
   local self = setmetatable({}, BlockNetwork)
   self.graph = Graph.new()
   self.entityPos2blockIDTable = {}    -- for e.pos = [x=1, y=5] would be: 100005 = 100013
   return self
end

function BlockNetwork:Scan(startEntity)

   local todo = {startEntity}

   while #todo > 0 do
      local currEntity = todo[1]

      local block = FindBlock(currEntity)
      DebugPrint("Block: " .. #block.entities .. " entities, " .. #block.inputEntities .. " inputs, " .. #block.outputEntities .. " outputs")

      local worked = self.graph:AddNode(block.ID, block)    -- TODO: Store them chronologically (along item-flow-direction)

      if not worked then
         DebugPrint("Error: Block already in graph. ID = " .. block.ID)
         return false
      end

      for _,entity in ipairs(block.entities) do

         DebugAssert(self.entityPos2blockIDTable[Pos2ID(entity.position)] == nil)

         self.entityPos2blockIDTable[Pos2ID(entity.position)] = block.ID
      end
      
      for _,inputEntity in ipairs(block.inputEntities) do

         if not self.entityPos2blockIDTable[Pos2ID(inputEntity.position)] then 
            table.insert(todo, inputEntity)
         end
      end
      
      for _,outputEntity in ipairs(block.outputEntities) do

         if not self.entityPos2blockIDTable[Pos2ID(outputEntity.position)] then 
            table.insert(todo, outputEntity)
         end
      end
      table.remove(todo, 1)
   end
   
   DebugPrint("BlockNetwork: " .. #self.graph.nodes .. " nodes, " .. #self.graph.edges .. " edges")
   
   return blockNetwork
end

function BlockNetwork:Label()
   for _,node in ipairs(self.graph.nodes) do
	   -- for i,entity in ipairs(block.entities) do
	   --    table.insert(overlayEntities, DrawOverlay(entity))
	   -- end

	   node.obj:Label()

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