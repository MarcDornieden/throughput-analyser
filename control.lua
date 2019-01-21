
--    ##############################################################################
--    # Requirements & variables                                                   #
--    ##############################################################################

local CONST = require("luaclasses.Constants")
local Visualizer = require("luaclasses.Visualizer").new()

local Graph = require("luaclasses.Graph")
local Block = require("luaclasses.Block")
local BlockNetwork = require("luaclasses.BlockNetwork")


local blockNetworks = {}










--    ##############################################################################
--    # events                                                                     #
--    ##############################################################################

script.on_event(defines.events.on_tick, function(event)

   for _,player in pairs(game.connected_players) do
      if player.character and player.get_inventory(defines.inventory.player_armor).get_item_count("TA-Armor") >= 1 then

         p = player.position

         local area = player.surface.find_entities_filtered{area={{p.x-1, p.y-1}, {p.x+1, p.y+1}}, type=CONST.TYPESLIST}

         for _,entity in ipairs(area) do

            if isItemInList(entity.type, CONST.TYPESLIST) then 

               for _,blockNetwork in ipairs(blockNetworks) do

                  if blockNetwork:ContainsEntity(entity) then return end
               end

               if isItemInList(entity.type, CONST.TYPESLIST) then
                  local blockNetwork = BlockNetwork.new()
                  blockNetwork:Scan(entity)
                  blockNetwork:Label(Visualizer)
                  table.insert(blockNetworks, blockNetwork)
               end
               if entity.type == CONST.TYPES.SPLITTER then
                  game.print("Dats a splitter")
               end
            end
         end
      end
   end
end)

script.on_event(defines.events.on_player_pipette, function(event)

   game.write_file("debug.log", "")

   Visualizer:Clear()

   blockNetworks = {}
end)








--    ##############################################################################
--    # functions to build blocks                                                  #
--    ##############################################################################

function getAdjacentInputsAndOutputs(originalEntity, ignorePos)

   local inputs = {}
   local outputs = {}

   for _,currDirection in pairs(CONST.DIRECTIONS) do

      local posInDir = PositionInDirection(originalEntity.position, currDirection, 1)

      if not isSamePosition(posInDir, ignorePos) then 

         local currEntities = {}

         if (originalEntity.type == CONST.TYPES.U_BELT) and
            ((originalEntity.belt_to_ground_type == "input"  and originalEntity.direction == currDirection) or
            (originalEntity.belt_to_ground_type == "output" and originalEntity.direction == OppositeDirection(currDirection))) then
            currEntities = { originalEntity.neighbours }

         else
            currEntities = getAdjacentEntities(originalEntity, currDirection)
         end

         for _,currEntity in ipairs(currEntities) do

            if currEntity then
               if isOutput(originalEntity, currEntity, currDirection) then
                  if originalEntity.type == CONST.TYPES.SPLITTER then 
                     table.insert(outputs, currEntity)
                  else
                     table.insert(outputs, currEntity)
                  end

               elseif isInput(currEntity, originalEntity, currDirection) then
                  if currEntity.type == CONST.TYPES.SPLITTER then
                     table.insert(inputs, currEntity)
                  else
                     table.insert(inputs, currEntity)
                  end
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

   if     typeIn == CONST.TYPES.BELT     and typeOut == CONST.TYPES.BELT then
      return directionIn == direction and directionOut ~= OppositeDirection(directionIn)

   elseif typeIn == CONST.TYPES.BELT     and typeOut == CONST.TYPES.U_BELT then
      return entityOut.belt_to_ground_type == "input" and directionIn == direction and directionOut ~= OppositeDirection(direction)
      
   elseif typeIn == CONST.TYPES.U_BELT   and typeOut == CONST.TYPES.BELT then
      return entityIn.belt_to_ground_type == "output" and directionIn == direction and directionOut ~= OppositeDirection(direction)

   elseif typeIn == CONST.TYPES.U_BELT   and typeOut == CONST.TYPES.U_BELT then
      if     entityIn.belt_to_ground_type == "input" then
         return entityOut.neighbours == entityIn

      elseif entityIn.belt_to_ground_type == "output" and entityOut.belt_to_ground_type == "input" then
         return entityIn.direction == direction and entityOut.direction == direction
      end
      
   elseif typeIn == CONST.TYPES.INSERTER and (typeOut == CONST.TYPES.BELT or typeOut == CONST.TYPES.U_BELT) then
      return isSameEntity(entityIn.drop_target, entityOut)
      
   elseif (typeIn == CONST.TYPES.BELT or typeIn == CONST.TYPES.U_BELT) and typeOut == CONST.TYPES.INSERTER then
      return isSameEntity(entityOut.pickup_target, entityIn)

   elseif typeIn == CONST.TYPES.BELT     and typeOut == CONST.TYPES.SPLITTER then
      return directionIn == direction and directionOut == direction

   elseif typeIn == CONST.TYPES.U_BELT   and typeOut == CONST.TYPES.SPLITTER then
      return entityIn.belt_to_ground_type == "output" and directionIn == direction and directionOut == direction

   elseif typeIn == CONST.TYPES.SPLITTER and typeOut == CONST.TYPES.BELT then
      return directionIn == direction and directionOut ~= OppositeDirection(direction)

   elseif typeIn == CONST.TYPES.SPLITTER and typeOut == CONST.TYPES.U_BELT then
      return directionIn == direction and entityOut.belt_to_ground_type == "input" and directionOut ~= OppositeDirection(direction)

   elseif typeIn == CONST.TYPES.SPLITTER and typeOut == CONST.TYPES.SPLITTER then
      return directionIn == direction and directionOut == direction

   end
