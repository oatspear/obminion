extends Reference

################################################################################
# Constants
################################################################################

enum BattleState {
    INITIAL,        # wait for all players to be ready
    BEGIN_TURN,     # start the player's turn
    MAIN_PHASE,     # player can choose any action
    INPUT_MAIN,     # wait for main phase input
    COMBAT_PHASE,   # player can choose combat after moving
    INPUT_COMBAT,   # wait for combat phase input
    END_TURN,       # end the player's turn
    ACTION_MOVE,    # player chose to move a minion
    ACTION_ATTACK,  # player chose to start combat
    ACTION_SPAWN,   # player chose to spawn a minion from bench
    BEGIN_COMBAT,   # start the combat between two minions
    BEGIN_RAID,     # start the combat against a commander
    COMBAT_RESOLVE, # damage and after-effects of combat (send to graveyard)
    RAID_RESOLVE,   # damage and after-effects of raid (send to graveyard)
    END_COMBAT,     # end the combat between two minions
    END_RAID,       # end the combat against a commander
    FINAL           # the battle has ended
}

const BOARD = "res://scripts/battle/Board.gd"

################################################################################
# Signals
################################################################################

# We are able to use tile indexes for many of the minion-related events because:
#   1. events can only happen at one location (battlefield, bench, graveyard);
#   2. there is only one minion per tile, at most.
# For instance, combat and damage happen only on the battlefield.
# Benched minions are still "in training", and thus are unaffected by combat.
# If this changes later on, we can always add more events or more arguments.

# signal ready_check(pid)
signal battle_set_up(board_data)
signal battle_started()
signal battle_ended()
signal turn_order_chosen(pis)
signal turn_started(pi)
signal turn_ended(pi)
signal turn_skipped(pi)
signal main_phase_started(pi)
signal main_phase_ended(pi)
signal combat_phase_started(pi, mi)
signal combat_phase_ended(pi)
signal input_requested(pi)
signal movement_issued(pi, ti, path)
signal minion_moving(ti, tj)
signal minion_moved(ti, tj)
signal spawn_issued(pi, bi, ti, path)
signal attack_issued(pi, ti, tj)
signal combat_started(ti, tj)
signal combat_ended(ti, tj)
signal minion_attacking(ti, tj)
signal minion_attacked(ti, tj)
signal minion_defending(ti, tj)
signal minion_defended(ti, tj)
signal minion_damaged(ti, dmg)
signal raid_started(ti, pi)
signal raid_ended(ti, pi)
signal minion_raiding(ti, pi)
signal minion_raided(ti, pi)
signal hero_defending(pi, ti)
signal hero_defended(pi, ti)
signal hero_damaged(pi, dmg)
signal minion_died(pi, mi, ti)
signal minion_survived(ti)
signal minion_spawning(pi, bi, ti)
signal minion_reviving(pi, gi, bi)
signal minion_entered_battlefield(pi, mi, ti)
signal minion_entered_bench(pi, mi, bi)
signal minion_entered_graveyard(pi, mi, gi)
signal minion_exited_battlefield(pi, mi, ti)
signal minion_exited_bench(pi, mi, bi)
signal minion_exited_graveyard(pi, mi, gi)
signal player_updated_indicators(pi, nh, nr, nsa, nsu)

################################################################################
# Variables
################################################################################

var state: int = BattleState.INITIAL
var board: Reference = null
var turns: int = 0

var _pi: int = 0
var _prev: int = BattleState.INITIAL
var _next: int = BattleState.INITIAL

var _arg_minion: Reference = null
var _arg_target: Reference = null
var _arg_path: Array = []
var _arg_position: int = 0
var _arg_phase: int = BattleState.MAIN_PHASE

################################################################################
# Processing
################################################################################

func step():
    if _next != state:
        _prev = state
        state = _next
    match state:
        BattleState.BEGIN_TURN:
            return _step_begin_turn()
        BattleState.MAIN_PHASE:
            return _step_main_phase()
        BattleState.COMBAT_PHASE:
            return _step_combat_phase()
        BattleState.END_TURN:
            return _step_end_turn()
        BattleState.ACTION_MOVE:
            return _step_action_move()
        BattleState.ACTION_ATTACK:
            return _step_action_attack()
        BattleState.ACTION_SPAWN:
            return _step_action_spawn()
        BattleState.BEGIN_COMBAT:
            return _step_begin_combat()
        BattleState.COMBAT_RESOLVE:
            return _step_combat_resolve()
        BattleState.END_COMBAT:
            return _step_end_combat()
        BattleState.BEGIN_RAID:
            return _step_begin_raid()
        BattleState.RAID_RESOLVE:
            return _step_raid_resolve()
        BattleState.END_RAID:
            return _step_end_raid()
        BattleState.INPUT_MAIN:
            return true
        BattleState.INPUT_COMBAT:
            return true
        _:
            return false

