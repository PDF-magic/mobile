// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';

import '../models/pdf_source.dart';

class PdfViewerScreen extends StatefulWidget {
  const PdfViewerScreen({
    required this.source,
    super.key,
  });

  final PdfSource source;

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late final PdfDocumentRef _documentRef = widget.source.createDocumentRef();
  final PdfViewerController _controller = PdfViewerController();
  final TextEditingController _pageInput = TextEditingController(text: '1');

  int _currentPage = 1;
  int _pageCount = 0;
  bool _viewerReady = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_syncCurrentPage);
  }

  @override
  void dispose() {
    _controller.removeListener(_syncCurrentPage);
    _pageInput.dispose();
    super.dispose();
  }

  void _syncCurrentPage() {
    if (!_controller.isReady) {
      return;
    }

    final page = _controller.pageNumber;
    if (page == null || page == _currentPage || !mounted) {
      return;
    }

    setState(() {
      _currentPage = page;
      _pageInput.text = page.toString();
    });
  }

  void _onViewerReady(PdfDocument document, PdfViewerController controller) {
    if (!mounted) {
      return;
    }

    final page = controller.pageNumber ?? 1;
    setState(() {
      _viewerReady = true;
      _pageCount = document.pages.length;
      _currentPage = page;
      _pageInput.text = page.toString();
    });
  }

  Future<void> _goToPage(int pageNumber) async {
    if (!_viewerReady || _pageCount == 0) {
      return;
    }

    final target = pageNumber.clamp(1, _pageCount).toInt();
    await _controller.goToPage(
      pageNumber: target,
      anchor: PdfPageAnchor.topCenter,
    );
  }

  Future<void> _submitPage(String rawValue) async {
    final requested = int.tryParse(rawValue.trim());
    if (requested == null) {
      _pageInput.text = _currentPage.toString();
      return;
    }

    await _goToPage(requested);
    if (mounted) {
      _pageInput.text = _currentPage.toString();
    }
  }

  Future<void> _copyPageReference() async {
    final reference = widget.source.referenceUri;
    final value = reference == null
        ? '${widget.source.displayName}#page=$_currentPage'
        : reference.replace(fragment: 'page=$_currentPage').toString();
    await Clipboard.setData(ClipboardData(text: value));

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Page reference copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewer = PdfViewer(
      _documentRef,
      controller: _controller,
      params: PdfViewerParams(
        backgroundColor: theme.colorScheme.surfaceContainerLowest,
        margin: 8,
        onViewerReady: _onViewerReady,
        verticalCacheExtent: 1.5,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 4,
        title: Text(
          widget.source.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            onPressed: _viewerReady ? _copyPageReference : null,
            tooltip: 'Copy page reference',
            icon: const Icon(Icons.link_rounded),
          ),
          PopupMenuButton<_ViewerAction>(
            tooltip: 'More tools',
            onSelected: (action) async {
              switch (action) {
                case _ViewerAction.zoomOut:
                  await _controller.zoomDown();
                  break;
                case _ViewerAction.zoomIn:
                  await _controller.zoomUp();
                  break;
                case _ViewerAction.copyPage:
                  await _copyPageReference();
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _ViewerAction.zoomOut,
                child: ListTile(
                  leading: Icon(Icons.zoom_out_rounded),
                  title: Text('Zoom out'),
                ),
              ),
              PopupMenuItem(
                value: _ViewerAction.zoomIn,
                child: ListTile(
                  leading: Icon(Icons.zoom_in_rounded),
                  title: Text('Zoom in'),
                ),
              ),
              PopupMenuItem(
                value: _ViewerAction.copyPage,
                child: ListTile(
                  leading: Icon(Icons.link_rounded),
                  title: Text('Copy page reference'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _ReaderToolbar(
            currentPage: _currentPage,
            pageCount: _pageCount,
            pageInput: _pageInput,
            enabled: _viewerReady,
            onPrevious: () => _goToPage(_currentPage - 1),
            onNext: () => _goToPage(_currentPage + 1),
            onSubmitPage: _submitPage,
            onZoomOut: () async {
              await _controller.zoomDown();
            },
            onZoomIn: () async {
              await _controller.zoomUp();
            },
          ),
          Expanded(child: viewer),
        ],
      ),
    );
  }
}

enum _ViewerAction {
  zoomOut,
  zoomIn,
  copyPage,
}

class _ReaderToolbar extends StatelessWidget {
  const _ReaderToolbar({
    required this.currentPage,
    required this.pageCount,
    required this.pageInput,
    required this.enabled,
    required this.onPrevious,
    required this.onNext,
    required this.onSubmitPage,
    required this.onZoomOut,
    required this.onZoomIn,
  });

  final int currentPage;
  final int pageCount;
  final TextEditingController pageInput;
  final bool enabled;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<String> onSubmitPage;
  final VoidCallback onZoomOut;
  final VoidCallback onZoomIn;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surface,
      elevation: 1,
      child: SafeArea(
        top: false,
        bottom: false,
        child: SizedBox(
          height: 52,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 440;

              return Row(
                children: [
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: enabled && currentPage > 1 ? onPrevious : null,
                    tooltip: 'Previous page',
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  SizedBox(
                    width: compact ? 88 : 112,
                    child: Row(
                      children: [
                        SizedBox(
                          width: compact ? 42 : 52,
                          child: TextField(
                            controller: pageInput,
                            enabled: enabled,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            textAlign: TextAlign.end,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            onSubmitted: onSubmitPage,
                          ),
                        ),
                        Text('/ ${pageCount == 0 ? '—' : pageCount}'),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed:
                        enabled && currentPage < pageCount ? onNext : null,
                    tooltip: 'Next page',
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                  const Spacer(),
                  if (!compact) ...[
                    IconButton(
                      onPressed: enabled ? onZoomOut : null,
                      tooltip: 'Zoom out',
                      icon: const Icon(Icons.zoom_out_rounded),
                    ),
                    IconButton(
                      onPressed: enabled ? onZoomIn : null,
                      tooltip: 'Zoom in',
                      icon: const Icon(Icons.zoom_in_rounded),
                    ),
                  ],
                  const SizedBox(width: 4),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
