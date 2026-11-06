// CG 4 — SHADER DE MEDO (roda uma vez para cada pixel da tela, na placa de vídeo).
// Ele lê a imagem do jogo já desenhada (hint_screen_texture) e aplica 3 efeitos,
// todos mais fortes conforme o "medo" (0 a 1):
//   1. aberração cromática: o vermelho e o azul se separam nas bordas
//   2. grão: ruído que muda 24 vezes por segundo, como filme velho
//   3. vinheta: as bordas escurecem e "pulsam" no ritmo do coração
shader_type canvas_item;

uniform float medo : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D tela : hint_screen_texture, filter_nearest;

// Número pseudoaleatório entre 0 e 1 a partir de uma posição (truque clássico de shader).
float ruido(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;                 // posição do pixel na tela, de (0,0) a (1,1)
	vec2 do_centro = uv - vec2(0.5);     // vetor do centro da tela até o pixel

	// 1. Aberração cromática: cada canal de cor é lido num lugar um pouco diferente.
	float desloc = 0.006 * medo * medo;
	vec3 cor;
	cor.r = texture(tela, uv + do_centro * desloc).r;
	cor.g = texture(tela, uv).g;
	cor.b = texture(tela, uv - do_centro * desloc).b;

	// 2. Grão: um valor aleatório por pixel do jogo (640x360), trocado 24x por segundo.
	vec2 pixel = floor(uv * vec2(640.0, 360.0));
	float grao = ruido(pixel + floor(TIME * 24.0)) - 0.5;
	cor += grao * 0.14 * medo;

	// 3. Vinheta com batimento: o coração bate de 60 a 140 vezes por minuto.
	float bpm = 60.0 + 80.0 * medo;
	float batida = pow(max(sin(TIME * bpm / 60.0 * 6.2832), 0.0), 8.0);  // pico curto
	float raio = 0.78 - 0.38 * medo - 0.06 * batida * medo;   // o círculo de visão encolhe
	float dist = length(do_centro * vec2(1.0, 0.62));         // corrige a tela larga
	float vinheta = smoothstep(raio, raio - 0.30, dist);       // 1 no centro, 0 na borda
	cor *= mix(1.0, vinheta, clamp(medo * 1.4, 0.0, 0.92));

	COLOR = vec4(cor, 1.0);
}
