extends Control

@onready var Fail_View: Control = get_node('FailView')
@onready var Balance_View: Control = get_node('BalanceView')
@onready var Balance_Indicator: Control = get_node('BalanceView/BalanceIndicator')

func _ready():
	set_fail_view(false)
	set_balance_value(false)
	
	
func set_fail_view(_val):
	#enable or disable fail view
	Fail_View.visible = _val
	
	
func set_balance_view(_val):
	#enable or disable balance view
	Balance_View.visible = _val
	
	
func set_balance_value(_val):
	#change angle of balance view
	_val = float(_val) / PI *400
	Balance_Indicator.position= Vector2(_val -2,-20)
