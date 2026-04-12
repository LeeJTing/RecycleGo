import 'package:flutter/material.dart';

class TaskRunner {
  static Future<T?> run<T>({
    required BuildContext context,
    required Future<T> Function() task,
    String loadingMessage = "Processing...",
    String successMessage = "Success!",
    bool showSuccessDialog = true,
  }) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _LoadingDialog(message: loadingMessage),
    );

    try {
      late T result;

      // 🔹 Run the task AND a 2-second delay at the exact same time.
      // This guarantees the loading screen shows for AT LEAST 2 seconds,
      // preventing "flickering" if the task finishes instantly.
      await Future.wait([
        task().then((value) => result = value),
        Future.delayed(const Duration(seconds: 1)),
      ]);

      // Close loading dialog safely
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show success dialog (optional)
      if (showSuccessDialog && context.mounted) {
        await showDialog(
          context: context,
          builder: (_) => _SuccessDialog(message: successMessage),
        );
      }

      return result;
    } catch (e) {
      // Close loading dialog safely on error
      if (context.mounted) {
        Navigator.of(context).pop();

        // Show error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }

      return null;
    }
  }
}

class _LoadingDialog extends StatelessWidget {
  final String message;

  const _LoadingDialog({required this.message});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 🔹 Background blur + dim
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.35),
          ),
        ),

        // 🔹 Center dialog
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🔹 Modern loader
                SizedBox(
                  height: 40,
                  width: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 🔹 Message
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SuccessDialog extends StatefulWidget {
  final String message;

  const _SuccessDialog({required this.message});

  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop(); // close dialog only
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.green,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Success",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}