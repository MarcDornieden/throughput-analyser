--[[
    This is a custom graph data structure.
    
    Nodes are the points that are connected to each other.
    Each node has an ID for easy and fast identification in the code, and an object that can store whatever you want.

        nodes = {
            {
                ID,
                obj
            },
            ...
        }

    Edges are the connections between the nodes.
    The edges are stored as a dictionary in which every nodeID has a key.
    The value for that key, is a list of nodeIDs, that that nodeID is connected to.
    
        edges = {
            nodeID = {
                connectedNodeID1,
                connectedNodeID2,
                connectedNodeID3,
                ...
            },
            ...
        }
]]

local Graph = {}
Graph.__index = Graph

function Graph.new()
    local self = setmetatable({}, Graph)
    self.nodes = {}
    self.edges = {}
    return self
end










--    ##############################################################################
--    # data manipulation                                                          #
--    ##############################################################################

function Graph:AddNode(nodeID, nodeObj)
    if self:HasNode(nodeID) then return false end

    table.insert(self.nodes, {ID = nodeID, obj = nodeObj})

    return true
end

function Graph:AddEdge(nodeIDA, nodeIDB)

    if self.edges[nodeIDA] then
        if self.IsConnectedTo(nodeIDA, nodeIDB) then return false end

        table.insert(self.edges[nodeIDA], nodeIDB)
    else
        self.edges[nodeIDA] = {nodeIDB}
    end

    return true
end










--    ##############################################################################
--    # helper functions                                                           #
--    ##############################################################################

function Graph:HasNode(nodeID)
    for _,node in ipairs(self.nodes) do
        if node.ID == nodeID then
            return true
        end
    end

    return false
end

function Graph:IsConnectedTo(nodeIDA, nodeIDB)
    for _,node in ipairs(self.edges[nodeIDA]) do
        if node.ID == nodeIDB then
            return true
        end
    end

    return false
end

return Graph
