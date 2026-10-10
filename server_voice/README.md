# Cidade Lexus — transporte de voz experimental

Este servidor **não é o servidor multiplayer do jogo**. Somente encaminha blocos PCM16 mono entre conexões WebSocket na mesma sala de testes. Não autentica identidade, não valida proximidade, não tem moderação e não deve ser publicado aberto na Internet.

Para testar **em ambiente isolado**:

```bash
cd server_voice
npm install
npm start
```

Por segurança, o exemplo só escuta em `127.0.0.1:8082`. Para testar dois dispositivos Android, você precisa fornecer um endpoint `wss://` com TLS, autenticação e controle de acesso, além de sincronizar as posições dos personagens por um servidor multiplayer real. A V16 inclui interface, permissão do microfone e transporte experimental de áudio, mas **VoIP público não está pronto**.

No menu Configurações do APK, informe o endereço `wss://...`, entre no mundo, toque em `VOZ` e mantenha `SEGURAR P/ FALAR` pressionado. A permissão do microfone só é pedida nesse momento. Nenhum áudio é transmitido antes de conectar e pressionar o botão.
