local Node = {}
Node.__index = Node

function Node.new(type)
   local self = setmetatable({}, Node)
   self.inputs = {}		-- {{block=b1, entity=e1},{block=b2, entity=e2},}
   self.outputs = {}	-- {{block=b1, entity=e1},{block=b2, entity=e2},}
   return self
end


function Node.AddInput(self, block, entity)
	table.insert(self.inputs, {block=block, entity=entity})
end
function Node.AddOutput(self, block, entity)
	table.insert(self.outputs, {block=block, entity=entity})
end

return Node