# Cidade Lexus RP — Avatar Oficial V17

`character.glb` é o personagem **Lexus Urbano 01**, incluído na source e no APK.
Tem aproximadamente 1,82 m no jogo, rosto com olhos, nariz e boca, cabelo prateado, tatuagens, corrente, camiseta LX, calça cargo, tênis, mãos e acessórios.

O humanoide usa nós hierárquicos nomeados `LexusLeftLeg`, `LexusRightArm` e equivalentes.
O script `scripts/humanoid.gd` controla animações procedurais de parado, andar, correr, agachar, pular, mirar, recuo e queda. Não é um rig humanoide completo com movimentos capturados; esse é o próximo passo para fotorealismo.

Se o importador Godot não carregar o GLB, o script usa um personagem simples alternativo para não bloquear o APK.

A V17 mantém a Godot 4.4.1 / Android (renderização GL Compatibility).
