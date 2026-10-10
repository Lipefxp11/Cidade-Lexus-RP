# CIDADE LEXUS RP — V13 MEGA (protótipo Android)

## O que foi implementado na source

- Projeto Godot 4.4.1, renderizador de compatibilidade, orientação **paisagem** (`orientation=0`) e exportação APK via GitHub Actions.
- Menu futurista com imagem de fundo fornecida pelo usuário (versão recortada da V12), seleção de **demonstração offline**, configurações de qualidade/sensibilidade e botão Jogar.
- Tela de carregamento entre menu e jogo. Ela representa uma transição local, **não uma conexão a servidor real**.
- Câmera em terceira pessoa **360 graus arrastando o dedo** na área livre do lado direito; botões de girar câmera removidos; correção de obstrução por paredes usando raycast.
- Joystick analógico com multitouch, botões correr (liga/desliga), pular, agachar, atirar, recarregar, usar/entrar/sair, mochila, chat e menu.
- Modelo de jogador humanoide feito com malhas primitivas: cabeça, cabelo, tronco, quadril, braços, antebraços, mãos, pernas, pés e arma visível. Movimento simples com animações procedurais. **Ainda não é um humano fotorealista com rig**.
- Cidade fictícia aberta de aproximadamente 380 x 380 unidades, ruas em grade, 108 casas simples, calçadas, faixas, telhados, janelas, árvores e postes.
- Oito texturas proceduralmente geradas para asfalto, calçada, reboco, tijolo, grama, concreto, telhado e vidro, usando arquivos PNG no projeto.
- Três carros dirigíveis com aceleração, ré, freio por desaceleração, curva, consumo de combustível, velocímetro e entrada/saída por proximidade. A física é simplificada (não um simulador automotivo).
- Pistola inicial, munição 12/60, recarga de 1,8s, tiros com raycast, traçador visual, cooldown e dano.
- Quatro NPCs demonstrativos: ficam hostis ao levar dano, atacam o jogador, caem e reaparecem após 20 segundos.
- Sistema de vida e colete, morte/incapacitação e botão de reviver no hospital (modo demonstração offline).
- Mini mapa desenhado em tempo real com ruas, jogador, carros e NPCs; HUD com dinheiro, vida, stamina, colete, munição, velocidade, localização e trabalho.
- Economia offline simplificada: dinheiro, XP, kit médico, comprar munição e missão de entrega remunerada por proximidade.
- Chat local com comandos funcionais `/ajuda`, `/rg`, `/saldo`, `/inventario`, `/mochila`, `/gps`, `/trabalho`, `/carro`, `/recarregar`, `/curar`, `/comprarmunicao`.
- Persistência local com `ConfigFile` em `user://lexus_v13.cfg` (dinheiro, banco inicial, munição reserva, medkits, XP, vitórias, mortes, gráficos, sensibilidade).

## Limitações importantes

- **É um protótipo offline**. As opções de servidor online aparecem indisponíveis; não existe servidor multiplayer nem contas online nesta V13.
- A cidade é original/procedural, não é o mapa real do Rio de Janeiro.
- Não foram usados assets 3D realistas licenciados; boneco, casas e veículos são modelos simplificados, com texturas próprias.
- O modo de tiro é para NPCs do protótipo. Não há sincronização de combate multiplayer.
- A física de veículos e colisões de cenário é básica; requer playtest em celulares diferentes.
- **O APK ainda precisa ser compilado e testado no GitHub Actions**. Não há validação real de execução Android neste ambiente.
- O workflow atual gera uma keystore debug temporária por build. Instalação por cima de um APK antigo pode falhar por assinatura diferente. Para atualizações sem reinstalar, configure uma chave de assinatura persistente nos segredos do GitHub em etapa futura.

## Como atualizar o repositório pelo Termux

```sh
cd ~/cidade-lexus/cidade-lexus
unzip -o /sdcard/Download/CIDADE_LEXUS_RP_V13_MEGA_SOURCE.zip -d .
git status --short
git add -A
git commit -m "Cidade Lexus RP V13 - Mega gameplay Android"
git push origin main
```

ZIP contém os arquivos já na raiz do projeto. Não cria pasta `cidade-lexus` duplicada.

## Controles

Android: joystick esquerdo para andar/dirigir, arrastar dedo em parte livre à direita para câmera, botões dedicados para correr, agachar, pular, atirar, recarregar e usar/entrar no carro.

Teclado PC no editor (apenas para desenvolvimento): WASD/Setas, botão direito do mouse + mover para câmera, Espaço pular, F usar/entrar, R recarregar, M mochila, T chat, Q atirar, C agachar, Shift correr, Esc menu.

## Como testar

1. Abrir APK na horizontal.
2. Esperar o carregamento local e tocar em Jogar.
3. Testar multitouch joystick e arrastar câmera na área livre à direita.
4. Testar corrida/agachamento/pulo.
5. Ir até o carro próximo da garagem e apertar USAR; dirigir, sair.
6. Localizar NPC e testar atirar/recarregar e incapacitação/revivência.
7. Pegar entrega em X=9/Z=-15, dirigir até X=120/Z=60, sair e apertar USAR.
8. Testar /curar, /comprarmunicao, /rg, /saldo e mochila; reiniciar para checar persistência.
