# CIDADE LEXUS RP — V18: MEGA MORROS E SISTEMAS RP

**Engine:** Godot 4.4.1, Android horizontal, OpenGL Compatibility.
**Entrega:** source jogável offline com sistemas demonstrativos. Não é um servidor multiplayer nem um mundo fotorealista.

## Implementado na source

- Morros com malhas inclinadas, colisão trimesh e bairros de favela gerados por regiões (células -1,0; 0,-1; -1,-1 e outras).
- Casas em encostas, rampas para acesso, placas nas fachadas com COMANDO VERMELHO / PRIMEIRO COMANDO e identificação dos bairros.
- Barricadas de concreto com colisão, fumaça leve via CPUParticles3D, árvores e túneis com pilares/teto e colisão.
- Bases de BOPE, POLICIA CIVIL, COMANDO VERMELHO, PRIMEIRO COMANDO e SAMU.
- Frota inicial: BOPE BMW X7 (visual estilizado), POLICIA CIVIL BMW X7, CV SW4, PRIMEIRO COMANDO SW4 e SAMU ambulância. Viaturas com placa, adesivo textual, colisão, combustível, dano/reparo e sirene em equipes de emergência.
- Sistema F / USAR no teclado e tela para entrar/sair dos carros, visitar interiores e abrir serviços.
- Interiores residenciais com sala, sofá, cama, cozinha, iluminação, colisão e saída pela porta.
- Concessionária (3 opções), loja de skins (3 roupas), tunagem (motor e pintura), oficina (reparo/combustível), mercado (kits e munição), hospital (cura), compra de casas e entrada em organizações — todos demonstrativos offline com validação de distância e preço.
- HUD reorganizado com nome da organização, dica contextual de F, minimapa tocável, mapa ampliado com zoom, pontos de serviços e veículos.
- Economia e itens locais com salvamento em user://lexus_v13.cfg, incluindo casas, veículos comprados, upgrades visuais e roupas.
- Staff de demonstração protegido por feature debug e /staffmodo, com /staffdinheiro, /staffvida, /staffcurar, /staffcarro, /stafftp, /staffhora, /stafforg. **Isto não é autenticação de staff online.**
- Cenário continua com geração procedural e descarregamento de regiões distantes para desempenho no Android. Jogador GLB da V17 permanece com 3 aparências trocáveis.

## Onde encontrar os lugares (GPS aproximado)

| Serviço | Coordenadas no mundo (X,Z) |
| --- | --- |
| Loja de roupas | (-24,-14) |
| Concessionária | (24,-14) |
| Tunagem | (24,31) |
| Oficina | (-24,31) |
| BOPE | (104,-14) |
| Polícia Civil | (56,31) |
| CV | (24,111) |
| Primeiro Comando | (-24,65) |
| SAMU | (56,111) |
| Mercado | (104,65) |
| Morro / Favela | (-80,0), (0,-80) |
| Túneis | (0,-160), (160,0) |

**Observação:** as coordenadas são posições aproximadas das entradas. As bases e os morros surgem automaticamente conforme você se aproxima.

## Teclas / controles

- `F` / botão `F • INTERAGIR`: usar serviço / casa / veículo.
- Tocar no **minimapa** ou botão `MAPA`: abrir mapa grande; `+/-` altera zoom.
- Joystick: movimentar / dirigir; arraste na região livre da tela para girar a câmera.
- `ESPAÇO`: pular; `R`: recarregar; `M`: mochila; `T`: chat RP; `ESC`: voltar.
- Comandos locais: `/ajuda`, `/rg`, `/saldo`, `/org`, `/casas`, `/mapa`, `/gps`, `/staffhelp`.

## Limitações transparentes

- BMW X7 e SW4 são **silhuetas procedurais estilizadas com identificação textual**, não modelos oficiais ou réplicas 3D licenciadas.
- O mundo é uma cidade procedural por células, não a reprodução fotográfica ou geográfica exata do Rio de Janeiro.
- Facções e corporações, staff, economia e inventário funcionam apenas na demonstração local; **não há servidor autoritativo nem anticheat online**. Não há guerra territorial multiplayer.
- VoIP experimental da V17 continua necessitando backend seguro hospedado e testes em dois aparelhos.
- Não foi possível executar Godot/Android neste ambiente. Há testes estáticos e de sistema adicionados ao GitHub Actions; a APK só estará validada depois da build e teste no aparelho.
- O APK de debug assinado por chave nova no workflow pode exigir desinstalar o anterior; faça backup do armazenamento local antes.
