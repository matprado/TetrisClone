extends TileMap

#Cena principal onde o jogo é executado
#O mapa do tetris é simulado por meio de um grid

#matriz grade com todas as posições disponíveis do jogo
var grid = []

#se uma célula do grid(uma posição na matriz) ter um:
#(null) -> está vazio
#(mino) -> está ocupado

#dimensões da grade
var grid_size = Vector2(10, 20)

#Variável de correção da borda
var BORDA = Vector2(-3, -1)

#Array com próximas 3 peças que será tratado como uma fila
var next_3 = []

const TETROMINOS_QUANTITY = 8

#Deixam pré-carregadas as cenas das peças
var TetroI = preload("res://scenes/Tetrominos/I.tscn") as PackedScene
var TetroJ = preload("res://scenes/Tetrominos/J.tscn") as PackedScene
var TetroL = preload("res://scenes/Tetrominos/L.tscn") as PackedScene
var TetroO = preload("res://scenes/Tetrominos/O.tscn") as PackedScene
var TetroS = preload("res://scenes/Tetrominos/S.tscn") as PackedScene
var TetroT = preload("res://scenes/Tetrominos/T.tscn") as PackedScene
var TetroZ = preload("res://scenes/Tetrominos/Z.tscn") as PackedScene
var TetroBomb = preload("res://scenes/Tetrominos/Bomb.tscn") as PackedScene

#boolean para identificar se a peça é a bomba ou não
var is_bomb

#variável para guardar uma peça
var tetromino

#variável para guardar a peça que está sendo controlada pelo player
var current_tetromino

#boolean para identificar o fim de jogo
var game_over

#inteiro para contar o início do game(3...2...1...)
var count

#pontuação
var score

#nível
var level

#fator de incremento do nível
var level_factor

#quantidade de linhas eliminadas
var line

#boolean que indica se o jogo está pausado ou não
var is_paused

#Método ready executado quando o Node Grid é carregado
func _ready():
	
	#inicializa as variáveis
	score = 0
	level = 1
	level_factor = 500
	line = 0
	
	get_parent().get_node("Pause").hide()
	is_paused = false
	
	get_parent().get_node("TryAgain").hide()
	get_parent().get_node("Quit").hide()
	get_parent().get_node("GameOver").hide()
	get_parent().get_node("FinalScore").hide()
	get_parent().get_node("FinalScoreNumber").hide()
	game_over = false
	
	#Cria e inicializa a matriz grade com 0 em todas as 
	# posições, o que indica que estão vazias
	#IMPORTANTE:
	#as linhas da matriz são as posições em y, ou seja, as linhas do grid
	for y in range(grid_size.y):
		grid.append([])
		#as colunas da matriz são as posições em x, ou seja, as colunas do grid
		for x in range(grid_size.x):
			grid[y].append(null)
	
	#cria uma fila para próximas 3 peças		
	create_queue()
	
	#mostra a contagem para o ínicio do jogo
	get_parent().get_node("GetReady").show()
	get_parent().get_node("321").show()
	$ReadySound.play()
	count = 2
	$ReadyTimer.start()
			
	pass		


#função que cria uma fila com as próximas 3 peças que entrarão no jogo
func create_queue():
	randomize()
	#chance de incluir a peça bomba entre as outras é 10%
	var bomb_chance = randi() % 10
	if(bomb_chance == 0):
		for i in range(3):
			#assim, a chance de uma peça bomba ser escolhido é (10% * 1/8) = 1/80(um pouco mais de 1% de chance)
			next_3.append(randi() % TETROMINOS_QUANTITY)
	else:
		for i in range(3):
			#considera apenas as 7 peças clássicas
			next_3.append(randi() % (TETROMINOS_QUANTITY-1))
	pass	


#função para retirar da fila
func dequeue():
	var ret = next_3.front() 
	# shift <<2
	for i in range(2):
		next_3[i] = next_3[i+1]
	#remove última posição
	next_3.remove(2)	
	return ret
	
	
#função para enfileirar uma nova peça
func enqueue():
	
	var bomb_chance = randi() % 10
	if(bomb_chance == 0):
		next_3.append(randi() % (TETROMINOS_QUANTITY))
	else:
		next_3.append(randi() % (TETROMINOS_QUANTITY-1))
	pass


#função que é executada quando o timer da contagem de preparação termina
func _on_ReadyTimer_timeout():
	if(count != 0):
		get_parent().get_node("321").text = str(count)
		$ReadyTimer.start()
		$ReadySound.play()
		count -= 1
	else:
		get_parent().get_node("321").hide()
		get_parent().get_node("GetReady").hide()
		$ReadyTimer.stop()
		#quando acaba a contagem, começa o jogo
		start_game()	
	


#função de início do jogo
func start_game():
	#instancia um novo tetromino
	new_tetromino()
	current_tetromino = tetromino
	#adiciona o tetromino atual como um elemento presente na cena e define seu nível
	add_child(current_tetromino)
	current_tetromino.set_current_level(level)
	
	#mostra fila com próximas 3 peças
	first_show_next()
	
	#ativa método process
	set_process(true)
	
	#toca(ou não) a música do jogo
	if(Global.get_music_state()):
		$GameMusic.play()
	

