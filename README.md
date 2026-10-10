## V17 — Personagem Oficial

Modelo 3D original **Lexus Urbano 01** (`assets/models/character.glb`) vem **incluído no APK**, animado em `scripts/humanoid.gd`. Teste automático em `tests/v17_character_smoke.gd`. Para mais informações consulte `BUILD_NOTES_V17.md`.

---

# CIDADE LEXUS RP — Protótipo V16

**Engine:** Godot 4.4.1 · **plataforma:** Android horizontal · **estado:** demo **offline**.

A source integra o menu futurista da V15, personagem articulado ou modelo GLB externo, câmera estilo GTA SA (mais próxima), disparos com recuo/sons, veículos procedurais, HUD, staff de testes locais, mapa gerado em blocos e interface de um protótipo de voz. **Não há multiplayer autenticado nem voz por proximidade em produção.**

## Executar e compilar

- Abra `project.godot` na Godot 4.4.1. A cena inicial é `res://scenes/main.tscn`.
- No GitHub, o workflow `.github/workflows/android.yml` baixa Godot, executa testes headless e, se tudo passar, exporta `CidadeLexus-V16-debug.apk` no artefato `CidadeLexus-V16-Android-APK`.
- Copie o conteúdo do ZIP **para a raiz do repositório Git existente**. Não crie uma pasta `cidade-lexus` dentro de outra.
- Consulte `BUILD_NOTES_V16.md` para limitações e testes.
- Os scripts têm verificações estáticas, mas **esta versão ainda não foi executada no celular nem compilada com Godot neste ambiente**.

## Controles

- Arraste a tela livre para girar a câmera; use o joystick para andar.
- Pressione **CORRER**, **PULAR**, **AGACHAR**, **USAR** e **RECARREGAR**.
- **Segure ATIRAR** para disparar sequencialmente (com munição, recuo e sons).
- **VOZ** conecta/desconecta do transporte experimental; **SEGURAR P/ FALAR** só funciona com endpoint e permissão de microfone. Configure URL em **Configurações**.
- Chat RP: `/ajuda`, `/rg`, `/saldo`, `/inventario`, `/gps`, `/trabalho`, `/carro`, `/curar`, `/recarregar`, `/comprarmunicao`. Comandos **STAFF LOCAIS**: `/staffhelp`.

## Modelos realistas

Há suporte opcional a GLB com licenças apropriadas em `assets/models/README.md`. A source **não inclui assets fotorealistas**: os personagens e veículos-padrão são estilizados e montados com geometria simples.

## Voz experimental

`server_voice/` contém exemplo de relay PCM/WebSocket para desenvolvimento local. **Não publicar** sem autenticação, controle de acesso, codec apropriado, criptografia na borda, sincronização de posições e moderação. O cliente continua offline se não houver servidor configurado.
