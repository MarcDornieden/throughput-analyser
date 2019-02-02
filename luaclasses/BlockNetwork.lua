local CONST = require("constants")
local Graph = require("luaclasses.Graph")
local Block = require("luaclasses.Block")

local BlockNetwork = {}
BlockNetwork.__index = BlockNetwork

function BlockNetwork.new()
   local self = setmetatable({}, BlockNetwork)
   self.graph = Graph.new()
   self.entityID2blockIDTable = {}
   return self
end

function BlockNetwork:Scan(startEntity)

   self:ScanNodes(startEntity)
   self:ScanEdges()

   local count = 0

   for _,_ in pairs(self.entityID2blockIDTable) do
      count = count + 1
   end

   DebugPrint("BlockNetwork: " .. count .. " entities, " .. #self.graph.nodes .. " nodes, " .. self.graph:CountEdges() .. " edges")
end

function BlockNetwork:ScanNodes(startEntity)
   
   local todo = {startEntity}

   while #todo > 0 do
      local currEntity = todo[1]

      local block = Block.FromEntity(currEntity)

      local notAddedYet = self.graph:AddNode(block.ID, block)

      if notAddedYet then

         for _,entity in ipairs(block.entities) do
   
            DebugAssert(self.entityID2blockIDTable[Pos2ID(entity.position)] == nil)
   
            self.entityID2blockIDTable[Pos2ID(entity.position)] = block.ID
         end
         
         for entityID,inputEntities in pairs(block.inputEntities) do
   
            for _,inputEntity in ipairs(inputEntities) do
               if not self.entityID2blockIDTable[Pos2ID(inputEntity.position)] then 
                  table.insert(todo, inputEntity)
               end
            end
         end
         
         for entityID,outputEntities in pairs(block.outputEntities) do

            for _,outputEntity in ipairs(outputEntities) do
               if not self.entityID2blockIDTable[Pos2ID(outputEntity.position)] then 
                  table.insert(todo, outputEntity)
               end
            end
         end
      end
      
      table.remove(todo, 1)
   end
end

function BlockNetwork:ScanEdges()

   self.graph:ClearEdges()

   for _,node in ipairs(self.graph.nodes) do
      
      for entityID,inputEntities in pairs(node.obj.inputEntities) do

         for _,inputEntity in ipairs(inputEntities) do
         
            local inputBlockID = self.entityID2blockIDTable[Pos2ID(inputEntity.position)]
   
            if inputBlockID then
               self.graph:AddEdge(inputBlockID, node.ID)
            end
         end
      end

      for entityID,outputEntities in pairs(node.obj.outputEntities) do
         
         for _,outputEntity in ipairs(outputEntities) do
      
            local outputBlockID = self.entityID2blockIDTable[Pos2ID(outputEntity.position)]
   
            if outputBlockID then
               self.graph:AddEdge(node.ID, outputBlockID)
            end
         end
      end
   end
end

function BlockNetwork:Label(visualizer)
   for _,node in ipairs(self.graph.nodes) do
	   node.obj:Label(visualizer)
   end
   
   if CONST.DEBUG then
      DebugPrintWithName("blockNetwork", self.graph)
   end
end

function BlockNetwork:ContainsEntity(entity)

   local ID = Pos2ID(entity.position)

   return self.entityID2blockIDTable[ID] ~= nil
end

return BlockNetwork