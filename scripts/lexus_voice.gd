extends Node

# Optional EXPERIMENTAL voice relay. Nothing is recorded/sent before the user
# explicitly connects and holds the microphone button. Not a multiplayer stack.
signal status_changed(label: String)

const RATE = 16000
const MAX_PACKET_BYTES = 1500
var peer: WebSocketPeer
var connected := false
var transmitting := false
var endpoint := ""
var mic_player: AudioStreamPlayer
var mic_capture: AudioEffectCapture
var mic_bus_index := -1
var voice_player: AudioStreamPlayer
var playback: AudioStreamGeneratorPlayback
var time_since_last_poll := 0.0
var last_status := "VOZ: OFFLINE"

func _ready() -> void:
	# A playback generator uses a small jitter buffer for incoming PCM audio.
	voice_player = AudioStreamPlayer.new()
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = float(RATE)
	stream.buffer_length = 0.35
	voice_player.stream = stream
	add_child(voice_player)
	voice_player.play()
	playback = voice_player.get_stream_playback() as AudioStreamGeneratorPlayback
	_emit_status("VOZ: OFFLINE")

func connection_label() -> String:
	return last_status

func is_connected_to_voice() -> bool:
	return connected

func connect_server(url: String, room: String) -> void:
	if peer != null:
		disconnect_server()
	if not (url.begins_with("ws://") or url.begins_with("wss://")):
		_emit_status("VOZ: URL INVÁLIDA")
		return
	endpoint = url
	peer = WebSocketPeer.new()
	peer.handshake_headers = PackedStringArray(["X-Lexus-Voice-Room: " + room])
	var err := peer.connect_to_url(url)
	if err != OK:
		peer = null
		_emit_status("VOZ: FALHA DE REDE")
		return
	_emit_status("VOZ: CONECTANDO")

func disconnect_server() -> void:
	transmitting = false
	connected = false
	if peer != null:
		peer.close()
		peer = null
	if mic_player != null:
		mic_player.stop()
	_emit_status("VOZ: OFFLINE")

func start_transmission() -> void:
	if not connected:
		_emit_status("VOZ: SEM SERVIDOR")
		return
	if OS.get_name() == "Android":
		# Android permission is requested only from explicit user interaction.
		if not OS.request_permission("android.permission.RECORD_AUDIO"):
			_emit_status("VOZ: PERMITA O MICROFONE E TENTE DE NOVO")
			return
	if mic_capture == null:
		_setup_mic()
	if mic_player != null:
		mic_player.play()
		transmitting = true
		_emit_status("VOZ: TRANSMITINDO")

func stop_transmission() -> void:
	transmitting = false
	if mic_player != null:
		mic_player.stop()
	if connected:
		_emit_status("VOZ: CONECTADO")

func _setup_mic() -> void:
	if not ProjectSettings.get_setting("audio/driver/enable_input", false):
		_emit_status("VOZ: MICROFONE DESABILITADO")
		return
	mic_bus_index = AudioServer.bus_count
	AudioServer.add_bus()
	AudioServer.set_bus_name(mic_bus_index, "LexusVoiceCapture")
	AudioServer.set_bus_send(mic_bus_index, "Master")
	AudioServer.set_bus_volume_db(mic_bus_index, -80.0)
	mic_capture = AudioEffectCapture.new()
	mic_capture.buffer_length = 0.5
	AudioServer.add_bus_effect(mic_bus_index, mic_capture)
	mic_player = AudioStreamPlayer.new()
	mic_player.stream = AudioStreamMicrophone.new()
	mic_player.bus = "LexusVoiceCapture"
	add_child(mic_player)

func _process(_delta: float) -> void:
	if peer == null:
		return
	peer.poll()
	var state := peer.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN and not connected:
		connected = true
		_emit_status("VOZ: CONECTADO")
	elif state == WebSocketPeer.STATE_CLOSED:
		connected = false
		transmitting = false
		peer = null
		_emit_status("VOZ: DESCONECTADO")
		return
	if not connected:
		return
	while peer.get_available_packet_count() > 0:
		var incoming := peer.get_packet()
		if incoming.size() >= 2 and incoming.size() <= MAX_PACKET_BYTES and not peer.was_string_packet():
			_play_voice_pcm16(incoming)
	if transmitting and mic_capture != null:
		_send_microphone()

func _send_microphone() -> void:
	var mix_rate := maxf(16000.0, float(AudioServer.get_mix_rate()))
	var read_frames := int(mix_rate / 50.0)
	if not mic_capture.can_get_buffer(read_frames):
		return
	var samples := mic_capture.get_buffer(read_frames)
	if samples.is_empty():
		return
	var packet := PackedByteArray()
	packet.resize(640) # 20 ms mono PCM16 @ 16 kHz
	for i in range(320):
		var sample_index := mini(read_frames - 1, int(float(i) / 320.0 * read_frames))
		var stereo: Vector2 = samples[sample_index]
		var mono := clampf((stereo.x + stereo.y) * 0.5, -1.0, 1.0)
		packet.encode_s16(i * 2, int(mono * 32767.0))
	if peer != null and connected:
		peer.send(packet, WebSocketPeer.WRITE_MODE_BINARY)

func _play_voice_pcm16(packet: PackedByteArray) -> void:
	if playback == null or packet.size() % 2 != 0:
		return
	var count: int = mini(int(packet.size() / 2), 640)
	if not playback.can_push_buffer(count):
		return
	var frames := PackedVector2Array()
	frames.resize(count)
	for i in range(count):
		var sample := float(packet.decode_s16(i * 2)) / 32768.0
		frames[i] = Vector2(sample, sample)
	playback.push_buffer(frames)

func _emit_status(label: String) -> void:
	last_status = label
	status_changed.emit(label)

func _exit_tree() -> void:
	disconnect_server()
