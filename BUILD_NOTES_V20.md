# CIDADE LEXUS RP — V20: PERSONAGEM, CÂMERA, GPS, BUILD ANDROID

## Principais alterações (implementadas na source)

1. **Sem dependência de internet na exportação do personagem**: o APK sempre inclui `assets/models/character.glb`, personagem original do projeto, com articulações e animações procedurais. Importar `assets/models/hero_realistic.glb` é opcional. A V19 tentava baixar um senhor idoso animado em toda build; isso podia quebrar o APK se o servidor externo falhasse.
2. **Menu de personalização**: botão **PERSONALIZAR PERSONAGEM**, prévia 3D usando o modelo efetivo, três roupas, quatro tons de pele, quatro cores de cabelo; escolhas salvas no perfil local. Roupas desbloqueáveis continuam controladas pela loja de skins da demonstração. Modelos realistas externos com materiais próprios NÃO têm seus mapas de textura recoloridos.
3. **Câmera terceira pessoa**: distância do pedestre reduzida para 3,05 m; mira no personagem, órbita por arrastar no lado direito, ângulo vertical limitado, distância ajustável de 2,5 a 4,5 m nas configurações, suavização, deslocamento de ombro e teste de colisão com paredes. Continua controle touch + teclado.
4. **GPS no mapa ampliado**: toque num ponto do mapa para marcar destino. Minimapa e HUD mostram marcador e distância aproximada em metros. Botão **REMOVER GPS**. Comandos locais `/gps`, `/gpsgaragem`, `/gpsentrega`, `/gpscancelar`.
5. **Continuidade offline**: salva roupas, cor do cabelo, tom de pele, ponto GPS e a última posição externa do jogador. Ao voltar, carrega o setor correspondente do mundo procedural para evitar spawn sem chão.
6. **Qualidade/estabilidade**: preview de personagem usa viewport apenas quando visível; Godot continua com compatibilidade GL, tela horizontal e simulação de clique a partir do toque. Build GitHub Actions agora usa somente assets locais obrigatórios, tem teste de importação do personagem e smoke do menu/GPS.
7. **Mantidos da V18–V19**: favelas em morros estilizados, carros com colisão/fuel/tunagem/sirene, casas/interiores, loja, staff local de desenvolvimento, inventário, arma com munição/dano e VOIP experimental. Não são sistemas online completos.

## Limitações honestas

- O `character.glb` incluído é um modelo humano **estilizado**, não um ator fotorrealista de GTA V/VI. Para aparência de alta qualidade é preciso licenciar/adquirir um humano skinned + rig + animações com orçamento de triângulos/texturas adequado ao Android e testar no jogo.
- O `hero_realistic.glb` pode ser fornecido **separadamente** por quem possui os direitos. Deve conter `Skeleton3D` e `AnimationPlayer` com clips compatíveis. A fonte externa V19 não é mais obrigatória.
- GPS mostra destino/direção no mapa e distância em linha reta, **não navegação por ruas**. A cidade procedural reutiliza prédios e texturas e não é um mapa autoral infinito fotorrealista.
- Servidores exibidos são offline; comandos staff são locais e sem autoridade em rede; VOIP exige infraestrutura própria. Não são soluções de segurança multiplayer.
- A V20 foi inspecionada e passou em testes estáticos, mas **a compilação Android e os botões em celular físico ainda precisam ser testados no GitHub Actions/aparelho**.

## Como enviar ao GitHub pelo Termux

```bash
cd ~/cidade-lexus/cidade-lexus
unzip -o /sdcard/Download/CIDADE_LEXUS_RP_V20_MEGA_ANDROID_SOURCE.zip -d .
git add -A
git commit -m "Cidade Lexus RP V20 - Personagem, camera e GPS"
git push origin main
```

Consulte **Actions** no repositório e o artefato `CidadeLexus-V20-Android-APK` em execução bem-sucedida. Se falhar, faça download do artefato `CidadeLexus-V20-logs` para ver os logs. APK de debug pode ter assinatura diferente da versão instalada, e reinstalar pode apagar dados locais.

## Arquivos modificados

- `.github/workflows/android.yml`
- `export_presets.cfg`, `project.godot`
- `scripts/humanoid.gd`, `scripts/lexus_ui.gd`, `scripts/lexus_minimap.gd`, `scripts/main.gd`
- `tests/v20_static_check.py`, `tests/v20_avatar_gps_smoke.gd`
