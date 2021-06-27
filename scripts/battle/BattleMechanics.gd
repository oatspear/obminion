extends Reference

class_name BattleMechanics

################################################################################
# Interface
################################################################################

func do_battle(minion1, minion2):
    var win = false
    var loss = false
    if minion1.power >= minion2.health:
        win = true
    if minion2.power >= minion1.health:
        loss = true
    if win and loss:
        return Global.Battle.TIE
    if win:
        return Global.Battle.WIN
    return Global.Battle.LOSS
