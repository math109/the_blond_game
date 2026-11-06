extends CanvasLayer
## CELULAR DA BIA — autoload. Tab abre e fecha (e pausa o jogo).
## Abas: ITENS (inventário de vocês, usar o power bank), MSGS (grupo "Calouros Noite",
## Mamãe) e NOTAS. Com o celular aberto, F3 mostra a tabela hash do inventário.
##
## A tela é montada por código no _ready (dá para ver cada pedaço sendo criado).
## As mensagens e notas iniciais vêm de dados/celular.json.
##     Celular.receber_mensagem("Calouros Noite", "Théo", "alguém aí?")
##     Celular.anotar("Eu vi e não falei.")

const DADOS := "res://dados/celular.json"
const FONTE := preload("res://assets/fonts/fonte_dialogo.tres")
const ARTE := preload("res://assets/ui/celular.png")   # moldura gerada no SpriteCook
const FONTE_PEQUENA := preload("res://assets/fonts/Silkscreen-Regular.ttf")
const SOM_NOTIFICACAO := preload("res://assets/audio/sfx/35_celular_notificacao.wav")
const SOM_MOVER := preload("res://assets/audio/sfx/30_menu_mover.wav")
const SOM_CONFIRMAR := preload("res://assets/audio/sfx/31_menu_confirmar.wav")

const ABAS := ["ITENS", "MSGS", "NOTAS"]
const COR_FUNDO := Color(0.05, 0.06, 0.09)
const COR_BORDA := Color(0.17, 0.19, 0.29)
const COR_DESTAQUE := Color(0.85, 0.82, 1.0)

var aberto := false
var conversas: Array = []        # [{ "nome": "...", "mensagens": [[autor, texto], ...] }]
var notas: Array[String] = []

var _aba := 0
var _selecionado := ""            # id do item selecionado
var _raiz: Control
var _botoes_aba: Array[Button] = []
var _paginas: Array[Control] = []
var _grade: GridContainer
var _slots: Array[Button] = []
var _nome_item: Label
var _desc_item: RichTextLabel
var _texto_msgs: RichTextLabel
var _texto_notas: RichTextLabel
var _bateria: Label
var _painel_hash: PanelContainer
var _texto_hash: Label
var _som: AudioStreamPlayer


func _ready() -> void:
	layer = 7
	process_mode = Node.PROCESS_MODE_ALWAYS   # continua funcionando com o jogo pausado
	_carregar_dados()
	_montar_tela()
	_raiz.hide()
	Inventory.changed.connect(_atualizar_itens)


func _carregar_dados() -> void:
	var arquivo := FileAccess.open(DADOS, FileAccess.READ)
	if arquivo == null:
		return
	var dados: Dictionary = JSON.parse_string(arquivo.get_as_text())
	conversas = dados.get("conversas", [])
	for n in dados.get("notas", []):
		notas.append(str(n))


# ─────────────────────────────────────────────────────────────
# ABRIR, FECHAR, TECLAS
# ─────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("abrir_celular"):
		if aberto:
			fechar()
		elif not Dialogo.ativo and get_tree().get_first_node_in_group("lanterna") != null:
			abrir()
		get_viewport().set_input_as_handled()
	elif not aberto:
		return
	elif event.is_action_pressed("ui_cancel"):
		fechar()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("debug_hash"):
		_painel_hash.visible = not _painel_hash.visible
		_atualizar_hash()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interagir") and _aba == 0:
		_usar_selecionado()
		get_viewport().set_input_as_handled()


func abrir() -> void:
	aberto = true
	get_tree().paused = true          # a Loira, o Medo e a lanterna param
	_raiz.show()
	_mudar_aba(_aba)
	_tocar(SOM_CONFIRMAR)


func fechar() -> void:
	aberto = false
	get_tree().paused = false
	_painel_hash.hide()
	_raiz.hide()


func _mudar_aba(i: int) -> void:
	_aba = i
	for j in _paginas.size():
		_paginas[j].visible = j == i
		_botoes_aba[j].button_pressed = j == i
	match i:
		0:
			_atualizar_itens()
			_slots[0].grab_focus()
		1:
			_atualizar_msgs()
			_botoes_aba[1].grab_focus()
		2:
			_atualizar_notas()
			_botoes_aba[2].grab_focus()


