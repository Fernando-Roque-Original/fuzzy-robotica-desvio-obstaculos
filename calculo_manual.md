# Cálculo manual - Atividade 3A

Entradas do teste:

- Distância frontal: `d = 10 cm`
- Assimetria lateral: `a = -10 cm`

## Fase 1 - Fuzzificação

Para a distância `d = 10 cm`:

- μPerto(10) = `1,0`, pois `10` pertence ao patamar `[0, 15]`.
- μMédia(10) = `0,0`, pois `10 < 15`, início do suporte.
- μLonge(10) = `0,0`, pois `10 < 60`, início do suporte.

Para a assimetria `a = -10 cm`:

- μNegativa(-10) = `(0 - (-10)) / (0 - (-25)) = 10/25 = 0,4`
- μZero(-10) = `((-10) - (-25)) / (0 - (-25)) = 15/25 = 0,6`
- μPositiva(-10) = `0,0`, pois `-10 < 0`, início do suporte.

## Fase 2 - Regras ativadas

Exatamente duas regras têm antecedente diferente de zero:

1. Se a distância é Perto e a assimetria é Negativa, então Virar à Esquerda.
2. Se a distância é Perto e a assimetria é Zero, então Virar à Direita.

## Fase 3 - Conectivo E e implicação de Mamdani

As forças são calculadas pelo operador mínimo:

- Força da Regra 1 = `min(1,0; 0,4) = 0,4`
- Força da Regra 2 = `min(1,0; 0,6) = 0,6`

Na implicação de Mamdani, a função Virar à Esquerda é truncada em `0,4` e a função Virar à Direita é truncada em `0,6`.

## Fase 4 - Agregação

As duas saídas truncadas são combinadas ponto a ponto pelo operador máximo:

`μagregada(θ) = max(min(0,4; μEsquerda(θ)); min(0,6; μDireita(θ)))`

## Fase 5 - Defuzzificação em passos de 5 graus

| θ (graus) | μ agregada | μ(θ)·θ |
|---:|---:|---:|
| -45 | 0,40 | -18,00 |
| -40 | 0,40 | -16,00 |
| -35 | 0,40 | -14,00 |
| -30 | 0,40 | -12,00 |
| -25 | 0,40 | -10,00 |
| -20 | 0,40 | -8,00 |
| -15 | 0,40 | -6,00 |
| -10 | 0,40 | -4,00 |
| -5 | 0,25 | -1,25 |
| 0 | 0,00 | 0,00 |
| 5 | 0,25 | 1,25 |
| 10 | 0,50 | 5,00 |
| 15 | 0,60 | 9,00 |
| 20 | 0,60 | 12,00 |
| 25 | 0,60 | 15,00 |
| 30 | 0,60 | 18,00 |
| 35 | 0,60 | 21,00 |
| 40 | 0,60 | 24,00 |
| 45 | 0,60 | 27,00 |
| **Soma** | **8,40** | **43,00** |

### Memorial dos somatórios do CDA

Denominador:

`Σμ = (8×0,40 + 0,25) + (0,25 + 0,50 + 7×0,60)`

`Σμ = 3,45 + 4,95 = 8,40`

Numerador:

`Σμθ = [0,40×(-45-40-35-30-25-20-15-10) + 0,25×(-5)] + [0,25×5 + 0,50×10 + 0,60×(15+20+25+30+35+40+45)]`

`Σμθ = -89,25 + 132,25 = 43,00`

Logo:

`CDA = Σ μ(θ)·θ / Σ μ(θ) = 43 / 8,4 = 5,1190°`

O ângulo é positivo, portanto a ação é **virar para a direita**.

O sciFLT usa uma discretização mais fina, com 1001 pontos, e por isso pode produzir uma pequena diferença em relação ao cálculo manual de 5 em 5 graus.