end










--    ##############################################################################
--    # highlevel helper functions                                                 #
--    ##############################################################################

function GetDirection(entity)
   DebugAssert(entity ~= nil)
   

   if entity.type == CONST.TYPES.INSERTER then return OppositeDirection(entity.direction) end
   return entity.direction
end

function GetDirectionStr(direction)
   if     direction == CONST.DIRECTIONS.EAST  then return "East"
   elseif direction == CONST.DIRECTIONS.SOUTH then return "South"
   elseif direction == CONST.DIRECTIONS.WEST  then return "West" end
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
      {CONST.TYPES.BELT, CONST.TYPES.U_BELT}
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
         if isItemInList(entity.type, CONST.TYPESLIST) then
            table.insert(result, entity)
         end
      end
   end

   return result
end

function PositionsInDirection(entity, direction, distance)
   distance = distance or 1

   if entity.type ~= CONST.TYPES.SPLITTER then
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

   DebugAssert(position ~= nil)

   if     direction == CONST.DIRECTIONS.NORTH then position.y = position.y - distance
   elseif direction == CONST.DIRECTIONS.EAST  then position.x = position.x + distance
   elseif direction == CONST.DIRECTIONS.SOUTH then position.y = position.y + distance
   elseif direction == CONST.DIRECTIONS.WEST  then position.x = position.x - distance end
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

   if not (pos1 and pos2) then return false end

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
   if not CONST.DEBUG then return end

   if     type(value) == "table"   then game.write_file("debug.log", dump(value) .. "\n", true)
   elseif type(value) == "boolean" then game.write_file("debug.log", (value == true and "true" or "false") .. "\n", true)
   elseif value == nil             then game.write_file("debug.log", "nil\n", true)
   else
      game.write_file("debug.log", value .. "\n", true)
   end
end

function DebugPrintWithName(variableName, value)
   if not CONST.DEBUG then return end

   if     type(value) == "table"   then game.write_file("debug.log", variableName .. " = " .. dump(value) .. "\n", true)
   elseif type(value) == "boolean" then game.write_file("debug.log", variableName .. " = " .. (value == true and "true" or "false") .. "\n", true)
   elseif value == nil             then game.write_file("debug.log", variableName .. " = nil\n", true)
   else
      game.write_file("debug.log", variableName .. " = " .. value .. "\n", true)
   end
end

function DebugAssert(expression)
   if not CONST.DEBUG then return end

   if not expression then
      game.print("Error: DebugAssert failed")
      DebugPrintWithName("DebugAssert", debug.traceback())
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
