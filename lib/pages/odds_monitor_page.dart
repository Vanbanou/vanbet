import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MonitorItem {
  String id;
  String name;
  String selector;
  String url;
  String currentValue;
  DateTime lastUpdated;

  MonitorItem({
    required this.id,
    required this.name,
    required this.selector,
    required this.url,
    this.currentValue = '...',
    required this.lastUpdated,
  });
}

class OddsMonitorPage extends StatefulWidget {
  const OddsMonitorPage({super.key});

  @override
  _OddsMonitorPageState createState() => _OddsMonitorPageState();
}

class _OddsMonitorPageState extends State<OddsMonitorPage> {
  late final WebViewController _controller;
  final List<MonitorItem> _monitoredItems = [];
  final TextEditingController _urlController = TextEditingController();

  int _currentIndex = 0; // 0: Browser, 1: Dashboard
  bool _isLoading = false;
  bool _isMonitorMode = false;
  Timer? _monitorTimer;

  // Default URL
  String currentUrl = 'https://m.bantubet.co.ao';

  @override
  void initState() {
    super.initState();
    _urlController.text = currentUrl;
    _initializeController();
    _startMonitoring();
  }

  @override
  void dispose() {
    _monitorTimer?.cancel();
    super.dispose();
  }

  void _initializeController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FlutterMonitor',
        onMessageReceived: (JavaScriptMessage message) {
          // Parse the message from JavaScript
          try {
            final data = jsonDecode(message.message);
            _showAddMonitorDialog(
              selector: data['selector'],
              text: data['text'],
            );
          } catch (e) {
            debugPrint('Error parsing message: $e');
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _isLoading = true;
              currentUrl = url;
              _urlController.text = url;
            });
          },
          onPageFinished: (url) {
            setState(() {
              _isLoading = false;
            });
            // Re-inject script if monitor mode is active
            if (_isMonitorMode) {
              _injectClickListener();
            }
          },
          onNavigationRequest: (request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(currentUrl));
  }

  void _startMonitoring() {
    _monitorTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_monitoredItems.isEmpty) return;

      for (var item in _monitoredItems) {
        try {
          final result = await _controller.runJavaScriptReturningResult(
            "document.querySelector('${item.selector}').innerText",
          );

          if (result is String) {
            String cleanResult = result.replaceAll('"', '');
            if (cleanResult != 'null' && cleanResult.isNotEmpty) {
              setState(() {
                item.currentValue = cleanResult;
                item.lastUpdated = DateTime.now();
              });
            }
          }
        } catch (e) {
          // Element not found or other error
        }
      }
    });
  }

  void _navigate() {
    final url = _urlController.text;
    if (url.isNotEmpty) {
      _controller.loadRequest(
        Uri.parse(url.startsWith('http') ? url : 'https://$url'),
      );
      FocusScope.of(context).unfocus();
    }
  }

  void _toggleMonitorMode() {
    setState(() {
      _isMonitorMode = !_isMonitorMode;
    });

    if (_isMonitorMode) {
      _injectClickListener();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Modo Monitor ativado. Clique em um elemento.'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      _removeClickListener();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Modo Monitor desativado.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _injectClickListener() {
    _controller.runJavaScript('''
      (function() {
        // Remove previous listener if exists
        if (window.__flutterClickHandler) {
          document.removeEventListener('click', window.__flutterClickHandler, true);
        }

        // Create new handler
        window.__flutterClickHandler = function(e) {
          e.preventDefault();
          e.stopPropagation();
          
          var element = e.target;
          var selector = '';
          
          // Generate CSS selector
          if (element.id) {
            selector = '#' + element.id;
          } else if (element.className) {
            var classes = element.className.split(' ').filter(function(c) { return c; });
            if (classes.length > 0) {
              selector = '.' + classes.join('.');
            }
          }
          
          // Fallback to tag name
          if (!selector) {
            selector = element.tagName.toLowerCase();
          }
          
          // Get text content
          var text = element.innerText || element.textContent || '';
          text = text.trim().substring(0, 50); // Limit to 50 chars
          
          // Send to Flutter
          FlutterMonitor.postMessage(JSON.stringify({
            selector: selector,
            text: text
          }));
        };
        
        // Add listener
        document.addEventListener('click', window.__flutterClickHandler, true);
      })();
    ''');
  }

  void _removeClickListener() {
    _controller.runJavaScript('''
      (function() {
        if (window.__flutterClickHandler) {
          document.removeEventListener('click', window.__flutterClickHandler, true);
          delete window.__flutterClickHandler;
        }
      })();
    ''');
  }

  void _showAddMonitorDialog({String? selector, String? text}) {
    final nameController = TextEditingController();
    final selectorController = TextEditingController(text: selector ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Adicionar Monitor"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (text != null && text.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Texto: "$text"',
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Nome (ex: Vitória Time A)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: selectorController,
              decoration: const InputDecoration(
                labelText: "Seletor CSS (ex: .odd-value)",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  selectorController.text.isNotEmpty) {
                setState(() {
                  _monitoredItems.add(
                    MonitorItem(
                      id: DateTime.now().toString(),
                      name: nameController.text,
                      selector: selectorController.text,
                      url: currentUrl,
                      lastUpdated: DateTime.now(),
                    ),
                  );
                  // Auto-disable monitor mode after adding
                  _isMonitorMode = false;
                  _removeClickListener();
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Monitor adicionado com sucesso!"),
                  ),
                );
              }
            },
            child: const Text("Adicionar"),
          ),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    // Check if we can go back in browser
    if (_currentIndex == 0 && await _controller.canGoBack()) {
      _controller.goBack();
      return false;
    }

    // Show exit confirmation
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sair"),
        content: const Text("Tem certeza que deseja sair do Monitor de Odds?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Sair"),
          ),
        ],
      ),
    );

    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Monitor de Odds'),
          elevation: 0,
          actions: _currentIndex == 0
              ? [
                  IconButton(
                    icon: Icon(
                      Icons.touch_app,
                      color: _isMonitorMode ? Colors.green : null,
                    ),
                    onPressed: _toggleMonitorMode,
                    tooltip: _isMonitorMode
                        ? "Desativar Modo Monitor"
                        : "Ativar Modo Monitor",
                  ),
                  const SizedBox(width: 8),
                ]
              : null,
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            // Index 0: Browser View
            Column(
              children: [
                // URL Bar
                Container(
                  padding: const EdgeInsets.all(8.0),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _urlController,
                          decoration: InputDecoration(
                            hintText: "Digite a URL",
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 0,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade200,
                            prefixIcon: const Icon(
                              Icons.lock,
                              size: 16,
                              color: Colors.grey,
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.arrow_forward),
                              onPressed: _navigate,
                            ),
                          ),
                          onSubmitted: (_) => _navigate(),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isLoading) const LinearProgressIndicator(minHeight: 2),
                Expanded(child: WebViewWidget(controller: _controller)),
              ],
            ),

            // Index 1: Dashboard View
            _monitoredItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Nenhum monitor ativo",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => setState(() => _currentIndex = 0),
                          child: const Text("Ir para o Navegador"),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _monitoredItems.length,
                    itemBuilder: (context, index) {
                      final item = _monitoredItems[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _monitoredItems.removeAt(index);
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Valor Atual",
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        item.currentValue,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text(
                                        "Última atualização",
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        "${item.lastUpdated.hour}:${item.lastUpdated.minute}:${item.lastUpdated.second}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Seletor: ${item.selector}",
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.public),
              label: "Navegador",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: "Dashboard",
            ),
          ],
        ),
        floatingActionButton: _currentIndex == 0 && !_isMonitorMode
            ? FloatingActionButton(
                onPressed: () => _showAddMonitorDialog(),
                tooltip: "Adicionar Monitor Manualmente",
                child: const Icon(Icons.add_chart),
              )
            : null,
      ),
    );
  }
}
