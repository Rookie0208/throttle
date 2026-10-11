import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Global Navigation Key to allow showing dialogs and banners without context
class AppNavigation {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static BuildContext? get currentContext => navigatorKey.currentContext;
}

enum FeedbackType { info, success, warning, error }

/// Clean, modern feedback utility that replaces low-level debug SnackBars.
/// Provides top floating banners and dialogs with smooth micro-animations.
class AppFeedback {
  static OverlayEntry? _currentOverlay;
  static Timer? _dismissTimer;

  /// Sanitizes raw error strings so normal users never see technical jargon
  /// like "JWT expired", "Token expired", "SocketException", or 500 status codes.
  static String sanitizeErrorMessage(dynamic error, {String? defaultMessage}) {
    if (error == null) {
      return defaultMessage ?? "Something went wrong. Please try again.";
    }

    final raw = error.toString().trim();
    final lower = raw.toLowerCase();

    // Session / Token expired
    if (lower.contains("token") ||
        lower.contains("jwt") ||
        lower.contains("unauthorized") ||
        lower.contains("401")) {
      return "Your session has expired. Please sign in again.";
    }

    // Network / Connectivity
    if (lower.contains("socketexception") ||
        lower.contains("connection refused") ||
        lower.contains("network is unreachable") ||
        lower.contains("failed host lookup") ||
        lower.contains("clientexception")) {
      return "Unable to connect. Please check your internet connection.";
    }

    // Timeouts
    if (lower.contains("timeoutexception") || lower.contains("timed out")) {
      return "Request timed out. Please try again in a moment.";
    }

    // Internal Server Error
    if (lower.contains("500") || lower.contains("internal server error")) {
      return "Our servers ran into a hiccup. Please try again shortly.";
    }

    // Clean up "Exception: " prefix if present
    if (raw.startsWith("Exception: ")) {
      final stripped = raw.substring(11).trim();
      if (stripped.isNotEmpty) return stripped;
    }

    return raw.isNotEmpty
        ? raw
        : (defaultMessage ?? "Something went wrong. Please try again.");
  }

  /// Displays an elegant floating notification pill at the top of the screen
  static void showFloatingBanner({
    BuildContext? context,
    required String message,
    FeedbackType type = FeedbackType.error,
    Duration duration = const Duration(seconds: 4),
  }) {
    final ctx = context ?? AppNavigation.currentContext;
    if (ctx == null) return;

    final overlay = Overlay.maybeOf(ctx);
    if (overlay == null) return;

    _dismissTimer?.cancel();
    _currentOverlay?.remove();
    _currentOverlay = null;

    final sanitized = sanitizeErrorMessage(message);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _FloatingBannerWidget(
        message: sanitized,
        type: type,
        onDismiss: () {
          _dismissTimer?.cancel();
          entry.remove();
          if (_currentOverlay == entry) _currentOverlay = null;
        },
      ),
    );

    _currentOverlay = entry;
    overlay.insert(entry);

    _dismissTimer = Timer(duration, () {
      if (_currentOverlay == entry) {
        entry.remove();
        _currentOverlay = null;
      }
    });
  }

  /// Shorthand methods
  static void showError(String message, {BuildContext? context}) {
    showFloatingBanner(
      context: context,
      message: message,
      type: FeedbackType.error,
    );
  }

  static void showSuccess(String message, {BuildContext? context}) {
    showFloatingBanner(
      context: context,
      message: message,
      type: FeedbackType.success,
    );
  }

  static void showWarning(String message, {BuildContext? context}) {
    showFloatingBanner(
      context: context,
      message: message,
      type: FeedbackType.warning,
    );
  }

  static void showInfo(String message, {BuildContext? context}) {
    showFloatingBanner(
      context: context,
      message: message,
      type: FeedbackType.info,
    );
  }

  /// User-friendly modal sheet when the session has naturally expired
  static bool _isSessionDialogShowing = false;

  static Future<void> showSessionExpiredModal(
    VoidCallback onConfirmLogin,
  ) async {
    final ctx = AppNavigation.currentContext;
    if (ctx == null || _isSessionDialogShowing) return;

    _isSessionDialogShowing = true;

    try {
      await showModalBottomSheet(
        context: ctx,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (dialogCtx) {
          final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
          final bgColor = isDark
              ? const Color(0xFF1E212B)
              : const Color(0xFFFFFFFF);
          final textColor = isDark ? Colors.white : const Color(0xFF111827);
          final subTextColor = isDark
              ? const Color(0xFF9CA3AF)
              : const Color(0xFF6B7280);

          return SafeArea(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_clock_rounded,
                      color: Color(0xFFF59E0B),
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Session Expired",
                    style: GoogleFonts.lexend(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "For your security, your session has ended. Please sign in again to continue your journey.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lexend(
                      fontSize: 14,
                      color: subTextColor,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogCtx).pop();
                        onConfirmLogin();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5722),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        "Sign In Again",
                        style: GoogleFonts.lexend(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } finally {
      _isSessionDialogShowing = false;
    }
  }
}

class _FloatingBannerWidget extends StatefulWidget {
  final String message;
  final FeedbackType type;
  final VoidCallback onDismiss;

  const _FloatingBannerWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<_FloatingBannerWidget> createState() => _FloatingBannerWidgetState();
}

class _FloatingBannerWidgetState extends State<_FloatingBannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<Offset> _offsetAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _offsetAnim = Tween<Offset>(
      begin: const Offset(0, -0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Color _getBgColor() {
    switch (widget.type) {
      case FeedbackType.error:
        return const Color(0xFF1E1719);
      case FeedbackType.success:
        return const Color(0xFF14241B);
      case FeedbackType.warning:
        return const Color(0xFF2B2114);
      case FeedbackType.info:
        return const Color(0xFF161F2E);
    }
  }

  Color _getAccentColor() {
    switch (widget.type) {
      case FeedbackType.error:
        return const Color(0xFFFF4D4F);
      case FeedbackType.success:
        return const Color(0xFF22C55E);
      case FeedbackType.warning:
        return const Color(0xFFF59E0B);
      case FeedbackType.info:
        return const Color(0xFF3B82F6);
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case FeedbackType.error:
        return Icons.error_outline_rounded;
      case FeedbackType.success:
        return Icons.check_circle_outline_rounded;
      case FeedbackType.warning:
        return Icons.warning_amber_rounded;
      case FeedbackType.info:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _getAccentColor();
    final bg = _getBgColor();

    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _offsetAnim,
          child: FadeTransition(
            opacity: _fadeAnim,
            child: GestureDetector(
              onTap: widget.onDismiss,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_getIcon(), color: accent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: GoogleFonts.lexend(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: widget.onDismiss,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
