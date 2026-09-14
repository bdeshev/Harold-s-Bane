extends Node2D


func _ready() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval(
			"document.addEventListener('contextmenu', function(e) { e.preventDefault(); });",
			true
		)