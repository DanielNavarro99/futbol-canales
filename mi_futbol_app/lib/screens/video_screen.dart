import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoScreen extends StatefulWidget {
  final String streamUrl;
  final String title;

  const VideoScreen({
    super.key,
    required this.streamUrl,
    required this.title,
  });

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen>
    with WidgetsBindingObserver {
  late final Player player;
  late final VideoController controller;
  static const _pipChannel = MethodChannel('mi_futbol_app/pip');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    player = Player();
    controller = VideoController(player);

    player.open(Media(
      widget.streamUrl,
      httpHeaders: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Referer': 'https://latamvidz1.com/',
        'Origin': 'https://latamvidz1.com',
      },
    ));

    // Fuerza máxima calidad disponible
    player.stream.tracks.listen((tracks) {
      if (tracks.video.length > 1) {
        final mejor = tracks.video.reduce((a, b) {
          final altA = a.h ?? 0;
          final altB = b.h ?? 0;
          return altA >= altB ? a : b;
        });
        player.setVideoTrack(mejor);
        print('🎬 Track elegido: ${mejor.w}x${mejor.h}');
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _activarPip();
    }
  }

  Future<void> _activarPip() async {
    try {
      await _pipChannel.invokeMethod('enterPip');
    } catch (e) {
      print('PiP no disponible: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    player.dispose();
    super.dispose();
  }

  Future<void> _castToTV() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF111811),
        title: const Text('📺 Ver en TV',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Para ver en tu TCL Google TV:',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 12),
            _instruccion('1', 'Desliza el panel de notificaciones'),
            _instruccion('2', 'Toca "Smart View" o "Cast"'),
            _instruccion('3', 'Selecciona tu TV TCL'),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: widget.streamUrl));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Link copiado'),
                    backgroundColor: Color(0xFF00ff6a),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0a0f0a),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF1e2e1e)),
                ),
                child: Text(
                  widget.streamUrl.length > 50
                      ? '${widget.streamUrl.substring(0, 50)}...'
                      : widget.streamUrl,
                  style: const TextStyle(
                      color: Color(0xFF00ff6a),
                      fontSize: 10,
                      fontFamily: 'monospace'),
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Text('Toca para copiar el link',
                style: TextStyle(color: Color(0xFF5a7a5a), fontSize: 11)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar',
                style: TextStyle(color: Color(0xFF00ff6a))),
          ),
        ],
      ),
    );
  }

  Widget _instruccion(String num, String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFF00ff6a),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(num,
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(texto,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: Video(controller: controller)),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.picture_in_picture_alt,
                        color: Color(0xFF00ff6a), size: 26),
                    onPressed: _activarPip,
                    tooltip: 'Mini pantalla',
                  ),
                  IconButton(
                    icon: const Icon(Icons.cast,
                        color: Color(0xFF00ff6a), size: 26),
                    onPressed: _castToTV,
                    tooltip: 'Ver en TV',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
