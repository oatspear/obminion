extends Node

################################################################################
# Constants
################################################################################

enum FSM { INITIAL, READY, WAIT, EVAL }

################################################################################
# Variables
################################################################################

var state: int = FSM.INITIAL
var ai: Reference = null setget set_ai

func set_ai(the_ai: Reference):
    if ai != null:
        ai.disconnect("eval_done", self, "_on_eval_done")
    ai = the_ai
    var err = ai.connect("eval_done", self, "_on_eval_done")
    assert(err == OK)
    if state == FSM.INITIAL:
        state = FSM.READY

################################################################################
# Interface
################################################################################

func get_player_input():
    if state != FSM.WAIT:
        push_error("Expected WAIT state.")
    state = FSM.EVAL
    set_process(true)
    ai.compute_actions()


################################################################################
# Event Callbacks
################################################################################

func on_battle_started():
    if state != FSM.READY:
        push_error("Expected READY state.")
    if ai == null:
        push_error("AI is not set.")
    state = FSM.WAIT


################################################################################
# AI Callbacks
################################################################################

func _on_eval_done():
    set_process(false)
    state = FSM.WAIT


################################################################################
# Node Callbacks
################################################################################

func _ready():
    set_process(false)
    if ai == null:
        state = FSM.INITIAL
    else:
        state = FSM.READY

func _process(_delta):
    assert(state == FSM.EVAL, "Expected EVAL state.")
    ai.eval_next_action()
