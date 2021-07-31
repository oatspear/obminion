extends Node2D

# NOTE
# Animations are implemented as a queue of co-routines (yield).
# Co-routines save internal state, and avoid creating new classes.
# Plus, they allow multi-step animations, with multiple yield statements
# over the course of the function.

################################################################################
# Constants
################################################################################

const MINION_SCENE = preload("res://scenes/minions/Minion.tscn")
const HERO_SCENE = preload("res://scenes/minions/Commander.tscn")

const FCT = preload("res://scenes/ui/FloatingCombatText.tscn")

enum UIState {
    PASSIVE, MAIN_ACTION, SELECT_MOVE, SELECT_SPAWN, CHECK_INFO, ATTACK_OR_SKIP
}

################################################################################
# Signals
################################################################################

signal action_move(minion_index, tile_index)
signal action_attack(minion_index, tile_index)
signal action_spawn(minion_index, spawn_tile_index, dest_tile_index)
signal action_end_turn()

################################################################################
# Variables
################################################################################

onready var board = $BoardLayer/Board
onready var battlefield = board.battlefield
onready var object_layer = $ObjectLayer
onready var end_turn_button = $GUILayer/EndTurn
onready var minion_info_modal = $GUILayer/MinionInfoModal
onready var top_panel = $GUILayer/TopPanel

# animation loop
var _animating: bool = false
var _anim_queue: Array = []

# more or less constant after setting
var _this_player: int = -1
var _enemy_player: int = -1
var _benches: Array = [null, null]
var _graveyards: Array = [null, null]
var _heroes: Array = [null, null]
var _minions: Array = [[], []]

# internal state variables
var _ui_state: int = UIState.PASSIVE
var _selected_minion: Node2D = null
var _highlighted_tiles: Array = []
var _spawn_issued: bool = false


################################################################################
# Initialization
################################################################################

# @pre: called after _ready()
func set_player_index(i: int):
    print("[DEBUG] set_player_index()")
    var ei = (i + 1) % 2
    _this_player = i
    _enemy_player = ei
    _benches[i] = board.player_bench
    _benches[ei] = board.enemy_bench
    _graveyards[i] = board.player_graveyard
    _graveyards[ei] = board.enemy_graveyard

# @pre: called after set_player_index()
func set_battle_board(board_state: Reference):
    print("[DEBUG] set_battle_board()")
    for i in range(len(board_state.players)):
        var player_state = board_state.players[i]
        _minions[i].resize(len(player_state.minions))
    _set_battlefield_tiles(battlefield, board_state)
    for i in range(len(board_state.players)):
        print("[DEBUG] board_state.players[%d]" % i)
        var player_state = board_state.players[i]
        _set_benched_minions(_benches[i], player_state.bench)
        _set_graveyard_minions(_graveyards[i], player_state.graveyard)


func _set_battlefield_tiles(field_view, field_state):
    assert(len(field_view.tiles) == len(field_state.tiles))
    for i in range(len(field_state.tiles)):
        var tile_state = field_state.tiles[i]
        var tile_view = field_view.tiles[i]
        tile_view.set_tile_type(tile_state.tile_type)
        tile_view.player_owner = tile_state.owner
        tile_view.adjacent = tile_state.adjacent.duplicate()
        var minion_state = tile_state.minion
        if minion_state != null:
            assert(minion_state.location == Global.BoardLocation.BATTLEFIELD)
            assert(minion_state.position == i)
            if tile_state.is_base():
                #var hero_view = HERO_SCENE.instance()
                #hero_view.set_state(minion_state)
                #hero_view.tile_index = i
                #object_layer.add_child(hero_view)
                assert(tile_view.tile_type == Global.TileType.BASE)
                #field_view.place_minion(hero_view, i)
                #_heroes[tile_view.player_owner] = hero_view
            else:
                var minion_view = MINION_SCENE.instance()
                minion_view.set_state(minion_state)
                minion_view.board_location = Global.BoardLocation.BATTLEFIELD
                minion_view.tile_index = i
                object_layer.add_child(minion_view)
                field_view.place_minion(minion_view, i)
                _minions[minion_state.owner][minion_state.index] = minion_view

func _set_benched_minions(bench_view, bench_state):
    for i in range(len(bench_state)):
        var minion_state = bench_state[i]
        assert(minion_state.location == Global.BoardLocation.BENCH)
        var minion_view = MINION_SCENE.instance()
        minion_view.set_state(minion_state)
        minion_view.board_location = Global.BoardLocation.BENCH
        minion_view.tile_index = minion_state.index
        object_layer.add_child(minion_view)
        bench_view.place_minion(minion_view, minion_state.index) # different
        _minions[minion_state.owner][minion_state.index] = minion_view

