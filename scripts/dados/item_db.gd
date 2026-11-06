@tool
class_name ItemDB
extends RefCounted
## Catálogo de itens. Para criar um item novo, adicione uma entrada em ITEMS.
## Ícone opcional: res://assets/items/<id>.png (pixel art). Sem o PNG,
## o slot mostra a sigla de "short" na cor de "color".

enum Category { CONSUMIVEL, CHAVE, PISTA }

const CATEGORY_NAMES := {
	Category.CONSUMIVEL: "Consumível",
	Category.CHAVE: "Item de história",
	Category.PISTA: "Pista",
}

const ITEMS := {
	"power_bank": {
		"name": "Power bank",
		"short": "PB",
		"category": Category.CONSUMIVEL,
		"max_stack": 3,
		"usable": true,
		"color": "#F2B84B",
		"description": "Recarrega 50% da bateria do celular. A lanterna depende dela.",
	},
	"bilhete_helena": {
		"name": "Bilhete de Helena",
		"short": "BH",
		"category": Category.CHAVE,
		"max_stack": 1,
		"usable": false,
		"color": "#E8DCC0",
		"description": "Papel dobrado, letra caprichada:\n“Marina, posso sentar contigo amanhã?”\nNunca foi entregue.",
	},
	"chave_antiga": {
		"name": "Chave antiga",
		"short": "CH",
		"category": Category.CHAVE,
		"max_stack": 1,
		"usable": false,
		"color": "#C79A4E",
		"description": "Chave de latão gasta, com uma etiqueta: “Bloco Antigo · banheiro”. Alguém a guardou por muito tempo.",
	},
	"caderno_davi": {
		"name": "Caderno do Davi",
		"short": "CD",
		"category": Category.CHAVE,
		"max_stack": 1,
		"usable": false,
		"color": "#D9CBA3",
		"description": "Anotações de aula e, na última página, uma conta circulada: “soma, resto de 26”.",
	},
	"algodao": {
		"name": "Algodão",
		"short": "AL",
		"category": Category.PISTA,
		"max_stack": 1,
		"usable": false,
		"color": "#F4F1EA",
		"description": "Um chumaço de algodão com cheiro de álcool, no chão do corredor, onde não deveria haver nada.",
	},
	"foto_1998": {
		"name": "Foto da turma de 1998",
		"short": "FT",
		"category": Category.PISTA,
		"max_stack": 1,
		"usable": false,
		"color": "#C9A27E",
		"description": "Foto desbotada de calouros na escadaria. Uma menina loira no canto, quase fora do enquadramento.",
	},
	"ficha_biblioteca": {
		"name": "Ficha de empréstimo",
		"short": "FB",
		"category": Category.PISTA,
		"max_stack": 1,
		"usable": false,
		"color": "#A7B8A0",
		"description": "“Empréstimo: M. Duarte. Devolução: —.”\nCom outra letra, por cima: “vai se esconder onde?”",
	},
	"recorte_jornal": {
		"name": "Recorte de jornal",
		"short": "RJ",
		"category": Category.PISTA,
		"max_stack": 1,
		"usable": false,
		"color": "#9FA4A8",
		"description": "Nota pequena, de março de 1998: “Caloura sofre mal súbito no campus”. Nenhum nome citado.",
	},
}


static func exists(id: String) -> bool:
	return ITEMS.has(id)


static func get_data(id: String) -> Dictionary:
	return ITEMS.get(id, {})


static func category_name(id: String) -> String:
	return CATEGORY_NAMES.get(get_data(id).get("category", -1), "")


static func color_of(id: String) -> Color:
	return Color(get_data(id).get("color", "#FFFFFF"))


## Guarda as texturas carregadas: quem desenha com draw_texture() não segura a
## referência, e sem o cache a textura seria liberada antes de ir para a tela.
static var _icones := {}


static func icon(id: String) -> Texture2D:
	if not _icones.has(id):
		var path := "res://assets/items/%s.png" % id
		_icones[id] = load(path) if ResourceLoader.exists(path) else null
	return _icones[id]