################################################################################
# Interface - Setup
################################################################################

func set_board(board_data: Resource):
    board = load(BOARD).new()
    board.init(board_data)
    var err = board.connect("minion_moving", self, "_on_minion_moving")
    assert(err == OK)
    err = board.connect("minion_moved", self, "_on_minion_moved")
    assert(err == OK)
    err = board.connect("minion_entered_battlefield", self, "_on_enter_battlefield")
    assert(err == OK)
    err = board.connect("minion_entered_bench", self, "_on_enter_bench")
    assert(err == OK)
    err = board.connect("minion_entered_graveyard", self, "_on_enter_graveyard")
    assert(err == OK)
    err = board.connect("minion_exited_battlefield", self, "_on_exit_battlefield")
    assert(err == OK)
    err = board.connect("minion_exited_bench", self, "_on_exit_bench")
    assert(err == OK)
    err = board.connect("minion_exited_graveyard", self, "_on_exit_graveyard")
    assert(err == OK)


func set_player_deck(i: int, player_data: Resource):
    assert(board != null)
    assert(i >= 0 and i < len(board.players))
    var p = board.players[i]
    #p.player_id = player_id
    p.init(player_data)
    assert(len(p.tokens) == 0)
    assert(len(p.bench) == 0)
    assert(len(p.graveyard) == 0)
    assert(len(p.spawn_points) > 0)
    assert(p.commander != null)
    var c = p.commander
    assert(c.owner == p.index)
    assert(c.species != null)
    assert(c.location == Global.BoardLocation.BATTLEFIELD)
    c.position = p.base_point
    board.tiles[c.position].minion = c
    assert(len(p.minions) > 0)
    for i in range(len(p.minions)):
        var m = p.minions[i]
        assert(m.index == i)
        assert(m.owner == p.index)
        assert(m.species != null)
        assert(not m.is_token)
        m.location = Global.BoardLocation.BENCH
        m.position = i
        p.bench.append(m)


################################################################################
# Interface
################################################################################

func start():
    assert(board != null)
    assert(len(board.players) >= 2)
    state = BattleState.INITIAL
    turns = 0
    randomize()
    # if there is no custom battle setup script:
    #_default_battle_setup()
    emit_signal("battle_set_up", board)
    _update_player_supplies()
    emit_signal("battle_started")
    _who_goes_first()
    _next = BattleState.BEGIN_TURN
    return true


func move_active_minion(pi: int, mi: int, ti: int):
    if pi != _pi or state != BattleState.INPUT_MAIN:
        return false
    var p = board.players[_pi]
    if not p.has_minion(mi):
        return false
    var m = p.get_minion(mi)
    if not m.is_active():
        return false
    var path = board.get_path(m.position, ti, m.movement)
    if not path:
        return false
    _arg_minion = m
    _arg_path = path
    _next = BattleState.ACTION_MOVE
    return true


func spawn_benched_minion(pi: int, mi: int, ti: int, tj: int):
    if pi != _pi or state != BattleState.INPUT_MAIN:
        return false
    if not board.is_spawn_point(ti):
        return false
    var p = board.players[_pi]
    if not p.has_minion(mi):
        return false
    if not p.spawn_points.has(ti):
        return false
    if not board.is_empty(ti):
        return false
    var m = p.get_minion(mi)
    if not m.is_benched():
        return false
    if not p.has_free_supplies(m.supply_cost):
        return false
    var path = []
    if ti != tj:
        path = board.get_path(ti, tj, m.movement - 1)
        if not path:
            return false
    _arg_position = ti
    _arg_minion = m
    _arg_path = path
    _next = BattleState.ACTION_SPAWN
    return true


func attack_minion(pi: int, mi: int, ti: int):
    if state != BattleState.INPUT_MAIN and state != BattleState.INPUT_COMBAT:
        return false
    if pi != _pi:
        return false
    var p = board.players[_pi]
    if not p.has_minion(mi):
        return false
    var m = p.get_minion(mi)
    if not m.is_active():
        return false
    if state == BattleState.INPUT_COMBAT and m != _arg_minion:
        return false
    if not board.is_adjacent(m.position, ti):
        return false
    var e = board.get_active_minion_at(ti)
    if e == null or e.owner == pi:
        return false
    _arg_minion = m
    _arg_target = e
    assert(_prev == BattleState.MAIN_PHASE or _prev == BattleState.COMBAT_PHASE)
    _arg_phase = _prev
    _next = BattleState.ACTION_ATTACK
    return true


