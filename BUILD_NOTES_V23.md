# Cidade Lexus RP V23 — Novo protagonista jogável

## Arquivos alterados
- `assets/models/character.glb`: substituído o boneco V17 por **Lexus Urbano 02**.
- `scripts/humanoid.gd`: aparência e roupas compatíveis com o GLB novo.
- `tests/v23_character_smoke.gd`: valida importação, nome, juntas, aparência e animação procedural.
- `.github/workflows/android.yml`: inclui o teste V23 após importar o projeto.
- `assets/models/README.md`, `LICENSE_CHARACTER.txt`: documentação do modelo.

## Personagem
Adulto em roupa urbana preta/vermelha, rosto esculpido com olhos, nariz,
barba curta e cabelo escuro; calça cargo, tênis e mãos com dedos.
Preserva os controles, entrada em veículos, morte e tiro da V22.

**Atenção:** não é personagem fotogramétrico nem tem skinning de ossos completo.
O corpo tem juntas hierárquicas, animadas por código. Não podemos prometer
realismo de GTA V ou movimento natural de captura profissional.

## Testes
O GLB passou na validação de estrutura glTF 2.0 e contém todas as juntas do jogo.
O workflow foi atualizado para confirmar a importação na Godot antes da exportação.
A compilação e a aparência em um Android físico ainda precisam ser testadas.

## Compilar
Coloque o conteúdo do ZIP na raiz do repositório e faça commit/push.
Não misture duas pastas `cidade-lexus` aninhadas.
