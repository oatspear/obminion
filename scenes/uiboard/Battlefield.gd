extends MarginContainer

################################################################################
# Signals
################################################################################

signal battlefield_tile_selected(i)

################################################################################
# Internal State
################################################################################

onready var tiles = $Margin/Tiles.get_children()

################################################################################
# Interface
################################################################################

func place_minion(minion: Node2D, i: int):
    var tile = tiles[i]
    assert(tile.minion == null, "tile is not empty")
    tile.minion = minion
    minion.global_position.x = tile.global_x()
    minion.global_position.y = tile.global_y()


func find_minion(minion: Node2D):
    for tile in tiles:
        if tile.minion == minion:
            return tile
    return null


func get_spawn_points(pi: int = -1, only_free: bool = true):
    var indices = []
    for i in range(len(tiles)):
        if not tiles[i].is_spawn_tile():
            continue
        if only_free and not tiles[i].is_empty():
            continue
        if pi >= 0 and tiles[i].player_owner != pi:
            continue
        indices.append(i)
    return indices


func get_adjacent_enemies(i: int):
    var tile = tiles[i]
    var minion = tile.minion
    var enemies = []
    if minion != null:
        var p = minion.player_owner
        for k in tile.adjacent:
            minion = tiles[k].minion
            if minion != null and minion.player_owner != p:
                enemies.append(k)
    return enemies


func get_reachable_tiles(i: int, n: int):
    assert(n >= 0)
    var reach = {i: 0}
    _build_reach(reach, i, n, 1)
    return reach.keys()

func _build_reach(reach: Dictionary, i: int, n: int, steps: int):
    if n <= 0:
        return
    for j in tiles[i].adjacent:
        if not tiles[j].is_empty():
            continue
        if j in reach and reach[j] < steps:
            continue
        reach[j] = steps
        _build_reach(reach, j, n - 1, steps + 1)


func get_paths(i: int, n: int):
    var paths = {i: []}
    _build_paths(paths, [], i, n)
    return paths

func _build_paths(paths: Dictionary, path: Array, i: int, n: int):
    if n <= 0:
        return
    for j in tiles[i].adjacent:
        if j in paths or tiles[j].minion != null:
            pass
        else:
            var curr_path = path.duplicate(true)
            curr_path.append(j)
            paths[j] = curr_path
            print("Path to %d: %s" % [j, curr_path])
            _build_paths(paths, curr_path, j, n - 1)



func enable_minion_tiles(pi: int = -1, data=null):
    for tile in tiles:
        if (tile.minion != null and tile.minion.can_act()
                and (pi < 0 or tile.minion.player_owner == pi)):
            tile.enable_selection(data)


func disable_all_tiles():
    for tile in tiles:
        tile.disable_tile()


################################################################################
# Event Callbacks
################################################################################

func _ready():
    for i in range(0, len(tiles)):
        var tile = tiles[i]
        tile.tile_index = i
        tile.connect("tile_selected", self, "_on_tile_selected")


func _on_tile_selected(i: int):
    print("Tile %d is selected" % i)
    emit_signal("battlefield_tile_selected", i)
