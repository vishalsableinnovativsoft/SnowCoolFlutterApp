// // import 'package:flutter/material.dart';

// // class FloronGasCylinder extends StatefulWidget {
// //   @override
// //   _FloronGasCylinderState createState() => _FloronGasCylinderState();
// // }

// // class _FloronGasCylinderState extends State<FloronGasCylinder> with SingleTickerProviderStateMixin {
// //   late AnimationController _controller;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _controller = AnimationController(
// //       vsync: this,
// //       duration: Duration(seconds: 4),
// //     )..repeat(reverse: false);
// //   }

// //   @override
// //   void dispose() {
// //     _controller.dispose();
// //     super.dispose();
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Center(
// //       child: AnimatedBuilder(
// //         animation: _controller,
// //         builder: (_, __) {
// //           return CustomPaint(
// //             size: Size(120, 240),
// //             painter: CylinderSmokePainter(_controller.value),
// //           );
// //         },
// //       ),
// //     );
// //   }
// // }

// // class CylinderSmokePainter extends CustomPainter {
// //   final double animationValue;

// //   CylinderSmokePainter(this.animationValue);

// //   @override
// //   void paint(Canvas canvas, Size size) {
// //     final cylinderPaint = Paint()..color = Colors.grey.shade800;
// //     final cylinderRect = Rect.fromLTWH(size.width * 0.3, size.height * 0.4, size.width * 0.4, size.height * 0.5);
// //     final rRect = RRect.fromRectAndRadius(cylinderRect, Radius.circular(20));
// //     canvas.drawRRect(rRect, cylinderPaint);

// //     // Draw cylinder top ellipse
// //     final ellipseRect = Rect.fromCenter(center: Offset(size.width / 2, size.height * 0.4), width: size.width * 0.4, height: 30);
// //     final ellipsePaint = Paint()..color = Colors.grey.shade900;
// //     canvas.drawOval(ellipseRect, ellipsePaint);

// //     // Animate smoke as expanding circles going upwards from the cylinder top
// //     final smokePaint = Paint()..color = Colors.grey.withOpacity(0.3 * (1 - animationValue));
// //     final maxRadius = size.width * 0.5;
// //     final smokeRadius = maxRadius * animationValue;

// //     // Draw multiple expanding smoke circles with different positions and staggered animations
// //     for (int i = 0; i < 5; i++) {
// //       double offsetX = size.width / 2 + (i - 2) * 15 * (1 - animationValue);
// //       double offsetY = ellipseRect.top - smokeRadius * (0.5 + i * 0.1);
// //       canvas.drawCircle(Offset(offsetX, offsetY), smokeRadius * (0.5 + i * 0.2), smokePaint);
// //     }
// //   }

// //   @override
// //   bool shouldRepaint(CylinderSmokePainter oldDelegate) {
// //     return animationValue != oldDelegate.animationValue;
// //   }
// // }

// import 'dart:math';
// import 'package:flutter/material.dart';

// class FloronGasCylinder extends StatefulWidget {
//   const FloronGasCylinder({Key? key}) : super(key: key);

//   @override
//   _FloronGasCylinderState createState() => _FloronGasCylinderState();
// }

// class _FloronGasCylinderState extends State<FloronGasCylinder> with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   final List<SmokeParticle> _particles = [];
//   final Random _random = Random();

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 10),
//     )..addListener(() {
//         _updateParticles();
//       });
//     _controller.repeat();
//   }

//   void _updateParticles() {
//     // Add new particles
//     if (_particles.length < 100) {
//       _particles.add(SmokeParticle(
//         position: Offset(150 + _random.nextDouble() * 100, 600), // Bottom area horizontally randomized
//         velocity: Offset((_random.nextDouble() - 0.5) * 0.5, -(_random.nextDouble() * 1.5 + 0.5)), // Upwards with slight horizontal drift
//         size: _random.nextDouble() * 20 + 10,
//         life: 100,
//       ));
//     }

//     // Update existing particles
//     for (int i = _particles.length - 1; i >= 0; i--) {
//       SmokeParticle p = _particles[i];
//       p.position += p.velocity;
//       p.life -= 1;
//       p.size *= 0.98; // shrink over time
//       if (p.life <= 0 || p.size <= 0) {
//         _particles.removeAt(i);
//       }
//     }
//     setState(() {});
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: CustomPaint(
//         painter: SmokePainter(_particles),
//         child: Container(),
//       ),
//     );
//   }
// }

// class SmokeParticle {
//   Offset position;
//   Offset velocity;
//   double size;
//   int life;

//   SmokeParticle({
//     required this.position,
//     required this.velocity,
//     required this.size,
//     required this.life,
//   });
// }
// class SmokePainter extends CustomPainter {
//   final List<SmokeParticle> particles;

//   SmokePainter(this.particles);

//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint();
//     for (var p in particles) {
//       final alpha = (p.life / 100).clamp(0.0, 1.0);
//       paint.color = const Color.fromARGB(255, 188, 187, 187)!.withOpacity(alpha * 0.3);
//       canvas.drawCircle(p.position, p.size, paint);
//     }
//   }

//   @override
//   bool shouldRepaint(covariant SmokePainter oldDelegate) => true;
// }
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class FloronGasCylinder extends StatelessWidget {
  const FloronGasCylinder({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        // height: 250,
        alignment: Alignment.center,
        child: Lottie.asset(
          'assets/lottieFile/GAS Cylinder.json',
          width: 150,
          height: 150,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
