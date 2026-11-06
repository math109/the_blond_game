class_name Interagivel
extends Area2D
## Qualquer coisa do mapa com que a Bia pode interagir apertando E.
## Coloque este script num Area2D (com um CollisionShape2D dentro) e escolha no
## Inspector o que acontece:
##   • INSPECIONAR → a Bia pensa um texto curto
##   • DIALOGO     → abre um arquivo de diálogo (.json)
##   • PEGAR_ITEM  → o item vai para o inventário e o objeto some do mapa
##
## A tecla E só funciona se a Bia estiver dentro da área E olhando para o objeto.
## "Olhando para" usa o produto escalar (CG 2), igual ao cone da lanterna.

enum Acao { INSPECIONAR, DIALOGO, PEGAR_ITEM }

@export var acao: Acao = Acao.INSPECIONAR
@export_multiline var texto := ""                 # para INSPECIONAR
@export_file("*.json") var dialogo := ""          # para DIALOGO
@export var item_id := ""                         # para PEGAR_ITEM (id do ItemDB)
@export var so_uma_vez := false                   # depois de usar, não reage mais
@export var altura_do_aviso := 18.0               # onde o "E" aparece, acima do objeto

var _bia: CharacterBody2D = null
var _aviso: Label
var _usado := false

const SOM_PEGAR := preload("res://assets/audio/sfx/25_item_pegar.wav")


func _ready() -> void:
	body_entered.connect(func(corpo): if corpo.name == "Bia": _bia = corpo)
	body_exited.connect(func(corpo): if corpo == _bia: _bia = null)
	_criar_aviso()
	if acao == Acao.PEGAR_ITEM:
		_mostrar_icone()


## O "E" que flutua acima do objeto.
func _criar_aviso() -> void:
	_aviso = Label.new()
	_aviso.text = "E"
	_aviso.add_theme_font_override("font", load("res://assets/fonts/Silkscreen-Regular.ttf"))
	_aviso.add_theme_font_size_override("font_size", 12)
	_aviso.add_theme_color_override("font_outline_color", Color.BLACK)
	_aviso.add_theme_constant_override("outline_size", 7)
	_aviso.position = Vector2(-3, -altura_do_aviso)
	_aviso.hide()
	add_child(_aviso)


## No chão, o item aparece com o ícone de 16x16 que o grupo desenhou.
func _mostrar_icone() -> void:
	var icone := ItemDB.icon(item_id)
	if icone:
		var sprite := Sprite2D.new()
		sprite.texture = icone
		add_child(sprite)


func _process(_delta: float) -> void:
	var pode := _pode_interagir()
	_aviso.visible = pode
	if pode:   # o "E" sobe e desce devagar
		_aviso.position.y = -altura_do_aviso + sin(Time.get_ticks_msec() / 200.0) * 1.5


func _pode_interagir() -> bool:
	if _bia == null or _usado or Dialogo.ativo:
		return false
	# CG 2 — produto escalar: a direção em que a Bia olha · direção até o objeto.
	# 1 = de frente, 0 = de lado, −1 = de costas. Aceitamos até uns 70° para o lado.
	var ate_objeto := global_position - _bia.global_position
	if ate_objeto.length() < 14.0:
		return true   # em cima do objeto: não importa para onde ela olha
	return _bia.direcao.dot(ate_objeto.normalized()) > 0.35


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interagir") and _pode_interagir():
		get_viewport().set_input_as_handled()   # o E não passa para o diálogo
		interagir()


func interagir() -> void:
	match acao:
		Acao.INSPECIONAR:
			Dialogo.pensar(texto)
		Acao.DIALOGO:
			Dialogo.iniciar(dialogo)
		Acao.PEGAR_ITEM:
			if Inventory.add_item(item_id):
				Avisos.mostrar("Pegou: " + ItemDB.get_data(item_id).get("name", item_id))
				_tocar(SOM_PEGAR)
				queue_free()   # some do mapa
			return
	if so_uma_vez:
		_usado = true


func _tocar(som: AudioStream) -> void:
	# O som precisa sobreviver ao queue_free do objeto, então vai para a fase.
	var p := AudioStreamPlayer.new()
	p.stream = som
	p.bus = &"SFX"
	get_tree().current_scene.add_child(p)
	p.play()
	p.finished.connect(p.queue_free)
