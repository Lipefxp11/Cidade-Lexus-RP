# Cidade Lexus RP — source revisada

- Workflow Android refeito com Godot 4.4.1, Java 17 e SDK Android 35.
- Inicialização do editor ANTES de configurar caminhos de exportação.
- Assinatura de desenvolvimento configurada no runner (não há caminho fixo no preset versionado).
- Upload do APK somente se a exportação realmente funcionar.
- Controles touchscreen ajustados para âncoras absolutas.

**Validação local:** YAML analisado e arquivos inspecionados. Não foi possível executar a Godot/Android SDK neste ambiente; o GitHub Actions fará a validação de exportação.

Para publicar: extraia os arquivos dentro da raiz do repositório, faça commit e push.