func _set_graveyard_minions(grave_view, grave_state):
    for i in range(len(grave_state)):
        var minion_state = grave_state[i]
        assert(minion_state.location == Global.BoardLocation.GRAVEYARD)
        assert(minion_state.position == i)
        var minion_view = MINION_SCENE.instance()
        minion_view.set_state(minion_state)
        minion_view.board_location = Global.BoardLocation.GRAVEYARD
        minion_view.tile_index = i
        object_layer.add_child(minion_view)
        grave_view.place_minion(minion_view, i)
        _minions[minion_state.owner][minion_state.index] = minion_view

func _set_commander(i, player_state):
    var hero_state = player_state.commander
    var hero_view = HERO_SCENE.instance()
    hero_view.set_state(hero_state)
    hero_view.tile_index = hero_state.position
    object_layer.add_child(hero_view)
    assert(battlefield.tiles[hero_state.position].tile_type == Global.TileType.BASE)
    assert(battlefield.tiles[hero_state.position].player_owner == i)
    battlefield.place_minion(hero_view, i)
    _heroes[i] = hero_view


################################################################################
# Player Handle Interface
################################################################################

func get_player_input():
    var anim = _anim_get_player_input()
    assert(anim is GDScriptFunctionState)
    _anim_queue.append(anim)


################################################################################
# Event Callbacks
################################################################################

func _process(_delta):
    _play_next_animation()


func _on_Board_battlefield_tile_selected(ti):
    match _ui_state:
        UIState.MAIN_ACTION:
            _main_action_field_tile_selected(ti)
        UIState.SELECT_MOVE:
            _select_move_field_tile_selected(ti)
        UIState.ATTACK_OR_SKIP:
            _attack_or_skip_field_tile_selected(ti)
        UIState.SELECT_SPAWN:
            _select_spawn_field_tile_selected(ti)
        _:
            pass

# warning-ignore:unused_argument
func _on_Board_enemy_graveyard_tile_selected(ti):
    if _ui_state == UIState.MAIN_ACTION:
        var minion = board.enemy_graveyard.tiles[ti].minion
        minion_info_modal.show_minion(minion)

# warning-ignore:unused_argument
func _on_Board_player_graveyard_tile_selected(ti):
    if _ui_state == UIState.MAIN_ACTION:
        var minion = board.player_graveyard.tiles[ti].minion
        minion_info_modal.show_minion(minion)

func _on_Board_player_bench_tile_selected(ti):
    match _ui_state:
        UIState.MAIN_ACTION:
            _main_action_bench_tile_selected(ti)
        UIState.SELECT_MOVE:
            _select_move_bench_tile_selected(ti)
        UIState.SELECT_SPAWN:
            _select_spawn_bench_tile_selected(ti)
        _:
            pass

# warning-ignore:unused_argument
func _on_Board_enemy_bench_tile_selected(ti):
    match _ui_state:
        UIState.MAIN_ACTION:
            var minion = board.enemy_bench.tiles[ti].minion
            minion_info_modal.show_minion(minion)
        _:
            pass

func _on_EndTurn_pressed():
    assert(_ui_state != UIState.PASSIVE)
    _block_player_input()
    emit_signal("action_end_turn")


################################################################################
# Game Logic Callbacks
################################################################################

func on_battle_started():
    var anim = _anim_battle_started()
    assert(anim is GDScriptFunctionState)
    _anim_queue.append(anim)

func on_battle_ended(pi):
# warning-ignore:function_may_yield
    _anim_queue.append(_anim_battle_ended(pi))

func on_turn_order_chosen(pis):
# warning-ignore:function_may_yield
    _anim_queue.append(_anim_turn_order_chosen(pis))

func on_turn_started(pi):
# warning-ignore:function_may_yield
    _anim_queue.append(_anim_turn_started(pi))

func on_turn_ended(pi):
# warning-ignore:function_may_yield
    _anim_queue.append(_anim_turn_ended(pi))

func on_turn_skipped(pi):
# warning-ignore:function_may_yield
    _anim_queue.append(_anim_turn_skipped(pi))

func on_main_phase_started(pi):
# warning-ignore:function_may_yield
    _anim_queue.append(_anim_main_phase_started(pi))
    print("[ANIM] placed main_phase_started")

func on_main_phase_ended(pi):
# warning-ignore:function_may_yield
    _anim_queue.append(_anim_main_phase_ended(pi))
    print("[ANIM] placed main_phase_ended")

func on_combat_phase_started(pi, mi):
# warning-ignore:function_may_yield
    _anim_queue.append(_anim_combat_phase_started(pi, mi))
    print("[ANIM] placed combat_phase_started")

