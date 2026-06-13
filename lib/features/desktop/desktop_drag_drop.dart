import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DesktopDragDropHandler extends StatefulWidget {
  final Widget child;
  final Function(List<String> files)? onFilesDropped;

  const DesktopDragDropHandler({
    super.key,
    required this.child,
    this.onFilesDropped,
  });

  @override
  State<DesktopDragDropHandler> createState() => _DesktopDragDropHandlerState();
}

class _DesktopDragDropHandlerState extends State<DesktopDragDropHandler> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) {
        setState(() => _isDragging = true);
        return true;
      },
      onLeave: (data) {
        setState(() => _isDragging = false);
      },
      onAcceptWithDetails: (details) {
        setState(() => _isDragging = false);
        final data = details.data;
        if (data.isNotEmpty) {
          widget.onFilesDropped?.call([data]);
        }
      },
      builder: (context, candidateData, rejectedData) {
        return Stack(
          children: [
            widget.child,
            if (_isDragging)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.7),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.upload_file, size: 48, color: Colors.white),
                          const SizedBox(height: 16),
                          Text(
                            'DROP FILE HERE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Images, documents, or text files',
                            style: TextStyle(color: Colors.grey[400], fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
