extends Reference

const MINION = "res://scripts/battle/Minion.gd"
const COMMANDER = "res://scripts/battle/Commander.gd"

const HEALTH_MAX = 3
const RESOURCE_INIT = 0
const RESOURCE_MAX = 2
const SUPPLY_INIT = 4
const SUPPLY_MAX = 6

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

# Indicators
var health: int = HEALTH_MAX
var resources: int = RESOURCE_INIT
var supplies: int = SUPPLY_INIT
var used_supplies: int = 0

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

func get_free_supplies():
    return 0 if used_supplies >= supplies else supplies - used_supplies

func has_free_supplies(cost: int = 0):
    var s = supplies - used_supplies
    if cost <= 0:
        return s > 0
    return s >= cost

func has_supply_shortage():
    return used_supplies > supplies

func update_supplies():
    used_supplies = 0
    for minion in minions:
        if minion.is_active():
            used_supplies += minion.supply_cost
