// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';

import '../enhancer/enhancement_backend.dart';
import '../enhancer/enhancement_screen.dart';
import '../models/pdf_source.dart';
import '../settings/app_settings.dart';

class PdfViewerScreen extends StatefulWidget {
  const PdfViewerScreen({
    required this.source,
    required this.settings,
    super.key,
  });

  final PdfSource source;
  final AppSettingsController settings;

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late final PdfDocumentRef _documentRef = widget.source.createDocumentRef();
  final PdfViewerController _controller = PdfViewerController();
  late final PdfTextSearcher _textSearcher = PdfTextSearcher(_controller);
  final TextEditingController _pageInput = TextEditingController(text: '1');
  final TextEditingController _searchInput = TextEditingController();
  final EnhancementBackend _enhancementBackend = createEnhancementBackend();

  Timer? _searchTimer;
  int _currentPage = 1;
  int _pageCount = 0;
  bool _viewerReady = false;
  bool _searchVisible = false;
  int? _scrubPreviewPage;
  List<PdfOutlineNode> _outline = const [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_syncCurrentPage);
    _textSearcher.addListener(_syncSearch);
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _controller.removeListener(_syncCurrentPage);
    _textSearcher.removeListener(_syncSearch);
    _textSearcher.dispose();
    _pageInput.dispose();
    _searchInput.dispose();
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

  void _syncSearch() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _onViewerReady(
    PdfDocument document,
    PdfViewerController controller,
  ) async {
    final outline = await document.loadOutline();
    if (!mounted) {
      return;
    }

    final page = controller.pageNumber ?? 1;
    setState(() {
      _viewerReady = true;
      _pageCount = document.pages.length;
      _currentPage = page;
      _pageInput.text = page.toString();
      _outline = outline;
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

  void _queueSearch(String query) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 180), () {
      final normalized = query.trim();
      if (normalized.isEmpty) {
        _textSearcher.resetTextSearch();
      } else {
        _textSearcher.startTextSearch(
          normalized,
          caseInsensitive: true,
          goToFirstMatch: true,
        );
      }
    });
  }

  void _toggleSearch() {
    setState(() {
      _searchVisible = !_searchVisible;
      if (!_searchVisible) {
        _searchInput.clear();
        _textSearcher.resetTextSearch();
      }
    });
  }

