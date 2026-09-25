// ============================================================================
// ATIVIDADE 3A - LOGICA FUZZY
// Controle Fuzzy para Desvio de Obstaculos em Robotica Movel
// Implementacao para Scilab 6.1.1 + sciFLT 0.5
// Autor: Fernando Roque Caldas de Oliveira
// Matricula: 202211130038
// ============================================================================

mode(-1);
clc;
clear;

// Carrega o Fuzzy Logic Toolbox do Scilab.
atomsLoad("sciFLT");

// Pasta em que este arquivo esta salvo.
pasta_projeto = get_absolute_file_path("fuzzy_robotica.sce");
pasta_prints = pasta_projeto + "prints/";

if ~isdir(pasta_prints) then
    mkdir(pasta_prints);
end

// ============================================================================
// 1. CRIACAO DO SISTEMA FUZZY MAMDANI
// S-Norm = maximo; T-Norm = minimo; complemento = classico;
// defuzzificacao = centroide.
// ============================================================================

fls = newfls("m", "Controle_Robotica", "max", "min", "one", "centroide");
fls.comment = "Controle fuzzy Mamdani para desvio de obstaculos";
fls.ImpMethod = "min";
fls.AggMethod = "max";

// ============================================================================
// 2. ENTRADA 1 - DISTANCIA FRONTAL
// Universo: [0 100] cm
// ============================================================================

fls = addvar(fls, "input", "Distancia", [0 100]);
fls = addmf(fls, "input", 1, "Perto", "trapmf", [0 0 15 40]);
fls = addmf(fls, "input", 1, "Media", "trimf", [15 50 85]);
fls = addmf(fls, "input", 1, "Longe", "trapmf", [60 85 100 100]);

// ============================================================================
// 3. ENTRADA 2 - ASSIMETRIA LATERAL
// a = d_dir - d_esq; universo: [-50 50] cm
// ============================================================================

fls = addvar(fls, "input", "Assimetria", [-50 50]);
fls = addmf(fls, "input", 2, "Negativa", "trapmf", [-50 -50 -25 0]);
fls = addmf(fls, "input", 2, "Zero", "trimf", [-25 0 25]);
fls = addmf(fls, "input", 2, "Positiva", "trapmf", [0 25 50 50]);

// ============================================================================
// 4. SAIDA - ANGULO DE DIRECAO
// Universo: [-45 45] graus
// ============================================================================

fls = addvar(fls, "output", "Angulo", [-45 45]);
fls = addmf(fls, "output", 1, "Virar_Esquerda", "trapmf", [-45 -45 -20 0]);
fls = addmf(fls, "output", 1, "Seguir_Frente", "trimf", [-20 0 20]);
fls = addmf(fls, "output", 1, "Virar_Direita", "trapmf", [0 20 45 45]);

// ============================================================================
// 5. BASE DE REGRAS
// Formato por linha:
// [MF_distancia MF_assimetria MF_angulo conectivo peso]
// conectivo 1 = E (T-Norm); peso = 1.
// ============================================================================

regras = [
    1 1 1 1 1;  // Perto & Negativa -> Virar Esquerda
    1 2 3 1 1;  // Perto & Zero     -> Virar Direita
    1 3 3 1 1;  // Perto & Positiva -> Virar Direita
    2 1 1 1 1;  // Media & Negativa -> Virar Esquerda
    2 2 2 1 1;  // Media & Zero     -> Seguir em Frente
    2 3 3 1 1;  // Media & Positiva -> Virar Direita
    3 1 2 1 1;  // Longe & Negativa -> Seguir em Frente
    3 2 2 1 1;  // Longe & Zero     -> Seguir em Frente
    3 3 2 1 1   // Longe & Positiva -> Seguir em Frente
];

fls = addrule(fls, regras);

// ============================================================================
// 6. TESTE SOLICITADO: d = 10 cm; a = -10 cm
// ============================================================================

d = 10;
a = -10;
n_pontos = 1001;

[theta, entradas_regras, saida_agregada] = evalfls([d a], fls, n_pontos);
theta = theta(1);

if theta < 0 then
    acao = "VIRAR PARA A ESQUERDA";
elseif theta > 0 then
    acao = "VIRAR PARA A DIREITA";
else
    acao = "SEGUIR EM FRENTE";
end

mprintf("\n=========================================\n");
mprintf("       RESULTADO DO SISTEMA FUZZY\n");
mprintf("=========================================\n");
mprintf("Distancia frontal = %.2f cm\n", d);
mprintf("Assimetria lateral = %.2f cm\n", a);
mprintf("Angulo calculado = %.6f graus\n", theta);
mprintf("Acao: %s\n", acao);
mprintf("=========================================\n\n");

// ============================================================================
// 7. CALCULO MANUAL DISCRETIZADO EM PASSOS DE 5 GRAUS
// ============================================================================

mu_perto = trapmf(d, [0 0 15 40]);
mu_media = trimf(d, [15 50 85]);
mu_longe = trapmf(d, [60 85 100 100]);

mu_negativa = trapmf(a, [-50 -50 -25 0]);
mu_zero = trimf(a, [-25 0 25]);
mu_positiva = trapmf(a, [0 25 50 50]);

