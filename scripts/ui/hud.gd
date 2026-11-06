extends CanvasLayer
## HUD: mostra a bateria da lanterna e aplica o efeito de Medo na tela.
## Fica numa CanvasLayer, então não é escurecido pela Escuridao (CanvasModulate).

@onready var efeito: ColorRect = $EfeitoMedo
@onready var tentaculos: Node2D = $Tentaculos
@onready var bateria: Label = $Bateria
@onready var coracao_lento: AudioStreamPlayer = $CoracaoLento
@onready var coracao_rapido: AudioStreamPlayer = $CoracaoRapido


func _ready() -> void:
	Medo.medo_mudou.connect(_ao_mudar_medo)
	var lanterna := get_tree().get_first_node_in_group("lanterna")
	if lanterna:
		lanterna.bateria_mudou.connect(_ao_mudar_bateria)
		_ao_mudar_bateria(lanterna.bateria)
	_ao_mudar_medo(Medo.valor)


func _ao_mudar_bateria(valor: float) -> void:
	bateria.text = "LANTERNA %d%%" % int(ceil(valor))
	bateria.modulate = Color(1, 0.35, 0.3) if valor < 20.0 else Color(1, 1, 1, 0.8)


func _ao_mudar_medo(valor: float) -> void:
	var m := valor / 100.0
	efeito.material.set_shader_parameter("medo", m)
	tentaculos.medo = m
	# Coração: aparece a partir de 30% de medo; acima de 70% troca para o rápido.
	var volume := clampf((m - 0.3) / 0.7, 0.0, 1.0)
	var rapido := m > 0.7
	_ajustar(coracao_lento, 0.0 if rapido else volume)
	_ajustar(coracao_rapido, volume if rapido else 0.0)


func _ajustar(som: AudioStreamPlayer, volume: float) -> void:
	som.volume_db = linear_to_db(maxf(volume, 0.0001))
	if volume > 0.0 and not som.playing:
		som.play()
	elif volume == 0.0 and som.playing:
		som.stop()
