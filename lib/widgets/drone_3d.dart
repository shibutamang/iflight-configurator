import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class Drone3D extends StatefulWidget {
  final double roll;  // degrees
  final double pitch; // degrees
  final double yaw;   // degrees

  const Drone3D({
    super.key,
    required this.roll,
    required this.pitch,
    required this.yaw,
  });

  @override
  State<Drone3D> createState() => _Drone3DState();
}

class _Drone3DState extends State<Drone3D> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rollAnimation;
  late Animation<double> _pitchAnimation;
  late Animation<double> _yawAnimation;
  
  double _currentRoll = 0;
  double _currentPitch = 0;
  double _currentYaw = 0;

  @override
  void initState() {
    super.initState();
    _currentRoll = widget.roll;
    _currentPitch = widget.pitch;
    _currentYaw = widget.yaw;
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 50), // Match polling rate for real-time feel
      vsync: this,
    );
    
    _rollAnimation = Tween<double>(begin: _currentRoll, end: _currentRoll).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
    _pitchAnimation = Tween<double>(begin: _currentPitch, end: _currentPitch).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
    _yawAnimation = Tween<double>(begin: _currentYaw, end: _currentYaw).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  @override
  void didUpdateWidget(Drone3D oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.roll != widget.roll || 
        oldWidget.pitch != widget.pitch || 
        oldWidget.yaw != widget.yaw) {
      // Animate from current animated value to new target
      _rollAnimation = Tween<double>(
        begin: _rollAnimation.value,
        end: widget.roll,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
      
      _pitchAnimation = Tween<double>(
        begin: _pitchAnimation.value,
        end: widget.pitch,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
      
      // Handle yaw wraparound (e.g., 350° to 10° should go through 360°, not back through 180°)
      double yawDiff = widget.yaw - _yawAnimation.value;
      if (yawDiff > 180) yawDiff -= 360;
      if (yawDiff < -180) yawDiff += 360;
      
      _yawAnimation = Tween<double>(
        begin: _yawAnimation.value,
        end: _yawAnimation.value + yawDiff,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
      
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1a1a2e), // Dark blue-gray
                Color(0xFF16213e), // Darker blue
                Color(0xFF0f0f1a), // Near black
              ],
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CustomPaint(
              painter: Drone3DPainter(
                roll: _rollAnimation.value,
                pitch: _pitchAnimation.value,
                yaw: _yawAnimation.value,
              ),
              size: const Size(double.infinity, double.infinity),
            ),
          ),
        );
      },
    );
  }
}

class Drone3DPainter extends CustomPainter {
  final double roll;
  final double pitch;
  final double yaw;
  
  // Camera view angles (fixed perspective)
  static const double cameraElevation = 25.0; // degrees - view from slightly above
  static const double cameraAzimuth = -20.0;  // degrees - view from slightly to the side

