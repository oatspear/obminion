extends Reference

################################################################################
# Signals
################################################################################

signal eval_done()

################################################################################
# Constants
################################################################################

enum AC {SKIP, SPAWN, MOVE, ATTACK}

const A_I_CONST: int = 0
const A_I_ARGS: int = 1
const A_I_SCORE: int = 2
const DISCOURAGED: int = -100

################################################################################
# Variables
################################################################################

var player_index: int = -1
var game_logic: Reference = null

var _player_state: Reference = null
var _enemy_base: int = -1
var _actions: Array = []
var _eval_i: int = -1
var _combat_minion: Reference = null

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
    # events
    game_logic.connect("combat_phase_started", self, "_on_combat_phase_started")


# Called when logic asks for player input.
# It should read the game state and compute possible actions.
func compute_actions():
    print("[AI] compute_actions()")
    _actions = []
    _eval_i = 0
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
    if _eval_i < len(_actions):
        var action = _actions[_eval_i]
        var args = action[A_I_ARGS]
        match action[A_I_CONST]:
            AC.SPAWN:
                action[A_I_SCORE] = _eval_spawn(args)
            AC.MOVE:
                action[A_I_SCORE] = _eval_move(args)
            AC.ATTACK:
                action[A_I_SCORE] = _eval_attack(args)
            _:
                action[A_I_SCORE] = DISCOURAGED
        _eval_i += 1
    else:
        # when there are no more actions to evaluate,
        emit_signal("eval_done")
        # then choose one and act directly on game_logic
        var selected = _choose_action()
        if selected == null:
            game_logic.skip_turn(player_index)
        else:
            _exec_action(selected)


################################################################################
# Helper Functions - Computing
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
    if _combat_minion != null:
        var i = _combat_minion.position
        var enemy_tiles = game_logic.board.get_adjacent_enemies(i)
        if enemy_tiles:
            var j = enemy_tiles[randi() % len(enemy_tiles)]
            print("[AI] consider ATTACK %d, %d" % [i, j])
            _consider(AC.ATTACK, [_combat_minion, j])


func _consider(ac: int, args: Array):
    _actions.append([ac, args, 0])


################################################################################
# Helper Functions - Evaluation
################################################################################

func _eval_spawn(args):
    return 1

func _eval_move(args):
    var dest = args[1][-1]
    if dest == _enemy_base:
        return 100
    return 1

func _eval_attack(args):
    return 1


################################################################################
# Helper Functions - Action
################################################################################

func _choose_action():
    var ac = AC.SKIP
    var args = null
    var score = 0
    var candidates = []
    for action in _actions:
        if action[A_I_SCORE] > score:
            candidates = [action]
            score = action[A_I_SCORE]
        elif action[A_I_SCORE] == score:
            candidates.append(action)
    if len(candidates) == 0:
        return null
    return candidates[randi() % len(candidates)]

func _exec_action(action):
    var args = action[A_I_ARGS]
    var mi = -1
    var ti = -1
    var tj = -1
    match action[A_I_CONST]:
        AC.SPAWN:
            mi = args[0].index
            ti = args[1]
            tj = args[2][-1]
            game_logic.spawn_benched_minion(player_index, mi, ti, tj)
        AC.MOVE:
            mi = args[0].index
            ti = args[1][-1]
            game_logic.move_active_minion(player_index, mi, ti)
        AC.ATTACK:
            mi = args[0].index
            ti = args[1]
            game_logic.attack_minion(player_index, mi, ti)
        _:
            game_logic.skip_turn(player_index)


################################################################################
# Event Listeners
################################################################################

func _on_combat_phase_started(pi: int, mi: int):
    if pi == player_index:
        _combat_minion = _player_state.minions[mi]
    else:
        _combat_minion = null
