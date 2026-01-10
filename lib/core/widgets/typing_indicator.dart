import 'package:flutter/material.dart';

/// Widget que mostra indicador de "digitando..."
class TypingIndicator extends StatefulWidget {
  final bool isTyping;
  final String? userName;
  final Color? color;

  const TypingIndicator({
    super.key,
    required this.isTyping,
    this.userName,
    this.color,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _controllers = List.generate(3, (index) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    // Iniciar animações com delay escalonado
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted && widget.isTyping) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void didUpdateWidget(TypingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTyping != oldWidget.isTyping) {
      if (widget.isTyping) {
        for (int i = 0; i < _controllers.length; i++) {
          Future.delayed(Duration(milliseconds: i * 150), () {
            if (mounted) {
              _controllers[i].repeat(reverse: true);
            }
          });
        }
      } else {
        for (var controller in _controllers) {
          controller.stop();
          controller.reset();
        }
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isTyping) {
      return const SizedBox.shrink();
    }

    final color = widget.color ?? Colors.grey;
    final text = widget.userName != null
        ? '${widget.userName} está digitando'
        : 'Digitando';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bolinhas animadas
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              return AnimatedBuilder(
                animation: _animations[index],
                builder: (context, child) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.3 + (_animations[index].value * 0.7)),
                      shape: BoxShape.circle,
                    ),
                  );
                },
              );
            }),
          ),
          const SizedBox(width: 8),
          // Texto
          Text(
            '$text...',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget compacto de indicador de digitação (apenas bolinhas)
class TypingDots extends StatefulWidget {
  final Color? color;
  final double size;

  const TypingDots({
    super.key,
    this.color,
    this.size = 8,
  });

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (index) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    // Iniciar animações com delay escalonado
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Colors.grey;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: color.withOpacity(0.3 + (_animations[index].value * 0.7)),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}
