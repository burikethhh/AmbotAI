import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AmbotErrorBoundary extends StatefulWidget {
  final Widget child;

  const AmbotErrorBoundary({super.key, required this.child});

  @override
  State<AmbotErrorBoundary> createState() => _AmbotErrorBoundaryState();
}

class _AmbotErrorBoundaryState extends State<AmbotErrorBoundary> {
  FlutterErrorDetails? _error;

  @override
  void initState() {
    super.initState();
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      if (mounted) {
        setState(() => _error = details);
      }
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      if (mounted) {
        setState(() {
          _error = FlutterErrorDetails(
            exception: error,
            stack: stack,
          );
        });
      }
      return true;
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'SOMETHING WENT WRONG',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!.exception.toString().replaceFirst('Exception: ', ''),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _error = null);
                    },
                    child: const Text('TAP TO RETRY'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return widget.child;
  }
}
