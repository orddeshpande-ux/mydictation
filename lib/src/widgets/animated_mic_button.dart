import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AnimatedMicButton extends StatefulWidget {
  final bool isListening;
  final bool isProcessing;
  final VoidCallback onTap;
  final double size;

  const AnimatedMicButton({
    super.key,
    required this.isListening,
    required this.isProcessing,
    required this.onTap,
    this.size = 72,
  });

  @override
  State<AnimatedMicButton> createState() => _AnimatedMicButtonState();
}

class _AnimatedMicButtonState extends State<AnimatedMicButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _ringController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _ringAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _ringAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeOut),
    );
    _updateAnimations();
  }

  @override
  void didUpdateWidget(covariant AnimatedMicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isListening != widget.isListening ||
        oldWidget.isProcessing != widget.isProcessing) {
      _updateAnimations();
    }
  }

  void _updateAnimations() {
    if (widget.isListening) {
      _pulseController.repeat(reverse: true);
      _ringController.repeat();
    } else {
      _pulseController.stop();
      _pulseController.reset();
      _ringController.stop();
      _ringController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = widget.isListening
        ? const Color(0xFFEF4444) // Red when listening
        : widget.isProcessing
            ? Theme.of(context).colorScheme.secondary // Secondary color when processing
            : Theme.of(context).colorScheme.primary; // Primary color default

    final Color glowColor = primaryColor.withOpacity(0.4);

    return SizedBox(
      width: widget.size + 40,
      height: widget.size + 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer animated rings when listening
          if (widget.isListening)
            AnimatedBuilder(
              animation: _ringAnimation,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(widget.size + 40, widget.size + 40),
                  painter: _RingPainter(
                    progress: _ringAnimation.value,
                    color: primaryColor,
                  ),
                );
              },
            ),
          // Main button with pulse
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              final scale = widget.isListening ? _pulseAnimation.value : 1.0;
              return Transform.scale(
                scale: scale,
                child: child,
              );
            },
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                widget.onTap();
              },
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryColor,
                      primaryColor.withOpacity(0.7),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: glowColor,
                      blurRadius: widget.isListening ? 30 : 15,
                      spreadRadius: widget.isListening ? 5 : 0,
                    ),
                  ],
                ),
                child: widget.isProcessing
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        widget.isListening ? Icons.stop_rounded : Icons.mic,
                        color: Colors.white,
                        size: widget.size * 0.45,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 0; i < 3; i++) {
      final ringProgress = ((progress + i * 0.33) % 1.0);
      final radius = maxRadius * 0.5 + maxRadius * 0.5 * ringProgress;
      final opacity = (1.0 - ringProgress) * 0.3;

      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
