extends Node
## MEDO — autoload (existe o jogo inteiro, em qualquer cena).
## Vai de 0 (calma) a 100 (pânico). Aula 2: sobe no escuro e desce com a lanterna.
## Depois: a Loira por perto faz subir (Aula 6), ponto seguro faz baixar (Aula 5).

signal medo_mudou(valor: float)      # 0 a 100

@export var sobe_no_escuro := 3.0        # por segundo, lanterna desligada
@export var desce_na_luz := 2.0          # por segundo, lanterna ligada

var valor := 0.0


func _process(delta: float) -> void:
	var lanterna := get_tree().get_first_node_in_group("lanterna")
	if lanterna == null or Dialogo.ativo:
		return  # sem a Bia na tela, ou conversando: o medo fica parado
	if lanterna.ligada:
		descer(desce_na_luz * delta)
	else:
		subir(sobe_no_escuro * delta)


func subir(quanto: float) -> void:
	_mudar(valor + quanto)


func descer(quanto: float) -> void:
	_mudar(valor - quanto)


func _mudar(novo: float) -> void:
	novo = clampf(novo, 0.0, 100.0)
	if novo != valor:
		valor = novo
		medo_mudou.emit(valor)