# ─────────────────────────────────────────────────────────────
# ABA ITENS — usa o Inventory e o ItemDB de vocês
# ─────────────────────────────────────────────────────────────
func _atualizar_itens() -> void:
	var itens := Inventory.get_items()     # [{ "id": ..., "qty": ... }] na ordem de chegada
	for i in _slots.size():
		var slot := _slots[i]
		var icone: TextureRect = slot.get_node("Icone")
		var qtd: Label = slot.get_node("Qtd")
		if i < itens.size():
			var id: String = itens[i].id
			slot.set_meta("id", id)
			icone.texture = ItemDB.icon(id)
			qtd.text = "x%d" % itens[i].qty if itens[i].qty > 1 else ""
		else:
			slot.set_meta("id", "")
			icone.texture = null
			qtd.text = ""
	_mostrar_item(_selecionado if Inventory.has_item(_selecionado) else "")
	if _bateria:
		var lanterna := get_tree().get_first_node_in_group("lanterna")
		_bateria.text = "%d%%" % int(ceil(lanterna.bateria)) if lanterna else ""
	_atualizar_hash()


func _ao_focar_slot(slot: Button) -> void:
	_tocar(SOM_MOVER)
	_mostrar_item(slot.get_meta("id", ""))


func _mostrar_item(id: String) -> void:
	_selecionado = id
	if id == "":
		_nome_item.text = ""
		_desc_item.text = "[color=#6a7090]Nenhum item.[/color]" if Inventory.get_items().is_empty() else ""
		return
	var dados := ItemDB.get_data(id)
	_nome_item.text = dados.get("name", id)
	_desc_item.text = "[color=#8a90a8]%s[/color]\n%s" % [ItemDB.category_name(id), dados.get("description", "")]


func _usar_selecionado() -> void:
	if _selecionado == "":
		return
	var resposta := Inventory.use_item(_selecionado)
	_atualizar_itens()
	if resposta != "":
		# A resposta do use_item de vocês aparece no lugar da descrição.
		_desc_item.text = "[color=#d9d0ff]%s[/color]" % resposta
		_tocar(SOM_CONFIRMAR)


# ─────────────────────────────────────────────────────────────
# ABAS MSGS E NOTAS
# ─────────────────────────────────────────────────────────────
func receber_mensagem(conversa: String, autor: String, texto: String) -> void:
	var alvo: Dictionary = {}
	for c in conversas:
		if c.nome == conversa:
			alvo = c
	if alvo.is_empty():
		alvo = {"nome": conversa, "mensagens": []}
		conversas.append(alvo)
	alvo.mensagens.append([autor, texto])
	Avisos.mostrar("%s: %s" % [conversa, texto])
	_tocar(SOM_NOTIFICACAO)
	_atualizar_msgs()


func anotar(texto: String) -> void:
	notas.append(texto)
	Avisos.mostrar("Nova nota no celular.")
	_atualizar_notas()


func _atualizar_msgs() -> void:
	var t := ""
	for c in conversas:
		t += "[color=#d9d0ff]%s[/color]\n" % c.nome
		for m in c.mensagens:
			t += "[color=#8a90a8]%s:[/color] %s\n" % [m[0], m[1]]
		t += "\n"
	_texto_msgs.text = t


func _atualizar_notas() -> void:
	var t := ""
	for n in notas:
		t += "• %s\n\n" % n
	_texto_notas.text = t if t != "" else "[color=#6a7090]Sem notas.[/color]"


# ─────────────────────────────────────────────────────────────
# F3 — TABELA HASH (Comp 8), usa o debug_text() do Inventory de vocês
# ─────────────────────────────────────────────────────────────
func _atualizar_hash() -> void:
	if _painel_hash and _painel_hash.visible:
		_texto_hash.text = Inventory.debug_text()


