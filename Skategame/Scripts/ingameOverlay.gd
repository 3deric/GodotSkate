extends Control

@onready var failView: Label = get_node("FailView")
@onready var balanceView: Control = get_node("BalanceView")

func _ready():
	_setFailView(false)
	_setBalanceValue(false)
	
func _setFailView(val):
	#enable or disable fail view
	failView.visible = val
	
func _setBalanceView(val):
	#enable or disable balance view
	balanceView.visible = val
	
func _setBalanceValue(val):
	#change angle of balance view
	balanceView.rotation = val
