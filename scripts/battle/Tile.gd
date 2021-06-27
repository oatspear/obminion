extends Reference

################################################################################
# Internal State
################################################################################

var adjacent: Array = []
var minion: Reference = null
var tile_type: int = Global.TileType.NORMAL
var owner: int = -1

################################################################################
# Interface
################################################################################

func is_empty():
    return minion == null

func set_normal():
    tile_type = Global.TileType.NORMAL

func set_spawn(pi: int = -1):
    tile_type = Global.TileType.SPAWN
    owner = pi

func set_base(pi: int = -1):
    tile_type = Global.TileType.BASE
    owner = pi

func is_normal():
    return tile_type == Global.TileType.NORMAL

func is_spawn():
    return tile_type == Global.TileType.SPAWN

func is_base():
    return tile_type == Global.TileType.BASE
