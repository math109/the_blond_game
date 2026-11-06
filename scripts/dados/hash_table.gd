class_name HashTable
extends RefCounted
## Tabela hash própria (encadeamento separado), usada pelo inventário.
## Requisito de computação do GDD (tabela, item 8): os itens não ficam no
## Dictionary do Godot, e sim nesta estrutura.
##
## Função de hash polinomial com módulo:
##   h(k) = (c0·31^(n-1) + c1·31^(n-2) + ... + c(n-1)) mod capacidade
## Quando o fator de carga passa de 0,75, a tabela dobra de tamanho (rehash).

const MAX_LOAD := 0.75

var _buckets: Array = []
var _size := 0


func _init(initial_capacity: int = 8) -> void:
	_alloc(maxi(initial_capacity, 1))


func capacity() -> int:
	return _buckets.size()


func size() -> int:
	return _size


func load_factor() -> float:
	return float(_size) / float(capacity())


## Índice do balde onde a chave cai.
func index_of(key: String) -> int:
	var h := 0
	for i in key.length():
		h = (h * 31 + key.unicode_at(i)) % capacity()
	return h


func put(key: String, value: Variant) -> void:
	var bucket: Array = _buckets[index_of(key)]
	for pair in bucket:
		if pair[0] == key:
			pair[1] = value
			return
	bucket.append([key, value])
	_size += 1
	if load_factor() > MAX_LOAD:
		_rehash(capacity() * 2)


func lookup(key: String, default: Variant = null) -> Variant:
	for pair in _buckets[index_of(key)]:
		if pair[0] == key:
			return pair[1]
	return default


func contains(key: String) -> bool:
	for pair in _buckets[index_of(key)]:
		if pair[0] == key:
			return true
	return false


func remove(key: String) -> bool:
	var bucket: Array = _buckets[index_of(key)]
	for i in bucket.size():
		if bucket[i][0] == key:
			bucket.remove_at(i)
			_size -= 1
			return true
	return false


func keys() -> Array[String]:
	var out: Array[String] = []
	for bucket in _buckets:
		for pair in bucket:
			out.append(pair[0])
	return out


func clear() -> void:
	_alloc(capacity())


## Só as chaves de cada balde, para a tela de debug (F3 no celular).
func buckets_snapshot() -> Array:
	var out: Array = []
	for bucket in _buckets:
		var ks: Array[String] = []
		for pair in bucket:
			ks.append(pair[0])
		out.append(ks)
	return out


func _alloc(new_capacity: int) -> void:
	_buckets = []
	_buckets.resize(new_capacity)
	for i in new_capacity:
		_buckets[i] = []
	_size = 0


func _rehash(new_capacity: int) -> void:
	var old := _buckets
	_alloc(new_capacity)
	for bucket in old:
		for pair in bucket:
			put(pair[0], pair[1])
