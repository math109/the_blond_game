extends Node2D
## Script de uma fase (um mapa do jogo).
## Aula 1: prende a câmera dentro do cenário e deixa os sons de ambiente em loop.
## Aula 2: os móveis fazem sombra na luz da lanterna.
## Aula 3: pode abrir um diálogo assim que a fase começa.

## Diálogo que começa sozinho quando a fase abre (deixe vazio para nenhum).
@export_file("*.json") var dialogo_ao_entrar := ""

@onready var fundo: Sprite2D = $Fundo
@onready var bia: CharacterBody2D = $Bia


func _ready() -> void:
	_limitar_camera()
	_repetir_sons_de_ambiente()
	_criar_sombras()
	if dialogo_ao_entrar != "":
		Dialogo.iniciar(dialogo_ao_entrar)


## A câmera segue a Bia, mas não pode mostrar nada fora da imagem de fundo.
func _limitar_camera() -> void:
	var camera: Camera2D = bia.get_node("Camera2D")
	var tamanho := fundo.texture.get_size()  # 960 x 640 nos nossos cenários
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(tamanho.x)
	camera.limit_bottom = int(tamanho.y)


## Todo nó no grupo "som_em_loop" volta a tocar quando termina.
func _repetir_sons_de_ambiente() -> void:
	for som in get_tree().get_nodes_in_group("som_em_loop"):
		som.finished.connect(som.play)


## CG 3 — SOMBRAS: cada colisão retangular dentro do nó "Moveis" ganha um
## LightOccluder2D. O occluder é um polígono que a luz não atravessa: o Godot
## projeta, a partir da luz, a "sombra" atrás dele.
## Usamos só uma faixa fina na borda de trás do móvel (ESPESSURA pixels):
## se o polígono cobrisse o móvel inteiro, o próprio móvel ficaria no escuro.
const ESPESSURA := 3.0


func _criar_sombras() -> void:
	var moveis := get_node_or_null("Moveis")
	if moveis == null:
		return  # fase sem móveis: nada a fazer
	for forma in moveis.get_children():
		if not (forma is CollisionShape2D and forma.shape is RectangleShape2D):
			continue
		var metade: Vector2 = forma.shape.size / 2.0
		# Os 4 cantos da faixa fina, na borda de cima (de trás) da colisão.
		var poligono := OccluderPolygon2D.new()
		poligono.polygon = PackedVector2Array([
			Vector2(-metade.x, -metade.y),
			Vector2(metade.x, -metade.y),
			Vector2(metade.x, -metade.y + ESPESSURA),
			Vector2(-metade.x, -metade.y + ESPESSURA),
		])
		var oclusor := LightOccluder2D.new()
		oclusor.name = "Sombra" + forma.name
		oclusor.occluder = poligono
		oclusor.position = forma.position
		moveis.add_child(oclusor)
