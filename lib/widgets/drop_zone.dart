import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'dart:io';

class FileDropArea extends StatefulWidget {
  final List<String> allowedExtensions;
  final void Function(String filePath) onFileSelected;
  final String title;
  final String subtitle;
  final IconData icon;
  final double height;
  final String? currentFilePath;
  final VoidCallback? onClear;
  final FileType fileType;

  const FileDropArea({
    super.key,
    required this.allowedExtensions,
    required this.onFileSelected,
    this.title = 'فایل را انتخاب کنید',
    this.subtitle = 'کلیک کنید یا فایل را بکشید',
    this.icon = Icons.upload_file,
    this.height = 150,
    this.currentFilePath,
    this.onClear,
    this.fileType = FileType.custom,
  });

  @override
  State<FileDropArea> createState() => _FileDropAreaState();
}

class _FileDropAreaState extends State<FileDropArea> {
  bool _isHovering = false;
  bool _isDragging = false;

  bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  @override
  Widget build(BuildContext context) {
    if (widget.currentFilePath != null && widget.currentFilePath!.isNotEmpty) {
      return _buildPreview();
    }

    if (!_isDesktop) {
      return _buildClickableArea();
    }

    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: (details) {
        setState(() => _isDragging = false);
        if (details.files.isNotEmpty) {
          final filePath = details.files.first.path;
          if (_isValidFile(filePath)) {
            widget.onFileSelected(filePath);
          } else {
            _showInvalidFileSnackBar();
          }
        }
      },
      child: _buildClickableArea(),
    );
  }

  Widget _buildClickableArea() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: _pickFile,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: widget.height,
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: _isDragging
                  ? Theme.of(context).colorScheme.primary
                  : _isHovering
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                  : Theme.of(context).dividerColor,
              width: _isDragging
                  ? 3
                  : _isHovering
                  ? 2
                  : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            color: _isDragging
                ? Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withOpacity(0.4)
                : _isHovering
                ? Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withOpacity(0.2)
                : Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isDragging ? Icons.file_download : widget.icon,
                size: _isDragging ? 56 : 48,
                color: _isDragging || _isHovering
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 12),
              Text(
                _isDragging ? 'فایل را اینجا رها کنید' : widget.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _isDragging || _isHovering
                      ? Theme.of(context).colorScheme.primary
                      : null,
                  fontWeight: _isDragging ? FontWeight.bold : null,
                ),
              ),
              if (!_isDragging) ...[
                const SizedBox(height: 4),
                Text(
                  widget.subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'فرمت‌های مجاز: ${widget.allowedExtensions.join(', ')}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: 11),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final isImage = _isImageFile(widget.currentFilePath!);

    Widget content = Container(
      height: widget.height,
      decoration: BoxDecoration(
        border: Border.all(
          color: _isDragging
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).dividerColor,
          width: _isDragging ? 3 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          if (isImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.file(
                File(widget.currentFilePath!),
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) => _buildFileInfo(),
              ),
            )
          else
            _buildFileInfo(),
          if (_isDragging)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.file_download,
                      size: 56,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'فایل جدید را رها کنید',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (!_isDragging)
            Positioned(
              top: 8,
              left: 8,
              child: Row(
                children: [
                  _buildActionButton(Icons.edit, _pickFile),
                  if (widget.onClear != null) ...[
                    const SizedBox(width: 4),
                    _buildActionButton(
                      Icons.close,
                      widget.onClear!,
                      isDestructive: true,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );

    if (_isDesktop) {
      return DropTarget(
        onDragEntered: (_) => setState(() => _isDragging = true),
        onDragExited: (_) => setState(() => _isDragging = false),
        onDragDone: (details) {
          setState(() => _isDragging = false);
          if (details.files.isNotEmpty) {
            final filePath = details.files.first.path;
            if (_isValidFile(filePath)) {
              widget.onFileSelected(filePath);
            } else {
              _showInvalidFileSnackBar();
            }
          }
        },
        child: content,
      );
    }

    return content;
  }

  Widget _buildFileInfo() {
    final fileName = widget.currentFilePath!.split(Platform.pathSeparator).last;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getFileIcon(widget.currentFilePath!),
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              fileName,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    VoidCallback onPressed, {
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 18,
            color: isDestructive ? Colors.red.shade300 : Colors.white,
          ),
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: widget.fileType,
        allowedExtensions: widget.fileType == FileType.custom
            ? widget.allowedExtensions
            : null,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        widget.onFileSelected(result.files.single.path!);
      }
    } catch (e) {
      // خطا را نادیده بگیر
    }
  }

  bool _isValidFile(String path) {
    final ext = path.toLowerCase().split('.').last;
    return widget.allowedExtensions.any(
      (allowed) => allowed.toLowerCase() == ext,
    );
  }

  void _showInvalidFileSnackBar() {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          'فرمت فایل نامعتبر است. فرمت‌های مجاز: ${widget.allowedExtensions.join(', ')}',
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool _isImageFile(String path) {
    final ext = path.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext);
  }

  IconData _getFileIcon(String path) {
    final ext = path.toLowerCase().split('.').last;
    return switch (ext) {
      'xlsx' || 'xls' => Icons.table_chart,
      'csv' => Icons.description,
      'pdf' => Icons.picture_as_pdf,
      _ => _isImageFile(path) ? Icons.image : Icons.insert_drive_file,
    };
  }
}
