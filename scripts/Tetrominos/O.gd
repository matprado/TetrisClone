extends KinematicBody2D

#TETROMINO O
class_name TetrominoO

#Velocidade do tetromino:
var velocity = Vector2()

#Velocidade do tetromino com jogador controlando: 
var custom_velocity = Vector2()

#Referência para a classe pai Grid:
var Grid

#Referência para as classes filhas Minos
var Minos

#Quantidade de minos ainda existentes no grid
var living_Minos

#Rapidez do tetromino é uma célula por ciclo de timer
var SPEED

#Nível de dificuldade atual
var current_level

#Posição padrão inicial
const INITIAL_POS = Vector2(160, -32)

#Sinal que é emitido quando colide
signal collided

#Sinal que é emitido quando o player acelera a queda da peça
signal faster

#Método ready executado quando o Node O é carregado
func _ready():
	
	position = INITIAL_POS   #define pos inicial
	
	Minos = get_node("Minos").get_children()
	
	living_Minos = 4
	
	Grid = get_parent()
	
	SPEED = 32
	
	for i in Minos:
		# Define as cores dos minos
		i.set_color("yellow")
	
	#inicia o DropTimer	
	$DropTimer.start()	
		
	#Inicia o método process 	
	set_process(true)	
	
	pass


#Método process executado a cada taxa de frame
func _process(delta):
	
	#Velocidade padrão: bloco caindo	
	velocity = Vector2(0, SPEED)
	
	#Lê entrada e move ou gira a peça
	if Input.is_action_pressed("Left"):
		custom_velocity = Vector2(-SPEED, 0)
	
	if Input.is_action_pressed("Right"):
		custom_velocity = Vector2(SPEED, 0)
	
	if Input.is_action_pressed("Down"):
		emit_signal("faster")
		custom_velocity = Vector2(0, SPEED)
		
	#Não tem rotação para o tetromino O
			
	if Input.is_action_pressed("Left") or Input.is_action_pressed("Right") or Input.is_action_pressed("Down"):
		#Se o usuário está apertando algum botão de controle de movimento
		#da peça e o ControlTimer está parado, então inicia o mesmo.
		if $ControlTimer.is_stopped():
			$ControlTimer.start()
	else:
		#Se o usuário não está controlando movimento, então para o ControlTimer.
		$ControlTimer.stop()
		
	pass


#função para definir o nível atual de dificuldade
func set_current_level(value):
	current_level = value
	$DropTimer.wait_time = 1 - (current_level * 0.02)


#função para atualizar a quantidade de minos da peça existentes no grid
func update_living_minos():
	living_Minos -= 1
	if living_Minos == 0:
		queue_free()	



#Método que é acionado quando se recebe o sinal de timeout do DropTimer.
func _on_DropTimer_timeout():
	
	#Se conseguir mover...
	if can_move(velocity):
		if not will_collide(velocity):
			#Move o tetromino
			position += velocity
		else:
			on_Mino_collided()	
	else:
		#Se não pode se mover, confere se vai colidir
		if will_collide(velocity):
			#Se colidir, chama o método...
			on_Mino_collided()
	pass


#Método que é acionado quando se recebe o sinal de timeout do ControlTimer.
func _on_ControlTimer_timeout():
	
	#Se conseguir mover...
	if can_move(custom_velocity):
		if not will_collide(custom_velocity):
			#Move o tetromino
			position += custom_velocity
		else:
			#Só vai parar a peça se a colisão for no sentido para baixo
			if custom_velocity.y > 0:
				on_Mino_collided()	
	else:
		#Se não pode se mover, confere se vai colidir
		if will_collide(custom_velocity):
			#Só vai parar a peça se a colisão for no sentido para baixo
			if custom_velocity.y > 0:
				on_Mino_collided()
	pass


#Método chamado quando há colisão
func on_Mino_collided():
	#Para os timers
	$DropTimer.stop()
	$ControlTimer.stop()
	#Para a execução do método process
	set_process(false)
	#Define as posições finais dos minos no Grid.
	for mino in Minos:
		Grid.set_final_position(mino)
		
	emit_signal("collided")	
	pass


#Método que confere se o tetromino poderá se mover
func can_move(vel):
	for mino in Minos:
		#Se algum mino não estiver dentro das limitações do grid
		if not Grid.is_inside_grid(mino, vel):
			#Não pode
			return false
	#Se todos estão nos limites do Grid, então pode
	return true


#Método que confere se o tetromino vai colidir	
func will_collide(vel):
	for mino in Minos:
		#Se algum mino não estiver em uma célula vazia do grid
		if not Grid.is_cell_vacant(mino, vel):
			#Vai colidir
			return true
	#Se todos estão em posições vagas, então não colidirá				
	return false
	