forca_regra_1 = min(mu_perto, mu_negativa);
forca_regra_2 = min(mu_perto, mu_zero);

theta_discreto = -45:5:45;
mf_esquerda = trapmf(theta_discreto, [-45 -45 -20 0]);
mf_direita = trapmf(theta_discreto, [0 20 45 45]);

// O trapmf do sciFLT retorna zero exatamente nos extremos quando a=b ou c=d.
// Nos ombros definidos pela atividade, esses extremos pertencem ao patamar 1.
mf_esquerda(1) = 1;
mf_direita($) = 1;

saida_regra_1 = min(forca_regra_1 * ones(theta_discreto), mf_esquerda);
saida_regra_2 = min(forca_regra_2 * ones(theta_discreto), mf_direita);
saida_manual = max([saida_regra_1; saida_regra_2], "r");

theta_manual = sum(theta_discreto .* saida_manual) / sum(saida_manual);

mprintf("Calculo manual (passo de 5 graus) = %.6f graus\n", theta_manual);
mprintf("Diferenca software - manual = %.6f graus\n\n", theta - theta_manual);

// ============================================================================
// 8. SALVAR O SISTEMA E O RESULTADO NUMERICO
// ============================================================================

savefls(fls, pasta_projeto + "fuzzy_robotica.fls");

fd = mopen(pasta_projeto + "resultado_simulacao.txt", "wt");
mfprintf(fd, "ATIVIDADE 3A - CONTROLE FUZZY PARA ROBOTICA MOVEL\n\n");
mfprintf(fd, "Entrada d = %.2f cm\n", d);
mfprintf(fd, "Entrada a = %.2f cm\n", a);
mfprintf(fd, "Angulo pelo sciFLT = %.6f graus\n", theta);
mfprintf(fd, "Angulo manual (passo de 5 graus) = %.6f graus\n", theta_manual);
mfprintf(fd, "Diferenca = %.6f graus\n", theta - theta_manual);
mfprintf(fd, "Acao = %s\n", acao);
mclose(fd);

// ============================================================================
// 9. GRAFICOS DAS FUNCOES DE PERTINENCIA
// ============================================================================

f1 = scf(1);
clf();
plotvar(fls, "input", 1, -0.1, 1.1, 1001);
xtitle("Distancia Frontal", "Distancia (cm)", "Grau de pertinencia");
xs2png(f1, pasta_prints + "01_distancia_frontal.png");

f2 = scf(2);
clf();
plotvar(fls, "input", 2, -0.1, 1.1, 1001);
xtitle("Assimetria Lateral", "Assimetria (cm)", "Grau de pertinencia");
xs2png(f2, pasta_prints + "02_assimetria_lateral.png");

f3 = scf(3);
clf();
plotvar(fls, "output", 1, -0.1, 1.1, 1001);
xtitle("Angulo de Direcao", "Angulo (graus)", "Grau de pertinencia");
xs2png(f3, pasta_prints + "03_angulo_direcao.png");

// Grafico da saida agregada e do valor defuzzificado.
universo_saida = linspace(-45, 45, n_pontos)';

f4 = scf(4);
clf();
plot(universo_saida, saida_agregada(:, 1), "b-", "LineWidth", 3);
plot([theta theta], [0 1], "r--", "LineWidth", 2);
xgrid();
xtitle(msprintf("Resultado: theta = %.4f graus - %s", theta, acao), ..
       "Angulo (graus)", "Grau de pertinencia agregado");
xs2png(f4, pasta_prints + "resultado_simulacao.png");

// Superficie tridimensional do controlador fuzzy.
// Eixo X: distancia; eixo Y: assimetria; eixo Z: angulo calculado.
n_distancia = 31;
n_assimetria = 31;
// Evita somente os pontos extremos exatos, pois o trapmf antigo do sciFLT
// devolve zero quando os dois vertices do ombro coincidem no limite.
distancias = linspace(0.001, 99.999, n_distancia)';
assimetrias = linspace(-49.999, 49.999, n_assimetria)';
malha_entradas = genspace(distancias, assimetrias);
angulos_malha = zeros(size(malha_entradas, 1), 1);

// A versao 0.5 do sciFLT pode falhar com uma matriz grande em evalfls.
// A avaliacao ponto a ponto produz a mesma superficie de forma compativel.
for k = 1:size(malha_entradas, 1)
    angulo_ponto = evalfls(malha_entradas(k, :), fls, 201);
    angulos_malha(k) = angulo_ponto(1);
end
superficie_angulo = matrix(angulos_malha, n_assimetria, n_distancia)';

f5 = scf(5);
clf();
f5.figure_size = [1000 700];
f5.color_map = jetcolormap(64);
plot3d1(distancias, assimetrias, superficie_angulo);
xtitle("Superficie 3D do Controle Fuzzy", ..
       "Distancia frontal (cm)", ..
       "Assimetria lateral (cm)", ..
       "Theta (graus)");
xs2png(f5, pasta_prints + "04_superficie_controle_3d.png");

mprintf("Arquivos salvos em: %s\n", pasta_projeto);
mprintf("Sistema salvo como fuzzy_robotica.fls\n");
mprintf("Graficos 2D e superficie 3D salvos na pasta prints.\n");
