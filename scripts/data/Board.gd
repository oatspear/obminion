extends Resource

export (int) var num_players: int = 2
export (int) var bench_size: int = 6
export (int) var graveyard_size: int = 2
export (Array, Global.TileType) var tiles: Array = []
export (Array, Array, int) var adjacency: Array = []
export (Array, Array, int) var spawn_points: Array = []
export (Array, int) var base_points: Array = []

func sanity_check():
    if num_players < 2:
        push_error("Needs at least two players")
    if bench_size < 1:
        push_error("Invalid bench_size")
    if graveyard_size < 1:
        push_error("Invalid graveyard_size")
    if len(tiles) < (2 * num_players):
        push_error("Board needs more tiles")
    _validate_adjacency()
    _validate_spawn_points()
    _validate_base_points()

func _validate_adjacency():
    var n = len(tiles)
    if len(adjacency) != n:
        push_error("Different lengths for tiles and adjacency")
    for points in adjacency:
        for ti in points:
            if ti < 0 or ti >= n:
                push_error("Tile out of bounds: %d" % ti)

func _validate_spawn_points():
    if len(spawn_points) < num_players:
        push_error("Needs spawn points for every player")
    var visited = {}
    for points in spawn_points:
        for ti in points:
            if ti in visited:
                push_error("Duplicated spawn point; %d" % ti)
            if tiles[ti] != Global.TileType.SPAWN:
                push_error("Not a spawn tile: %d" % ti)
            visited[ti] = true

func _validate_base_points():
    if len(base_points) < num_players:
        push_error("Needs base points for every player")
    var visited = {}
    for ti in base_points:
        if ti in visited:
            push_error("Duplicated base point; %d" % ti)
        if tiles[ti] != Global.TileType.BASE:
            push_error("Not a base tile: %d" % ti)
        visited[ti] = true
