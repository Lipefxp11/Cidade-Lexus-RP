# Cidade Lexus RP — protótipo 0.0.1

Projeto Godot 4.4.1, Android, renderizador Compatibility. **É um protótipo offline**, não é um multiplayer funcional nem tem gráficos no nível FiveM.

## Conteúdo
- Bairro de teste gerado com formas 3D simples
- Personagem cápsula com movimentação e câmera terceira pessoa
- Botões touchscreen de movimento e corrida
- GitHub Actions para tentar exportar APK debug

## GitHub
1. Crie um repositório e envie **o conteúdo desta pasta** à branch `main`.
2. Abra `Actions` > `Android APK (prototype)` > `Run workflow`.
3. Quando a execução terminar com sucesso, baixe o APK em `Artifacts`.

**Atenção:** pipeline não foi executado aqui. Exportação Android pode exigir ajustes de versão do SDK, editor settings ou preset. Se falhar, compartilhe o log do Actions para corrigirmos.

## Desenvolvimento
Abra a pasta no Godot 4.4.1. Execute F6/F5 para testar. No PC, use as setas do teclado e Shift para correr. Para Android, use os botões na tela.

## Próximas etapas
Substituir formas por modelos 3D originais, criar personagem animado, adicionar colisões e física, ajustar interface e então desenvolver backend multiplayer seguro.
