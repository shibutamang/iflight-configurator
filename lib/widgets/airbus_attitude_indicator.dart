import 'dart:math' as math;
import 'package:flutter/material.dart';

class AirbusAttitudeIndicator extends StatefulWidget {
  final double roll;  // degrees
  final double pitch; // degrees

  const AirbusAttitudeIndicator({
    super.key,
    required this.roll,
    required this.pitch,
  });

  @override
  State<AirbusAttitudeIndicator> createState() => _AirbusAttitudeIndicatorState();
}

class _AirbusAttitudeIndicatorState extends State<AirbusAttitudeIndicator> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rollAnimation;
  late Animation<double> _pitchAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 50), // Match polling rate for real-time feel
      vsync: this,
    );
    
    _rollAnimation = Tween<double>(begin: widget.roll, end: widget.roll).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
    _pitchAnimation = Tween<double>(begin: widget.pitch, end: widget.pitch).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  @override
  void didUpdateWidget(AirbusAttitudeIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.roll != widget.roll || oldWidget.pitch != widget.pitch) {
      // Handle roll wraparound for smooth animation
      double rollDiff = widget.roll - _rollAnimation.value;
      if (rollDiff > 180) rollDiff -= 360;
      if (rollDiff < -180) rollDiff += 360;
      
      _rollAnimation = Tween<double>(
        begin: _rollAnimation.value,
        end: _rollAnimation.value + rollDiff,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
      
      _pitchAnimation = Tween<double>(
        begin: _pitchAnimation.value,
        end: widget.pitch,
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
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF4A4A4A),
              width: 3,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: CustomPaint(
              painter: AirbusAttitudePainter(
                roll: _rollAnimation.value,
                pitch: _pitchAnimation.value,
              ),
              size: const Size(double.infinity, double.infinity),
            ),
          ),
        );
      },
    );
  }
}

class AirbusAttitudePainter extends CustomPainter {
  final double roll;
  final double pitch;

