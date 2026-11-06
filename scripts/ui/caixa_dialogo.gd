extends CanvasLayer
## CAIXA DE DIÁLOGO — autoload (cena). Qualquer script chama:
##     Dialogo.iniciar("res://dados/dialogos/cap1_corredor.json")
## e pode esperar o fim com:  await Dialogo.terminou
##
## Comp 5 — GRAFO DE DECISÃO. O diálogo é um grafo:
##   • cada FALA é um nó (tem um id, quem fala e o texto);
##   • "proximo" é uma aresta para o nó seguinte;
##   • uma ESCOLHA é um nó com várias arestas (as opções), e cada aresta pode ter
##     uma CONDIÇÃO ("se") para aparecer, e um EFEITO (Empatia, flag).
## Percorrer o diálogo = andar pelo grafo, um nó por vez, a partir de "inicio".

signal terminou
signal escolheu(id_escolha: String, indice: int)

const LETRAS_POR_SEGUNDO := 45.0

var ativo := false
var _grafo := {}            # { id_do_no: {dados do nó} }
var _personagens := {}      # { "BIA": {nome, retrato, cor} }
var _no_atual := {}
var _digitando := false
var _letras := 0.0
var _esperando_escolha := false

@onready var painel: Control = $Painel
@onready var retrato: TextureRect = $Painel/Retrato
@onready var nome: Label = $Painel/Nome
@onready var texto: RichTextLabel = $Painel/Texto
@onready var seta: Label = $Painel/Seta
@onready var opcoes: VBoxContainer = $Painel/Opcoes
@onready var som_letra: AudioStreamPlayer = $SomLetra
@onready var som_escolha: AudioStreamPlayer = $SomEscolha


func _ready() -> void:
	painel.hide()


## Abre um arquivo de diálogo e começa pelo nó "inicio" (ou outro).
func iniciar(caminho: String, no_inicial := "inicio") -> void:
	var arquivo := FileAccess.open(caminho, FileAccess.READ)
	if arquivo == null:
		push_error("Diálogo não encontrado: " + caminho)
		return
	var dados: Dictionary = JSON.parse_string(arquivo.get_as_text())
	iniciar_dados(dados, no_inicial, caminho)


## Mesma coisa, mas com o grafo já pronto na memória (sem arquivo).
func iniciar_dados(dados: Dictionary, no_inicial := "inicio", nome := "diálogo") -> void:
	_personagens = dados.get("personagens", {})
	_grafo = dados.get("nos", {})
	_validar(nome, no_inicial)
	ativo = true
	painel.show()
	_ir_para(no_inicial)


## Atalho: um pensamento curto da Bia, de um nó só (usado ao inspecionar objetos).
func pensar(texto_do_pensamento: String) -> void:
	iniciar_dados({
		"personagens": {"BIA": {"nome": "Bia", "retrato": "res://assets/retratos/bia.png", "cor": "#e8dcff"}},
		"nos": {"inicio": {"quem": "BIA", "tipo": "pensamento", "texto": texto_do_pensamento, "proximo": "fim"}},
	})


## Percorre o grafo a partir do início e avisa sobre arestas quebradas e nós
## que nunca são alcançados (busca em largura, a mesma ideia do BFS da Aula 6).
func _validar(caminho: String, inicio: String) -> void:
	var visitados := {inicio: true}
	var fila := [inicio]
	while not fila.is_empty():
		var id: String = fila.pop_front()
		var no: Dictionary = _grafo.get(id, {})
		var destinos := []
		if no.has("proximo"):
			destinos.append(no.proximo)
		for opcao in no.get("opcoes", []):
			destinos.append(opcao.get("proximo", "fim"))
		for destino in destinos:
			if destino == "fim":
				continue
			if not _grafo.has(destino):
				push_warning("%s: o nó '%s' aponta para '%s', que não existe." % [caminho, id, destino])
			elif not visitados.has(destino):
				visitados[destino] = true
				fila.append(destino)
	for id in _grafo:
		if not visitados.has(id):
			push_warning("%s: o nó '%s' nunca é alcançado." % [caminho, id])


func _ir_para(id: String) -> void:
	if id == "fim" or not _grafo.has(id):
		_fechar()
		return
	_no_atual = _grafo[id]
	if _no_atual.has("efeitos"):
		_aplicar(_no_atual.efeitos)
	_mostrar(_no_atual)


