// CG 7 — MÁSCARA DE GRADIENTE no retrato.
// Em vez de um recorte quadrado, o retrato some aos poucos na base e na lateral,
// como se saísse de dentro da caixa de diálogo. A máscara é só uma conta com UV:
// UV vai de (0,0) no canto de cima à esquerda até (1,1) no canto de baixo à direita.
shader_type canvas_item;

uniform float escurecer : hint_range(0.0, 1.0) = 0.0;   // 1 = personagem que não está falando

void fragment() {
	vec4 cor = texture(TEXTURE, UV);
	float base = smoothstep(1.0, 0.72, UV.y);      // some na parte de baixo
	float lado = smoothstep(1.0, 0.85, UV.x);      // e um pouco na borda direita
	cor.a *= base * lado;
	cor.rgb *= 1.0 - 0.55 * escurecer;
	COLOR = cor;
}
