extends Node2D

################################################################################
# Constants
################################################################################

const PLAYER_ID: int = 1
const AI_ID: int = 0

const STR_ILLEGAL = "Illegal player action: %s(%d, %d)"

################################################################################
# Variables
################################################################################

var logic: Reference = null
onready var scene: Node2D = $BattleScene
onready var ai_player: Node = $AIPlayer

################################################################################
# Initialization
################################################################################

# should be called after `_ready()`.
func start_battle(battle_data: Resource):
    logic = battle_data.logic_script.new()
    logic.set_board(battle_data.board_data)
    if battle_data.player_data == null:
        pass # TODO use default/saved player deck
    else:
        logic.set_player_deck(PLAYER_ID, battle_data.player_data)
    logic.set_player_deck(AI_ID, battle_data.ai_player_data)
    if battle_data.setup_script != null:
        var initializer = battle_data.setup_script.new()
        initializer.init_battle(logic, PLAYER_ID, AI_ID)
    ai_player.ai = battle_data.ai_script.new()
    ai_player.ai.player_index = AI_ID
    ai_player.ai.game_logic = logic
    ai_player.ai.initialize()
    scene.set_player_index(PLAYER_ID)
    _logic_events()
    logic.start()
    ai_player.on_battle_started()
    set_process(true)


################################################################################
# Player View Callbacks
################################################################################

func _on_player_action_move(mi: int, ti: int):
    var ok = logic.move_active_minion(PLAYER_ID, mi, ti)
    if not ok:
        push_error(STR_ILLEGAL % ["move", mi, ti])

func _on_player_action_attack(mi: int, ti: int):
    var ok = logic.attack_minion(PLAYER_ID, mi, ti)
    if not ok:
        push_error(STR_ILLEGAL % ["attack", mi, ti])

func _on_player_action_spawn(mi: int, ti: int, tj: int):
    var ok = logic.spawn_benched_minion(PLAYER_ID, mi, ti, tj)
    if not ok:
        push_error(STR_ILLEGAL % ["spawn", mi, tj])

func _on_player_action_end_turn():
    var ok = logic.skip_turn(PLAYER_ID)
    if not ok:
        push_error("Illegal player action: skip turn")


################################################################################
# Battle Logic Callbacks
################################################################################

func _on_input_requested(pi: int):
    match pi:
        PLAYER_ID:
            scene.get_player_input()
        AI_ID:
            ai_player.get_player_input()
        _:
            assert(false, "Not supposed to happen.")

func _on_battle_set_up(board: Reference):
    assert(board != null)
    # this is before the battle start event, animations can be skipped
    scene.set_battle_board(board)


################################################################################
# Node Callbacks
################################################################################

func _ready():
    set_process(false)

func _process(_delta):
    logic.step()


################################################################################
# Helper Functions
################################################################################

func _logic_events():
    var err = logic.connect("input_requested", self, "_on_input_requested")
    assert(err == OK)
    err = logic.connect("battle_set_up", self, "_on_battle_set_up")
    assert(err == OK)
    err = logic.connect("battle_started", scene, "on_battle_started")
    assert(err == OK)
    err = logic.connect("battle_ended", scene, "on_battle_ended")
    assert(err == OK)
    err = logic.connect("turn_order_chosen", scene, "on_turn_order_chosen")
    assert(err == OK)
    err = logic.connect("turn_started", scene, "on_turn_started")
    assert(err == OK)
    err = logic.connect("turn_ended", scene, "on_turn_ended")
    assert(err == OK)
    err = logic.connect("turn_skipped", scene, "on_turn_skipped")
    assert(err == OK)
    err = logic.connect("main_phase_started", scene, "on_main_phase_started")
    assert(err == OK)
    err = logic.connect("main_phase_ended", scene, "on_main_phase_ended")
    assert(err == OK)
    err = logic.connect("combat_phase_started", scene, "on_combat_phase_started")
    assert(err == OK)
    err = logic.connect("combat_phase_ended", scene, "on_combat_phase_ended")
    assert(err == OK)
    err = logic.connect("movement_issued", scene, "on_movement_issued")
    assert(err == OK)
    err = logic.connect("minion_moving", scene, "on_minion_moving")
    assert(err == OK)
    err = logic.connect("minion_moved", scene, "on_minion_moved")
    assert(err == OK)
    err = logic.connect("spawn_issued", scene, "on_spawn_issued")
    assert(err == OK)
    err = logic.connect("attack_issued", scene, "on_attack_issued")
    assert(err == OK)
    err = logic.connect("combat_started", scene, "on_combat_started")
    assert(err == OK)
    err = logic.connect("combat_ended", scene, "on_combat_ended")
    assert(err == OK)
    err = logic.connect("minion_attacking", scene, "on_minion_attacking")
    assert(err == OK)
    err = logic.connect("minion_attacked", scene, "on_minion_attacked")
    assert(err == OK)
    err = logic.connect("minion_defending", scene, "on_minion_defending")
    assert(err == OK)
    err = logic.connect("minion_defended", scene, "on_minion_defended")
    assert(err == OK)
    err = logic.connect("minion_damaged", scene, "on_minion_damaged")
    assert(err == OK)
    err = logic.connect("minion_died", scene, "on_minion_died")
    assert(err == OK)
    err = logic.connect("minion_survived", scene, "on_minion_survived")
    assert(err == OK)
    err = logic.connect("raid_started", scene, "on_raid_started")
    assert(err == OK)
    err = logic.connect("raid_ended", scene, "on_raid_ended")
    assert(err == OK)
    err = logic.connect("minion_raiding", scene, "on_minion_raiding")
    assert(err == OK)
    err = logic.connect("minion_raided", scene, "on_minion_raided")
    assert(err == OK)
    err = logic.connect("hero_defending", scene, "on_hero_defending")
    assert(err == OK)
    err = logic.connect("hero_defended", scene, "on_hero_defended")
    assert(err == OK)
    err = logic.connect("hero_damaged", scene, "on_hero_damaged")
    assert(err == OK)
    err = logic.connect("minion_entered_battlefield", scene, "on_minion_entered_battlefield")
    assert(err == OK)
    err = logic.connect("minion_entered_bench", scene, "on_minion_entered_bench")
    assert(err == OK)
    err = logic.connect("minion_entered_graveyard", scene, "on_minion_entered_graveyard")
    assert(err == OK)
    err = logic.connect("minion_exited_battlefield", scene, "on_minion_exited_battlefield")
    assert(err == OK)
    err = logic.connect("minion_exited_bench", scene, "on_minion_exited_bench")
    assert(err == OK)
    err = logic.connect("minion_exited_graveyard", scene, "on_minion_exited_graveyard")
    assert(err == OK)
    err = logic.connect("player_updated_indicators", scene, "on_player_updated_indicators")
    assert(err == OK)