func on_combat_phase_ended(pi):
# warning-ignore:function_may_yield
    _anim_queue.append(_anim_combat_phase_ended(pi))
    print("[ANIM] placed combat_phase_ended")

func on_movement_issued(pi, ti, path):
# warning-ignore:function_may_yield
    _anim_queue.append(_anim_movement_issued(pi, ti, path))

func on_minion_moving(ti, tj):
# warning-ignore:function_may_yield
    _anim_queue.append(_anim_minion_moving(ti, tj))

func on_minion_moved(ti, tj):
# warning-ignore:function_may_yield
    _anim_queue.append(_anim_minion_moved(ti, tj))

func on_spawn_issued(pi, mi, ti, path):
# warning-ignore:function_may_yield
    _anim_queue.append(_anim_spawn_issued(pi, mi, ti, path))
    print("[ANIM] placed spawn_issued")

func on_attack_issued(pi, mi, ti):
# warning-ignore:function_may_yield
    _anim_queue.append(_anim_attack_issued(pi, mi, ti))
    print("[ANIM] placed attack_issued")

func on_combat_started(ti, tj):
# warning-ignore:function_may_yield
    _anim_queue.append(_anim_combat_started(ti, tj))
    print("[ANIM] placed combat_started")

func on_combat_ended(ti, tj):
# warning-ignore:function_may_yield
    _anim_queue.append(_anim_combat_ended(ti, tj))

func on_minion_attacking(ti, tj):
# warning-ignore:function_may_yield
    _anim_queue.append(_anim_minion_attacking(ti, tj))

func on_minion_attacked(ti, tj):
# warning-ignore:function_may_yield
    _anim_queue.append(_anim_minion_attacked(ti, tj))

func on_minion_defending(ti, tj):
# warning-ignore:function_may_yield
    _anim_queue.append(_anim_minion_defending(ti, tj))

func on_minion_defended(ti, tj):
# warning-ignore:function_may_yield
    _anim_queue.append(_anim_minion_defended(ti, tj))

func on_minion_damaged(ti, dmg):
# warning-ignore:function_may_yield
    _anim_queue.append(_anim_minion_damaged(ti, dmg))

func on_minion_died(pi, mi, ti):
# warning-ignore:function_may_yield
    _anim_queue.append(_anim_minion_died(pi, mi, ti))

func on_minion_survived(ti):
# warning-ignore:function_may_yield
    _anim_queue.append(_anim_minion_survived(ti))

func on_raid_started(pi, mi, pj):
# warning-ignore:function_may_yield
    _anim_queue.append(_anim_raid_started(pi, mi, pj))

func on_raid_ended(pi, mi, pj):
# warning-ignore:function_may_yield
    _anim_queue.append(_anim_raid_ended(pi, mi, pj))

func on_minion_raiding(pi, mi, pj):
# warning-ignore:function_may_yield
    _anim_queue.append(_anim_minion_raiding(pi, mi, pj))

func on_minion_raided(pi, mi, pj):
# warning-ignore:function_may_yield
    _anim_queue.append(_anim_minion_raided(pi, mi, pj))

func on_hero_defending(pi, pj, mj):
# warning-ignore:function_may_yield
    _anim_queue.append(_anim_hero_defending(pi, pj, mj))

func on_hero_defended(pi, pj, mj):
# warning-ignore:function_may_yield
    _anim_queue.append(_anim_hero_defended(pi, pj, mj))

func on_hero_damaged(pi, dmg):
# warning-ignore:function_may_yield
    _anim_queue.append(_anim_hero_damaged(pi, dmg))

func on_minion_entered_battlefield(pi, mi, ti):
# warning-ignore:function_may_yield
    _anim_queue.append(_anim_minion_entered_battlefield(pi, mi, ti))

func on_minion_entered_bench(pi, mi, i):
# warning-ignore:function_may_yield
    _anim_queue.append(_anim_minion_entered_bench(pi, mi, i))

func on_minion_entered_graveyard(pi, mi, i):
# warning-ignore:function_may_yield
    _anim_queue.append(_anim_minion_entered_graveyard(pi, mi, i))

func on_minion_exited_battlefield(pi, mi, ti):
# warning-ignore:function_may_yield
    _anim_queue.append(_anim_minion_exited_battlefield(pi, mi, ti))

func on_minion_exited_bench(pi, mi, bi):
# warning-ignore:function_may_yield
    _anim_queue.append(_anim_minion_exited_bench(pi, mi, bi))

func on_minion_exited_graveyard(pi, mi, gi):
# warning-ignore:function_may_yield
    _anim_queue.append(_anim_minion_exited_graveyard(pi, mi, gi))

