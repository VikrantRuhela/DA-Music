import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/providers/backend_providers.dart';
import '../../../../shared/providers/library_providers.dart';

class CookieLoginDialog extends ConsumerStatefulWidget {
  const CookieLoginDialog({super.key});

  @override
  ConsumerState<CookieLoginDialog> createState() => _CookieLoginDialogState();
}

class _CookieLoginDialogState extends ConsumerState<CookieLoginDialog> {
  final TextEditingController _cookieController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _cookieController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final cookies = _cookieController.text.trim();
    if (cookies.isEmpty) {
      setState(() {
        _errorMessage = 'Please paste your cookie header value.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final accountService = ref.read(ytAccountServiceProvider);
    final bool success = await accountService.login(cookies);

    if (success) {
      ref.read(libraryManagerProvider).syncWithYouTubeMusic(accountService);
      if (mounted) {
        context.pop(); // Close dialog
        context.go('/'); // Route to home feed
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid cookie header. Please verify the steps and try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.daColors;
    final typography = context.daTypography;

    return Dialog(
      backgroundColor: colors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DATokens.radiusLarge),
      ),
      child: Container(
        width: 480.0,
        padding: const EdgeInsets.all(DATokens.spacingLarge),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Connect YouTube Music',
                style: typography.title.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0,
                ),
              ),
              const SizedBox(height: DATokens.spacingMedium),

              Text(
                'To login natively, follow these quick steps in your web browser:',
                style: typography.body.copyWith(
                  color: colors.textSecondary,
                  fontSize: 14.0,
                ),
              ),
              const SizedBox(height: DATokens.spacingSmall),

              _buildStep(context, '1', 'Go to music.youtube.com in Chrome/Firefox.'),
              _buildStep(context, '2', 'Sign in to your Google Account.'),
              _buildStep(context, '3', 'Press F12 to open Developer Tools, and navigate to the Network tab.'),
              _buildStep(context, '4', 'Refresh the page, click any request, and find the "cookie:" request header.'),
              _buildStep(context, '5', 'Copy the value of the cookie header and paste it below.'),
              const SizedBox(height: DATokens.spacingLarge),

              TextField(
                controller: _cookieController,
                maxLines: 4,
                style: typography.body.copyWith(fontSize: 13.0, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  hintText: 'Paste cookie string here (e.g. HSID=xxx; SSID=xxx; ...)',
                  hintStyle: typography.caption.copyWith(color: colors.textSecondary.withValues(alpha: 0.5)),
                  filled: true,
                  fillColor: colors.surfaceHover,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DATokens.radiusMedium),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DATokens.radiusMedium),
                    borderSide: BorderSide(color: colors.primary),
                  ),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: DATokens.spacingSmall),
                Text(
                  _errorMessage!,
                  style: typography.caption.copyWith(color: Colors.redAccent),
                ),
              ],

              const SizedBox(height: DATokens.spacingLarge),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => context.pop(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: DATokens.spacingMedium),
                  SizedBox(
                    height: 40.0,
                    width: 100.0,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(DATokens.radiusSmall),
                        ),
                      ),
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20.0,
                              height: 20.0,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                              ),
                            )
                          : const Text(
                              'Connect',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context, String index, String description) {
    final colors = context.daColors;
    final typography = context.daTypography;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20.0,
            height: 20.0,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Text(
              index,
              style: TextStyle(
                fontSize: 11.0,
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
            ),
          ),
          const SizedBox(width: DATokens.spacingSmall),
          Expanded(
            child: Text(
              description,
              style: typography.caption.copyWith(
                color: colors.textPrimary.withValues(alpha: 0.85),
                fontSize: 13.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
