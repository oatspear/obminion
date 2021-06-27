extends Reference

const MINION = "res://scripts/battle/Minion.gd"
const COMMANDER = "res://scripts/battle/Commander.gd"

################################################################################
# Internal State
################################################################################

var index: int = 0
#var player_id: int = 0
var commander: Reference = null
var minions: Array = []
var tokens: Array = []
var bench: Array = []
var graveyard: Array = []
var spawn_points: Array = []
var base_point: int = 0

################################################################################
# Interface
################################################################################

func init(player_data: Resource):
    #player_id = pid
    minions = []
    tokens = []
    var cs = load(COMMANDER)
    commander = cs.new()
    commander.owner = index
    commander.init(player_data.commander)
    var ms = load(MINION)
    for minion_data in player_data.minions:
        var minion = ms.new()
        add_minion(minion)
        minion.init(minion_data)

# @pre: player_id is set
func add_minion(minion: Reference):
    minion.index = len(minions)
    minion.owner = index # player_id
    minions.append(minion)
    for token in tokens:
        token.index += 1

func add_token(minion: Reference):
    assert(minion.is_token)
    minion.index = len(minions) + len(tokens)
    minion.owner = index # player_id
    tokens.append(minion)

func has_minion(i: int):
    # minions[minion_id]._minion_id == minion_id
    if i < 0:
        return false
    if i < len(minions):
        return true
    return i < len(minions) + len(tokens)

func get_minion(i: int):
    assert(i >= 0)
    if i < len(minions):
        return minions[i]
    return tokens[i - len(minions)]