func on_player_updated_indicators(pi, nh, nr, nsa, nsu):
# warning-ignore:function_may_yield
    _anim_queue.append(_anim_player_updated_indicators(pi, nh, nr, nsa, nsu))


################################################################################
# Animation Callbacks
################################################################################

func _play_next_animation():
    if not _animating and len(_anim_queue) > 0:
        var co = _anim_queue.pop_front()
        assert(co is GDScriptFunctionState and co.is_valid())
        _animating = true
        co.resume()

func _on_animation_finished():
    _animating = false


func _anim_get_player_input():
    yield()
    if _ui_state == UIState.MAIN_ACTION:
        print("[PLAYER] Get input (main phase)")
        _enable_main_input()
    elif _ui_state == UIState.ATTACK_OR_SKIP:
        print("[PLAYER] Get input (combat phase)")
        _enable_combat_input()
    else:
        print("[PLAYER] Get input (%d state)" % _ui_state)
        _selected_minion.error()
        assert(false)
    _on_animation_finished()

func _anim_battle_started():
    yield()
    print("Battle started!")
    _on_animation_finished()

func _anim_battle_ended(pi):
    yield()
    print("Battle ended! Winner is %d" % pi)
    _on_animation_finished()

func _anim_turn_order_chosen(pis):
    yield()
    print("Turn order chosen: %s" % var2str(pis))
    _on_animation_finished()

func _anim_turn_started(pi):
    yield()
    print("[P%d] Turn started" % pi)
    _on_animation_finished()

func _anim_turn_ended(pi):
    yield()
    print("[P%d] Turn ended" % pi)
    _on_animation_finished()

func _anim_turn_skipped(pi):
    yield()
    print("[P%d] Turn skipped" % pi)
    _on_animation_finished()

func _anim_main_phase_started(pi):
    yield()
    print("[P%d] Main phase started" % pi)
    _ui_state = UIState.MAIN_ACTION
    _spawn_issued = false
    _on_animation_finished()

func _anim_main_phase_ended(pi):
    yield()
    print("[P%d] Main phase ended" % pi)
    for tile in _highlighted_tiles:
        tile.disable_tile()
    if len(_highlighted_tiles) > 0:
        _highlighted_tiles = []
    _on_animation_finished()

func _anim_combat_phase_started(pi, mi):
    yield()
    print("[P%d](%d) Combat phase started" % [pi, mi])
    _ui_state = UIState.ATTACK_OR_SKIP
    _selected_minion = _minions[pi][mi]
    _on_animation_finished()

func _anim_combat_phase_ended(pi):
    yield()
    print("[P%d] Combat phase ended" % pi)
    _selected_minion = null
    _on_animation_finished()

func _anim_movement_issued(pi, ti, path):
    yield()
    print("[P%d](%d, %s) Movement issued" % [pi, ti, var2str(path)])
    _on_animation_finished()

func _anim_minion_moving(ti, tj):
    yield()
    print("[P*] Minion moving from %d to %d" % [ti, tj])
    _on_animation_finished()

func _anim_minion_moved(ti, tj):
    yield()
    var src_tile = battlefield.tiles[ti]
    var dst_tile = battlefield.tiles[tj]
    var minion = src_tile.minion
    assert(minion != null)
    var pi = minion.player_owner
    var mi = minion.minion_index
    print("[P%d] Minion %d moved from %d to %d" % [pi, mi, ti, tj])
    # assert(minion.player_owner == pi)
    # assert(minion.minion_index == mi)
    assert(dst_tile.minion == null)
    src_tile.minion = null
    dst_tile.minion = minion
    print("[TILE %d] minion = %s" % [ti, src_tile.minion])
    print("[TILE %d] minion = %s" % [tj, dst_tile.minion])
    minion.move_to_tile(dst_tile)
    minion.board_location = Global.BoardLocation.BATTLEFIELD
    yield(minion, "animation_finished")
    minion.play_idle()
    _on_animation_finished()

func _anim_spawn_issued(pi, mi, ti, path):
    yield()
    print("[P%d](%d, %d) Spawn issued %s" % [pi, mi, ti, var2str(path)])
    _spawn_issued = true
    var tile = battlefield.tiles[ti]
    tile.highlight_friend()
    _highlighted_tiles.append(tile)
    _on_animation_finished()

func _anim_attack_issued(pi, mi, ti):
    yield()
    print("[P%d] Minion %d attacking %d" % [pi, mi, ti])
    _on_animation_finished()

