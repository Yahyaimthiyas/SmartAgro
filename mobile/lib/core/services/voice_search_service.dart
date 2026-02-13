import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceSearchService {
  final SpeechToText _speech = SpeechToText();
  bool _isAvailable = false;

  Future<bool> init() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      return false;
    }
    _isAvailable = await _speech.initialize(
       onStatus: (status) => print('Voice Status: $status'),
       onError: (error) => print('Voice Error: $error'),
    );
    return _isAvailable;
  }

  Future<void> startListening({
    required Function(String) onResult,
    required VoidCallback onDone,
  }) async {
    if (!_isAvailable) {
       bool initialized = await init();
       if (!initialized) return;
    }

    await _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
        if (result.finalResult) {
           onDone();
        }
      },
      localeId: 'en_IN', // Default, can swap to 'ta_IN' if supported
      cancelOnError: true,
    );
  }

  Future<void> stop() async {
    await _speech.stop();
  }
  
  bool get isListening => _speech.isListening;
}
