extends Reference

func init_battle(logic, player_index: int, ai_index: int):
    var board = logic.board
    var ai = board.players[ai_index]
    assert(len(ai.bench) > 0)
    var minion = ai.bench.pop_back()
    minion.location = Global.BoardLocation.BATTLEFIELD
    minion.position = 16
    board.tiles[16].minion = minion