func _anim_combat_started(ti, tj):
    yield()
    var t = battlefield.tiles[ti]
    var pi = t.minion.player_owner
    var mi = t.minion.minion_index
    t = battlefield.tiles[tj]
    var pj = t.minion.player_owner
    var mj = t.minion.minion_index
    print("[P%d](%d) Combat started vs (%d, %d)" % [pi, mi, pj, mj])
    var minion = _minions[pj][mj]
    minion.play_defend()
    minion = _minions[pi][mi]
    minion.play_pre_attack()
    yield(minion, "animation_finished")
    _on_animation_finished()

func _anim_combat_ended(ti, tj):
    yield()
    # battlefield.tiles[ti].minion
    # battlefield.tiles[tj].minion
    print("[P*] Combat ended (Tile %d vs Tile %d)" % [ti, tj])
    _on_animation_finished()

func _anim_minion_attacking(ti, tj):
    yield()
    var t = battlefield.tiles[ti]
    var pi = t.minion.player_owner
    var mi = t.minion.minion_index
    t = battlefield.tiles[tj]
    var pj = t.minion.player_owner
    var mj = t.minion.minion_index
    print("[P%d](%d) Attacking (%d, %d)" % [pi, mi, pj, mj])
    _on_animation_finished()

func _anim_minion_defending(ti, tj):
    yield()
    var t = battlefield.tiles[ti]
    var pi = t.minion.player_owner
    var mi = t.minion.minion_index
    t = battlefield.tiles[tj]
    var pj = t.minion.player_owner
    var mj = t.minion.minion_index
    print("[P%d](%d) Defending vs (%d, %d)" % [pi, mi, pj, mj])
    _on_animation_finished()

func _anim_minion_attacked(ti, tj):
    yield()
    var t = battlefield.tiles[ti]
    var pi = t.minion.player_owner
    var mi = t.minion.minion_index
    t = battlefield.tiles[tj]
    var pj = t.minion.player_owner
    var mj = t.minion.minion_index
    print("[P%d](%d) Attacked (%d, %d)" % [pi, mi, pj, mj])
    var minion = _minions[pi][mi]
    minion.play_attack()
    yield(minion, "animation_finished")
    minion.play_idle()
    _on_animation_finished()

func _anim_minion_defended(ti, tj):
    yield()
    var t = battlefield.tiles[ti]
    var pi = t.minion.player_owner
    var mi = t.minion.minion_index
    t = battlefield.tiles[tj]
    var pj = t.minion.player_owner
    var mj = t.minion.minion_index
    print("[P%d](%d) Defended vs (%d, %d)" % [pi, mi, pj, mj])
    var minion = _minions[pi][mi]
    minion.play_attack_full()
    yield(minion, "animation_finished")
    _on_animation_finished()

func _anim_minion_damaged(ti, dmg):
    yield()
    var minion = battlefield.tiles[ti].minion
    var pi = minion.player_owner
    var mi = minion.minion_index
    print("[P%d](%d) Took %d damage" % [pi, mi, dmg])
    assert(minion.tile_index == ti)
    # var minion = _minions[pi][mi]
    _show_combat_text(minion.tile_index, dmg)
    minion.damage(dmg)
    yield(minion, "animation_finished")
    _on_animation_finished()

func _anim_minion_died(pi, mi, ti):
    yield()
    print("[P%d](%d) Minion died at (%d)" % [pi, mi, ti])
    var minion = _minions[pi][mi]
    minion.play_dead()
    yield(minion, "animation_finished")
    _on_animation_finished()

func _anim_minion_survived(ti):
    yield()
    var t = battlefield.tiles[ti]
    var pi = t.minion.player_owner
    var mi = t.minion.minion_index
    print("[P%d](%d) Minion survived" % [pi, mi])
    _minions[pi][mi].play_idle()
    _on_animation_finished()

func _anim_raid_started(pi, mi, pj):
    yield()
    print("[P%d](%d) Raid started vs %d" % [pi, mi, pj])
    # FIXME
    # var minion = _minions[pj][mj]
    # minion.play_defend()
    var minion = _minions[pi][mi]
    minion.play_pre_attack()
    yield(minion, "animation_finished")
    _on_animation_finished()

func _anim_raid_ended(pi, mi, pj):
    yield()
    print("[P%d](%d) Raid ended vs %d" % [pi, mi, pj])
    _on_animation_finished()

func _anim_minion_raiding(pi, mi, pj):
    yield()
    print("[P%d](%d) Raiding %d" % [pi, mi, pj])
    _on_animation_finished()

func _anim_hero_defending(pi, pj, mj):
    yield()
    print("[P%d] Defending vs (%d, %d)" % [pi, pj, mj])
    _on_animation_finished()

func _anim_minion_raided(pi, mi, pj):
    yield()
    print("[P%d](%d) Raided %d" % [pi, mi, pj])
    var minion = _minions[pi][mi]
    minion.play_attack()
    yield(minion, "animation_finished")
    minion.play_idle()
    _on_animation_finished()