func _mostrar(no: Dictionary) -> void:
	var quem: String = no.get("quem", "")
	var p: Dictionary = _personagens.get(quem, {})
	var pensamento: bool = no.get("tipo", "") == "pensamento"

	# Nome e cor de quem fala. Pensamento não mostra nome e fica em itálico e mais claro.
	nome.text = "" if pensamento else p.get("nome", quem)
	nome.modulate = Color(p.get("cor", "#ffffff"))
	var t: String = no.get("texto", "")
	texto.text = ("[i][color=#aab0c8]%s[/color][/i]" % t) if pensamento else t

	# Retrato: aparece se o personagem tiver um. No pensamento, fica mais escuro.
	var caminho_retrato: String = p.get("retrato", "")
	retrato.visible = caminho_retrato != ""
	if retrato.visible:
		retrato.texture = load(caminho_retrato)
		retrato.material.set_shader_parameter("escurecer", 0.6 if pensamento else 0.0)

	# Efeito máquina de escrever: começa sem nenhuma letra visível.
	texto.visible_characters = 0
	_letras = 0.0
	_digitando = true
	seta.hide()
	_limpar_opcoes()


func _process(delta: float) -> void:
	if not _digitando:
		return
	var antes := int(_letras)
	_letras += LETRAS_POR_SEGUNDO * delta
	texto.visible_characters = int(_letras)
	if int(_letras) / 2 != antes / 2:   # um "tic" a cada 2 letras
		som_letra.pitch_scale = randf_range(0.9, 1.15)
		som_letra.play()
	if texto.visible_characters >= texto.get_total_character_count():
		_terminar_de_digitar()


func _terminar_de_digitar() -> void:
	_digitando = false
	texto.visible_characters = -1      # -1 = mostra tudo
	if _no_atual.get("tipo", "") == "escolha":
		_mostrar_opcoes()
	else:
		seta.show()


func _unhandled_input(event: InputEvent) -> void:
	if not ativo or _esperando_escolha:
		return
	if event.is_action_pressed("interagir") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		if _digitando:
			_terminar_de_digitar()           # 1º aperto: mostra o texto todo
		else:
			_ir_para(_no_atual.get("proximo", "fim"))


# ─────────────────────────────────────────────────────────────
# ESCOLHAS
# ─────────────────────────────────────────────────────────────
func _mostrar_opcoes() -> void:
	_esperando_escolha = true
	som_escolha.play()
	var primeiro: Button = null
	var indice := 0
	for opcao in _no_atual.get("opcoes", []):
		if _condicao_ok(opcao.get("se", {})):
			var botao := Button.new()
			botao.text = opcao.texto
			botao.alignment = HORIZONTAL_ALIGNMENT_LEFT
			botao.pressed.connect(_escolher.bind(opcao, indice))
			opcoes.add_child(botao)
			if primeiro == null:
				primeiro = botao
		indice += 1
	if primeiro:
		primeiro.grab_focus()   # setas ↑ ↓ andam entre as opções, E/Enter confirma


## Uma aresta só aparece se a condição for verdadeira.
## Ex.: "se": {"empatia_min": 2}  ou  {"medo_max": 60}  ou  {"flag": "achou_davi"}
func _condicao_ok(se: Dictionary) -> bool:
	if se.has("empatia_min") and Historia.empatia < se.empatia_min:
		return false
	if se.has("medo_max") and Medo.valor > se.medo_max:
		return false
	if se.has("flag") and not Historia.tem(se.flag):
		return false
	return true


func _escolher(opcao: Dictionary, indice: int) -> void:
	_esperando_escolha = false
	var id_escolha: String = _no_atual.get("id_escolha", "?")
	var empatia: int = int(opcao.get("empatia", 0))
	Historia.somar_empatia(empatia)                   # escondido do jogador
	Historia.registrar_escolha(id_escolha, opcao.texto, empatia)
	if opcao.has("efeitos"):
		_aplicar(opcao.efeitos)
	escolheu.emit(id_escolha, indice)
	_ir_para(opcao.get("proximo", "fim"))


func _aplicar(efeitos: Dictionary) -> void:
	if efeitos.has("flag"):
		Historia.marcar(efeitos.flag)
	if efeitos.has("medo"):
		Medo.subir(float(efeitos.medo))
	if efeitos.has("nota"): Celular.anotar(efeitos.nota)


func _limpar_opcoes() -> void:
	for filho in opcoes.get_children():
		filho.queue_free()


func _fechar() -> void:
	ativo = false
	_esperando_escolha = false
	_limpar_opcoes()
	painel.hide()
	terminou.emit()
