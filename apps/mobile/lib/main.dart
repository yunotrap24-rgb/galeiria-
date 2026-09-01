import 'package:flutter/material.dart';
import 'package:galeiria_client/galeiria_client.dart';

void main() => runApp(const GaleiriaMobileApp());

class GaleiriaMobileApp extends StatelessWidget {
  const GaleiriaMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Galeiria',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark, colorSchemeSeed: Colors.indigo),
      home: const MobileGalleryPage(),
    );
  }
}

class MobileGalleryPage extends StatefulWidget {
  const MobileGalleryPage({super.key});

  @override
  State<MobileGalleryPage> createState() => _MobileGalleryPageState();
}

class _MobileGalleryPageState extends State<MobileGalleryPage> {
  final _serverController = TextEditingController(text: 'http://192.168.1.100:8765');
  GaleiriaClient? _client;
  List<Map<String, dynamic>> _photos = const [];
  Map<String, dynamic>? _stats;
  String _status = 'Informe o IP do PC na rede Wi-Fi.';
  bool _loading = false;

  GaleiriaClient _getClient() {
    final url = _serverController.text.trim();
    if (_client == null || _client!.baseUrl != url) {
      _client?.close();
      _client = GaleiriaClient(baseUrl: url);
    }
    return _client!;
  }

  @override
  void dispose() {
    _client?.close();
    _serverController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    setState(() {
      _loading = true;
      _status = 'Conectando ao PC...';
    });
    try {
      final client = _getClient();
      final health = await client.health();
      final results = await Future.wait([client.stats(), client.photos(limit: 120)]);
      if (!mounted) return;
      setState(() {
        _stats = results[0] as Map<String, dynamic>;
        _photos = results[1] as List<Map<String, dynamic>>;
        _status = 'PC conectado • API ${health['version'] ?? ''}';
      });
    } catch (error) {
      if (mounted) setState(() => _status = 'Não foi possível conectar: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Galeiria')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _serverController,
                        decoration: const InputDecoration(
                          labelText: 'PC Galeiria',
                          hintText: 'http://192.168.1.10:8765',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.url,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _loading ? null : _connect,
                      child: _loading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Conectar'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerLeft, child: Text(_status)),
                if (_stats != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('${_stats!['photos']} fotos • ${_stats!['exact_duplicate_groups']} grupos duplicados'),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _photos.isEmpty
                ? const Center(child: Text('A galeria do PC aparecerá aqui.'))
                : GridView.builder(
                    padding: const EdgeInsets.all(4),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                    ),
                    itemCount: _photos.length,
                    itemBuilder: (context, index) {
                      final photo = _photos[index];
                      final id = photo['id'] as int;
                      return Hero(
                        tag: 'photo-$id',
                        child: Material(
                          clipBehavior: Clip.antiAlias,
                          borderRadius: BorderRadius.circular(6),
                          child: InkWell(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PhotoPage(client: _getClient(), photo: photo),
                              ),
                            ),
                            child: Image.network(
                              _getClient().thumbnailUrl(id),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black12, child: Icon(Icons.broken_image)),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.photo_library_outlined), selectedIcon: Icon(Icons.photo_library), label: 'Galeria'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Pesquisar'),
          NavigationDestination(icon: Icon(Icons.folder_outlined), label: 'Projetos'),
          NavigationDestination(icon: Icon(Icons.sync), label: 'Sync'),
        ],
      ),
    );
  }
}

class PhotoPage extends StatelessWidget {
  const PhotoPage({super.key, required this.client, required this.photo});

  final GaleiriaClient client;
  final Map<String, dynamic> photo;

  @override
  Widget build(BuildContext context) {
    final id = photo['id'] as int;
    return Scaffold(
      appBar: AppBar(title: Text(photo['filename']?.toString() ?? 'Foto')),
      body: Center(
        child: Hero(
          tag: 'photo-$id',
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 6,
            child: Image.network(client.fileUrl(id), fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