func _anim_hero_defended(pi, pj, mj):
    yield()
    print("[P%d] Defended vs (%d, %d)" % [pi, pj, mj])
    # FIXME
    #var minion = _minions[pi][mi]
    #minion.play_attack_full()
    #yield(minion, "animation_finished")
    _on_animation_finished()

func _anim_hero_damaged(pi, dmg):
    yield()
    print("[P%d] Took %d damage" % [pi, dmg])
    # FIXME
    #var minion = _minions[pi][mi]
    #_show_combat_text(minion.tile_index, dmg)
    #minion.damage(dmg)
    #yield(minion, "animation_finished")
    _on_animation_finished()

func _anim_minion_entered_battlefield(pi, mi, ti):
    yield()
    print("[P%d](%d) Entered battlefield at %d" % [pi, mi, ti])
    var tile = battlefield.tiles[ti]
    var minion = _minions[pi][mi]
    assert(tile.minion == null)
    assert(minion.player_owner == pi)
    assert(minion.minion_index == mi)
    tile.minion = minion
    if _spawn_issued:
        minion.board_location = Global.BoardLocation.BATTLEFIELD
        minion.tile_index = ti
        minion.enter_battlefield(tile.screen_position())
        yield(minion, "animation_finished")
    else:
        # FIXME
        minion.global_position = tile.screen_position()
        minion.board_location = Global.BoardLocation.BATTLEFIELD
        minion.tile_index = ti
        minion.visible = true
    minion.play_idle()
    _on_animation_finished()

func _anim_minion_entered_bench(pi, mi, ti):
    yield()
    print("[P%d](%d) Entered bench at %d" % [pi, mi, ti])
    # We are going to diverge from logic here
    var minion = _minions[pi][mi]
    var tile = _benches[pi].tiles[minion.minion_index]
    assert(tile.minion == null)
    assert(minion.player_owner == pi)
    assert(minion.minion_index == mi)
    tile.minion = minion
    # FIXME
    minion.global_position = tile.screen_position()
    minion.board_location = Global.BoardLocation.BENCH
    minion.tile_index = minion.minion_index
    minion.visible = true
    _on_animation_finished()

func _anim_minion_entered_graveyard(pi, mi, ti):
    yield()
    print("[P%d](%d) Entered graveyard at %d" % [pi, mi, ti])
    var tile = _graveyards[pi].tiles[ti]
    var minion = _minions[pi][mi]
    assert(tile.minion == null)
    assert(minion.player_owner == pi)
    assert(minion.minion_index == mi)
    tile.minion = minion
    ####################################
    #var minion = battlefield.tiles[i].minion
    #assert(minion != null)
    #battlefield.tiles[i].minion = null
    #if minion.player_owner == _this_player:
    #    var first = board.player_graveyard.enqueue_minion(minion)
    #    if first != null:
    #        var nil = board.player_bench.enqueue_minion(first)
    #        assert(nil == null)
    #else:
    #    assert(minion.player_owner == _enemy_player)
    #    var first = board.enemy_graveyard.enqueue_minion(minion)
    #    if first != null:
    #        var nil = board.enemy_bench.enqueue_minion(first)
    #        assert(nil == null)
    ####################################
    # FIXME
    minion.global_position = tile.screen_position()
    minion.board_location = Global.BoardLocation.GRAVEYARD
    minion.tile_index = ti
    minion.visible = true
    minion.play_default()
    _on_animation_finished()

func _anim_minion_exited_battlefield(pi, mi, ti):
    yield()
    print("[P%d](%d) Exited battlefield" % [pi, mi])
    var minion = _minions[pi][mi]
    # var tile = battlefield.find_minion(minion)
    # assert(tile != null)
    var tile = battlefield.tiles[ti]
    assert(tile.minion == minion)
    assert(minion.player_owner == pi)
    assert(minion.minion_index == mi)
    tile.minion = null
    minion.board_location = Global.BoardLocation.NONE
    minion.visible = false
    _on_animation_finished()

func _anim_minion_exited_bench(pi, mi, bi):
    yield()
    print("[P%d](%d) Exited bench" % [pi, mi])
    var minion = _minions[pi][mi]
    # must use find because we diverged from logic above
    var tile = _benches[pi].find_minion(minion)
    assert(tile != null)
    assert(tile.minion == minion)
    assert(minion.player_owner == pi)
    assert(minion.minion_index == mi)
    tile.minion = null
    minion.board_location = Global.BoardLocation.NONE
    if _spawn_issued:
        minion.exit_bench()
        yield(minion, "animation_finished")
    else:
        minion.visible = false
    _on_animation_finished()

