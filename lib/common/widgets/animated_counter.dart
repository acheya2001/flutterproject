import 'package:flutter/material.dart';

/// 🔢 Widget de compteur animé
class AnimatedCounter extends StatefulWidget {
  final int value;
  final TextStyle? style;
  final Duration duration;
  final String prefix;
  final String suffix;
  final Curve curve;

  const AnimatedCounter({
    Key? key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 1500),
    this.prefix = '',
    this.suffix = '',
    this.curve = Curves.easeOutCubic,
  }) : super(key: key);

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.value.toDouble(),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: widget.curve,
    ));
    _animationController.forward();
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value;
      _animation = Tween<double>(
        begin: _previousValue.toDouble(),
        end: widget.value.toDouble(),
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: widget.curve,
      ));
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          '${widget.prefix}${_animation.value.round()}${widget.suffix}',
          style: widget.style ?? const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    );
  }
}

/// 💰 Compteur animé pour les montants
class AnimatedCurrencyCounter extends StatefulWidget {
  final double value;
  final TextStyle? style;
  final Duration duration;
  final String currency;
  final int decimalPlaces;
  final Curve curve;

  const AnimatedCurrencyCounter({
    Key? key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 1500),
    this.currency = 'TND',
    this.decimalPlaces = 2,
    this.curve = Curves.easeOutCubic,
  }) : super(key: key);

  @override
  State<AnimatedCurrencyCounter> createState() => _AnimatedCurrencyCounterState();
}

class _AnimatedCurrencyCounterState extends State<AnimatedCurrencyCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  double _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.value,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: widget.curve,
    ));
    _animationController.forward();
  }

  @override
  void didUpdateWidget(AnimatedCurrencyCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value;
      _animation = Tween<double>(
        begin: _previousValue,
        end: widget.value,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: widget.curve,
      ));
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatCurrency(double value) {
    return '${value.toStringAsFixed(widget.decimalPlaces)} ${widget.currency}';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          _formatCurrency(_animation.value),
          style: widget.style ?? const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    );
  }
}

/// 📊 Compteur animé avec pourcentage
class AnimatedPercentageCounter extends StatefulWidget {
  final double value;
  final TextStyle? style;
  final Duration duration;
  final int decimalPlaces;
  final Curve curve;
  final Color? color;

  const AnimatedPercentageCounter({
    Key? key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 1500),
    this.decimalPlaces = 1,
    this.curve = Curves.easeOutCubic,
    this.color,
  }) : super(key: key);

  @override
  State<AnimatedPercentageCounter> createState() => _AnimatedPercentageCounterState();
}

class _AnimatedPercentageCounterState extends State<AnimatedPercentageCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  double _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.value,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: widget.curve,
    ));
    _animationController.forward();
  }

  @override
  void didUpdateWidget(AnimatedPercentageCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value;
      _animation = Tween<double>(
        begin: _previousValue,
        end: widget.value,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: widget.curve,
      ));
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getColor(double value) {
    if (widget.color != null) return widget.color!;
    
    if (value >= 80) return Colors.green;
    if (value >= 60) return Colors.orange;
    if (value >= 40) return Colors.yellow.shade700;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final currentValue = _animation.value;
        final color = _getColor(currentValue);
        
        return Text(
          '${currentValue.toStringAsFixed(widget.decimalPlaces)}%',
          style: widget.style?.copyWith(color: color) ?? TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        );
      },
    );
  }
}

/// ⏱️ Compteur animé avec durée
class AnimatedDurationCounter extends StatefulWidget {
  final Duration value;
  final TextStyle? style;
  final Duration animationDuration;
  final Curve curve;
  final bool showDays;
  final bool showHours;
  final bool showMinutes;
  final bool showSeconds;

  const AnimatedDurationCounter({
    Key? key,
    required this.value,
    this.style,
    this.animationDuration = const Duration(milliseconds: 1500),
    this.curve = Curves.easeOutCubic,
    this.showDays = true,
    this.showHours = true,
    this.showMinutes = true,
    this.showSeconds = false,
  }) : super(key: key);

  @override
  State<AnimatedDurationCounter> createState() => _AnimatedDurationCounterState();
}

class _AnimatedDurationCounterState extends State<AnimatedDurationCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  Duration _previousValue = Duration.zero;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.value.inSeconds.toDouble(),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: widget.curve,
    ));
    _animationController.forward();
  }

  @override
  void didUpdateWidget(AnimatedDurationCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value;
      _animation = Tween<double>(
        begin: _previousValue.inSeconds.toDouble(),
        end: widget.value.inSeconds.toDouble(),
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: widget.curve,
      ));
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    final parts = <String>[];

    if (widget.showDays && days > 0) {
      parts.add('${days}j');
    }
    if (widget.showHours && hours > 0) {
      parts.add('${hours}h');
    }
    if (widget.showMinutes && minutes > 0) {
      parts.add('${minutes}m');
    }
    if (widget.showSeconds && seconds > 0) {
      parts.add('${seconds}s');
    }

    return parts.isEmpty ? '0' : parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final currentDuration = Duration(seconds: _animation.value.round());
        return Text(
          _formatDuration(currentDuration),
          style: widget.style ?? const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    );
  }
}
