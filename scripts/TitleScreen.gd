extends Node

#Tela/Menu inicial 

func _ready():
	#Prepara o funcionamento do botão de música
	if Global.get_music_state():
		$Music/MusicButton.text = "MUSIC: ON"
		$MenuTheme.play()
	else:
		$Music/MusicButton.text = "MUSIC: OFF"	
		$MenuTheme.stop()
	pass


#função que é executada quando o botão de start é pressionado
func _on_StartButton_pressed():
	#vai para a cena Game
	Global.goto_scene("res://scenes/Game.tscn")


#função que é executada quando o botão de música é pressionado
func _on_MusicButton_pressed():
	
	#muda o estado atual
	if(Global.get_music_state()):
		$Music/MusicButton.text = "MUSIC: OFF"
		$MenuTheme.stop()
		Global.set_music_state(false)
	else:
		$Music/MusicButton.text = "MUSIC: ON"
		$MenuTheme.play()
		Global.set_music_state(true)
				

#função que é executada quando o botão de saída é pressionado			
func _on_ExitButton_pressed():
	Global.quit_game()


#função que é executada quando o botão de tutorial é pressionado			
func _on_TutorialButton_pressed():
	Global.goto_scene("res://scenes/Tutorial.tscn")