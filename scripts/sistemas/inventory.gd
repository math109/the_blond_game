extends Node
## Autoload "Inventory": inventário de Bia (código do grupo, reaproveitado na Aula 4).
## Mudança: os avisos agora vão para o autoload Avisos, e o power bank recarrega a lanterna.
## id → quantidade fica numa HashTable própria (busca em O(1) em média);
## _ordem guarda a ordem de chegada, que é a ordem dos slots na tela.

signal changed
signal item_added(id: String, amount: int)
signal item_removed(id: String, amount: int)

const MAX_SLOTS := 12

var _tabela := HashTable.new(8)
var _ordem: Array[String] = []


func add_item(id: String, amount: int = 1) -> bool:
	if not ItemDB.exists(id) or amount <= 0:
		push_warning("Item desconhecido: %s" % id)
		return false
	var atual: int = _tabela.lookup(id, 0)
	var max_stack: int = ItemDB.get_data(id).get("max_stack", 1)
	if atual == 0 and _ordem.size() >= MAX_SLOTS:
		Avisos.mostrar("Inventário cheio.")
		return false
	if atual >= max_stack:
		Avisos.mostrar("Bia já carrega o máximo de %s." % ItemDB.get_data(id)["name"])
		return false
	var novo := mini(atual + amount, max_stack)
	_tabela.put(id, novo)
	if atual == 0:
		_ordem.append(id)
	item_added.emit(id, novo - atual)
	changed.emit()
	return true


func remove_item(id: String, amount: int = 1) -> bool:
	var atual: int = _tabela.lookup(id, 0)
	if atual < amount or amount <= 0:
		return false
	var restante := atual - amount
	if restante == 0:
		_tabela.remove(id)
		_ordem.erase(id)
	else:
		_tabela.put(id, restante)
	item_removed.emit(id, amount)
	changed.emit()
	return true


func count(id: String) -> int:
	return _tabela.lookup(id, 0)


func has_item(id: String) -> bool:
	return _tabela.contains(id)


func is_usable(id: String) -> bool:
	return has_item(id) and ItemDB.get_data(id).get("usable", false)


## Itens na ordem dos slots: [{ "id": String, "qty": int }, ...]
func get_items() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id in _ordem:
		out.append({"id": id, "qty": count(id)})
	return out


## Usa o item e retorna a mensagem que aparece no celular.
func use_item(id: String) -> String:
	if not has_item(id):
		return ""
	match id:
		"power_bank":
			var lanterna := get_tree().get_first_node_in_group("lanterna")
			if lanterna == null:
				return "Agora não."
			if lanterna.bateria >= 100.0:
				return "A bateria já está cheia."
			lanterna.recarregar(50.0)
			remove_item(id)
			return "Bateria recarregada (+50%)."
	return "Bia não sabe como usar isso agora."


func clear() -> void:
	_tabela.clear()
	_ordem.clear()
	changed.emit()


func to_dict() -> Dictionary:
	var quantidades := {}
	for id in _ordem:
		quantidades[id] = count(id)
	return {"ordem": _ordem.duplicate(), "quantidades": quantidades}


func from_dict(data: Dictionary) -> void:
	_tabela.clear()
	_ordem.clear()
	var quantidades: Dictionary = data.get("quantidades", {})
	for raw_id in data.get("ordem", []):
		var id := str(raw_id)
		var qtd := int(quantidades.get(id, 1))
		if ItemDB.exists(id) and qtd > 0 and not _tabela.contains(id):
			_tabela.put(id, qtd)
			_ordem.append(id)
	changed.emit()


## Texto da tela de debug (F3): em que balde cada item caiu, 4 baldes por linha.
func debug_text() -> String:
	var linhas := PackedStringArray()
	linhas.append("Tabela hash · capacidade %d · itens %d · carga %.2f · h(k) = Σ cᵢ·31ⁿ⁻¹⁻ⁱ mod %d" % [
		_tabela.capacity(), _tabela.size(), _tabela.load_factor(), _tabela.capacity()])
	var baldes := _tabela.buckets_snapshot()
	var linha := ""
	for i in baldes.size():
		var conteudo: Array = baldes[i]
		var celula := "[%2d] %s" % [i, "—" if conteudo.is_empty() else " → ".join(conteudo)]
		linha += celula.rpad(26)
		if i % 4 == 3 or i == baldes.size() - 1:
			linhas.append(linha.strip_edges(false, true))
			linha = ""
	return "\n".join(linhas)
