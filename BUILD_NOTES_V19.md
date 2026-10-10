# Cidade Lexus RP V19 — personagem humano realista, prova técnica

## O que foi feito
- Implementação do pipeline para personagem skinned GLB, Skeleton3D e AnimationPlayer.
- Troca automática do personagem básico por modelo humano texturizado quando presente.
- Suporte a animações do GLB: idle, caminhada e corrida. Agachamento e pulo têm fallback aproximado.
- Novo teste de GLB e animações no GitHub Actions.
- Personagem V17 continua como fallback para execução local sem o asset.
- O GitHub Actions baixa automaticamente o modelo para gerar o APK. Não depende de baixar manualmente no Android.

## Honestidade sobre o modelo
O arquivo de demonstração livre é um **senhor idoso** da Bake3D, não o protagonista final jovem.
Não há animações prontas de tiro, arma e morte; nesses casos o gameplay continua mas o novo modelo usa
uma animação neutra como fallback. Não prometer uma integração de combate perfeita.
Modelo de aproximadamente 150 mil triângulos; pesado para celulares modestos.
A otimização final exigirá LOD/redução de polígonos e um modelo jovem de licença adequada.

## Fonte e licença
"Old Man" by Bake3D (https://bake3d.ai), CC BY 4.0.
https://creativecommons.org/licenses/by/4.0/

## Fonte local vs APK
A source ZIP não distribui o arquivo externo realista. O GitHub Actions o baixa no passo
`Download real human 3D sample`. Quem abrir offline a source verá o personagem V17.
Para testar a versão realista no Godot local, execute `python tools/fetch_real_character.py`
com conexão à Internet antes de abrir o editor.