func skip_turn(pi: int):
    if state != BattleState.INPUT_MAIN and state != BattleState.INPUT_COMBAT:
        return false
    if pi != _pi:
        return false
    emit_signal("turn_skipped", pi)
    _next = BattleState.END_TURN
    return true


################################################################################
# State Machine
################################################################################

func _step_begin_turn():
    turns += 1
    emit_signal("turn_started", _pi)
    _next = BattleState.MAIN_PHASE
    return true

func _step_main_phase():
    emit_signal("main_phase_started", _pi)
    _prev = state
    state = BattleState.INPUT_MAIN
    _next = BattleState.INPUT_MAIN
    emit_signal("input_requested", _pi)
    return true

func _step_combat_phase():
    var enemies = board.get_adjacent_enemies(_arg_minion.position)
    if enemies:
        emit_signal("combat_phase_started", _pi, _arg_minion.index)
        _prev = state
        state = BattleState.INPUT_COMBAT
        _next = BattleState.INPUT_COMBAT
        emit_signal("input_requested", _pi)
    else:
        _next = BattleState.END_TURN
    return true

func _step_end_turn():
    emit_signal("turn_ended", _pi)
    _pi = (_pi + 1) % len(board.players)
    _next = BattleState.BEGIN_TURN
    return true

func _step_action_move():
    assert(_arg_minion != null)
    assert(_arg_minion.owner == _pi)
    assert(len(_arg_path) > 0)
    var ti = _arg_minion.position
    emit_signal("movement_issued", _pi, ti, _arg_path)
    board.move_along_path(ti, _arg_path)
    emit_signal("main_phase_ended", _pi)
    _next = BattleState.COMBAT_PHASE
    return true

func _step_action_attack():
    assert(_arg_minion != null)
    assert(_arg_minion.owner == _pi)
    assert(_arg_target != null)
    emit_signal("attack_issued", _pi, _arg_minion.position, _arg_target.position)
    if _arg_target.is_hero():
        _next = BattleState.BEGIN_RAID
    else:
        _next = BattleState.BEGIN_COMBAT
    return true

func _step_action_spawn():
    assert(_arg_minion != null)
    assert(_arg_minion.owner == _pi)
    emit_signal("spawn_issued", _pi, _arg_minion.position, _arg_position, _arg_path)
    emit_signal("minion_spawning", _pi, _arg_minion.position, _arg_position)
    board.remove_from_bench(_pi, _arg_minion.position)
    board.place_minion_on_battlefield(_arg_minion, _arg_position)
    board.players[_pi].update_supplies()
    _signal_player_indicators(board.players[_pi])
    board.move_along_path(_arg_position, _arg_path)
    emit_signal("main_phase_ended", _pi)
    _next = BattleState.COMBAT_PHASE
    return true

func _step_begin_combat():
    assert(_arg_minion != null)
    assert(_arg_minion.owner == _pi)
    assert(_arg_target != null)
    assert(not _arg_target.is_hero())
    emit_signal("combat_started", _arg_minion.position, _arg_target.position)
    emit_signal("minion_attacking", _arg_minion.position, _arg_target.position)
    emit_signal("minion_defending", _arg_target.position, _arg_minion.position)
    _next = BattleState.COMBAT_RESOLVE
    return true

func _step_combat_resolve():
    assert(_arg_minion != null)
    assert(_arg_target != null)
    assert(not _arg_target.is_hero())
    var ap = _arg_minion.power
    var dp = _arg_target.power
    var ah = _arg_minion.health
    var dh = _arg_target.health
    emit_signal("minion_attacked", _arg_minion.position, _arg_target.position)
    _arg_target.health -= ap
    emit_signal("minion_damaged", _arg_target.position, ap)
    emit_signal("minion_defended", _arg_target.position, _arg_minion.position)
    _arg_minion.health -= dp
    emit_signal("minion_damaged", _arg_minion.position, dp)
    if _arg_target.health <= 0:
        _minion_death(_arg_target)
    else:
        emit_signal("minion_survived", _arg_target.position)
        _arg_target.health = dh
    if _arg_minion.health <= 0:
        _minion_death(_arg_minion)
    else:
        emit_signal("minion_survived", _arg_minion.position)
        _arg_minion.health = ah
    _next = BattleState.END_COMBAT
    return true

func _step_end_combat():
    assert(_arg_minion != null)
    assert(_arg_target != null)
    assert(not _arg_target.is_hero())
    emit_signal("combat_ended", _arg_minion.position, _arg_target.position)
    if _arg_phase == BattleState.MAIN_PHASE:
        emit_signal("main_phase_ended", _pi)
    else:
        assert(_arg_phase == BattleState.COMBAT_PHASE)
        emit_signal("combat_phase_ended", _pi)
    _next = BattleState.END_TURN
    return true