func _anim_minion_exited_graveyard(pi, mi, gi):
    yield()
    print("[P%d](%d) Exited graveyard" % [pi, mi])
    var minion = _minions[pi][mi]
    var tile = _graveyards[pi].find_minion(minion)
    assert(tile != null)
    assert(tile.minion == minion)
    assert(minion.player_owner == pi)
    assert(minion.minion_index == mi)
    tile.minion = null
    minion.board_location = Global.BoardLocation.NONE
    minion.visible = false
    # FIXME reposition other minions
    _on_animation_finished()

func _anim_player_updated_indicators(pi, nh, nr, nsa, nsu):
    yield()
    print("[P%d] (H) %d, (R) %d, (S) %d/%d" % [pi, nh, nr, nsu, nsa])
    if pi == _this_player:
        top_panel.update_this_player_indicators(nh, nr, nsa, nsu)
    else:
        top_panel.update_enemy_player_indicators(nh, nr, nsa, nsu)
    _on_animation_finished()


################################################################################
# Main Phase
################################################################################

func _main_action_field_tile_selected(ti: int):
    var tile = battlefield.tiles[ti]
    var minion = tile.minion
    assert(minion != null)
    if minion.player_owner != _this_player:
        print("Inspecting minion (t%d, m%d)." % [ti, minion.minion_index])
        minion_info_modal.show_minion(minion)
        return
    assert(minion.player_owner == _this_player)
    assert(minion.board_location == Global.BoardLocation.BATTLEFIELD)
    assert(minion.tile_index == ti)
    assert(minion.can_act())
    _disable_highlighted_tiles()
    for tj in battlefield.get_reachable_tiles(ti, minion.movement):
        if tj == ti:
            continue
        var dst_tile = battlefield.tiles[tj]
        dst_tile.enable_selection()
        _highlighted_tiles.append(dst_tile)
    for tj in battlefield.get_adjacent_enemies(ti):
        var dst_tile = battlefield.tiles[tj]
        dst_tile.enable_targeting()
        _highlighted_tiles.append(dst_tile)
    _selected_minion = minion
    _ui_state = UIState.SELECT_MOVE
    print("Minion tile selected (t%d, m%d). Choose target." % [ti, minion.minion_index])


func _main_action_bench_tile_selected(ti: int):
    var tile = board.player_bench.tiles[ti]
    var minion = tile.minion
    assert(minion != null)
    assert(minion.player_owner == _this_player)
    assert(minion.board_location == Global.BoardLocation.BENCH)
    assert(minion.tile_index == ti)
    assert(minion.can_act())
    _disable_highlighted_tiles()
    var spawns = battlefield.get_spawn_points(_this_player, true)
    if len(spawns) > 0:
        # _highlighted_tiles = []
        for tj in spawns:
            for tk in battlefield.get_reachable_tiles(tj, minion.movement - 1):
                var dst_tile = battlefield.tiles[tk]
                dst_tile.enable_selection(tj)
                _highlighted_tiles.append(dst_tile)
        _selected_minion = minion
        _ui_state = UIState.SELECT_SPAWN
        minion.play_salute()
        print("Benched '%s' (#%d) selected. Choose target." % [minion.species_name, minion.minion_index])
    else:
        print("No available spawn points.")


################################################################################
# Main Phase - Select Move State
################################################################################

func _select_move_field_tile_selected(ti: int):
    assert(_selected_minion != null)
    var tile = battlefield.tiles[ti]
    var minion = tile.minion
    if minion == _selected_minion:
        assert(_selected_minion.tile_index == ti)
        print("Selected the same minion; go back to main phase input.")
        for dst_tile in _highlighted_tiles:
            dst_tile.disable_tile()
        _highlighted_tiles = []
        _selected_minion = null
        _ui_state = UIState.MAIN_ACTION
    elif minion == null:
        var mi = _selected_minion.minion_index
        _block_player_input()
        print("Selected move destination tile (%d, %d)" % [mi, ti])
        emit_signal("action_move", mi, ti)
    elif minion.player_owner != _this_player:
        var mi = _selected_minion.minion_index
        _block_player_input()
        print("Selected enemy tile to attack (%d, %d)" % [mi, ti])
        emit_signal("action_attack", mi, ti)
    else:
        assert(minion.player_owner == _this_player)
        for dst_tile in _highlighted_tiles:
            dst_tile.disable_tile()
        print("Selected active friendly minion; transfer input control.")
        _main_action_field_tile_selected(ti)

func _select_move_bench_tile_selected(ti: int):
    assert(_selected_minion != null)
    for tile in _highlighted_tiles:
        tile.disable_tile()
    print("Transfer selection to benched minion.")
    _main_action_bench_tile_selected(ti)


