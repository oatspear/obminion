extends Reference

const TILE = "res://scripts/battle/Tile.gd"
const PLAYER = "res://scripts/battle/Player.gd"

################################################################################
# Signals
################################################################################

signal minion_moving(minion, i, j)
signal minion_moved(minion, i, j)
signal minion_entered_battlefield(minion, i)
signal minion_entered_bench(minion, i)
signal minion_entered_graveyard(minion, i)
signal minion_exited_battlefield(minion)
signal minion_exited_bench(minion)
signal minion_exited_graveyard(minion)

################################################################################
# Internal State
################################################################################

var tiles: Array = [] # battlefield
var players: Array = []

var _grave_size: int = 1

################################################################################
# Interface
################################################################################

func init(board_data: Resource):
    board_data.sanity_check()
    _grave_size = board_data.graveyard_size
    tiles = []
    var scr = load(TILE)
    for i in range(len(board_data.tiles)):
        var t = scr.new()
        t.tile_type = board_data.tiles[i]
        t.adjacent = board_data.adjacency[i].duplicate()
        assert(len(t.adjacent) > 0)
        assert(t.is_empty())
        tiles.append(t)
    players = []
    scr = load(PLAYER)
    for i in range(board_data.num_players):
        var p = scr.new()
        p.index = i
        #p.bench.resize(board_data.bench_size)
        #p.graveyard.resize(board_data.graveyard_size)
        p.spawn_points = board_data.spawn_points[i].duplicate()
        p.base_point = board_data.base_points[i]
        players.append(p)
        for j in p.spawn_points:
            assert(j >= 0 and j < len(tiles))
            assert(tiles[j].is_spawn())
            assert(tiles[j].owner < 0)
            tiles[j].owner = i
        assert(p.base_point >= 0 and p.base_point < len(tiles))
        assert(tiles[p.base_point].is_base())
        assert(tiles[p.base_point].owner < 0)
        tiles[p.base_point].owner = i


func get_path(i: int, j: int, n: int):
    var paths = _get_paths(i, n)
    if not j in paths:
        return []
    return paths[j]

func get_paths_n_steps(i: int, n: int):
    var key_value_paths = _get_paths(i, n)
    key_value_paths.erase(i)
    return key_value_paths.values()

func is_spawn_point(i: int):
    return tiles[i].is_spawn()

func is_empty(i: int = -1):
    if i < 0:
        for tile in tiles:
            if not tile.is_empty():
                return false
        return true
    return tiles[i].is_empty()

func is_adjacent(i: int, j: int):
    return j in tiles[i].adjacent

func get_active_minion_at(i: int):
    return tiles[i].minion

func get_adjacent_enemies(i: int):
    var tile = tiles[i]
    var minion = tile.minion
    var enemies = []
    if minion != null:
        var pi = minion.owner
        for k in tile.adjacent:
            minion = tiles[k].minion
            if minion != null and minion.owner != pi:
                enemies.append(k)
    return enemies


func move_along_path(i: int, path: Array):
    var j = i
    var minion = tiles[i].minion
    for k in path:
        emit_signal("minion_moving", minion, j, k)
        tiles[j].minion = null
        tiles[k].minion = minion
        minion.position = k
        emit_signal("minion_moved", minion, j, k)
        j = k


func place_minion_on_battlefield(minion: Reference, ti: int):
    assert(minion != null)
    assert(tiles[ti].minion == null)
    tiles[ti].minion = minion
    minion.set_active()
    minion.position = ti
    emit_signal("minion_entered_battlefield", minion, ti)
    return true

func place_minion_on_bench(minion: Reference):
    assert(minion != null)
    var player = players[minion.owner]
    var bench = player.bench
    assert(not bench.has(minion))
    minion.set_benched()
    minion.position = len(bench)
    bench.append(minion)
    emit_signal("minion_entered_bench", minion, minion.position)

func place_minion_on_graveyard(minion: Reference):
    assert(minion != null)
    var player = players[minion.owner]
    var graveyard = player.graveyard
    assert(not graveyard.has(minion))
    assert(len(graveyard) < _grave_size)
    minion.set_dead()
    minion.position = len(graveyard)
    graveyard.append(minion)
    emit_signal("minion_entered_graveyard", minion, minion.position)


func remove_from_battlefield(i: int):
    var minion = tiles[i].minion
    assert(minion != null)
    tiles[i].minion = null
    minion.set_removed()
    emit_signal("minion_exited_battlefield", minion)
    return minion

func remove_from_bench(pi: int, i: int):
    var player = players[pi]
    var minion = player.bench[i]
    assert(minion != null)
    assert(minion.position == i)
    player.bench.remove(i)
    minion.set_removed()
    for j in range(i, len(player.bench)):
        player.bench[j].position = j
    for j in range(0, i):
        assert(player.bench[j].position == j)
    emit_signal("minion_exited_bench", minion)
    return minion

func remove_from_graveyard(pi: int, i: int):
    var player = players[pi]
    var minion = player.graveyard[i]
    assert(minion != null)
    assert(minion.position == i)
    player.graveyard.remove(i)
    minion.set_removed()
    for j in range(i, len(player.graveyard)):
        player.graveyard[j].position = j
    for j in range(0, i):
        assert(player.graveyard[j].position == j)
    emit_signal("minion_exited_graveyard", minion)
    return minion


func is_graveyard_full(pi: int):
    return len(players[pi].graveyard) >= _grave_size

func dequeue_from_graveyard(pi: int):
    return remove_from_graveyard(pi, 0)


################################################################################
# Helper Functions
################################################################################

func _get_paths(i: int, n: int):
    var paths = {i: []}
    _build_paths(paths, [], i, n)
    return paths

func _build_paths(paths: Dictionary, path: Array, i: int, n: int):
    if n <= 0:
        return
    for j in tiles[i].adjacent:
        if not tiles[j].is_empty():
            continue
        if j in paths and len(paths[j]) <= (len(path) + 1):
            continue
        var curr_path = path.duplicate(true)
        curr_path.append(j)
        paths[j] = curr_path
        _build_paths(paths, curr_path, j, n - 1)
