# Cidade Lexus RP V16 — Gameplay e mundo procedural

## Alterações na source (comparadas à V15)

- **Câmera:** reduzida de 7,0 m para 3,55 m a pé, enquadramento de ombro e colisão com obstáculos; continuam os gestos de arrastar na parte livre da tela, sem botões para giro.
- **Tiro:** evento `button_down/button_up` para manter disparo enquanto pressionado, cadência, munição, recarga, raycast pelo centro da tela, traçador, cor do retículo, recuo no braço e flash/luzes e sons demonstrativos. NPCs continuam com vida, dano e respawn.
- **Veículos:** aceleração ajustada, velocidade de demonstração maior, grades, faróis, lanternas, retrovisores, direção e combustível; são modelos simples até a importação de `.glb` próprios.
- **Personagem:** animação procedural melhorada; adicionada opção de importar personagem `.glb` com animações Idle/Walk/Run/Aim/Crouch. NÃO inclui modelo humano fotorealista.
- **Cidade:** removido limite de 182 m; geração e descarte de trechos do mapa de 80 m em torno do jogador. É um mapa procedural sem limite fixo, mas com peças repetidas, não um mapa do Rio real nem tamanho ilimitado em memória.
- **Minimapa:** agora é centrado no personagem, adequado ao cenário procedural.
- **HUD:** voz, disparos, combustível e botões melhor organizados.
- **Staff:** `/staffhelp`, `/staffmodo`, `/staffcurar`, `/stafftp X Z`, `/staffcarro`, `/staffhora HH`: exclusivamente demonstração local. Um servidor real deve validar permissões no backend, nunca somente no APK.
- **Voz:** botão de conexão e push-to-talk e exemplo de WebSocket/PCM; exige endpoint externo e permissionamento no Android. Sem autenticação segura, voz por proximidade real ou multiplayer sincronizado. Não está pronta para produção.

## O que não está concluído

- Jogador e carros com fotorealismo, física avançada e animações AAA: requerem modelos e materiais licenciados, rigging, teste de desempenho e ajuste de física.
- Multiplayer real e staff online: requerem servidor autoritativo, persistência e autenticação.
- VoIP com proximidade real, segurança e baixa latência: requer backend autenticado, codec e sincronização de posições.
- APK Android validado em aparelho: não foi possível executar Godot neste ambiente. O workflow continua verificando parser, menu e inicialização ao compilar no GitHub.

## Uso

1. Extraia na raiz do repositório existente, sem substituir `.git`.
2. `git add -A && git commit -m "Cidade Lexus V16" && git push origin main`.
3. Confira **Actions**, depois teste instalação, personagem, câmera, tiro, carros, mapa e microfone.
4. Use `assets/models/README.md` para importar seus arquivos 3D com licença.