func _step_begin_raid():
    assert(_arg_minion != null)
    assert(_arg_minion.owner == _pi)
    assert(_arg_target != null)
    assert(_arg_target.is_hero())
    emit_signal("raid_started", _arg_minion.position, _arg_target.owner)
    emit_signal("minion_raiding", _arg_minion.position, _arg_target.owner)
    emit_signal("hero_defending", _arg_target.owner, _arg_minion.position)
    _next = BattleState.COMBAT_RESOLVE
    return true

func _step_raid_resolve():
    assert(_arg_minion != null)
    assert(_arg_target != null)
    assert(_arg_target.is_hero())
    var ap = _arg_minion.power
    var dp = _arg_target.power
    var ah = _arg_minion.health
    var dh = _arg_target.health
    emit_signal("minion_raided", _arg_minion.position, _arg_target.owner)
    _arg_target.health -= ap
    emit_signal("hero_damaged", _arg_target.owner, ap)
    emit_signal("hero_defended", _arg_target.owner, _arg_minion.position)
    _arg_minion.health -= dp
    emit_signal("minion_damaged", _arg_minion.position, dp)
    if _arg_target.health <= 0:
        _end_battle()
    if _arg_minion.health <= 0:
        _minion_death(_arg_minion)
    else:
        emit_signal("minion_survived", _arg_minion.position)
        _arg_minion.health = ah
    _next = BattleState.END_RAID
    return true

func _step_end_raid():
    assert(_arg_minion != null)
    assert(_arg_target != null)
    assert(_arg_target.is_hero())
    emit_signal("raid_ended", _arg_minion.position, _arg_target.owner)
    if _arg_phase == BattleState.MAIN_PHASE:
        emit_signal("main_phase_ended", _pi)
    else:
        assert(_arg_phase == BattleState.COMBAT_PHASE)
        emit_signal("combat_phase_ended", _pi)
    _next = BattleState.END_TURN
    return true


################################################################################
# Board Callbacks
################################################################################

func _on_minion_moving(minion: Reference, ti: int, tj: int):
    emit_signal("minion_moving", ti, tj)

func _on_minion_moved(minion: Reference, ti: int, tj: int):
    emit_signal("minion_moved", ti, tj)

func _on_enter_battlefield(minion, ti):
    emit_signal("minion_entered_battlefield", minion.owner, minion.index, ti)

func _on_enter_bench(minion, bi):
    emit_signal("minion_entered_bench", minion.owner, minion.index, bi)

func _on_enter_graveyard(minion, gi):
    emit_signal("minion_entered_graveyard", minion.owner, minion.index, gi)

func _on_exit_battlefield(minion):
    emit_signal("minion_exited_battlefield", minion.owner, minion.index, minion.position)

func _on_exit_bench(minion):
    emit_signal("minion_exited_bench", minion.owner, minion.index, minion.position)

func _on_exit_graveyard(minion):
    emit_signal("minion_exited_graveyard", minion.owner, minion.index, minion.position)


################################################################################
# Helper Functions
################################################################################

func _minion_death(minion: Reference):
    var pi = minion.owner
    emit_signal("minion_died", pi, minion.index, minion.position)
    board.remove_from_battlefield(minion.position)
    if board.is_graveyard_full(pi):
        emit_signal("minion_reviving", pi, 0, len(board.players[pi].bench))
        var other = board.dequeue_from_graveyard(pi)
        board.place_minion_on_bench(other)
    minion.reset_stats()
    board.place_minion_on_graveyard(minion)
    board.players[pi].update_supplies()
    _signal_player_indicators(board.players[_pi])


func _end_battle():
    emit_signal("battle_ended")
    board = null
    _next = BattleState.FINAL
    _arg_minion = null
    _arg_target = null
    _arg_path = []


func _who_goes_first():
    var n = len(board.players)
    _pi = randi() % n
    var pis = [_pi]
    var i = (_pi + 1) % n
    while i != _pi:
        pis.append(i)
        i = (i + 1) % n
    emit_signal("turn_order_chosen", pis)

func _update_player_supplies():
    for player in board.players:
        player.update_supplies()
        _signal_player_indicators(player)

func _signal_player_indicators(player):
    var pi = player.index
    var nh = player.health
    var nr = player.resources
    var nsa = player.supplies
    var nsu = player.used_supplies
    emit_signal("player_updated_indicators", pi, nh, nr, nsa, nsu)
