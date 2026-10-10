# Cidade Lexus RP V17 — Personagem Oficial

## Personagem padrão: LEXUS URBANO 01

Agora o APK inclui fisicamente `assets/models/character.glb` (arquivo .glb, aproximadamente 154 KB), um modelo 3D original para Cidade Lexus RP. Antes, a V16 somente procurava o arquivo opcional e, quando ausente, montava boneco provisório de cápsulas.

### O que está implementado
- Um personagem urbano masculino original com rosto modelado, olhos, nariz, boca, orelhas, cabelo curto, camiseta LX, calça cargo, tênis e detalhes metálicos.
- Modelo com **17.024 triângulos** e **115 malhas** em arquivo GLB PBR autossuficiente. O jogo carrega essa geometria por padrão. Não requer baixar assets na inicialização.
- Hierarquia de juntas com braços, cotovelos, mãos, quadris, pernas, joelhos, pés, cabeça e tronco separados.
- Atualizado `scripts/humanoid.gd` para dirigir a movimentação procedural de parado, andando, correndo, agachado, salto, mira, recuo e queda usando as juntas do próprio GLB.
- Modelo oficial também serve de base para os NPCs da demonstração (reaproveitando a cena, não gerando modelo por script a cada NPC).
- Nomes de personagem em informações locais passam a Lexus Urbano 01.
- Adicionado `tests/v17_character_smoke.gd` ao GitHub Actions para verificar importação e presença de juntas após o importador Godot.

### Limites atuais
- Não é escaneamento fotográfico nem humano AAA de fotorealismo. É um personagem estilizado, com proporções humanas, pronto para jogos Android de protótipo.
- Animações são procedurais por pivôs, **não** capturas de movimento com rig deformável/skinning completo.
- Não há editor completo de cabelo, rosto ou roupas nesta V17. Isso requer GLBs extras ou malhas customizáveis e persistência de personagem.
- Não foi executada a Godot 4.4.1 neste ambiente; o smoke-test rodará no GitHub. O APK deve ser instalado e testado em Android.

## Atualizar via Termux

```bash
cd ~/cidade-lexus/cidade-lexus
unzip -o /sdcard/Download/CIDADE_LEXUS_RP_V17_PERSONAGEM_OFICIAL.zip -d .
git add -A
git commit -m "Cidade Lexus RP V17 - Personagem Oficial"
git push origin main
```

## Licença do personagem
Geometria original elaborada programaticamente para o projeto (sem modelos externos e sem depender de assets comerciais). Mais detalhes em `assets/models/LICENSE_CHARACTER.txt`.