################################################################################
# Combat Phase
################################################################################

func _attack_or_skip_field_tile_selected(ti):
    assert(_selected_minion != null)
    var tile = battlefield.tiles[ti]
    assert(not tile.is_empty())
    assert(tile.minion.player_owner != _this_player)
    assert(tile.minion.tile_index == ti)
    var mi = _selected_minion.minion_index
    _block_player_input()
    print("Selected enemy tile to attack (%d, %d)" % [mi, ti])
    emit_signal("action_attack", mi, ti)


################################################################################
# Main Phase - Select Spawn State
################################################################################

func _select_spawn_field_tile_selected(tj: int):
    assert(_selected_minion != null)
    var tile = battlefield.tiles[tj]
    if tile.is_empty():
        var mi = _selected_minion.minion_index
        assert(mi >= 0)
        var ti = tile.ui_data
        assert(ti != null and ti >= 0)
        print("Selected spawn destination tile (%d, %d, %d)." % [mi, ti, tj])
        _block_player_input()
        emit_signal("action_spawn", mi, ti, tj)
    else:
        assert(tile.minion.player_owner == _this_player)
        print("Selected active friendly minion; transfer input control.")
        _selected_minion.play_default()
        for dst_tile in _highlighted_tiles:
            dst_tile.disable_tile()
        _main_action_field_tile_selected(tj)

func _select_spawn_bench_tile_selected(ti: int):
    assert(_selected_minion != null)
    _selected_minion.play_default()
    for tile in _highlighted_tiles:
        tile.disable_tile()
    if _selected_minion.tile_index == ti:
        print("Selected the same minion; go back to main phase input.")
        _highlighted_tiles = []
        _selected_minion = null
        _ui_state = UIState.MAIN_ACTION
        _enable_minion_tile_inspection()
    else:
        print("Transfer selection to another minion.")
        _main_action_bench_tile_selected(ti)


################################################################################
# Helper Functions
################################################################################

func _enable_main_input():
    # enable player tiles and actions
    for minion in _minions[_this_player]:
        if minion.can_act():
            var ti = minion.tile_index
            if minion.board_location == Global.BoardLocation.BATTLEFIELD:
                var tile = battlefield.tiles[ti]
                assert(tile.minion == minion)
                tile.enable_selection()
            elif minion.board_location == Global.BoardLocation.BENCH:
                var tile = board.player_bench.tiles[ti]
                assert(tile.minion == minion)
                tile.enable_selection()
    # allow inspection of enemy minions
    assert(len(_highlighted_tiles) == 0)
    _enable_minion_tile_inspection()
    end_turn_button.disabled = false

func _enable_combat_input():
    assert(_selected_minion != null)
    assert(_selected_minion.player_owner == _this_player)
    var tile = battlefield.tiles[_selected_minion.tile_index]
    assert(tile.minion == _selected_minion)
    tile.highlight_friend()
    for tj in battlefield.get_adjacent_enemies(tile.tile_index):
        battlefield.tiles[tj].enable_targeting()
    end_turn_button.disabled = false

func _block_player_input():
    board.player_bench.disable_all_tiles()
    battlefield.disable_all_tiles()
    end_turn_button.disabled = true
    # reset internal variables; discard temporary data
    _selected_minion = null
    _ui_state = UIState.PASSIVE
    if len(_highlighted_tiles) > 0:
        _highlighted_tiles = []


func _enable_minion_tile_inspection():
    for minion in _minions[_enemy_player]:
        var ti = minion.tile_index
        if minion.board_location == Global.BoardLocation.BATTLEFIELD:
            var tile = battlefield.tiles[ti]
            assert(tile.minion == minion)
            tile.enable_inspection()
            _highlighted_tiles.append(tile)
        elif minion.board_location == Global.BoardLocation.BENCH:
            var tile = board.enemy_bench.tiles[ti]
            assert(tile.minion == minion)
            tile.enable_inspection()
            _highlighted_tiles.append(tile)
        elif minion.board_location == Global.BoardLocation.GRAVEYARD:
            var tile = board.enemy_graveyard.tiles[ti]
            assert(tile.minion == minion)
            tile.enable_inspection()
            _highlighted_tiles.append(tile)

func _disable_highlighted_tiles():
    for tile in _highlighted_tiles:
        tile.disable_tile()
    if len(_highlighted_tiles) > 0:
        _highlighted_tiles = []


func _show_combat_text(ti, value, crit=false):
    var fct = FCT.instance()
    var gui_layer = $GUILayer
    var tile = battlefield.tiles[ti]
    gui_layer.add_child(fct)
    fct.show_value(str(value), tile.screen_position(), crit)
