
--    ##############################################################################
--    # Requirements & variables                                                   #
--    ##############################################################################

CONST = require("constants")

Helper = require("luaclasses.Helper").new()

Entity = require("luaclasses.Entity")

Visualizer = require("luaclasses.Visualizer").new()


Graph = require("luaclasses.Graph")
Block = require("luaclasses.Block")
BlockNetwork = require("luaclasses.BlockNetwork")


blockNetworks = {}










--    ##############################################################################
--    # events                                                                     #
--    ##############################################################################

script.on_event(defines.events.on_tick, function(event)

   for _,player in pairs(game.connected_players) do
      if player.character and player.get_inventory(defines.inventory.player_armor).get_item_count("TA-Armor") >= 1 then

         p = player.position

         local area = player.surface.find_entities_filtered{area={{p.x-1, p.y-1}, {p.x+1, p.y+1}}, type=CONST.TYPESLIST}

         for _,gameEntity in ipairs(area) do

            local entity = Entity.new(gameEntity)
            if Helper:IsItemInList(entity.type, CONST.TYPESLIST) then 

               for _,blockNetwork in ipairs(blockNetworks) do

                  if blockNetwork:ContainsEntity(entity) then return end
               end

               if Helper:IsItemInList(entity.type, CONST.TYPESLIST) then
                  local blockNetwork = BlockNetwork.new()
                  blockNetwork:Scan(entity)
                  blockNetwork:Label(Visualizer)
                  table.insert(blockNetworks, blockNetwork)
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

