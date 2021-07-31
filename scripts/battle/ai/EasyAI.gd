extends Reference

################################################################################
# Signals
################################################################################

signal eval_done()

################################################################################
# Constants
################################################################################

enum AC {SPAWN, MOVE, ATTACK}

################################################################################
# Variables
################################################################################

var player_index: int = -1
var game_logic: Reference = null

var _player_state: Reference = null
var _enemy_base: int = -1
var _actions: Array = []

################################################################################
# Interface
################################################################################

# @pre: `player_index` is set.
# @pre: `game_logic` is set.
func initialize():
    _player_state = game_logic.board.players[player_index]
    assert(_player_state.index == player_index)
    var epi = (player_index + 1) % len(game_logic.board.players)
    _enemy_base = game_logic.board.players[epi].base_point


# Called when logic asks for player input.
# It should read the game state and compute possible actions.
func compute_actions():
    print("[AI] compute_actions()")
    _actions = []
    if game_logic.is_main_phase_input():
        _compute_main_phase_actions()
    elif game_logic.is_combat_phase_input():
        _compute_combat_phase_actions()


# Called once every frame, after `compute_actions()`.
# It should evaluate an action per frame.
# When there are no more actions to evaluate,
#   emit the "eval_done" signal and call an action method
#   directly on `game_logic`.
func eval_next_action():
    print("[AI] eval_next_action()")
    # evaluate a computed action
    # when there are no more actions to evaluate,
    emit_signal("eval_done")
    # then choose one and act directly on game_logic
    game_logic.skip_turn(player_index)


################################################################################
# Helper Functions
################################################################################

func _compute_main_phase_actions():
    for ti in _player_state.spawn_points:
        if not game_logic.board.is_empty(ti):
            continue
        for minion in _player_state.bench:
            if _player_state.has_free_supplies(minion.supply_cost):
                var n = minion.movement - 1
                var paths = game_logic.board.get_paths_n_steps(ti, n)
                for path in paths:
                    print("[AI] consider SPAWN %d, %d, %s" % [minion.index, ti, path])
                    _consider(AC.SPAWN, [minion, ti, path])
    for minion in _player_state.minions:
        if not minion.is_active():
            continue
        var ti = minion.position
        var n = minion.movement
        var paths = game_logic.board.get_paths_n_steps(ti, n)
        for path in paths:
            print("[AI] consider MOVE %d, %s" % [minion.index, path])
            _consider(AC.MOVE, [minion, path])


func _compute_combat_phase_actions():
    pass


func _consider(ac: int, args: Array):
    _actions.append([ac, args, 0])
