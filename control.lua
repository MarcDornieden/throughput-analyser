
--    ##############################################################################
--    # TODO-List                                                                  #
--    ##############################################################################

-- Find every necessary kind of block
   -- Types to do:
      -- underground-belts       CHECK
      -- splitters               CHECK
      -- furnaces
      -- long handed inserters
      -- assembling machines
   -- Test the shit out of it

-- Find a good way of visualizing the BlockNetwork
   -- Actually visualize it

-- Find a good way of visualizing the different types of throughput-deltas
   -- Actually visualize it

-- Refactor the code
   -- Make it more object-oriented
   -- Maybe figure out how to use less textures and more post-processing
   -- Test the actual shit out of it



-- Way fucking later
   -- Maybe make BlockNetwork it's own mod? Could be helpful for other modders
   -- Maybe build a second mod ontop of BlockNetwork for detecting items on the wrong belts?
      -- It could notice items that'll never fit into outputs down the line










--    ##############################################################################
--    # ALREADYDONE-List                                                           #
--    ##############################################################################

-- Design a good way of visualizing blocks
   -- Figure out how to draw stuff in Factorio
   -- Actually draw the stuff

-- Find a good way of using the mod
   -- Make an item for the mod?
      -- Make the mod only be active when the item is held

-- Design a convenient BlockNetwork-Structure
   -- Actually generate this convenient BlockNetwork-Structure
   -- Test the shit out of it










--    ##############################################################################
--    # constants                                                                  #
--    ##############################################################################

local DEBUG = true

local Graph = require("luaclasses.Graph")
local Block = require("luaclasses.Block")
local BlockNetwork = require("luaclasses.BlockNetwork")


local DIRECTIONS = {
   NORTH = defines.direction.north,
   EAST = defines.direction.east,
   SOUTH = defines.direction.south,
   WEST = defines.direction.west
}

local INPUT = "Input"
local OUTPUT = "Output"
local TODO = "TODO"

local TYPES = {
   BELT = "transport-belt",
   U_BELT = "underground-belt",
   SPLITTER = "splitter",
   INSERTER = "inserter"
}

local TYPESLIST = { "transport-belt", "underground-belt", "splitter", "inserter" }







--    ##############################################################################
--    # variables                                                                  #
--    ##############################################################################

clearedLogFile = false

blockNetworks = {}
overlayEntities = {}










--    ##############################################################################
--    # events                                                                     #
--    ##############################################################################

script.on_event(defines.events.on_tick, function(event)

   if not clearedLogFile then
      game.write_file("debug.log", "")
      clearedLogFile = true
   end

   for _,player in pairs(game.connected_players) do
      if player.character and player.get_inventory(defines.inventory.player_armor).get_item_count("TA-Armor") >= 1 then

         p = player.position

         local area = player.surface.find_entities_filtered{area={{p.x-1, p.y-1}, {p.x+1, p.y+1}}, type=TYPESLIST}

         for _,entity in ipairs(area) do

            if isItemInList(entity.type, TYPESLIST) then 

               for _,blockNetwork in ipairs(blockNetworks) do

                  if blockNetwork:ContainsEntity(entity) then return end
               end

               if isItemInList(entity.type, TYPESLIST) then
                  local blockNetwork = BlockNetwork.new()
                  blockNetwork:Scan(entity)
                  blockNetwork:Label()
                  table.insert(blockNetworks, blockNetwork)
               end
               if entity.type == TYPES.SPLITTER then
                  game.print("Dats a splitter")
               end
            end
         end
      end
   end
end)

script.on_event(defines.events.on_player_pipette, function(event)

   for _,entity in ipairs(overlayEntities) do
      entity.destroy()
   end

   blockNetworks = {}
end)








--    ##############################################################################
--    # functions to build blocks                                                  #
--    ##############################################################################

function FindBlock(startEntity)
   if startEntity == nil then return end

   local block = Block.new(startEntity)

   local todo = {startEntity}
   local cycles = 0 -- failsave to prevent infinite loops. Probably not needed when everything is working

   while #todo > 0 and cycles < 10000 do
      cycles = cycles + 1

      currEntity = todo[1]

      local inputEntities, outputEntities = getAdjacentInputsAndOutputs(currEntity)

      for _,inputEntity in ipairs(inputEntities) do
         if TypesCompatible(inputEntity.type, block.type) then
            if isInBlock(block, inputEntity) == false then
               table.insert(block.entities, 1, inputEntity)
               table.insert(todo, inputEntity)
            end

         elseif not isEntityInList(block.inputEntities, inputEntity) then
            table.insert(block.inputEntities, 1, inputEntity)
         end
      end

      for _,outputEntity in ipairs(outputEntities) do
         if TypesCompatible(outputEntity.type, block.type) then
            if isInBlock(block, outputEntity) == false then
               table.insert(block.entities, outputEntity)
               table.insert(todo, outputEntity)
            end

         elseif not isEntityInList(block.outputEntities, outputEntity) then
            table.insert(block.outputEntities, 1, outputEntity)
         end
      end

      table.remove(todo, 1)
   end

   if cycles == 10000 then
      game.print("Had to prevent infinite loop.")
   end

   block:UpdateID()

   return block
