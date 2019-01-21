return {
   DIRECTIONS = {
      NORTH = defines.direction.north,
      EAST = defines.direction.east,
      SOUTH = defines.direction.south,
      WEST = defines.direction.west
   },

   INPUT = "Input",
   OUTPUT = "Output",

   TYPES = {
      BELT = "transport-belt",
      U_BELT = "underground-belt",
      SPLITTER = "splitter",
      INSERTER = "inserter"
   },

   TYPESLIST = {
      "transport-belt",
      "underground-belt",
      "splitter",
      "inserter"
   },

   THROUGHPUT = {
      transport_belt = 13.333,
      fast_transport_belt = 26.667,
      express_transport_belt = 40,

      underground_belt = 13.333,
      fast_underground_belt = 26.667,
      express_underground_belt = 40,

      splitter = 13.333,
      fast_splitter = 26.667,
      express_splitter = 40,

      burner_inserter = 0.59,
      inserter = 0.83,
      long_handed_inserter = 1.15,
      fast_inserter = 2.31,
      filter_inserter = 2.31,
      stack_inserter = 4.62,
      stack_filter_inserter = 4.62,
   },

   DEBUG = true
}