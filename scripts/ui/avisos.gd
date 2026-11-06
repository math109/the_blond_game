extends CanvasLayer
## AVISOS — autoload (cena). Mensagens curtas no topo da tela que somem sozinhas.
##     Avisos.mostrar("Pegou: Power bank")

const DURACAO := 2.5

@onready var lista: VBoxContainer = $Lista


func mostrar(texto: String) -> void:
	var aviso := Label.new()
	aviso.text = texto
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lista.add_child(aviso)
	# Tween: anima uma propriedade ao longo do tempo (aqui, a transparência).
	var tween := create_tween()
	tween.tween_interval(DURACAO)
	tween.tween_property(aviso, "modulate:a", 0.0, 0.6)
	tween.tween_callback(aviso.queue_free)
