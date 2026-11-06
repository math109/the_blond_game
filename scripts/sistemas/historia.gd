extends Node
## HISTÓRIA — autoload. Guarda o que vale a noite inteira:
## a Empatia (escondida do jogador), as flags (fatos que aconteceram) e o registro
## das escolhas, usado no relatório "Escolhas que importaram" do final.

signal empatia_mudou(valor: int)

var empatia := 0                     # vai de −6 a +10 no roteiro
var flags := {}                      # ex.: {"filmou_trote": true}
var escolhas: Array[Dictionary] = [] # [{ "escolha": "trote", "opcao": "...", "empatia": 1 }]


func somar_empatia(quanto: int) -> void:
	if quanto == 0:
		return
	empatia += quanto
	empatia_mudou.emit(empatia)


func marcar(flag: String, valor: Variant = true) -> void:
	flags[flag] = valor


func tem(flag: String) -> bool:
	return flags.get(flag, false) == true


func registrar_escolha(id_escolha: String, texto_opcao: String, empatia_da_opcao: int) -> void:
	escolhas.append({"escolha": id_escolha, "opcao": texto_opcao, "empatia": empatia_da_opcao})


## Final pela Empatia (pág. 22 do roteiro): ruim < 0, neutro 0 a 4, bom >= 5.
func final() -> String:
	if empatia >= 5:
		return "bom"
	if empatia >= 0:
		return "neutro"
	return "ruim"
