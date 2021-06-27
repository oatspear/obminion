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

func compute_actions():
    pass # read game state, compute possible actions
    print("[AI] compute_actions()")


func eval_next_action():
    print("[AI] eval_next_action()")
    # evaluate a computed action
    # when there are no more actions to evaluate,
    emit_signal("eval_done")
    # then choose one and act directly on game_logic
    game_logic.skip_turn(player_index)
