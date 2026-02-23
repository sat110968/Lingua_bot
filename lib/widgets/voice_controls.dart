import 'package:flutter/material.dart';
import '../theme.dart';

class VoiceControls extends StatefulWidget {
  final VoidCallback onStop;

  const VoiceControls({
    Key? key,
    required this.onStop,
  }) : super(key: key);

  @override
  State<VoiceControls> createState() => _VoiceControlsState();
}

class _VoiceControlsState extends State<VoiceControls> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _barHeightAnimation1;
  late Animation<double> _barHeightAnimation2;
  late Animation<double> _barHeightAnimation3;
  late Animation<double> _barHeightAnimation4;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _barHeightAnimation1 = Tween<double>(begin: 3, end: 15).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeInOut),
      ),
    );

    _barHeightAnimation2 = Tween<double>(begin: 3, end: 22).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.5, curve: Curves.easeInOut),
      ),
    );

    _barHeightAnimation3 = Tween<double>(begin: 3, end: 18).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 0.7, curve: Curves.easeInOut),
      ),
    );

    _barHeightAnimation4 = Tween<double>(begin: 3, end: 12).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.6, 0.9, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Animated sound bars indicating playback
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Row(
                children: [
                  Container(
                    width: 3,
                    height: _barHeightAnimation1.value,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Container(
                    width: 3,
                    height: _barHeightAnimation2.value,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Container(
                    width: 3,
                    height: _barHeightAnimation3.value,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Container(
                    width: 3,
                    height: _barHeightAnimation4.value,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                ],
              );
            },
          ),
          
          const SizedBox(width: 12),
          
          // Playback status text
          Text(
            'Playing tutor voice...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const Spacer(),
          
          // Stop button
          GestureDetector(
            onTap: () {
              widget.onStop();
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.stop,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}