  Future<void> _copyPageReference() async {
    await Clipboard.setData(
      ClipboardData(text: widget.source.pageReference(_currentPage)),
    );

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Page link copied')),
    );
  }

  Future<void> _sharePage() async {
    final text = widget.source.pageReference(_currentPage);
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        title: widget.source.displayName,
      ),
    );
  }

  Future<void> _enhanceCurrentPdf() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EnhancementScreen(
          source: widget.source,
          backend: _enhancementBackend,
        ),
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) => PdfViewerScreen(
          source: result.source,
          settings: widget.settings,
        ),
      ),
    );
  }

  Future<void> _showOutline() async {
    if (_outline.isEmpty) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.35,
          maxChildSize: 0.94,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Text(
                    'Sections',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                _OutlineNodes(
                  nodes: _outline,
                  onOpen: (node) async {
                    Navigator.of(context).pop();
                    await _controller.goToDest(node.dest);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget viewer = PdfViewer(
      _documentRef,
      controller: _controller,
      params: PdfViewerParams(
        backgroundColor: theme.colorScheme.surfaceContainerLowest,
        margin: 8,
        onViewerReady: _onViewerReady,
        pagePaintCallbacks: [
          _textSearcher.pageTextMatchPaintCallback,
        ],
        verticalCacheExtent: 1.5,
      ),
    );

    if (theme.brightness == Brightness.dark) {
      viewer = ColorFiltered(
        colorFilter: const ColorFilter.mode(
          Colors.white,
          BlendMode.difference,
        ),
        child: viewer,
      );
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 4,
        title: Text(
          widget.source.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_outline.isNotEmpty)
            IconButton(
              onPressed: _showOutline,
              tooltip: 'Sections',
              icon: const Icon(Icons.segment_rounded),
            ),
          IconButton(
            onPressed: _viewerReady ? _toggleSearch : null,
            tooltip: 'Search',
            icon: Icon(
              _searchVisible ? Icons.search_off_rounded : Icons.search_rounded,
            ),
          ),
          PopupMenuButton<_ViewerAction>(
            tooltip: 'More tools',
            onSelected: (action) async {
              switch (action) {
                case _ViewerAction.enhance:
                  await _enhanceCurrentPdf();
                  break;
                case _ViewerAction.zoomOut:
                  await _controller.zoomDown();
                  break;
                case _ViewerAction.zoomIn:
                  await _controller.zoomUp();
                  break;
                case _ViewerAction.copyPage:
                  await _copyPageReference();
                  break;
                case _ViewerAction.sharePage:
                  await _sharePage();
                  break;
                case _ViewerAction.toggleTheme:
                  await widget.settings.toggleTheme(theme.brightness);
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _ViewerAction.enhance,
                child: ListTile(
                  leading: const Icon(Icons.auto_fix_high_rounded),
                  title: const Text('Enhance PDF'),
                  subtitle: Text(
                    _enhancementBackend.available
                        ? 'OCR missing text and add structure'
                        : (_enhancementBackend.unavailableReason ??
                            'Unavailable on this platform'),
                  ),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: _ViewerAction.zoomOut,
                child: ListTile(
                  leading: Icon(Icons.zoom_out_rounded),
                  title: Text('Zoom out'),
                ),
              ),
              const PopupMenuItem(
                value: _ViewerAction.zoomIn,
                child: ListTile(
                  leading: Icon(Icons.zoom_in_rounded),
                  title: Text('Zoom in'),
                ),
              ),
              const PopupMenuItem(
                value: _ViewerAction.copyPage,
                child: ListTile(
                  leading: Icon(Icons.link_rounded),
                  title: Text('Copy page link'),
                ),
              ),
              const PopupMenuItem(
                value: _ViewerAction.sharePage,
                child: ListTile(
                  leading: Icon(Icons.ios_share_rounded),
                  title: Text('Share page'),
                ),
              ),
              PopupMenuItem(
                value: _ViewerAction.toggleTheme,
                child: ListTile(
                  leading: Icon(
                    theme.brightness == Brightness.dark
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                  ),
                  title: Text(
                    theme.brightness == Brightness.dark
                        ? 'Use light mode'
                        : 'Use dark mode',
                  ),
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
          if (_searchVisible)
            _SearchToolbar(
              controller: _searchInput,
              searcher: _textSearcher,
              onChanged: _queueSearch,
            ),
          Expanded(child: viewer),
        ],
      ),
      bottomNavigationBar: _viewerReady && _pageCount > 1
          ? _DocumentScrubber(
              page: _scrubPreviewPage ?? _currentPage,
              pageCount: _pageCount,
              onChanged: (page) {
                setState(() => _scrubPreviewPage = page);
              },
              onChangeEnd: (page) async {
                setState(() => _scrubPreviewPage = null);
                await _goToPage(page);
              },
            )
          : null,
    );
  }
}

class _DocumentScrubber extends StatelessWidget {
  const _DocumentScrubber({
    required this.page,
    required this.pageCount,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final int page;
  final int pageCount;
  final ValueChanged<int> onChanged;
  final ValueChanged<int> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      elevation: 3,
      color: theme.colorScheme.surface,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(12, 2, 12, 4),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: Text(
                '$page',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium,
              ),
            ),
            Expanded(
              child: Semantics(
                label: 'Page scrubber',
                value: 'Page $page of $pageCount',
                child: Slider(
                  min: 1,
                  max: pageCount.toDouble(),
                  value: page.clamp(1, pageCount).toDouble(),
                  label: '$page',
                  onChanged: (value) => onChanged(value.round()),
                  onChangeEnd: (value) => onChangeEnd(value.round()),
                ),
              ),
            ),
            SizedBox(
              width: 44,
              child: Text(
                '$pageCount',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ViewerAction {
  enhance,
  zoomOut,
  zoomIn,
  copyPage,
  sharePage,
  toggleTheme,
}

class _SearchToolbar extends StatelessWidget {
  const _SearchToolbar({
    required this.controller,
    required this.searcher,
    required this.onChanged,
  });

  final TextEditingController controller;
  final PdfTextSearcher searcher;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final current = searcher.currentIndex;
    final total = searcher.matches.length;
    final resultText = total == 0
        ? (searcher.isSearching ? '…' : '0')
        : '${(current ?? 0) + 1}/$total';

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onChanged: onChanged,
                  decoration: const InputDecoration(
                    hintText: 'Search PDF',
                    isDense: true,
                    prefixIcon: Icon(Icons.search_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 56,
                child: Text(
                  resultText,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              IconButton(
                tooltip: 'Previous match',
                onPressed:
                    searcher.hasMatches ? searcher.goToPrevMatch : null,
                icon: const Icon(Icons.keyboard_arrow_up_rounded),
              ),
              IconButton(
                tooltip: 'Next match',
                onPressed:
                    searcher.hasMatches ? searcher.goToNextMatch : null,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutlineNodes extends StatelessWidget {
  const _OutlineNodes({
    required this.nodes,
    required this.onOpen,
  });

  final List<PdfOutlineNode> nodes;
  final ValueChanged<PdfOutlineNode> onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final node in nodes)
          if (node.children.isEmpty)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              title: Text(node.title),
              enabled: node.dest != null,
              onTap: node.dest == null ? null : () => onOpen(node),
            )
          else
            ExpansionTile(
              title: Text(node.title),
              leading: node.dest == null
                  ? null
                  : IconButton(
                      tooltip: 'Open section',
                      onPressed: () => onOpen(node),
                      icon: const Icon(Icons.arrow_forward_rounded),
                    ),
              childrenPadding: const EdgeInsets.only(left: 16),
              children: [
                _OutlineNodes(
                  nodes: node.children,
                  onOpen: onOpen,
                ),
              ],
            ),
      ],
    );
  }
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