  Drone3DPainter({
    required this.roll,
    required this.pitch,
    required this.yaw,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // Draw 3D space background elements
    _drawGrid(canvas, size, centerX, centerY);
    _drawAxes(canvas, centerX, centerY, size);
    
    // Draw the 3D drone
    _drawDrone3D(canvas, centerX, centerY, size);
    
    // Draw attitude info overlay
    _drawAttitudeInfo(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size, double centerX, double centerY) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    // Draw horizontal grid lines
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }
    
    // Draw vertical grid lines
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }
  }

  void _drawAxes(Canvas canvas, double centerX, double centerY, Size size) {
    final axisLength = math.min(size.width, size.height) * 0.3;
    
    // Convert drone angles to radians
    final rollRad = roll * math.pi / 180;
    final pitchRad = pitch * math.pi / 180;
    final yawRad = yaw * math.pi / 180;
    
    // 3D rotation matrices applied with camera offset
    // X-axis (red) - points right
    final xAxis = _rotate3DWithCamera(axisLength, 0, 0, rollRad, pitchRad, yawRad);
    // Y-axis (green) - points forward  
    final yAxis = _rotate3DWithCamera(0, -axisLength, 0, rollRad, pitchRad, yawRad);
    // Z-axis (blue) - points up
    final zAxis = _rotate3DWithCamera(0, 0, -axisLength, rollRad, pitchRad, yawRad);
    
    // Draw axes with perspective
    final xPaint = Paint()
      ..color = Colors.red.withOpacity(0.4)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    final yPaint = Paint()
      ..color = Colors.green.withOpacity(0.4)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    final zPaint = Paint()
      ..color = Colors.blue.withOpacity(0.4)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    // Draw X axis
    canvas.drawLine(
      Offset(centerX, centerY),
      Offset(centerX + xAxis[0], centerY + xAxis[1]),
      xPaint,
    );
    
    // Draw Y axis
    canvas.drawLine(
      Offset(centerX, centerY),
      Offset(centerX + yAxis[0], centerY + yAxis[1]),
      yPaint,
    );
    
    // Draw Z axis
    canvas.drawLine(
      Offset(centerX, centerY),
      Offset(centerX + zAxis[0], centerY + zAxis[1]),
      zPaint,
    );
    
    // Draw axis labels
    _drawAxisLabel(canvas, centerX + xAxis[0] + 10, centerY + xAxis[1], 'X', Colors.red);
    _drawAxisLabel(canvas, centerX + yAxis[0] + 10, centerY + yAxis[1], 'Y', Colors.green);
    _drawAxisLabel(canvas, centerX + zAxis[0] + 10, centerY + zAxis[1], 'Z', Colors.blue);
  }

  void _drawAxisLabel(Canvas canvas, double x, double y, String label, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color.withOpacity(0.6),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x, y - textPainter.height / 2));
  }

  List<double> _rotate3DWithCamera(double x, double y, double z, double roll, double pitch, double yaw) {
    // First apply drone rotation
    final rotated = _applyRotation(x, y, z, roll, pitch, yaw);
    
    // Then apply camera view transformation
    final camElevRad = cameraElevation * math.pi / 180;
    final camAzimRad = cameraAzimuth * math.pi / 180;
    
    // Apply camera azimuth (rotation around Z axis)
    double x1 = rotated[0] * math.cos(camAzimRad) - rotated[1] * math.sin(camAzimRad);
    double y1 = rotated[0] * math.sin(camAzimRad) + rotated[1] * math.cos(camAzimRad);
    double z1 = rotated[2];
    
    // Apply camera elevation (rotation around X axis)
    double x2 = x1;
    double y2 = y1 * math.cos(camElevRad) - z1 * math.sin(camElevRad);
    double z2 = y1 * math.sin(camElevRad) + z1 * math.cos(camElevRad);
    
    // Simple perspective projection
    final perspective = 1.0 + z2 / 400;
    return [x2 * perspective, y2 * perspective, z2];
  }

  List<double> _applyRotation(double x, double y, double z, double roll, double pitch, double yaw) {
    // Apply yaw (rotation around Z axis)
    double x1 = x * math.cos(yaw) - y * math.sin(yaw);
    double y1 = x * math.sin(yaw) + y * math.cos(yaw);
    double z1 = z;
    
    // Apply pitch (rotation around X axis)
    double x2 = x1;
    double y2 = y1 * math.cos(pitch) - z1 * math.sin(pitch);
    double z2 = y1 * math.sin(pitch) + z1 * math.cos(pitch);
    
    // Apply roll (rotation around Y axis)
    double x3 = x2 * math.cos(roll) + z2 * math.sin(roll);
    double y3 = y2;
    double z3 = -x2 * math.sin(roll) + z2 * math.cos(roll);
    
    return [x3, y3, z3];
  }

  void _drawDrone3D(Canvas canvas, double centerX, double centerY, Size size) {
    final scale = math.min(size.width, size.height) * 0.28;
    
    // Convert angles to radians
    final rollRad = roll * math.pi / 180;
    final pitchRad = pitch * math.pi / 180;
    final yawRad = yaw * math.pi / 180;
    
    // Define drone vertices (X-frame quadcopter)
    final armLength = scale * 0.75;
    final motorRadius = scale * 0.12;
    
    // Motor positions (45 degree X-frame)
    final motorPositions = [
      [-armLength * 0.7, -armLength * 0.7, 0.0], // Front-Left (M1)
      [armLength * 0.7, -armLength * 0.7, 0.0],  // Front-Right (M2)
      [armLength * 0.7, armLength * 0.7, 0.0],   // Back-Right (M3)
      [-armLength * 0.7, armLength * 0.7, 0.0],  // Back-Left (M4)
    ];
    
    // Transform motor positions
    final transformedMotors = motorPositions.map((pos) {
      return _rotate3DWithCamera(pos[0], pos[1], pos[2], rollRad, pitchRad, yawRad);
    }).toList();
    
    // Sort by Z for proper depth rendering (painter's algorithm)
    final motorIndices = [0, 1, 2, 3];
    motorIndices.sort((a, b) => transformedMotors[b][2].compareTo(transformedMotors[a][2]));
    
    // Draw arms first (behind motors)
    _drawArms(canvas, centerX, centerY, transformedMotors);
    
    // Draw body
    _drawBody(canvas, centerX, centerY, scale, rollRad, pitchRad, yawRad);
    
    // Draw motors in sorted order
    for (final i in motorIndices) {
      final pos = transformedMotors[i];
      final isFront = i < 2;
      _drawMotor(canvas, centerX + pos[0], centerY + pos[1], motorRadius, isFront, pos[2], i + 1);
    }
    
    // Draw front indicator
    _drawFrontIndicator(canvas, centerX, centerY, scale, rollRad, pitchRad, yawRad);
  }

  void _drawArms(Canvas canvas, double centerX, double centerY, List<List<double>> motorPositions) {
    final armPaint = Paint()
      ..color = const Color(0xFF555555)
      ..strokeWidth = 8.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    // Draw diagonal arms
    canvas.drawLine(
      Offset(centerX + motorPositions[0][0], centerY + motorPositions[0][1]),
      Offset(centerX + motorPositions[2][0], centerY + motorPositions[2][1]),
      armPaint,
    );
    canvas.drawLine(
      Offset(centerX + motorPositions[1][0], centerY + motorPositions[1][1]),
      Offset(centerX + motorPositions[3][0], centerY + motorPositions[3][1]),
      armPaint,
    );
  }

  void _drawBody(Canvas canvas, double centerX, double centerY, double scale, double roll, double pitch, double yaw) {
    final bodySize = scale * 0.35;
    
    // Body center point (rotated)
    final bodyPoints = [
      [-bodySize / 2, -bodySize / 2, 0.0],
      [bodySize / 2, -bodySize / 2, 0.0],
      [bodySize / 2, bodySize / 2, 0.0],
      [-bodySize / 2, bodySize / 2, 0.0],
    ];
    
    final transformedBody = bodyPoints.map((p) {
      return _rotate3DWithCamera(p[0], p[1], p[2], roll, pitch, yaw);
    }).toList();
    
    final bodyPath = Path()
      ..moveTo(centerX + transformedBody[0][0], centerY + transformedBody[0][1]);
    
    for (int i = 1; i < transformedBody.length; i++) {
      bodyPath.lineTo(centerX + transformedBody[i][0], centerY + transformedBody[i][1]);
    }
    bodyPath.close();
    
    // Body fill with gradient effect
    final bodyPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(bodyPath, bodyPaint);
    
    // Body outline
    final bodyStroke = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    canvas.drawPath(bodyPath, bodyStroke);
  }

  void _drawMotor(Canvas canvas, double x, double y, double radius, bool isFront, double z, int motorNumber) {
    // Adjust size based on depth
    final depthFactor = 1.0 + z / 250;
    final adjustedRadius = radius * depthFactor;
    
    // Motor base
    final motorPaint = Paint()
      ..color = isFront ? const Color(0xFF2196F3) : const Color(0xFF616161)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(x, y), adjustedRadius, motorPaint);
    
    // Motor outline
    final motorStroke = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    canvas.drawCircle(Offset(x, y), adjustedRadius, motorStroke);
    
    // Propeller circle
    final propPaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    canvas.drawCircle(Offset(x, y), adjustedRadius * 2.0, propPaint);
    
    // Motor number label
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'M$motorNumber',
        style: TextStyle(
          color: Colors.white.withOpacity(0.8),
          fontSize: 10 * depthFactor,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
  }

  void _drawFrontIndicator(Canvas canvas, double centerX, double centerY, double scale, double roll, double pitch, double yaw) {
    // Arrow pointing forward
    final arrowTip = _rotate3DWithCamera(0, -scale * 0.55, 0, roll, pitch, yaw);
    final arrowLeft = _rotate3DWithCamera(-scale * 0.12, -scale * 0.38, 0, roll, pitch, yaw);
    final arrowRight = _rotate3DWithCamera(scale * 0.12, -scale * 0.38, 0, roll, pitch, yaw);
    
    final arrowPath = Path()
      ..moveTo(centerX + arrowTip[0], centerY + arrowTip[1])
      ..lineTo(centerX + arrowLeft[0], centerY + arrowLeft[1])
      ..lineTo(centerX + arrowRight[0], centerY + arrowRight[1])
      ..close();
    
    final arrowPaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(arrowPath, arrowPaint);
    
    // Front label
    final frontLabel = _rotate3DWithCamera(0, -scale * 0.7, 0, roll, pitch, yaw);
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'FRONT',
        style: TextStyle(
          color: Colors.green.withOpacity(0.7),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(centerX + frontLabel[0] - textPainter.width / 2, centerY + frontLabel[1]));
  }

  void _drawAttitudeInfo(Canvas canvas, Size size) {
    final textStyle = TextStyle(
      color: Colors.white.withOpacity(0.8),
      fontSize: 12,
      fontWeight: FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    // Roll info (left side)
    textPainter.text = TextSpan(
      text: 'Roll: ${roll.toStringAsFixed(1)}°',
      style: textStyle.copyWith(color: Colors.red.withOpacity(0.9)),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(12, size.height - 54));
    
    // Pitch info
    textPainter.text = TextSpan(
      text: 'Pitch: ${pitch.toStringAsFixed(1)}°',
      style: textStyle.copyWith(color: Colors.green.withOpacity(0.9)),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(12, size.height - 36));
    
    // Yaw info
    textPainter.text = TextSpan(
      text: 'Yaw: ${yaw.toStringAsFixed(1)}°',
      style: textStyle.copyWith(color: Colors.blue.withOpacity(0.9)),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(12, size.height - 18));
  }

  @override
  bool shouldRepaint(covariant Drone3DPainter oldDelegate) {
    return oldDelegate.roll != roll ||
        oldDelegate.pitch != pitch ||
        oldDelegate.yaw != yaw;
  }
}
