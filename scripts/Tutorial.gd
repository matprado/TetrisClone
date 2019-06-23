extends Node

#se apertar o botão de return, volta para o Titlescreen
func _on_Button_pressed():
	Global.goto_scene("res://scenes/TitleScreen.tscn")
