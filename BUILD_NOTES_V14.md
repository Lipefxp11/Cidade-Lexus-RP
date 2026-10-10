# Cidade Lexus RP — V14: corrigir inicialização e horizontal

## Causas identificadas na V13
- Havia declarações `const NAME := ...` em 4 scripts Godot, sintaxe inválida para constantes GDScript. Alteradas para `const NAME = ...`.
- O mapa 3D com muitos objetos era criado *antes do menu* durante o boot. Agora o app carrega o menu primeiro; a geração da cidade é adiada até o toque em **JOGAR**.
- Qualidade de gráficos selecionada no menu chamava `city.set_quality` quando `city` ainda não existia. Agora há verificação.
- O controle de arma e câmera tinha código, mas faltavam chamadas em `_process` para executar os tiros, atualizar a câmera e simular a IA dos NPCs. As chamadas foram integradas.
- Android em modo paisagem: `display/window/handheld/orientation=0` (Godot 4.4 = landscape) e `DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)` em runtime Android. Proporção adaptativa para diferentes celulares.
- Mouse virtual por toque desativado para evitar duplicidade com joystick/touchscreen.

## Diagnóstico GitHub Actions
- Verifica consts incompatíveis e orientação.
- Executa `--check-only` no GDScript antes de exportar.
- Faz um smoke test do boot/menu por ~90 frames em modo headless, antes do APK.
- Anexa logs de importação e inicialização como artefato mesmo em falhas.
- APK sai com versionCode 14 e versão 0.0.14; nome de artefato **CidadeLexus-V14-Android-APK**.

## Limites de validação
- A sintaxe do YAML foi verificada, e a organização dos scripts, cenas e arquivos foi conferida.
- A execução nativa da Godot 4.4.1 e a abertura em Android não foram reproduzidas neste ambiente. O GitHub Actions fará uma verificação mais próxima e somente um teste em um celular confirma a experiência real.
- O APK de debug usa chave temporária e pode exigir desinstalar um APK de debug antigo. Para atualização sem perder dados, usar assinatura persistente.
- V14 mantém o protótipo offline: não é um servidor multiplayer.
