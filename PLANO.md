# Plano — The Blonde em 4 semanas

**Como a gente trabalha:** a cada aula eu escrevo o código e explico linha por linha
(`aulas/aula_XX.md`). Você abre, testa, faz os exercícios do fim da aula e me manda
o que mudou, o que deu erro ou o que quer diferente. Eu reviso e sigo para a próxima.

**Escopo:** a história inteira do roteiro, do prólogo aos 3 finais, com as 6 escolhas
e a Empatia. Para caber no prazo, algumas partes entram **simplificadas** (marcadas com ⤵).

**Fontes:** o **Roteiro** manda na história (inclusive na regra de que as escolhas só
mexem na Empatia e de que os finais dependem só dela). O **GDD** manda nos requisitos
técnicos, que são o que a disciplina de Computação Gráfica avalia.

---

## Semana 1 — a base (5 a 11/nov)

| Aula | O que fica pronto | Requisitos do GDD |
|---|---|---|
| **1 · Movimento** ✅ | Projeto novo, Bia andando/correndo/agachando com animação, colisões, câmera, sons | CG 5 (baixa resolução 320×180 de arte, escala inteira), CG 6 (spritesheet e animação por quadros), CG 1 (câmera com lerp) |
| **2 · Escuro, lanterna e Medo** | Lanterna (F) em cone com bateria, escuridão, sombras nas paredes, Medo visível com vinheta e batimento | CG 2 (produto escalar no cone), CG 3 (PointLight2D + LightOccluder2D, atenuação), CG 4 (shader de Medo: vinheta, grão, aberração), CG 1 (rotação do cone por matriz) |
| **3 · Diálogos e escolhas** | Caixa de visual novel com retratos, pensamentos da Bia, 6 escolhas com Empatia oculta | Comp 5 (grafo de decisão: falas são nós, arestas com condições de Empatia/Medo/flags), CG 7 (máscara de gradiente nos retratos) |

## Semana 2 — o mundo e a Loira (12 a 18/nov)

| Aula | O que fica pronto | Requisitos do GDD |
|---|---|---|
| **4 · Interagir e celular** | Tecla E, itens, celular (Tab) com abas — reaproveita o inventário + tabela hash de vocês | Comp 8 (tabela hash do inventário) |
| **5 · Portas, save e memórias** | Troca de área com fade, ponto seguro (salvar e baixar o Medo), memórias jogáveis como Marina em 1998 | CG 8 (filtro quente por matriz de cor, transição por interpolação) |
| **6 · A Loira** | **Grafo do campus** próprio, barulho que se espalha pelo grafo, patrulha → investigação → caça → recuo, fechar portas quebra a caça, esconderijos com chance de vistoria ⤵ perseguições curtas | Comp 1 (lista de adjacência), Comp 2 (BFS com fila de prioridade/heap), Comp 3 (A* com heurística euclidiana), Comp 9 (probabilidade da vistoria), CG 2 (cone de visão da Loira) |

> Na Aula 6 **não** vamos usar o NavigationAgent2D pronto do Godot: o GDD exige que o grafo,
> o BFS e o A* sejam implementados pelo grupo.

## Semana 3 — puzzles e pistas (19 a 25/nov)

| Aula | O que fica pronto | Requisitos do GDD |
|---|---|---|
| **7 · Puzzles** | Cifra de César (cadeado 0859), catálogo da biblioteca, carrinho de livros, painel de LEDs, rede de cabos, fila da cantina ⤵ cada um numa tela própria | Comp 9 (módulo 26, binário), Comp 8 (hash por módulo), Comp 6 (pilha), Comp 1/3 (caminho nos cabos), Comp 7 (fila) |
| **8 · Mural de pistas** | 20 fragmentos ligados por "aconteceu antes de", detecção de ciclo ("essa ligação não faz sentido"), título vira "Marina Duarte" | Comp 4 (DAG + ordenação topológica de Kahn) |
| Montagem | Prólogo, Capítulo 1 e Capítulo 2 jogáveis do início ao fim | — |

## Semana 4 — fechar o jogo (26/nov a 2/dez)

| Aula | O que fica pronto | Requisitos do GDD |
|---|---|---|
| **9 · Capítulos 3–5 e finais** | Laboratório, guarita, cantina, Bloco Antigo, confronto, 3 finais, relatório "Escolhas que importaram", tela do CVV, créditos | CG 9 (partículas: algodão, poeira, chuva) |
| **10 · Polimento e entrega** | Menu de vocês ligado ao jogo, opções e acessibilidade, diretor de tensão, testes do começo ao fim, exportar .exe, GitHub | Acessibilidade (seção 6), otimização (seção 7) |

---

## Diferenças entre o GDD e o que vamos fazer

| GDD | No projeto | Por quê |
|---|---|---|
| Escolhas com custo (bateria, aliado, dica) | Escolhas só mexem na Empatia | O próprio Roteiro decidiu isso (pág. 22) |
| Final bom pede mural + 2 amigos + Empatia ≥ 5 | Só Empatia ≥ 5 | Idem |
| Sprites 16×32 e tiles 16×16 | Sprite da Bia 16×24 e cenários pintados como imagem | Os cenários já existem; se a Ana Laura fizer tilesets, os mapas novos podem usar TileMapLayer |
| Mapa com ~50 nós | ⤵ grafo menor, com os nós das áreas que forem jogáveis | Prazo |

## Mapas

Temos 7 cenários. O roteiro passa por mais lugares:

| Já existe | Falta desenhar |
|---|---|
| parada de ônibus, entre os blocos, corredor, sala 1986/2026, banheiro 1986/2026 | porta da escada, passarela coberta, biblioteca, laboratório, guarita, cantina, pátio, hall e subsolo do Bloco Antigo ⤵ o interior do ônibus pode ser só uma tela de diálogo |

Eu desenho os que faltarem no mesmo estilo, conforme as aulas pedirem
(ou a Ana Laura, se o grupo preferir).

## O que você pode fazer em paralelo

- Testar cada aula e me contar o que achou estranho.
- Fazer os exercícios do fim de cada aula.
- Subir no GitHub a cada aula pronta (`git commit -m "Aula 1"`).
- Mostrar cada aula para o grupo: o guia serve para eles também.
