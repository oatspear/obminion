extends Reference

################################################################################
# Signals
################################################################################

signal eval_done()

################################################################################
# Variables
################################################################################

var player_index: int = -1
var game_logic: Reference = null

################################################################################
# Interface
################################################################################

# @pre: `player_index` is set.
# @pre: `game_logic` is set.
func initialize():
    pass


# Called when logic asks for player input.
# It should read the game state and compute possible actions.
func compute_actions():
    print("[AI] compute_actions()")


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
