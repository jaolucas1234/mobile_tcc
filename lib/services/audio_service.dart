class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  bool _isPlaying = false;
  bool _isInitialized = false;

  Future<bool> inicializarMusica() async {
    print('🎵 Sistema de áudio simulado ativo');

    _isInitialized = true;

    print('✅ Música ambiente simulada - "Som Relaxante para Meditação"');
    print('💡 Em produção, substitua por URLs reais de áudio');

    return true;
  }

  Future<void> toggleMusica() async {
    if (!_isInitialized) {
      await inicializarMusica();
    }

    _isPlaying = !_isPlaying;
    print(
      _isPlaying ? '▶️ Música simulada tocando' : '⏸️ Música simulada pausada',
    );
  }

  Future<void> pararMusica() async {
    _isPlaying = false;
    print('⏹️ Música simulada parada');
  }

  Future<void> setVolume(double volume) async {
    print('🔊 Volume simulado: ${(volume * 100).round()}%');
  }

  bool get isPlaying => _isPlaying;
  bool get isInitialized => _isInitialized;
  String get currentMusicName => 'Som Relaxante 🌿';

  void dispose() {
    _isPlaying = false;
    _isInitialized = false;
    print('🗑️ AudioService disposado');
  }
}
