import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/document_gen/document_gen_service.dart';
import '../../core/document_gen/smart_formatter.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_typography.dart';
import '../../shared/theme/theme_colors.dart';
import '../../shared/theme/app_spacing.dart';
import '../../shared/widgets/app_card.dart';
import 'widgets/document_guide.dart';
import 'widgets/document_stats_bar.dart';
import 'widgets/editor_body.dart';
import 'widgets/editor_toolbar.dart';
import 'widgets/formatting_toggle.dart';

class DocumentGenScreen extends ConsumerStatefulWidget {
  const DocumentGenScreen({super.key});

  @override
  ConsumerState<DocumentGenScreen> createState() => _DocumentGenScreenState();
}

class _DocumentGenScreenState extends ConsumerState<DocumentGenScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isAiProcessing = false;
  String _aiStage = '';
  double _aiProgress = 0.0;
  String? _pdfPath;
  String? _docxPath;
  String? _error;
  double _lineSpacing = 1.5;
  TextAlign _textAlign = TextAlign.left;
  double _fontSize = 14;
  bool _showGuide = false;
  bool _showPreview = false;
  String _aiTone = 'professional';
  Timer? _draftTimer;

  static const _draftKey = 'draft_content';
  static const _draftTitleKey = 'draft_title';

  final _guideSections = [
    GuideSection(
      title: 'FORMATTING BASICS',
      icon: Icons.format_bold,
      items: [
        '**Bold** - highlight important words',
        '*Italic* - emphasize or mark titles',
        '<u>Underline</u> - underscore key points',
      ],
    ),
    GuideSection(
      title: 'HEADINGS & STRUCTURE',
      icon: Icons.title,
      items: [
        '# Heading 1 - main title (largest)',
        '## Heading 2 - section title',
        '### Heading 3 - subsection title',
        'Leave blank lines between sections for clarity',
      ],
    ),
    GuideSection(
      title: 'LISTS',
      icon: Icons.format_list_bulleted,
      items: [
        '- Bullet list - items without order',
        '1. Numbered list - step-by-step',
        'Indent with 2 spaces for nested lists',
      ],
    ),
    GuideSection(
      title: 'AI FORMAT ASSIST',
      icon: Icons.auto_fix_high,
      items: [
        'Tap the green AI FORMAT button to auto-format',
        'Choose tone: Professional, Casual, or Academic',
        'AI fixes grammar, adds headings, organizes structure',
        'Works best with 3+ sentences of content',
      ],
    ),
    GuideSection(
      title: 'EXPORT',
      icon: Icons.save_alt,
      items: [
        'Tap EXPORT PDF for a professional PDF file',
        'Tap EXPORT DOCX for an editable document',
        'Exported files appear in My Files (top-right)',
        'Markdown formatting is preserved in exports',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadDraft();
    _contentController.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    _titleController.dispose();
    _contentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onContentChanged() {
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(seconds: 3), _saveDraft);
    setState(() {});
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_draftKey, _contentController.text);
    await prefs.setString(_draftTitleKey, _titleController.text);
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final content = prefs.getString(_draftKey) ?? '';
    final title = prefs.getString(_draftTitleKey) ?? '';
    if (content.isNotEmpty || title.isNotEmpty) {
      _titleController.text = title;
      _contentController.text = content;
    }
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
    await prefs.remove(_draftTitleKey);
  }

  void _wrapSelection(String prefix, String suffix) {
    final text = _contentController.text;
    final sel = _contentController.selection;
    if (!sel.isValid || sel.isCollapsed) {
      final pos = sel.isValid ? sel.start : text.length;
      final newText = '${text.substring(0, pos)}$prefix$suffix${text.substring(pos)}';
      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: pos + prefix.length),
      );
      return;
    }
    final selected = text.substring(sel.start, sel.end);
    final newText = '${text.substring(0, sel.start)}$prefix$selected$suffix${text.substring(sel.end)}';
    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection(baseOffset: sel.start, extentOffset: sel.start + prefix.length + selected.length + suffix.length),
    );
  }

  void _insertLinePrefix(String prefix) {
    final text = _contentController.text;
    final sel = _contentController.selection;
    final pos = sel.isValid ? sel.start : text.length;
    final lineStart = text.lastIndexOf('\n', pos - 1) + 1;
    final newText = '${text.substring(0, lineStart)}$prefix ${text.substring(lineStart)}';
    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: pos + prefix.length + 1),
    );
  }

  void _onBold() => _wrapSelection('**', '**');
  void _onItalic() => _wrapSelection('*', '*');
  void _onUnderline() => _wrapSelection('<u>', '</u>');
  void _onHeading1() => _insertLinePrefix('#');
  void _onHeading2() => _insertLinePrefix('##');
  void _onHeading3() => _insertLinePrefix('###');
  void _onBullet() => _insertLinePrefix('-');
  void _onNumbered() => _insertLinePrefix('1.');

  Future<void> _onAiAssist() async {
    final text = _contentController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isAiProcessing = true;
      _error = null;
      _aiProgress = 0.0;
      _aiStage = 'Smart formatting...';
    });

    // Pass 1: Instant smart formatting (no LLM needed)
    final formatted = SmartFormatter.format(text, tone: _aiTone);
    _contentController.text = formatted;

    if (!mounted) return;

    // Only do LLM grammar polish for shorter texts (under 2000 chars)
    // and skip if user already has well-formatted text (detect by seeing markdown)
    final hasMarkdown = formatted.contains('#') || formatted.contains('**') || formatted.contains('- ');
    final isShort = formatted.length < 2000;

    if (hasMarkdown || !isShort) {
      // Already has structure or too long — skip LLM pass
      if (mounted) {
        setState(() {
          _isAiProcessing = false;
          _aiStage = '';
          _aiProgress = 0.0;
        });
      }
      _saveDraft();
      return;
    }

    // Pass 2: LLM grammar polish (optional enhancement, with fast timeout)
    setState(() {
      _aiStage = 'Grammar polish...';
      _aiProgress = 0.4;
    });

    try {
      final engine = ref.read(aiEngineProvider);
      final polished = await engine.generate(
        'Fix grammar only. Keep all formatting intact.\n\n$formatted',
        systemPrompt: 'Output ONLY the text with fixed grammar.',
      ).timeout(const Duration(seconds: 60));

      if (mounted && polished.trim().isNotEmpty) {
        _contentController.text = polished.trim();
      }
    } catch (_) {
      // Smart format already applied — LLM polish is optional, so ignore failure
    } finally {
      if (mounted) {
        setState(() {
          _isAiProcessing = false;
          _aiStage = '';
          _aiProgress = 0.0;
        });
      }
      _saveDraft();
    }
  }

  String _buildExportContent() {
    final content = _contentController.text;
    final alignTag = _textAlign == TextAlign.left ? '' : '<align:${_textAlign.name}>';
    final spacingTag = _lineSpacing != 1.5 ? '<spacing:${_lineSpacing.toStringAsFixed(1)}x>' : '';
    return '$alignTag$spacingTag\n$content';
  }

  Future<void> _exportPdf() async {
    final title = _titleController.text.trim().isEmpty ? 'Untitled' : _titleController.text.trim();
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      setState(() => _error = 'No content to export');
      return;
    }

    try {
      final doc = await DocumentGenService.instance.generateFromResponse(
        title: title,
        aiResponse: _buildExportContent(),
      );
      final path = await DocumentGenService.instance.exportToPdf(doc);
      if (mounted) {
        setState(() {
          _pdfPath = path;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) { setState(() => _error = 'PDF export failed: $e'); }
    }
  }

  Future<void> _exportDocx() async {
    final title = _titleController.text.trim().isEmpty ? 'Untitled' : _titleController.text.trim();
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      setState(() => _error = 'No content to export');
      return;
    }

    try {
      final doc = await DocumentGenService.instance.generateFromResponse(
        title: title,
        aiResponse: _buildExportContent(),
      );
      final path = await DocumentGenService.instance.exportToDocx(doc);
      if (mounted) {
        setState(() {
          _docxPath = path;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) { setState(() => _error = 'DOCX export failed: $e'); }
    }
  }

  int _wordCount(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  int _paragraphCount(String text) {
    if (text.trim().isEmpty) return 0;
    return text.split(RegExp(r'\n\s*\n')).where((p) => p.trim().isNotEmpty).length;
  }

  int _lineCount(String text) {
    if (text.isEmpty) return 0;
    return '\n'.allMatches(text).length + 1;
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(themeColorsProvider);

    final wordCount = _wordCount(_contentController.text);
    final charCount = _contentController.text.length;
    final paraCount = _paragraphCount(_contentController.text);
    final lineCount = _lineCount(_contentController.text);
    final hasDraft = _contentController.text.isNotEmpty || _titleController.text.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textPrimary),
          onPressed: () {
            _saveDraft();
            Navigator.pop(context);
          },
        ),
        title: Text('DOCUMENTS', style: AppTypography.headlineMedium(c.textPrimary)),
        actions: [
          if (hasDraft)
            IconButton(
              icon: Icon(Icons.delete_sweep_outlined, color: AppColors.danger, size: 18),
              onPressed: () async {
                await _clearDraft();
                _titleController.clear();
                _contentController.clear();
                setState(() {});
              },
              tooltip: 'Clear draft',
            ),
          IconButton(
            icon: Icon(Icons.folder_outlined, color: c.textPrimary),
            onPressed: () => context.pushNamed('generatedFiles'),
            tooltip: 'My Files',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title field
                  AppCard(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      controller: _titleController,
                      style: AppTypography.bodyLarge(c.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Enter your document title here...',
                        hintStyle: AppTypography.bodyLarge(c.textTertiary),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onChanged: (_) => _onContentChanged(),
                    ),
                  ),
                  AppSpacing.h8,

                  EditorToolbar(
                    c: c,
                    lineSpacing: _lineSpacing,
                    fontSize: _fontSize,
                    textAlign: _textAlign,
                    onLineSpacingChanged: (v) => setState(() => _lineSpacing = v),
                    onFontSizeChanged: (v) => setState(() => _fontSize = v),
                    onTextAlignChanged: (v) => setState(() => _textAlign = v),
                    onBold: _onBold,
                    onItalic: _onItalic,
                    onUnderline: _onUnderline,
                    onHeading1: _onHeading1,
                    onHeading2: _onHeading2,
                    onHeading3: _onHeading3,
                    onBullet: _onBullet,
                    onNumbered: _onNumbered,
                  ),
                  AppSpacing.h8,

                  FormattingToggle(
                    c: c,
                    aiTone: _aiTone,
                    isAiProcessing: _isAiProcessing,
                    hasDraft: hasDraft,
                    showPreview: _showPreview,
                    onAiToneChanged: (v) => setState(() => _aiTone = v),
                    onAiAssist: _onAiAssist,
                    onTogglePreview: () => setState(() => _showPreview = !_showPreview),
                  ),
                  AppSpacing.h12,

                  EditorBody(
                    c: c,
                    contentController: _contentController,
                    focusNode: _focusNode,
                    fontSize: _fontSize,
                    lineSpacing: _lineSpacing,
                    textAlign: _textAlign,
                    showPreview: _showPreview,
                  ),
                  AppSpacing.h8,

                  DocumentStatsBar(
                    c: c,
                    wordCount: wordCount,
                    charCount: charCount,
                    lineCount: lineCount,
                    paraCount: paraCount,
                  ),
                  AppSpacing.h12,

                  // Error
                  if (_error != null)
                    AppCard(
                      padding: const EdgeInsets.all(12),
                      borderColor: AppColors.danger,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, size: 14, color: AppColors.danger),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_error!, style: AppTypography.bodySmall(AppColors.danger))),
                        ],
                      ),
                    ),

                  // Export buttons - using theme buttons instead of custom containers
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _exportPdf,
                          icon: const Icon(Icons.picture_as_pdf, size: 16),
                          label: const Text('EXPORT PDF'),
                        ),
                      ),
                      AppSpacing.w12,
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _exportDocx,
                          icon: const Icon(Icons.description_outlined, size: 16),
                          label: const Text('EXPORT DOCX'),
                        ),
                      ),
                    ],
                  ),

                  // Success paths
                  if (_pdfPath != null || _docxPath != null) ...[
                    AppSpacing.h12,
                    AppCard(
                      padding: const EdgeInsets.all(12),
                      borderColor: c.accent,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle, size: 14, color: c.accent),
                              const SizedBox(width: 6),
                              Text('EXPORTED SUCCESSFULLY', style: AppTypography.labelSmall(c.accent)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if (_pdfPath != null)
                            Text('PDF: ${_pdfPath!.split(Platform.pathSeparator).last}',
                                style: AppTypography.bodySmall(c.textTertiary)),
                          if (_docxPath != null)
                            Text('DOCX: ${_docxPath!.split(Platform.pathSeparator).last}',
                                style: AppTypography.bodySmall(c.textTertiary)),
                        ],
                      ),
                    ),
                  ],

                  AppSpacing.h16,

                  DocumentGuide(
                    c: c,
                    showGuide: _showGuide,
                    onToggleGuide: () => setState(() => _showGuide = !_showGuide),
                    sections: _guideSections,
                  ),

                  AppSpacing.h16,
                ],
              ),
            ),
          ),

          // AI Processing indicator with stage/progress
          if (_isAiProcessing)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.borderColor, width: 2)),
                color: c.cardColor,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, value: _aiProgress > 0 ? _aiProgress : null),
                  ),
                  const SizedBox(width: 10),
                  Text(_aiStage.isNotEmpty ? _aiStage : 'AI is formatting your document...',
                      style: AppTypography.bodySmall(c.textSecondary)),
                  if (_aiProgress > 0) ...[
                    const Spacer(),
                    Text('${(_aiProgress * 100).toStringAsFixed(0)}%', style: AppTypography.bodySmall(c.textTertiary)),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
