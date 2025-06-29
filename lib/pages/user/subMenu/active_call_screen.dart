import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class ActiveCallScreen extends StatefulWidget {
  final String callerName;
  final String audioUrl;

  const ActiveCallScreen({
    super.key,
    required this.callerName,
    required this.audioUrl,
  });

  @override
  State<ActiveCallScreen> createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends State<ActiveCallScreen> {
  final _audioPlayer = AudioPlayer();
  Timer? _callTimer;
  int _callDurationInSeconds = 0;

  @override
  void initState() {
    super.initState();
    _playConversationAudio();
    _startCallTimer();
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  // Fungsi untuk memutar audio percakapan dari URL
  Future<void> _playConversationAudio() async {
    try {
      String fullAudioUrl = 'http://192.168.43.45:8000${widget.audioUrl}';
      print('Memutar audio dari: $fullAudioUrl');
      await _audioPlayer.setUrl(fullAudioUrl);
      await _audioPlayer.play();
    } catch (e) {
      print("Error memutar audio dari URL: $e");
    }
  }

  // Fungsi untuk memulai timer durasi panggilan
  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _callDurationInSeconds++;
      });
    });
  }

  // Fungsi untuk memformat durasi menjadi MM:SS
  String _formatDuration(int seconds) {
    final minutes = (seconds / 60).floor().toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  void _endCall() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Info Penelepon
              Column(
                children: [
                  Text(
                    widget.callerName,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDuration(_callDurationInSeconds),
                    style: TextStyle(fontSize: 20, color: Colors.grey[400]),
                  ),
                ],
              ),
              
              // Grid Tombol Aksi (Mute, Speaker, dll)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(icon: Icons.mic_off_outlined, label: 'Mute'),
                  _buildActionButton(icon: Icons.key_off_outlined, label: 'Keypad'),
                  _buildActionButton(icon: Icons.volume_up_outlined, label: 'Speaker'),
                ],
              ),
              
              // Tombol Tutup Telepon
              GestureDetector(
                onTap: _endCall,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.red),
                  child: const Icon(Icons.call_end, color: Colors.white, size: 35),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget untuk tombol aksi di tengah
  Widget _buildActionButton({required IconData icon, required String label}) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.1),
          ),
          child: Icon(icon, color: Colors.white, size: 30),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}