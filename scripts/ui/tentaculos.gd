extends Node2D
## Tentáculos de sombra que entram pelas bordas da tela quando o Medo sobe.
## Cada tentáculo é uma Line2D: uma linha com vários pontos e largura que afina na ponta.
## A cada quadro a gente recalcula os pontos com uma onda (seno), então eles se mexem.
##
## CG 1 — transformações: cada ponto = base + direção * distância + perpendicular * onda.

@export var quantidade := 12
@export var pontos_por_tentaculo := 28
@export var comeca_em := 0.35        # medo (0 a 1) em que os tentáculos começam a aparecer
@export var largura_base := 22.0
@export var velocidade_recuo := 12.0  # quão rápido somem (antes era 3)     # grossura no pé do tentáculo, em pixels
@export var cor_borda := Color(0.32, 0.26, 0.38, 0.9)  # contorno: destaca no escuro

var medo := 0.0                      # o HUD atualiza este valor (0 a 1)
var _tentaculos: Array[Dictionary] = []
var _tempo := 0.0
var _crescimento := 0.0              # 0 = escondidos, 1 = tamanho máximo


func _ready() -> void:
	var tela := get_viewport_rect().size     # 640 x 360
	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = 98                        # sempre o mesmo desenho (1998...)
	for i in quantidade:
		var t := _criar(sorteio, tela, i)
		_tentaculos.append(t)


## Sorteia um ponto na borda da tela e aponta o tentáculo para o meio, meio torto.
func _criar(sorteio: RandomNumberGenerator, tela: Vector2, i: int) -> Dictionary:
	var lado := i % 4                         # 0 cima, 1 direita, 2 baixo, 3 esquerda
	var base := Vector2.ZERO
	match lado:
		0: base = Vector2(sorteio.randf() * tela.x, -6)
		1: base = Vector2(tela.x + 6, sorteio.randf() * tela.y)
		2: base = Vector2(sorteio.randf() * tela.x, tela.y + 6)
		3: base = Vector2(-6, sorteio.randf() * tela.y)
	var para_o_centro := (tela / 2.0 - base).normalized()
	var direcao := para_o_centro.rotated(sorteio.randf_range(-0.7, 0.7))

	var linha := Line2D.new()
	linha.default_color = Color(0.02, 0.02, 0.03, 0.95)
	linha.joint_mode = Line2D.LINE_JOINT_ROUND
	linha.end_cap_mode = Line2D.LINE_CAP_ROUND
	linha.antialiased = false                 # pixel art: borda dura
	var afinar := Curve.new()                 # largura: 100% no pé, 5% na ponta
	afinar.add_point(Vector2(0.0, 1.0))
	afinar.add_point(Vector2(0.7, 0.45))
	afinar.add_point(Vector2(1.0, 0.05))
	linha.width_curve = afinar
	linha.width = largura_base * sorteio.randf_range(0.6, 1.2)
	# Contorno: uma cópia um pouco mais grossa e mais clara, desenhada atrás.
	# Sem ele, preto em cima do escuro quase não aparece.
	var borda := linha.duplicate() as Line2D
	borda.default_color = cor_borda
	borda.width = linha.width + 4.0
	add_child(borda)
	add_child(linha)

	return {
		"linha": linha,
		"borda": borda,
		"base": base,
		"direcao": direcao,
		"comprimento": sorteio.randf_range(120.0, 260.0),
		"ondas": sorteio.randf_range(1.2, 2.4),     # quantas curvas ao longo do corpo
		"amplitude": sorteio.randf_range(10.0, 26.0),
		"velocidade": sorteio.randf_range(1.2, 2.6),
		"fase": sorteio.randf() * TAU,
		"atraso": sorteio.randf() * 0.25,           # uns aparecem antes dos outros
	}


func _process(delta: float) -> void:
	_tempo += delta
	# Quanto o medo passou do ponto de início, de 0 a 1.
	var alvo := clampf((medo - comeca_em) / (1.0 - comeca_em), 0.0, 1.0)
	# Fogem da luz: com a lanterna ligada, eles recuam na hora, mesmo com o Medo alto.
	var lanterna := get_tree().get_first_node_in_group("lanterna")
	if lanterna and lanterna.ligada:
		alvo = 0.0
	# Crescem devagar e recuam rápido.
	var ritmo := 1.5 if alvo > _crescimento else velocidade_recuo
	_crescimento = lerpf(_crescimento, alvo, 1.0 - exp(-ritmo * delta))
	visible = _crescimento > 0.01
	if visible:
		for t in _tentaculos:
			_desenhar(t)


func _desenhar(t: Dictionary) -> void:
	var g := clampf((_crescimento - t.atraso) / (1.0 - t.atraso), 0.0, 1.0)
	var comprimento: float = t.comprimento * g
	var dir: Vector2 = t.direcao
	var perpendicular := dir.orthogonal()      # vetor de lado, 90° da direção
	var pontos := PackedVector2Array()
	for i in pontos_por_tentaculo:
		var s := float(i) / (pontos_por_tentaculo - 1)   # 0 no pé, 1 na ponta
		# A onda anda do pé para a ponta (o "- tempo"), e é mais forte na ponta (* s).
		var onda := sin(s * t.ondas * TAU - _tempo * t.velocidade + t.fase)
		var p: Vector2 = t.base + dir * comprimento * s + perpendicular * onda * t.amplitude * s
		pontos.append(p.round())                 # arredonda: cai certinho no pixel
	t.linha.points = pontos
	t.borda.points = pontos
