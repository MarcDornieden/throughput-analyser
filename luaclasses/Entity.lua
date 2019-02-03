local Entity = {}
Entity.__index = Entity

function Entity.new(entity)
    local self = setmetatable({}, Entity)
    
    self.obj = entity
    self.position = entity.position
    self.ID = Helper:Pos2ID(self.position)
    self.type = entity.type
    self.name = entity.name
    self.valid = entity.valid

    self.saturation = 0

    if entity.type == CONST.TYPES.INSERTER then 
        self.direction = Helper:OppositeDirection(entity.direction)
    else
        self.direction = entity.direction
    end

    return self
end

function Entity:GetAdjacentInputsAndOutputs(ignorePos)

    local inputs = {}
    local outputs = {}

    for _,currDirection in pairs(CONST.DIRECTIONS) do
 
        local posInDir = Helper:PositionInDirection(self.position, currDirection, 1)

        if not Helper:IsSamePosition(posInDir, ignorePos) then 

            local currEntities = {}

            if (self.type == CONST.TYPES.U_BELT) and
                ((self.obj.belt_to_ground_type == "input"  and self.direction == currDirection) or
                (self.obj.belt_to_ground_type == "output" and self.direction == Helper:OppositeDirection(currDirection))) then

                currEntities = { Entity.new(self.obj.neighbours) }
            else
                currEntities = self:GetAdjacentEntities(currDirection)
            end
            
            for i,currEntity in ipairs(currEntities) do

                if not Helper:IsSamePosition(self.position, currEntity.position) then
                    
                    if self:HasOutput(currEntity) then
                        
                        table.insert(outputs, currEntity)

                    elseif self:HasInput(currEntity) then
                        
                        table.insert(inputs, currEntity)
                    end
                end
            end
        end
    end
 
    return inputs, outputs
end

function Entity:GetAdjacentEntities(direction)

    local result = {}

    local newPositions = self:PositionsInDirection(direction)

    for _,newPos in ipairs(newPositions) do
        
        local searchResult = self.obj.surface.find_entities_filtered{position=newPos}

        for _,entity in ipairs(searchResult) do
            if Helper:IsItemInList(entity.type, CONST.TYPESLIST) then
            table.insert(result, Entity.new(entity))
            end
        end
    end

    return result
end

function Entity:HasInput(entityIn)   -- Assuming they're next to each other!
    return entityIn:HasOutput(self)
end

function Entity:HasOutput(entityOut) -- Assuming they're next to each other!
    local direction = Helper:DirectionFromPositions(self.position, entityOut.position)

    local typeIn = self.type
    local typeOut = entityOut.type

    local directionIn = self.direction
    local directionOut = entityOut.direction

    if     typeIn == CONST.TYPES.BELT     and typeOut == CONST.TYPES.BELT then
        return directionIn == direction and directionOut ~= Helper:OppositeDirection(directionIn)

    elseif typeIn == CONST.TYPES.BELT     and typeOut == CONST.TYPES.U_BELT then
        return entityOut.obj.belt_to_ground_type == "input" and directionIn == direction and directionOut ~= Helper:OppositeDirection(direction)
        
    elseif typeIn == CONST.TYPES.U_BELT   and typeOut == CONST.TYPES.BELT then
        return self.obj.belt_to_ground_type == "output" and directionIn == direction and directionOut ~= Helper:OppositeDirection(direction)

    elseif typeIn == CONST.TYPES.U_BELT   and typeOut == CONST.TYPES.U_BELT then
        if     self.obj.belt_to_ground_type == "input" then
            return entityOut.obj.neighbours == self

        elseif self.obj.belt_to_ground_type == "output" and entityOut.obj.belt_to_ground_type == "input" then
            return self.direction == direction and entityOut.direction == direction
        end
        
    elseif typeIn == CONST.TYPES.INSERTER and (typeOut == CONST.TYPES.BELT or typeOut == CONST.TYPES.U_BELT or typeOut == CONST.TYPES.CHEST) then
        return entityOut:IsSameAs(self.obj.drop_target)
        
    elseif (typeIn == CONST.TYPES.BELT or typeIn == CONST.TYPES.U_BELT or typeIn == CONST.TYPES.CHEST) and typeOut == CONST.TYPES.INSERTER then
        return self:IsSameAs(entityOut.obj.pickup_target)

    elseif typeIn == CONST.TYPES.BELT     and typeOut == CONST.TYPES.SPLITTER then
        return directionIn == direction and directionOut == direction

    elseif typeIn == CONST.TYPES.U_BELT   and typeOut == CONST.TYPES.SPLITTER then
        return self.obj.belt_to_ground_type == "output" and directionIn == direction and directionOut == direction

    elseif typeIn == CONST.TYPES.SPLITTER and typeOut == CONST.TYPES.BELT then
        return directionIn == direction and directionOut ~= Helper:OppositeDirection(direction)

    elseif typeIn == CONST.TYPES.SPLITTER and typeOut == CONST.TYPES.U_BELT then
        return directionIn == direction and entityOut.obj.belt_to_ground_type == "input" and directionOut ~= Helper:OppositeDirection(direction)

    elseif typeIn == CONST.TYPES.SPLITTER and typeOut == CONST.TYPES.SPLITTER then
        return directionIn == direction and directionOut == direction

    end
end

function Entity:PositionsInDirection(direction, distance)
   distance = distance or 1

   if self.type ~= CONST.TYPES.SPLITTER then
      return { Helper:PositionInDirection(self.position, direction, distance) }
   end

   local pos = self.position

   if pos.x % 1 == 0 then 
      return {
         Helper:PositionInDirection({x = pos.x - 0.5, y = pos.y}, direction, distance),
         Helper:PositionInDirection({x = pos.x + 0.5, y = pos.y}, direction, distance)
      }
   else
      return {
         Helper:PositionInDirection({x = pos.x, y = pos.y - 0.5}, direction, distance),
         Helper:PositionInDirection({x = pos.x, y = pos.y + 0.5}, direction, distance)
      }
   end
end

function Entity:IsSameAs(entity2)

    return 
    entity2 and
    self.valid and entity2.valid and 
    Helper:IsSamePosition(self.position, entity2.position) and 
    self.type == entity2.type
end

function Entity:IsInList(list)

    if not list then return false end

    for _,listEntity in ipairs(list) do
        if self:IsSameAs(listEntity) then
            return true
        end
    end

    return false
end

function Entity:CompatibleWith(type2)
    compatible = {
        {CONST.TYPES.BELT, CONST.TYPES.U_BELT}
    }

    for _,currList in ipairs(compatible) do
        if Helper:IsItemInList(self.type, currList) and Helper:IsItemInList(type2, currList) then return true end
    end

    return false
end

return Entity