#função process que é executada a cada frame
func _process(delta):
	
	#pausar e despausar
	if count == 0 && Input.is_action_just_pressed("Pause"):
		if not is_paused:
			current_tetromino.get_node("DropTimer").set_paused(true)
			get_parent().get_node("Pause").show()
			get_parent().get_node("TryAgain").show()
			get_parent().get_node("Quit").show()
			$GameMusic.set_stream_paused(true)
			is_paused = true
		else:
			current_tetromino.get_node("DropTimer").set_paused(false)
			get_parent().get_node("Pause").hide()
			get_parent().get_node("TryAgain").hide()
			get_parent().get_node("Quit").hide()
			$GameMusic.set_stream_paused(false)
			is_paused = false
	
	
	#aumentar de nível quando atinge o fator de incremento		
	if not is_paused && score >= level_factor:
		level += 1
		update_level()
		level_factor += 500
	
	#se o jogo não estiver pausado, confere se uma linha está preenchida
	if not is_paused:
		for i in range(grid_size.y):
			if is_arrow_filled(grid[i]):
				$EliminateRow.play()
				#remove a linha
				remove_filled_arrow(grid[i])
				#abaixa todas as linhas acima da removida
				down_arrows_above(i)
				score += 100
				update_score()
				line += 1
				update_line()
	pass


#função que instancia um novo tetromino de acordo com o argumento passado
func instance_tetromino(current):
	match current:
		0:
			tetromino = TetroO.instance()
		1:
			tetromino = TetroI.instance()	
		2:
			tetromino = TetroT.instance()
		3:
			tetromino = TetroJ.instance()
		4:
			tetromino = TetroL.instance()
		5:
			tetromino = TetroS.instance()
		6:
			tetromino = TetroZ.instance()
		7:
			tetromino = TetroBomb.instance()	
	pass


#funçaõ que instancia um novo tetromino	usando a fila de próximos tetrominos	
func new_tetromino():
	#retira a peça atual da fila
	var current = dequeue()
	#enfileira mais uma peça
	enqueue()
	instance_tetromino(current)
	is_bomb = (current == 7)
	#conecta sinais que podem ser emitidos pelo tetromino
	tetromino.connect("faster", self, "on_tetromino_faster")
	tetromino.connect("collided", self, "_on_tetromino_collided")
	pass


#função para mostrar próximas peças pela primeira vez
func first_show_next():
	var base_position = Vector2(592, 144)
	var offset = 0
	for i in range(3):
		#instancia um tetromino
		instance_tetromino(next_3[i])
		#adiciona o tetromino como filho do nó Next3
		$Next3.add_child(tetromino)
		#este fica em um estado de espera
		tetromino.set_process(false)
		tetromino.get_node("ControlTimer").stop()
		tetromino.get_node("DropTimer").stop()
		tetromino.set_global_position(base_position + Vector2(0, offset))
		offset += 5 * 32


#função para mostrar peças
func show_next():
	var base_position = Vector2(592, 144)
	var offset = 0
	var past = $Next3.get_children()
	#remove os antigos
	for i in range(3):
		$Next3.remove_child(past[i])
	for i in range(3):
		instance_tetromino(next_3[i])
		$Next3.add_child(tetromino)
		tetromino.set_process(false)
		tetromino.get_node("ControlTimer").stop()
		tetromino.get_node("DropTimer").stop()
		tetromino.set_global_position(base_position + Vector2(0, offset))
		offset += 5 * 32


#função que confere se uma linha da matriz grid está completa
func is_arrow_filled(arrow):
	for j in range(grid_size.x):
		if arrow[j] == null:
			return false
	return true


#função que remove uma linha da matriz grid
func remove_filled_arrow(arrow):
	var tetro_dad
	for j in range(grid_size.x):
		if arrow[j] != null:
			tetro_dad = arrow[j].get_parent().get_parent()
			#diminui a quantidade de minos existentes de sua peça
			tetro_dad.update_living_minos()
			#libera o mino removido
			arrow[j].queue_free()
			arrow[j] = null


#função que abaixa todas linhas da matriz grid que estão acima de uma linha específica 
func down_arrows_above(pos):
	for i in range(pos, 0, -1):
		for j in range(grid_size.x):
			grid[i][j] = grid[i-1][j]
			if(grid[i-1][j] != null):
				var new_pos = Vector2(grid[i-1][j].get_global_position().x, grid[i-1][j].get_global_position().y + 32)
				grid[i-1][j].set_global_position(new_pos)
	for j in range(grid_size.x):
			grid[0][j] = null
					
	pass
	
	
#função que é chamada quando um tetromino emite um sinal de colisão	
func _on_tetromino_collided():
	$Collide.play()
	if not game_over && not is_paused:
		if(is_bomb):
			#ser for bomba, explode
			bomb_explode()
		score += 10
		update_score()
		#chama um novo tetromino
		new_tetromino()
		current_tetromino = tetromino
		add_child(current_tetromino)
		current_tetromino.set_current_level(level)
		show_next()
	pass	
	

