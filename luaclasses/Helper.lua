local Helper = {}
Helper.__index = Helper

function Helper.new()
    local self = setmetatable({}, Helper)
    self.logfilename = "debug.log"
    return self
end


function Helper:PositionInDirection(position, direction, distance)
    distance = distance or 1
    Helper:DebugAssert(position ~= nil)

    local pos = position

    if     direction == CONST.DIRECTIONS.NORTH then return { x = position.x,            y = position.y - distance }
    elseif direction == CONST.DIRECTIONS.EAST  then return { x = position.x + distance, y = position.y }
    elseif direction == CONST.DIRECTIONS.SOUTH then return { x = position.x,            y = position.y + distance }
    else                                            return { x = position.x - distance, y = position.y } end
end

function Helper:DirectionFromPositions(sourcePos, targetPos)

    local east = targetPos.x - sourcePos.x
    local north = targetPos.y - sourcePos.y

    Helper:DebugAssert(east ~= 0 or north ~= 0)

    if east == 0 then
        if north > 0 then
            return CONST.DIRECTIONS.NORTH
        else
            return CONST.DIRECTIONS.SOUTH
        end
    elseif east > 0 then
        if north == 0 then
                return CONST.DIRECTIONS.EAST
        elseif north > 0 then
            if north - east > 0 then
                return CONST.DIRECTIONS.NORTH
            else
                return CONST.DIRECTIONS.EAST
            end
        elseif north < 0 then
            if east + north > 0 then
                return CONST.DIRECTIONS.EAST
            else
                return CONST.DIRECTIONS.SOUTH
            end
        end
    else
        if north == 0 then
                return CONST.DIRECTIONS.WEST
        elseif north > 0 then
            if north + east > 0 then
                return CONST.DIRECTIONS.NORTH
            else
                return CONST.DIRECTIONS.WEST
            end
        elseif north < 0 then
            if north - east > 0 then
                return CONST.DIRECTIONS.WEST
            else
                return CONST.DIRECTIONS.SOUTH
            end
        end
    end
end

function Helper:OppositeDirection(direction)
    return (direction + 4) % 8
end

function Helper:IsSamePosition(pos1, pos2, tolerance)
    tolerance = tolerance or 0
 
    if not (pos1 and pos2) then return false end
 
    return math.abs(pos1.x - pos2.x) <= tolerance and math.abs(pos1.y - pos2.y) <= tolerance
end 

function Helper:IsItemInList(item, list)
    for _,listEntity in ipairs(list) do
        if item == listEntity then
            return true
        end
    end

    return false
end

function Helper:Pos2Str(pos)
    return "[" .. pos.x .. "/" .. pos.y .. "]"
end

function Helper:Pos2ID(pos)
    return math.floor(pos.x) * 100000 + math.floor(pos.y)
end

function Helper:DebugPrint(value)
    if not CONST.DEBUG then return end

    if     type(value) == "table"   then game.write_file(self.logfilename, Helper:Dump(value) .. "\n", true)
    elseif type(value) == "boolean" then game.write_file(self.logfilename, (value == true and "true" or "false") .. "\n", true)
    elseif value == nil             then game.write_file(self.logfilename, "nil\n", true)
    else
        game.write_file(self.logfilename, value .. "\n", true)
    end
end

function Helper:DebugPrintWithName(variableName, value)
    if not CONST.DEBUG then return end

    if     type(value) == "table"   then game.write_file(self.logfilename, variableName .. " = " .. Helper:Dump(value) .. "\n", true)
    elseif type(value) == "boolean" then game.write_file(self.logfilename, variableName .. " = " .. (value == true and "true" or "false") .. "\n", true)
    elseif value == nil             then game.write_file(self.logfilename, variableName .. " = nil\n", true)
    else
        game.write_file(self.logfilename, variableName .. " = " .. value .. "\n", true)
    end
end

function Helper:DebugAssert(expression)
    if not CONST.DEBUG then return end
 
    if not expression then
       game.print("Error: DebugAssert failed")
       Helper:DebugPrintWithName("DebugAssert", debug.traceback())
    end
 
    return expression
end



function Helper:Dump(o, indent)
    local indent = indent or 0

    if type(o) == 'table' then
        local s = '\n' .. Helper:RepeatString(" ", indent) .. '{\n'

        indent = indent + 4
        for k,v in pairs(o) do
            if type(k) ~= 'number' then k = '"'..k..'"' end
            s = s .. Helper:RepeatString(" ", indent) ..k..' = ' .. Helper:Dump(v, indent) .. ',\n'
        end
        indent = indent - 4
        return s .. Helper:RepeatString(" ", indent) .. '}'
    else
        return tostring(o)
    end
end

function Helper:RepeatString(s, n)
    return n > 0 and s .. Helper:RepeatString(s, n-1) or ""
end

return Helper