import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:just_audio/just_audio.dart';
import 'package:sheera/pages/user/subMenu/active_call_screen.dart';

class FakeIncomingCallScreen extends StatefulWidget {
  final String callerName;
  final String callerNumber;
  final String audioUrl;

  const FakeIncomingCallScreen({
    super.key,
    required this.callerName,
    required this.callerNumber,
    required this.audioUrl,
    
  });

  @override
  State<FakeIncomingCallScreen> createState() => _FakeIncomingCallScreenState();
}

class _FakeIncomingCallScreenState extends State<FakeIncomingCallScreen> {
  final _audioPlayer = AudioPlayer();
  @override
  
  void initState() {
    super.initState();
    // Saat halaman ini muncul, langsung mainkan nada dering
    FlutterRingtonePlayer().play(
      android: AndroidSounds.ringtone,
      ios: IosSounds.glass,
      looping: true,
      volume: 1.0,
    );                
  }

  @override
  void dispose() {
    // Hentikan nada dering saat halaman ditutup
    FlutterRingtonePlayer().stop();
    super.dispose();
  }

  Future<void> _playConversationAudio() async {
    try {
      String fullAudioUrl = 'http://192.168.43.45:8000${widget.audioUrl}';
      print('Playing audio from: $fullAudioUrl');

      await _audioPlayer.setUrl(fullAudioUrl);
      await _audioPlayer.play();
    } catch (e) {
      print("Error playing audio from URL: $e");
    }
  }
  
  void _acceptCall() {
    // Hentikan nada dering
    FlutterRingtonePlayer().stop();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ActiveCallScreen(
          callerName: widget.callerName,
          audioUrl: widget.audioUrl, 
        ),
      ),
    );
  }

  void _declineCall() {
    FlutterRingtonePlayer().stop();
    print('Panggilan Ditolak!');
    Navigator.of(context).pop(); // Kembali ke halaman sebelumnya
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/appimages/bg.jpg',
            fit: BoxFit.cover,
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),
          
          //Konten Panggilan
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Info Penelepon di Atas
                  Column(
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                      const CircleAvatar(
                        radius: 60,
                        backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=5'),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        widget.callerName,
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Panggilan Masuk...',
                        style: TextStyle(fontSize: 20, color: Colors.grey[300]),
                      ),
                    ],
                  ),
                  
                  // Tombol Aksi di Bawah
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildCallButton(
                        icon: Icons.call_end,
                        label: 'Tolak',
                        color: Colors.red,
                        onPressed: _declineCall,
                      ),
                      _buildCallButton(
                        icon: Icons.call,
                        label: 'Jawab',
                        color: Colors.green,
                        onPressed: _acceptCall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget untuk membuat tombol yang cantik
  Widget _buildCallButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            child: Icon(icon, color: Colors.white, size: 35),
          ),
        ),
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ],
    );
  }
}