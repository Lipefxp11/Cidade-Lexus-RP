# Cidade Lexus RP V15 — MENU E TOQUE ANDROID

Correções feitas diretamente na source V14:

- `input_devices/pointing/emulate_mouse_from_touch=true` no projeto Godot, necessário para os controles `Button`/`OptionButton` funcionarem por toque no Android.
- `Input.emulate_mouse_from_touch = true` logo no início do jogo como reforço.
- Menu, painéis e modal de configurações configurados para receber cliques; botões com filtro STOP e foco.
- Tela horizontal com menu reduzido e responsivo por escala; texto e botões sem ultrapassar o cartão.
- Faixa escura à esquerda cobre elementos de login antigos da imagem de fundo.
- Menu atualizado para V15, botão JOGAR, configurações e servidor offline selecionável.
- Joystick Android recebe eventos de toque nativos, sem duplicar mouse emulado.
- Teste leve de sinais dos botões incluído no workflow para conferir a conexão dos botões às ações.

O projeto continua sendo protótipo **offline**. Sem teste físico em aparelho, a compilação e os controles precisam ser validados após gerar o APK pelo GitHub Actions.