#função de explosão da peça bomba
func bomb_explode():
	var tetro_dad
	var grid_pos = world_to_map(current_tetromino.get_node("Minos").get_node("Mino").get_global_position()) + BORDA
	#destroi um quadrado em volta da peça bomba
	for i in range((grid_pos.y-1), grid_pos.y+2, 1):
		for j in range(grid_pos.x-1, grid_pos.x+2, 1):
			if i>=0 && i<grid_size.y && j>=0 && j<grid_size.x && grid[i][j] != null:
				tetro_dad = grid[i][j].get_parent().get_parent()
				tetro_dad.update_living_minos()
				grid[i][j].queue_free()
				grid[i][j] = null		
	
	#abaixa as linhas acima da bomba	
	down_arrows_above_bomb(grid_pos)
	score += 40
	update_score()
	$EliminateRow.play()
	
#função para abaixar as linhas que estavam acima da explosão da bomba
func down_arrows_above_bomb(grid_pos):
	#todas as linhas e colunas acima do quadrado explodido "caem" 3 linhas na matriz grid
	for i in range(grid_pos.y+1, 2, -1):
		for j in range(grid_pos.x-1, grid_pos.x+2):
			if i>=3 && i<grid_size.y && j>=0 && j<grid_size.x && grid[i-3][j] != null:
				grid[i][j] = grid[i-3][j]
				var new_pos = Vector2(grid[i][j].get_global_position().x, grid[i][j].get_global_position().y + 96)
				grid[i][j].set_global_position(new_pos)
				grid[i-3][j] = null
				
	for j in range(grid_pos.x-1, grid_pos.x+2):
		if j>=0 && j<grid_size.x:
			grid[0][j] = null
			grid[1][j] = null
			grid[2][j] = null
								
	pass
	
	
#função que é chamada quando um tetromino emite um sinal de que está com uma queda acelerada	
func on_tetromino_faster():
	score += 0.01
	update_score()
	
	
	
#função para conferir se um mino estará dentro dos limites do grid
func is_inside_grid(mino, vel):
	#Transforma o vetor de posição global do mino em um valor referente ao mapa(grid)
	var grid_vel = world_to_map(vel)
	#Posição com correção da borda e velocidade
	var grid_pos = world_to_map(mino.get_global_position()) + BORDA + grid_vel

	if grid_pos.x >= 0 and grid_pos.x < grid_size.x and grid_pos.y < grid_size.y:
		return true
	
	return false
	

	
#função para conferir se a próxima posição de um mino em uma célula estará disponível.
func is_cell_vacant(mino, vel):	
	#Transforma os vetores velocidade global do mino
	# e velocidade em valores referentes ao mapa(grid)
	var grid_vel = world_to_map(vel)
	#Posição com correção da borda e velocidade
	var grid_pos = world_to_map(mino.get_global_position()) + grid_vel + BORDA
	
	#Se estiver no chão, é colisão!
	if grid_pos.y >= grid_size.y:
		return false; 
		
	#únicas exceções: quando estiver acima do grid ou nas paredes, não é colisão.
	if grid_pos.y < 0 or grid_pos.x < 0 or grid_pos.x >= grid_size.x:
		return true;
	
	#Se não for um dos casos acima, então confere se a posição n grid está vazia
	return (grid[grid_pos.y][grid_pos.x] == null)
	


#Define uma posição final para um mino na matriz grid
func set_final_position(mino):
	#Posição com correção da borda
	var grid_pos = world_to_map(mino.get_global_position()) + BORDA
	
	if(grid_pos.y < 0):
		#se chegar ao topo do grid, fim de jogo!
		on_game_over()
	else:
		#Define que agora a posição no grid está ocupada
		grid[grid_pos.y][grid_pos.x] = mino
	pass


#função que é chamada quando o jogo acaba
func on_game_over():
	set_process(false)
	game_over = true
	$GameMusic.stop()
	$Lost.play()
	#mostra tela de game over
	get_parent().get_node("GameOver").show()
	get_parent().get_node("FinalScore").show()
	update_final_score()
	get_parent().get_node("FinalScoreNumber").show()
	get_parent().get_node("TryAgain").show()
	get_parent().get_node("Quit").show()

	
#função de atualização do score	
func update_score():
	get_parent().get_node("ScoreNumber").text = str(int(score))

#função de atualização do nível	
func update_level():
	get_parent().get_node("LevelNumber").text = str(level)

#função de atualização das linhas eliminadas 
func update_line():
	get_parent().get_node("LineNumber").text = str(line)

#função de atualização do score final
func update_final_score():
	get_parent().get_node("FinalScoreNumber").text = str(int(score))


#função que é chamada quando o botão de try again é pressionado
func _on_TryAgain_pressed():
	#reinicia a cena
	Global.goto_scene("res://scenes/Game.tscn")
	
	
#função que é chamada quando o botão de quit é pressionado
func _on_Quit_pressed():
	#sai do jogo
	Global.goto_scene("res://scenes/TitleScreen.tscn")
	