import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/appimages/flower.png',
              width: 120,
            ),
            const SizedBox(height: 24.0),

            const Text(
              'SHEERA',
              style: TextStyle(
                fontSize: 32.0,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 185, 68, 109),
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 48.0),

            CircularProgressIndicator(
              color: Colors.pink[600],
            ),
            const SizedBox(height: 16.0),

            // Text(
            //   'Memeriksa sesi...',
            //   style: TextStyle(
            //     color: Colors.grey[600],
            //     fontSize: 16.0,
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}