end


function getAdjacentInputsAndOutputs(originalEntity)

   inputs = {}
   outputs = {}

   for _,currDirection in pairs(DIRECTIONS) do

      local currEntities = {}

      if (originalEntity.type == TYPES.U_BELT) and
         ((originalEntity.belt_to_ground_type == "input"  and originalEntity.direction == currDirection) or
         (originalEntity.belt_to_ground_type == "output" and originalEntity.direction == OppositeDirection(currDirection))) then
         currEntities = { originalEntity.neighbours }

      elseif not (originalEntity.type == TYPES.U_BELT and originalEntity.belt_to_ground_type == "output" and originalEntity.direction ~= currDirection) and 
             not (originalEntity.type == TYPES.U_BELT and originalEntity.belt_to_ground_type == "input"  and originalEntity.direction ~= OppositeDirection(currDirection)) then
         currEntities = getAdjacentEntities(originalEntity, currDirection)
      end

      for _,currEntity in ipairs(currEntities) do

         if currEntity then
            if isOutput(originalEntity, currEntity, currDirection) then
               if originalEntity.type == TYPES.SPLITTER then 
                  table.insert(outputs, currEntity)
               else
                  table.insert(outputs, currEntity)
               end

            elseif isInput(currEntity, originalEntity, currDirection) then
               if currEntity.type == TYPES.SPLITTER then
                  table.insert(inputs, currEntity)
               else
                  table.insert(inputs, currEntity)
               end
            end
         end
      end
   end

   return inputs, outputs
end


function isInput(entityIn, entityOut, direction)   -- Assuming they're next to each other!
   if not (entityIn or entityOut) then return false end

   return isOutput(entityIn, entityOut, OppositeDirection(direction))
end

function isOutput(entityIn, entityOut, direction)   -- Assuming they're next to each other!
   if not (entityIn or entityOut) then return false end

   local typeIn = entityIn.type
   local typeOut = entityOut.type

   local directionIn = entityIn.direction
   local directionOut = entityOut.direction

   if     typeIn == TYPES.BELT     and typeOut == TYPES.BELT then
      return directionIn == direction and directionOut ~= OppositeDirection(directionIn)

   elseif typeIn == TYPES.BELT     and typeOut == TYPES.U_BELT then
      return entityOut.belt_to_ground_type == "input" and directionIn == direction and directionOut ~= OppositeDirection(direction)
      
   elseif typeIn == TYPES.U_BELT   and typeOut == TYPES.BELT then
      return entityIn.belt_to_ground_type == "output" and directionIn == direction and directionOut ~= OppositeDirection(direction)

   elseif typeIn == TYPES.U_BELT   and typeOut == TYPES.U_BELT then
      if     entityIn.belt_to_ground_type == "input" then
         return entityOut.neighbours == entityIn

      elseif entityIn.belt_to_ground_type == "output" and entityOut.belt_to_ground_type == "input" then
         return entityIn.direction == direction and entityOut.direction == direction
      end
      
   elseif typeIn == TYPES.INSERTER and (typeOut == TYPES.BELT or typeOut == TYPES.U_BELT) then
      return isSameEntity(entityIn.drop_target, entityOut)
      
   elseif (typeIn == TYPES.BELT or typeIn == TYPES.U_BELT) and typeOut == TYPES.INSERTER then
      return isSameEntity(entityOut.pickup_target, entityIn)

   elseif typeIn == TYPES.BELT     and typeOut == TYPES.SPLITTER then
      return directionIn == direction and directionOut == direction

   elseif typeIn == TYPES.U_BELT   and typeOut == TYPES.SPLITTER then
      return entityIn.belt_to_ground_type == "output" and directionIn == direction and directionOut == direction

   elseif typeIn == TYPES.SPLITTER and typeOut == TYPES.BELT then
      return directionIn == direction and directionOut ~= OppositeDirection(direction)

   elseif typeIn == TYPES.SPLITTER and typeOut == TYPES.U_BELT then
      return directionIn == direction and entityOut.belt_to_ground_type == "input" and directionOut ~= OppositeDirection(direction)

   elseif typeIn == TYPES.SPLITTER and typeOut == TYPES.SPLITTER then
      return directionIn == direction and directionOut == direction

   end
end







--    ##############################################################################
--    # functions for visualization                                                #
--    ##############################################################################

function DrawOverlay(entity, inputOutput)
   inputOutput = inputOutput or ""

   direction = GetDirection(entity)
   directionStr = GetDirectionStr(direction)

   local overlayEntity = game.surfaces[1].create_entity{
      name = "TA-Arrow" .. directionStr .. inputOutput,
      position = entity.position,
      force = game.forces.player
   }
   return overlayEntity
end

function DrawTextOverlay(entity, txt)

   local overlayEntity = game.surfaces[1].create_entity{
      name = "flying-text",
      position = entity.position,
      force = game.forces.player,
      text = txt
   }
   overlayEntity.active = false

   return overlayEntity
end







--    ##############################################################################
--    # highlevel helper functions                                                 #
--    ##############################################################################

