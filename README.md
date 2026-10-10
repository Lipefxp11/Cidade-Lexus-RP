# Cidade Lexus RP — V21 (3 cidades, ponte, túnel, água e clima)

**Duque de Caxias** é a região inicial. Pegue a avenida rumo a **Z positivo** para chegar à **Ponte Lexus** (Z=280–440), continue até **Cidade de Deus** (Z≈560) e siga para **X positivo** pelo **Túnel da Zona Norte** (X=520–760, Z=560) para acessar a **Zona Norte**. O minimapa e o mapa ampliado usam os mesmos eixos do mundo.

**Clima:** `/clima 1` = noite, `/clima 2` = dia, `/clima auto` = ciclo automático; `/tempo sol`, `/tempo nublado` e `/tempo chuva`. No mapa ampliado, há botões GPS para as três cidades.

O mundo é **procedural e estilizado**, inspirado em conceitos de cidades brasileiras — não é o mapa oficial do GTA V, nem cópia de ruas reais. Continua sendo uma **demo offline**, sem servidor de RP online. Consulte [BUILD_NOTES_V21.md](BUILD_NOTES_V21.md) e [MAPA_V21_ROTA.txt](MAPA_V21_ROTA.txt).

## Instalação

1. Baixe `CIDADE_LEXUS_RP_V21_TRES_CIDADES_MAPA_CLIMA.zip` na pasta Download.
2. Entre em `~/cidade-lexus/cidade-lexus` pelo Termux.
3. Extraia na raiz: `unzip -o /sdcard/Download/CIDADE_LEXUS_RP_V21_TRES_CIDADES_MAPA_CLIMA.zip -d .`
4. Execute `git add -A && git commit -m "Cidade Lexus RP V21" && git push origin main`.
5. Acesse **Actions** do GitHub. O artefato será `CidadeLexus-V21-Android-APK` se todos os testes e a exportação passarem.

---

# Cidade Lexus RP — Protótipo Android V20

Jogo indie de mundo aberto para Android feito com Godot 4.4.1 (GL Compatibility).
**Ainda é uma demonstração offline**, não um clone pronto de GTA/FiveM nem um servidor multiplayer.

## Jogar

Na tela horizontal inicial, abra **PERSONALIZAR PERSONAGEM** para ajustar roupa, cabelo e pele, selecione **JOGAR** e use o joystick à esquerda. Arraste o dedo na área livre à direita para girar a câmera (sem botões artificiais de rotação). À direita estão **ATIRAR**, **RECARGA**, **CORRER**, **PULAR**, **AGACHAR**, **INTERAGIR**, **MOCHILA**, **MAPA**, **CHAT** e opções de VOZ experimental. Encoste nas casas/serviços e use **F/INTERAGIR**. Entre em veículos pelos pontos próximos.

Toque no minimapa ou no botão **MAPA**. No mapa ampliado, toque no local desejado para marcar um **GPS** com distância em linha reta. Use **REMOVER GPS** para cancelar.

## Personagem

O modelo local `assets/models/character.glb` sempre vai junto no APK. O menu de aparência permite três roupas (duas exigem compra prévia em loja local), quatro cores de cabelo e quatro tons de pele. As escolhas persistem offline. Um modelo skinned de alta qualidade **licenciado pelo dono** pode ser adicionado em `assets/models/hero_realistic.glb` e assumirá prioridade se tiver esqueleto e animações. Esse arquivo não é requisito para o build.

## Exportar pelo GitHub

A source inclui workflow `.github/workflows/android.yml` para compilar APK de debug em **Actions** na branch `main`, usando Java 17, Android SDK 35, Godot 4.4.1 e export templates. O workflow não depende mais de baixar um personagem externo. Execute `python3 tests/v20_static_check.py` para checagens rápidas antes de subir.

## Recursos e limites

- Cidade procedural com ruas, morros, favelas estilizadas, serviços, túneis e interiores locais.
- Sistemas de veículos, saúde, combate e economia simples; persistência apenas no dispositivo.
- BOPE, Polícia Civil, SAMU e grupos fictícios da simulação têm bases/viaturas estilizadas; não há modelos oficiais fotorealistas nem uso de marcas licenciadas.
- VoIP em desenvolvimento, sem comunicação pronta entre jogadores; falta infraestrutura e autenticação de servidor.
- Staff de teste apenas no APK debug offline; não é sistema de administração multiplayer seguro.

**Leia `BUILD_NOTES_V20.md` para as novidades e limitações de testes.**
