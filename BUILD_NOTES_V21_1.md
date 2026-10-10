# Cidade Lexus RP — V21.1 hotfix de compilação

## Problema observado
GitHub Actions falha em **Verify landscape settings and script syntax**, no arquivo
`scripts/city_world.gd` linhas 366–369, por não conseguir inferir o tipo das
variáveis `ax`, `bx`, `az` e `bz` (operadores vindos de arrays sem tipo).

## Correção aplicada
- Quatro coordenadas agora têm tipo `float` explícito.
- Converte os valores dos loops `sx`, `sz`, `ix` e `iz` para `float`.
- Adiciona uma verificação de regressão no teste estático V21.
- Preserva a geografia, materiais, ponte, túnel, clima, UI, scripts e workflow V21.

## Validação
Os testes estáticos da source rodam localmente, mas o Godot 4.4.1 não está
instalado neste ambiente; a validação real da sintaxe GDScript e o APK devem
ser confirmados pela próxima execução do GitHub Actions.
