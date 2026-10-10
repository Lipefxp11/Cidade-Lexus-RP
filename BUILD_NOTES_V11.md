# Cidade Lexus RP V11 - Export Android

Correção prioritária: importar texturas ETC2/ASTC na máquina de compilação (GitHub Actions x86_64).

O Godot 4.x pode recusar o preset Android com a mensagem `Cannot export project ... due to configuration errors:` vazia quando `rendering/textures/vram_compression/import_etc2_astc` não está ativado.

Alterações:
- `project.godot`: `textures/vram_compression/import_etc2_astc=true` sob `[rendering]`.
- `export_presets.cfg`: `vram_texture_compression/for_mobile=true`.
- ZIP com arquivos na raiz, sem pasta `cidade-lexus/` interna.
- Workflow Android preservado com a instalação de Godot 4.4.1, SDK e a assinatura debug durante a execução.

Para testar:
1. Extraia o zip diretamente NA RAIZ do repositório.
2. Faça commit e push.
3. Confira a etapa `Export Android APK` do Actions.

Não foi possível executar Godot/Android em nosso ambiente; o Actions é a validação final.

Referência: https://github.com/godotengine/godot/issues/119895