function GetDirection(entity)
   if entity.type == TYPES.INSERTER then return OppositeDirection(entity.direction) end
   return entity.direction
end

function GetDirectionStr(direction)
   if     direction == DIRECTIONS.EAST  then return "East"
   elseif direction == DIRECTIONS.SOUTH then return "South"
   elseif direction == DIRECTIONS.WEST  then return "West" end
   return "North"
end

function isInBlock(block, entity)

   return isEntityInList(block.entities, entity)
end

function isEntityInList(list, searchEntity)

   for _,listEntity in ipairs(list) do
      if isSameEntity(searchEntity, listEntity) then
         return true
      end
   end

   return false
end

function TypesCompatible(type1, type2)
   compatible = {
      {TYPES.BELT, TYPES.U_BELT}
   }

   for _,currList in ipairs(compatible) do
      if isItemInList(type1, currList) and isItemInList(type2, currList) then return true end
   end

   return false
end

function getAdjacentEntities(originalEntity, direction)

   local result = {}

   local newPositions = PositionsInDirection(originalEntity, direction)

   for _,newPos in ipairs(newPositions) do
      
      local searchResult = originalEntity.surface.find_entities_filtered{position=newPos}

      for _,entity in ipairs(searchResult) do
         if isItemInList(entity.type, TYPESLIST) then
            table.insert(result, entity)
         end
      end
   end

   return result
end

function PositionsInDirection(entity, direction, distance)
   distance = distance or 1

   if entity.type ~= TYPES.SPLITTER then
      return { PositionInDirection(entity.position, direction, distance) }
   end

   local pos = entity.position

   local originalPositions

   if pos.x % 1 == 0 then 
      return {
         PositionInDirection({x = pos.x - 0.5, y = pos.y}, direction, distance),
         PositionInDirection({x = pos.x + 0.5, y = pos.y}, direction, distance)
      }
   else
      return {
         PositionInDirection({x = pos.x, y = pos.y - 0.5}, direction, distance),
         PositionInDirection({x = pos.x, y = pos.y + 0.5}, direction, distance)
      }
   end
end










--    ##############################################################################
--    # lowlevel helper functions                                                  #
--    ##############################################################################

function PositionInDirection(position, direction, distance)
   distance = distance or 1

   if     direction == DIRECTIONS.NORTH then position.y = position.y - distance
   elseif direction == DIRECTIONS.EAST  then position.x = position.x + distance
   elseif direction == DIRECTIONS.SOUTH then position.y = position.y + distance
   elseif direction == DIRECTIONS.WEST  then position.x = position.x - distance end
   return position
end

function OppositeDirection(direction)

   return (direction + 4) % 8
end

function isSameEntity(entity1, entity2)

   return 
   entity1 and entity1.valid and 
   entity2 and entity2.valid and 
   isSamePosition(entity1.position, entity2.position) and 
   entity1.type == entity2.type
end

function isSamePosition(pos1, pos2, tolerance)
   tolerance = tolerance or 0

   return math.abs(pos1.x - pos2.x) <= tolerance and math.abs(pos1.y - pos2.y) <= tolerance
end


function isItemInList(item, list)
   for _,listEntity in ipairs(list) do
      if item == listEntity then
         return true
      end
   end

   return false
end

function Pos2Str(pos)

   return "[" .. pos.x .. "/" .. pos.y .. "]"
end

function Pos2ID(pos)
   return math.floor(pos.x) * 100000 + math.floor(pos.y)
end

function DebugPrint(value)
   if not DEBUG then return end

   if     type(value) == "table"   then game.write_file("debug.log", dump(value) .. "\n", true)
   elseif type(value) == "boolean" then game.write_file("debug.log", (value == true and "true" or "false") .. "\n", true)
   elseif value == nil             then game.write_file("debug.log", "nil\n", true)
   else
      game.write_file("debug.log", value .. "\n", true)
   end
end

function DebugPrintWithName(variableName, value)
   if not DEBUG then return end

   if     type(value) == "table"   then game.write_file("debug.log", variableName .. " = " .. dump(value) .. "\n", true)
   elseif type(value) == "boolean" then game.write_file("debug.log", variableName .. " = " .. (value == true and "true" or "false") .. "\n", true)
   elseif value == nil             then game.write_file("debug.log", variableName .. " = nil\n", true)
   else
      game.write_file("debug.log", variableName .. " = " .. value .. "\n", true)
   end
end

function DebugAssert(expression)
   if not DEBUG then return end

   if not expression then
      game.print("Error: DebugAssert failed")
   end

   return expression
end




function dump(o, indent)
   local indent = indent or 0

   if type(o) == 'table' then
      local s = '\n' .. RepeatString(" ", indent) .. '{\n'

      indent = indent + 4
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. RepeatString(" ", indent) ..k..' = ' .. dump(v, indent) .. ',\n'
      end
      indent = indent - 4
      return s .. RepeatString(" ", indent) .. '}'
   else
      return tostring(o)
   end
end

function RepeatString(s, n)

   return n > 0 and s .. RepeatString(s, n-1) or ""
end
