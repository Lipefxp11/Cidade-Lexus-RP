# Cidade Lexus RP — V21: Duque de Caxias, Cidade de Deus e Zona Norte

## Arquitetura do mapa (implementação de protótipo Android offline)

O mundo ganhou **três regiões distintas**, unidas por uma travessia utilizável com colisões:

- **Duque de Caxias (cidade principal)**: cidade inicial, garagem, concessionária, lojas e bases RP. Centro aproximado: `(X 0, Z 0)`.
- **Cidade de Deus (segunda cidade)**: ao norte do canal, acessível pela **Ponte Lexus**. Cidade de Deus: `(X 0, Z 560)`.
- **Zona Norte (terceira cidade)**: ao leste da Cidade de Deus, por avenida e **Túnel da Zona Norte**. Ponto de referência: `(X 850, Z 560)`.

O corredor: **Duque de Caxias → avenida no eixo X=0, sentido Z crescente → ponte sobre o canal (Z 280–440) → Cidade de Deus (Z 560) → avenida sentido X crescente (Z=560) → túnel (X 520–760) → Zona Norte**.

O canal é água animada por shader próprio e tem leito com colisão. Só existe **ponte transitável em X=0**; outras ruas não continuam sobre a água. A ponte tem plataforma, guardas laterais, suportes e rampas físicas. O túnel recebe teto, paredes, iluminação, sinalização e colisões.

## Mapa e navegação

- O **minimapa** e o **mapa expandido** compartilham a mesma geografia de ruas, canal, ponte e túnel que o mundo 3D (`scripts/lexus_geography.gd`).
- São mapas vetoriais esquemáticos, desenhados a partir das coordenadas reais internas do jogo, **não texturas roubadas/importadas de GTA V** nem mapas de ruas reais do RJ.
- Botões do mapa ampliado: Duque de Caxias, Cidade de Deus, Zona Norte, zoom, remover GPS e fechar. O mapa pode marcar destino pelo toque.
- Comandos locais: `/duque`, `/cdd`, `/zonanorte`, `/gps` e `/mapa`.
- O GPS indica distância e posição, não fornece rota por ruas nem piloto automático.

## Clima e ciclo dia/noite

- Ciclo automático: **24 minutos reais = 24 horas do jogo**.
- `/clima 1` = noite às 22:00; `/clima 2` = dia às 12:00; `/clima auto` = retoma o ciclo.
- `/tempo sol`, `/tempo nublado` e `/tempo chuva` alteram luminosidade, céu/fog e partículas locais.
- HUD mostra horário, tempo e modo automático/fixo; configurações salvas em `user://`.
- Poste de luz ao anoitecer e iluminação local no túnel nas qualidades acima de baixa.

## Construções, relevo e ruas

- **Casas com fachadas diferentes por cidade**, alturas variadas, janelas texturizadas e algumas sacadas. As quatro zonas residenciais de cada quarteirão têm topografia ondulada com malha de colisão.
- Preservadas favelas e morros anteriores, agora conectados a uma geografia maior e pontos de serviço do RP.
- **Quebra-molas baixos, com perfis inclinados e colisão**, gerados em partes das avenidas.
- Construções e setores distantes ainda são procedurais repetitivos. Não é um mapa artesanal ou fotorrealista do GTA 5.

## Desempenho e estabilidade

- Continua Godot 4.4.1/Android/GL Compatibility/tela horizontal.
- A cidade usa **chunks de 80 m**, instanciando aproximadamente um chunk por frame, com descarte de chunks distantes.
- Água em shader de ondas leves, chuva local de baixa densidade, e sem necessidade de baixar dados externos para o mapa.
- Incluir `tests/v21_static_check.py` e `tests/v21_world_smoke.gd` no GitHub Actions. O smoke Godot tenta instanciar a ponte, água, túnel, testar dia/noite e mapa.

## Limitações

**Esta V21 permanece um protótipo offline**. Não integra GTA V nem usa seu mapa original. Veículos e personagens continuam modelos demonstrativos; texturas realistas/licenciadas e um mapa gigantesco detalhado exigem assets originais e trabalho de modelagem. O modo clima não sincroniza jogadores por rede. O acesso ao rio fora da ponte faz o personagem retornar à margem por segurança (não há natação).

A estrutura e os testes estáticos foram conferidos localmente. A compilação Godot + APK e a jogabilidade no celular precisam ser confirmadas pelo **GitHub Actions e por testes em um aparelho Android**.

## Instalação no Termux

```sh
cd ~/cidade-lexus/cidade-lexus
unzip -o /sdcard/Download/CIDADE_LEXUS_RP_V21_TRES_CIDADES_MAPA_CLIMA.zip -d .
git add -A
git commit -m "Cidade Lexus RP V21 - tres cidades, ponte, tunel e clima"
git push origin main
```
