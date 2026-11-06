extends PointLight2D
## Lanterna da Bia: liga e desliga com F, gira para onde ela olha e gasta bateria.
## Aula 2 — CG 1 (rotação suave com lerp), CG 2 (produto escalar no cone),
## CG 3 (luz pontual com textura e sombras).

signal bateria_mudou(valor: float)   # o HUD vai escutar isso
signal bateria_acabou

# ─────────────────────────────────────────────────────────────
# 1. CONFIGURAÇÕES
# ─────────────────────────────────────────────────────────────
@export var energia_maxima := 1.2       # brilho da luz com bateria cheia
@export var gasto_por_segundo := 1.0    # 100% dura 100 segundos ligada
@export var velocidade_giro := 12.0     # quão rápido o cone acompanha a Bia
@export var meio_angulo := 26.0         # metade da abertura do cone, em graus
@export var alcance := 250.0            # até onde a luz chega, em pixels

# ─────────────────────────────────────────────────────────────
# 2. ESTADO
# ─────────────────────────────────────────────────────────────
var ligada := true
var bateria := 100.0                    # de 0 a 100

@onready var bia: CharacterBody2D = get_parent()
@onready var som_ligar: AudioStreamPlayer2D = $SomLigar
@onready var som_desligar: AudioStreamPlayer2D = $SomDesligar


func _ready() -> void:
	add_to_group("lanterna")  # o Medo e o HUD procuram a lanterna por este grupo
	rotation = bia.direcao.angle()
	_atualizar_brilho()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("lanterna"):
		alternar()


func _process(delta: float) -> void:
	# CG 1 — rotação suave: em vez de pular para o ângulo novo, anda uma fração
	# do caminho a cada quadro. lerp_angle escolhe o lado mais curto do giro.
	var alvo: float = bia.direcao.angle()
	rotation = lerp_angle(rotation, alvo, 1.0 - exp(-velocidade_giro * delta))

	if ligada:
		bateria = maxf(bateria - gasto_por_segundo * delta, 0.0)
		bateria_mudou.emit(bateria)
		if bateria == 0.0:
			bateria_acabou.emit()
			alternar()
	_atualizar_brilho()


## Liga ou desliga (sem bateria, não liga).
func alternar() -> void:
	if not ligada and bateria <= 0.0:
		return
	ligada = not ligada
	(som_ligar if ligada else som_desligar).play()
	_atualizar_brilho()


## Recarrega com uma pilha/power bank (usado na Aula 4).
func recarregar(quanto: float) -> void:
	bateria = minf(bateria + quanto, 100.0)
	bateria_mudou.emit(bateria)


## Com menos de 20% a luz fica fraca e começa a falhar.
func _atualizar_brilho() -> void:
	if not ligada:
		energy = 0.0
		return
	energy = energia_maxima
	if bateria < 20.0:
		energy *= 0.4 + bateria / 20.0 * 0.6
		if randf() < 0.04:          # falha de vez em quando
			energy *= 0.2


## CG 2 — PRODUTO ESCALAR: diz se um ponto do mapa está dentro do cone.
## A Loira e os objetos escondidos vão perguntar isso (Aulas 4 e 6).
##
## Ideia: a = direção para onde a lanterna aponta (vetor de tamanho 1)
##        b = direção da lanterna até o ponto   (vetor de tamanho 1)
##        a · b = cos(ângulo entre eles)
## Se cos(ângulo) >= cos(meio_angulo), o ponto está dentro da abertura do cone.
func ilumina(ponto: Vector2) -> bool:
	if not ligada:
		return false
	var ate_ponto := ponto - global_position
	if ate_ponto.length() > alcance:
		return false
	var a := Vector2.RIGHT.rotated(global_rotation)   # para onde aponta
	var b := ate_ponto.normalized()
	return a.dot(b) >= cos(deg_to_rad(meio_angulo))