  AirbusAttitudePainter({
    required this.roll,
    required this.pitch,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // Pixels per degree for pitch
    final pixelsPerDegree = size.height / 60; // 60 degrees visible range
    
    // Convert to radians
    final rollRad = roll * math.pi / 180;
    
    // Calculate horizon offset
    final pitchOffset = pitch * pixelsPerDegree;
    
    // Save canvas and apply roll rotation
    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.rotate(rollRad);
    
    // Draw sky and ground
    _drawSkyAndGround(canvas, size, pitchOffset);
    
    // Draw pitch ladder
    _drawPitchLadder(canvas, size, pitchOffset, pixelsPerDegree);
    
    // Draw horizon line (yellow)
    _drawHorizonLine(canvas, size, pitchOffset);
    
    canvas.restore();
    
    // Draw fixed elements (aircraft symbol, roll scale)
    _drawRollScale(canvas, centerX, centerY, size);
    _drawAircraftSymbol(canvas, centerX, centerY);
  }

  void _drawSkyAndGround(Canvas canvas, Size size, double pitchOffset) {
    // Sky - blue gradient
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF4A90E2), // Bright sky blue
          Color(0xFF5BA3F5), // Lighter blue
        ],
      ).createShader(Rect.fromLTWH(-size.width, -size.height, size.width * 2, size.height * 2));
    
    // Ground - brown gradient
    final groundPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF8B6F47), // Brown
          Color(0xFF6B5638), // Darker brown
        ],
      ).createShader(Rect.fromLTWH(-size.width, -size.height, size.width * 2, size.height * 2));
    
    // Draw sky (above horizon)
    canvas.drawRect(
      Rect.fromLTWH(-size.width, -size.height, size.width * 2, size.height + pitchOffset),
      skyPaint,
    );
    
    // Draw ground (below horizon)
    canvas.drawRect(
      Rect.fromLTWH(-size.width, pitchOffset, size.width * 2, size.height),
      groundPaint,
    );
  }

  void _drawHorizonLine(Canvas canvas, Size size, double pitchOffset) {
    // Yellow horizon line
    final horizonPaint = Paint()
      ..color = Colors.yellow
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;
    
    canvas.drawLine(
      Offset(-size.width, pitchOffset),
      Offset(size.width, pitchOffset),
      horizonPaint,
    );
  }

  void _drawPitchLadder(Canvas canvas, Size size, double pitchOffset, double pixelsPerDegree) {
    final linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    // Draw pitch lines from -30 to +30 degrees
    for (int pitchDeg = -30; pitchDeg <= 30; pitchDeg += 5) {
      if (pitchDeg == 0) continue; // Skip horizon (drawn separately)
      
      final lineY = pitchOffset - (pitchDeg * pixelsPerDegree);
      
      // Skip lines outside visible area
      if (lineY < -size.height / 2 - 50 || lineY > size.height / 2 + 50) continue;
      
      // Line lengths - longer for 10° increments
      double lineHalfLength;
      bool isMajor = pitchDeg.abs() % 10 == 0;
      
      if (isMajor) {
        lineHalfLength = 35.0;
      } else {
        lineHalfLength = 20.0;
      }
      
      // Draw the pitch line
      canvas.drawLine(
        Offset(-lineHalfLength, lineY),
        Offset(lineHalfLength, lineY),
        linePaint,
      );
      
      // Draw numbers for 10° increments
      if (isMajor) {
        _drawPitchNumber(canvas, pitchDeg.abs(), lineHalfLength, lineY);
      }
    }
  }

  void _drawPitchNumber(Canvas canvas, int pitchDeg, double lineHalfLength, double lineY) {
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.bold,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    
    final textPainter = TextPainter(
      text: TextSpan(text: pitchDeg.toString(), style: textStyle),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    
    // Left number
    textPainter.paint(
      canvas,
      Offset(-lineHalfLength - textPainter.width - 6, lineY - textPainter.height / 2),
    );
    
    // Right number
    textPainter.paint(
      canvas,
      Offset(lineHalfLength + 6, lineY - textPainter.height / 2),
    );
  }

  void _drawRollScale(Canvas canvas, double centerX, double centerY, Size size) {
    final radius = math.min(size.width, size.height) * 0.42;
    final arcCenterY = centerY - radius * 0.15;
    
    // Draw roll arc (partial arc at top)
    final arcPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    // Draw arc from -60° to +60° at the top
    canvas.drawArc(
      Rect.fromCircle(center: Offset(centerX, arcCenterY), radius: radius),
      -math.pi / 2 - math.pi / 3, // Start at -60° from top
      2 * math.pi / 3, // 120° total arc
      false,
      arcPaint,
    );
    
    // Draw roll tick marks
    final tickPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    // Tick marks at specific angles
    final tickAngles = [-60, -45, -30, -20, -10, 0, 10, 20, 30, 45, 60];
    
    for (final angleDeg in tickAngles) {
      final angleRad = (-90 + angleDeg) * math.pi / 180;
      final isMajor = angleDeg.abs() % 30 == 0 || angleDeg == 0;
      final tickLength = isMajor ? 12.0 : 8.0;
      
      final outerX = centerX + math.cos(angleRad) * radius;
      final outerY = arcCenterY + math.sin(angleRad) * radius;
      final innerX = centerX + math.cos(angleRad) * (radius - tickLength);
      final innerY = arcCenterY + math.sin(angleRad) * (radius - tickLength);
      
      canvas.drawLine(Offset(innerX, innerY), Offset(outerX, outerY), tickPaint);
    }
    
    // Draw fixed white triangle at top (0° reference)
    final refTrianglePath = Path()
      ..moveTo(centerX, arcCenterY - radius - 2)
      ..lineTo(centerX - 8, arcCenterY - radius + 10)
      ..lineTo(centerX + 8, arcCenterY - radius + 10)
      ..close();
    
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(refTrianglePath, whitePaint);
    
    // Draw yellow roll pointer (rotates with roll)
    canvas.save();
    canvas.translate(centerX, arcCenterY);
    canvas.rotate(roll * math.pi / 180);
    
    // Yellow triangle pointing down from the arc
    final rollPointerPath = Path()
      ..moveTo(0, -radius + 12)
      ..lineTo(-6, -radius + 20)
      ..lineTo(6, -radius + 20)
      ..close();
    
    final yellowPaint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(rollPointerPath, yellowPaint);
    canvas.restore();
  }

  void _drawAircraftSymbol(Canvas canvas, double centerX, double centerY) {
    final yellowPaint = Paint()
      ..color = Colors.yellow
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    
    final yellowFillPaint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.fill;
    
    // Center dot/square
    canvas.drawRect(
      Rect.fromCenter(center: Offset(centerX, centerY), width: 6, height: 6),
      yellowFillPaint,
    );
    
    // Left wing - horizontal line with down tick at end
    canvas.drawLine(
      Offset(centerX - 6, centerY),
      Offset(centerX - 45, centerY),
      yellowPaint,
    );
    // Down tick at left end
    canvas.drawLine(
      Offset(centerX - 45, centerY),
      Offset(centerX - 45, centerY + 12),
      yellowPaint,
    );
    
    // Right wing - horizontal line with down tick at end
    canvas.drawLine(
      Offset(centerX + 6, centerY),
      Offset(centerX + 45, centerY),
      yellowPaint,
    );
    // Down tick at right end
    canvas.drawLine(
      Offset(centerX + 45, centerY),
      Offset(centerX + 45, centerY + 12),
      yellowPaint,
    );
    
    // Center vertical line going down
    canvas.drawLine(
      Offset(centerX, centerY + 3),
      Offset(centerX, centerY + 15),
      yellowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant AirbusAttitudePainter oldDelegate) {
    return oldDelegate.roll != roll || oldDelegate.pitch != pitch;
  }
}
