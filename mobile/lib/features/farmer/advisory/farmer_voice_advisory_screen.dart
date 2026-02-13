import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart'; // [NEW]
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';
import '../products/farmer_product_list_screen.dart';

class FarmerVoiceAdvisoryScreen extends StatefulWidget {
  final String messageId;

  const FarmerVoiceAdvisoryScreen({super.key, required this.messageId});

  @override
  State<FarmerVoiceAdvisoryScreen> createState() => _FarmerVoiceAdvisoryScreenState();
}

class _FarmerVoiceAdvisoryScreenState extends State<FarmerVoiceAdvisoryScreen> {
  final AudioPlayer _player = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts(); // [NEW]

  bool _loading = true;
  bool _playing = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  // TTS State
  bool _isTtsMode = false;
  bool _isTtsSpeaking = false;

  String _titleTa = '';
  String _titleEn = '';
  String _summaryTa = '';
  String _summaryEn = '';
  String? _imageUrl;
  String? _audioUrl;
  String? _categoryId;
  String _categoryNameTa = '';
  String _categoryNameEn = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Audio Player Listeners
    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playing = state == PlayerState.playing);
    });

    // TTS Listeners
    _flutterTts.setStartHandler(() {
      if (mounted) setState(() => _isTtsSpeaking = true);
    });
    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _isTtsSpeaking = false);
    });
    _flutterTts.setErrorHandler((msg) {
      if (mounted) setState(() => _isTtsSpeaking = false);
    });

    try {
      final snap = await FirebaseFirestore.instance
          .collection('advisory_messages')
          .doc(widget.messageId)
          .get();
      if (!snap.exists) {
        setState(() => _loading = false);
        return;
      }
      final data = snap.data()!;
      _titleTa = data['title_ta'] as String? ?? '';
      _titleEn = data['title_en'] as String? ?? '';
      _summaryTa = data['summary_ta'] as String? ?? '';
      _summaryEn = data['summary_en'] as String? ?? '';
      _imageUrl = data['imageUrl'] as String?;
      _audioUrl = data['audioUrl'] as String?;
      _categoryId = data['categoryId'] as String?;
      _categoryNameTa = data['categoryName_ta'] as String? ?? '';
      _categoryNameEn = data['categoryName_en'] as String? ?? '';

      if (_audioUrl != null && _audioUrl!.isNotEmpty) {
        await _player.setSourceUrl(_audioUrl!);
        _isTtsMode = false;
      } else {
        _isTtsMode = true; // Use TTS if no audio
      }
    } catch (_) {
      // ignore
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isTtsMode) {
      // TTS Logic
      if (_isTtsSpeaking) {
        await _flutterTts.stop();
        setState(() => _isTtsSpeaking = false);
      } else {
        final textToSpeak = LocalizationService.isTamil ? _summaryTa : _summaryEn;
        if (textToSpeak.isNotEmpty) {
           await _flutterTts.setLanguage(LocalizationService.isTamil ? "ta-IN" : "en-US");
           await _flutterTts.speak(textToSpeak);
        }
      }
    } else {
      // Audio Logic
      if (_audioUrl == null || _audioUrl!.isEmpty) return;
      if (_playing) {
        await _player.pause();
      } else {
        await _player.resume();
      }
    }
  }

  String _formatTime(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _imageUrl != null && _imageUrl!.isNotEmpty;
    final isPlaying = _isTtsMode ? _isTtsSpeaking : _playing;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 250,
                  pinned: true,
                  backgroundColor: Colors.white,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (hasImage)
                          Image.network(
                            _imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200),
                          )
                        else
                          Container(
                            color: AppColors.primaryLight,
                            child: const Icon(Icons.mic_external_on, size: 60, color: AppColors.primary),
                          ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  leading: IconButton(
                    icon: const CircleAvatar(
                       backgroundColor: Colors.white30,
                       child: Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                       color: Color(0xFFF8F9FA),
                       borderRadius: BorderRadius.vertical(top: Radius.circular(24))
                    ),
                    transform: Matrix4.translationValues(0, -20, 0),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            LocalizationService.isTamil ? _titleTa : _titleEn,
                            style: Localizations.localeOf(context).languageCode == 'ta' || LocalizationService.isTamil
                                ? GoogleFonts.notoSansTamil(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    height: 1.3,
                                    color: AppColors.textPrimary,
                                  )
                                : GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    height: 1.3,
                                    color: AppColors.textPrimary,
                                  ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Player Card
                          Container(
                             padding: const EdgeInsets.all(20),
                             decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                   BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4)
                                   )
                                ]
                             ),
                             child: Column(
                                children: [
                                   Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                         Text(
                                            _isTtsMode 
                                              ? "AI Text-to-Speech" 
                                              : LocalizationService.tr('voice_advisory_playback_status'),
                                            style: GoogleFonts.notoSansTamil(
                                               fontSize: 12,
                                               fontWeight: FontWeight.bold,
                                               color: AppColors.textSecondary
                                            ),
                                         ),
                                         Icon(Icons.graphic_eq, color: AppColors.primary.withOpacity(0.5))
                                      ],
                                   ),
                                   const SizedBox(height: 16),
                                   Row(
                                      children: [
                                         InkWell(
                                            onTap: _togglePlay,
                                            borderRadius: BorderRadius.circular(40),
                                            child: Container(
                                               padding: const EdgeInsets.all(12),
                                               decoration: const BoxDecoration(
                                                  color: AppColors.primary,
                                                  shape: BoxShape.circle,
                                               ),
                                               child: Icon(
                                                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                                  color: Colors.white,
                                                  size: 32,
                                               ),
                                            ),
                                         ),
                                         const SizedBox(width: 16),
                                         Expanded(
                                            child: _isTtsMode 
                                              ? Text(
                                                  isPlaying ? "Reading..." : "Tap to listen",
                                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.primary),
                                                )
                                              : Column(
                                               children: [
                                                  SliderTheme(
                                                     data: SliderTheme.of(context).copyWith(
                                                        trackHeight: 4,
                                                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                                        activeTrackColor: AppColors.primary,
                                                        inactiveTrackColor: AppColors.primary.withOpacity(0.1),
                                                        thumbColor: AppColors.primary
                                                     ),
                                                     child: Slider(
                                                        value: _position.inSeconds.toDouble().clamp(0, _duration.inSeconds.toDouble()),
                                                        min: 0,
                                                        max: _duration.inSeconds.toDouble() == 0 ? 1 : _duration.inSeconds.toDouble(),
                                                        onChanged: (v) async {
                                                           final pos = Duration(seconds: v.toInt());
                                                           await _player.seek(pos);
                                                        },
                                                     ),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                                    child: Row(
                                                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                       children: [
                                                          Text(
                                                             _formatTime(_position),
                                                             style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                                                          ),
                                                          Text(
                                                             _formatTime(_duration),
                                                             style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                                                          ),
                                                       ],
                                                    ),
                                                  )
                                               ],
                                            ),
                                         )
                                      ],
                                   )
                                ],
                             ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          Row(
                             children: [
                                const Icon(Icons.description_outlined, size: 20, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(
                                  LocalizationService.tr('voice_advisory_summary_title'),
                                  style: GoogleFonts.notoSansTamil(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                             ],
                          ),
                          const SizedBox(height: 12),
                          if (_summaryTa.isNotEmpty)
                            Text(
                              _summaryTa,
                              style: GoogleFonts.notoSansTamil(fontSize: 14, height: 1.6),
                            ),
                          if (_summaryEn.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              _summaryEn,
                              style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                            ),
                          ],
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _categoryId != null && _categoryId!.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))
                ]
              ),
              child: SafeArea(
                child: SizedBox(
                   width: double.infinity,
                   height: 56,
                   child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FarmerProductListScreen(
                            categoryId: _categoryId!,
                            categoryNameTa: _categoryNameTa,
                            categoryNameEn: _categoryNameEn,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      LocalizationService.tr('voice_advisory_btn_view_products'),
                      style: GoogleFonts.notoSansTamil(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

