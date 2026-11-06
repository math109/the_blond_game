extends CharacterBody2D
## Bia: a personagem que o jogador controla.
## Aula 1: andar, correr, agachar, animação pela spritesheet e som de passos.

# ─────────────────────────────────────────────────────────────
# 1. CONFIGURAÇÕES
# "@export" faz a variável aparecer no Inspector, para ajustar sem mexer no código.
# Velocidade em pixels por segundo.
# ─────────────────────────────────────────────────────────────
@export var velocidade_andar := 70.0
@export var velocidade_correr := 120.0
@export var velocidade_agachada := 35.0

# Quantos quadros de animação por segundo em cada jeito de andar.
@export var ritmo_andar := 10.0
@export var ritmo_correr := 16.0
@export var ritmo_agachada := 6.0

# Quanto a velocidade muda por segundo (aceleração e freio suaves).
@export var aceleracao := 900.0

# Ciclo de caminhada em 4 passos: passo A, parada, passo B, parada.
const CICLO := [1, 0, 2, 0]

# A spritesheet tem 3 colunas (parada, passo A, passo B) e 4 linhas (uma por direção).
const COLUNAS := 3
const LINHA_BAIXO := 0
const LINHA_ESQUERDA := 1
const LINHA_DIREITA := 2
const LINHA_CIMA := 3

# ─────────────────────────────────────────────────────────────
# 2. REFERÊNCIAS AOS NÓS FILHOS
# "@onready" espera a cena ficar pronta antes de procurar o nó.
# "$Sprite" é um atalho para get_node("Sprite").
# ─────────────────────────────────────────────────────────────
@onready var sprite: Sprite2D = $Sprite
@onready var som_passos: AudioStreamPlayer2D = $Passos

# ─────────────────────────────────────────────────────────────
# 3. ESTADO
# ─────────────────────────────────────────────────────────────
var linha_atual := LINHA_BAIXO  # para que lado a Bia está olhando
var direcao := Vector2.DOWN     # para onde ela olha, como vetor (a lanterna usa)
var tempo_animacao := 0.0       # conta o tempo para trocar de quadro


# _physics_process roda 60 vezes por segundo, sempre no mesmo ritmo.
# "delta" é o tempo desde a última chamada (≈ 0,016 s).
func _physics_process(delta: float) -> void:
	# Lê as setas/WASD e devolve um vetor: (-1, 0) esquerda, (1, 0) direita,
	# (0, -1) cima, (0, 1) baixo. Na diagonal ele já vem normalizado.
	var entrada := Input.get_vector("mover_esquerda", "mover_direita", "mover_cima", "mover_baixo")
	if Dialogo.ativo:
		entrada = Vector2.ZERO  # durante um diálogo a Bia fica parada

	if entrada != Vector2.ZERO:
		direcao = entrada.normalized()  # guarda a última direção

	var agachada := Input.is_action_pressed("agachar")
	var correndo := Input.is_action_pressed("correr") and not agachada

	var alvo := entrada * _velocidade(agachada, correndo)
	# Em vez de pular direto para a velocidade final, chega nela aos poucos.
	velocity = velocity.move_toward(alvo, aceleracao * delta)
	move_and_slide()  # move e para quando bate numa colisão

	_animar(entrada, agachada, correndo, delta)
	_tocar_passos(entrada, agachada, correndo)


## Escolhe a velocidade. Agachar tem prioridade sobre correr.
func _velocidade(agachada: bool, correndo: bool) -> float:
	if agachada:
		return velocidade_agachada
	if correndo:
		return velocidade_correr
	return velocidade_andar


## Escolhe o quadro certo da spritesheet.
func _animar(entrada: Vector2, agachada: bool, correndo: bool, delta: float) -> void:
	if entrada == Vector2.ZERO:
		# Parada: usa a coluna 0 da direção atual.
		tempo_animacao = 0.0
		sprite.frame = linha_atual * COLUNAS
		return

	# Descobre a direção pelo eixo mais forte (na diagonal, vence o maior).
	if absf(entrada.x) > absf(entrada.y):
		linha_atual = LINHA_DIREITA if entrada.x > 0 else LINHA_ESQUERDA
	else:
		linha_atual = LINHA_BAIXO if entrada.y > 0 else LINHA_CIMA

	var ritmo := ritmo_andar
	if agachada:
		ritmo = ritmo_agachada
	elif correndo:
		ritmo = ritmo_correr
	tempo_animacao += delta * ritmo

	# Percorre o CICLO: passo A, parada, passo B, parada.
	var coluna: int = CICLO[int(tempo_animacao) % CICLO.size()]
	# O índice do quadro conta da esquerda para a direita e de cima para baixo.
	sprite.frame = linha_atual * COLUNAS + coluna


## Som de passos: toca enquanto anda, mais rápido correndo, mudo agachada.
func _tocar_passos(entrada: Vector2, agachada: bool, correndo: bool) -> void:
	var andando := entrada != Vector2.ZERO
	if andando and not agachada:
		som_passos.pitch_scale = 1.35 if correndo else 1.0
		if not som_passos.playing:
			som_passos.play()  # quando o arquivo termina, recomeça aqui no próximo quadro
	elif som_passos.playing:
		som_passos.stop()