# ─────────────────────────────────────────────────────────────
# MONTAGEM DA TELA (tamanho do jogo: 640 x 360)
# ─────────────────────────────────────────────────────────────
func _montar_tela() -> void:
	_som = AudioStreamPlayer.new()
	_som.bus = &"SFX"
	add_child(_som)

	_raiz = Control.new()
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.theme = _criar_tema()
	add_child(_raiz)

	var escurecer := ColorRect.new()                 # o jogo fica escuro atrás
	escurecer.color = Color(0, 0, 0, 0.6)
	escurecer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.add_child(escurecer)

	var corpo := TextureRect.new()                   # o aparelho (arte pixel 228 x 336)
	corpo.texture = ARTE
	corpo.position = Vector2(206, 12)
	corpo.size = Vector2(228, 336)
	corpo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_raiz.add_child(corpo)

	var hora := _label("23:47", FONTE_PEQUENA, 8, Vector2(16, 15))
	corpo.add_child(hora)
	_bateria = _label("", FONTE_PEQUENA, 8, Vector2(190, 15))
	corpo.add_child(_bateria)

	var abas := HBoxContainer.new()                  # ITENS | MSGS | NOTAS
	abas.position = Vector2(14, 28)
	abas.size = Vector2(200, 20)
	abas.add_theme_constant_override("separation", 4)
	corpo.add_child(abas)
	for i in ABAS.size():
		var b := Button.new()
		b.text = ABAS[i]
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(64, 20)
		b.add_theme_font_override("font", FONTE_PEQUENA)
		b.add_theme_font_size_override("font_size", 8)
		b.pressed.connect(_mudar_aba.bind(i))
		abas.add_child(b)
		_botoes_aba.append(b)

	# Página ITENS: grade 4 x 3 + detalhes do item
	var itens := Control.new()
	itens.position = Vector2(14, 54)
	itens.size = Vector2(200, 244)
	corpo.add_child(itens)
	_paginas.append(itens)
	_grade = GridContainer.new()
	_grade.columns = 4
	_grade.add_theme_constant_override("h_separation", 4)
	_grade.add_theme_constant_override("v_separation", 4)
	itens.add_child(_grade)
	for i in Inventory.MAX_SLOTS:
		_slots.append(_criar_slot())
	_nome_item = _label("", FONTE, 16, Vector2(2, 112))
	itens.add_child(_nome_item)
	_desc_item = RichTextLabel.new()
	_desc_item.bbcode_enabled = true
	_desc_item.position = Vector2(2, 132)
	_desc_item.size = Vector2(198, 112)
	_desc_item.add_theme_font_size_override("normal_font_size", 16)
	itens.add_child(_desc_item)

	# Páginas MSGS e NOTAS: um texto com rolagem
	_texto_msgs = _pagina_texto(corpo)
	_texto_notas = _pagina_texto(corpo)

	var dica := _label("TAB fechar  E usar  F3 hash", FONTE_PEQUENA, 8, Vector2(16, 302))
	dica.modulate = Color(1, 1, 1, 0.5)
	corpo.add_child(dica)

	# Painel da tabela hash (F3), em cima do celular
	_painel_hash = PanelContainer.new()
	_painel_hash.position = Vector2(6, 6)
	_painel_hash.add_theme_stylebox_override("panel", _caixa(Color(0.02, 0.03, 0.05, 0.96), COR_DESTAQUE, 1, 0))
	_texto_hash = _label("", FONTE_PEQUENA, 8, Vector2.ZERO)
	_painel_hash.add_child(_texto_hash)
	_painel_hash.hide()
	_raiz.add_child(_painel_hash)


func _criar_slot() -> Button:
	var slot := Button.new()
	slot.custom_minimum_size = Vector2(47, 34)
	slot.focus_entered.connect(_ao_focar_slot.bind(slot))
	slot.mouse_entered.connect(slot.grab_focus)
	slot.pressed.connect(_usar_selecionado)
	var icone := TextureRect.new()
	icone.name = "Icone"
	icone.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icone.position = Vector2(7, 1)
	icone.size = Vector2(32, 32)                  # ícone 16x16 desenhado em dobro
	icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(icone)
	var qtd := _label("", FONTE_PEQUENA, 8, Vector2(32, 24))
	qtd.name = "Qtd"
	slot.add_child(qtd)
	_grade.add_child(slot)
	return slot


func _pagina_texto(corpo: Control) -> RichTextLabel:
	var t := RichTextLabel.new()
	t.bbcode_enabled = true
	t.position = Vector2(16, 54)
	t.size = Vector2(198, 242)
	t.focus_mode = Control.FOCUS_ALL                # setas rolam o texto
	t.add_theme_font_size_override("normal_font_size", 16)
	corpo.add_child(t)
	_paginas.append(t)
	return t


func _label(texto: String, fonte: Font, tamanho: int, pos: Vector2) -> Label:
	var l := Label.new()
	l.text = texto
	l.position = pos
	l.add_theme_font_override("font", fonte)
	l.add_theme_font_size_override("font_size", tamanho)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _caixa(fundo: Color, borda: Color, largura: int, canto: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fundo
	s.border_color = borda
	s.set_border_width_all(largura)
	s.set_corner_radius_all(canto)
	s.content_margin_left = 6
	s.content_margin_right = 6
	s.content_margin_top = 4
	s.content_margin_bottom = 4
	return s


func _criar_tema() -> Theme:
	var t := Theme.new()
	t.default_font = FONTE
	t.default_font_size = 16
	var normal := _caixa(Color(0.09, 0.1, 0.15), COR_BORDA, 1, 3)
	var foco := _caixa(Color(0.16, 0.17, 0.28), COR_DESTAQUE, 1, 3)
	for estado in ["normal", "disabled"]:
		t.set_stylebox(estado, "Button", normal)
	for estado in ["focus", "hover", "pressed", "hover_pressed"]:
		t.set_stylebox(estado, "Button", foco)
	t.set_color("font_color", "Button", Color(0.6, 0.63, 0.75))
	t.set_color("font_pressed_color", "Button", Color.WHITE)
	t.set_color("font_focus_color", "Button", Color.WHITE)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	return t


func _tocar(som: AudioStream) -> void:
	_som.stream = som
	_som.play()
