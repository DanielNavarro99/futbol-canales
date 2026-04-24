import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/stream_hunter.dart';
import 'video_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _loading = false;
  bool _loadingCanales = true;
  String _loadingMsg = '';
  List<Map<String, dynamic>> canales = [];

  late AnimationController _pulseController;
  late AnimationController _bgController;
  late Animation<double> _pulseAnim;
  late Animation<double> _bgAnim;

  // 🔗 URL del JSON en GitHub
  final String jsonUrl =
      'https://raw.githubusercontent.com/DanielNavarro99/futbol-canales/main/canales.json';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _bgAnim = Tween<double>(begin: 0, end: 1).animate(_bgController);

    _cargarCanales();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  Future<void> _cargarCanales() async {
    setState(() => _loadingCanales = true);
    try {
      final response = await http.get(
        Uri.parse(jsonUrl),
        headers: {'User-Agent': 'Mozilla/5.0', 'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          canales = data.cast<Map<String, dynamic>>();
          _loadingCanales = false;
        });
      }
    } catch (e) {
      setState(() => _loadingCanales = false);
    }
  }

  Future<void> _mostrarFuentes(Map<String, dynamic> canal) async {
    final fuentes = canal['fuentes'] as List<dynamic>;
    if (fuentes.length == 1) {
      _abrirStream(canal['nombre'], fuentes[0]['url']);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0d1a0d),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: Color(0xFF00ff6a), width: 1)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00ff6a),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(canal['emoji'] ?? '📺',
                      style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        canal['nombre'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        '${fuentes.length} fuentes disponibles',
                        style: const TextStyle(
                            color: Color(0xFF00ff6a), fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...fuentes.asMap().entries.map((entry) {
                final i = entry.key;
                final fuente = entry.value;
                final isFirst = i == 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _abrirStream(canal['nombre'], fuente['url']);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: isFirst
                            ? const LinearGradient(colors: [
                                Color(0xFF003d1a),
                                Color(0xFF001a0d)
                              ])
                            : null,
                        color: isFirst ? null : const Color(0xFF111811),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isFirst
                              ? const Color(0xFF00ff6a)
                              : const Color(0xFF1e2e1e),
                          width: isFirst ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isFirst
                                  ? const Color(0xFF00ff6a)
                                  : const Color(0xFF1e2e1e),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                  color: isFirst
                                      ? Colors.black
                                      : const Color(0xFF5a7a5a),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              fuente['label'],
                              style: TextStyle(
                                color: isFirst
                                    ? Colors.white
                                    : const Color(0xFFa0c0a0),
                                fontSize: 14,
                                fontWeight: isFirst
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (isFirst)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00ff6a),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'HD',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _abrirStream(String nombre, String url) async {
    setState(() {
      _loading = true;
      _loadingMsg = nombre;
    });

    final streamUrl = await StreamHunter().hunt(url);
    setState(() => _loading = false);

    if (!mounted) return;

    if (streamUrl != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoScreen(streamUrl: streamUrl, title: nombre),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sin señal en $nombre — prueba otra fuente'),
          backgroundColor: Colors.red[900],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050a05),
      body: Stack(
        children: [
          Positioned.fill(child: _buildFondo()),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _loadingCanales
                      ? _buildLoadingState()
                      : canales.isEmpty
                          ? _buildEmptyState()
                          : _buildGrid(),
                ),
              ],
            ),
          ),
          if (_loading) _buildSabuesoOverlay(),
        ],
      ),
    );
  }

  Widget _buildFondo() {
    return AnimatedBuilder(
      animation: _bgAnim,
      builder: (context, child) {
        return CustomPaint(painter: _CampoPainter(_bgAnim.value));
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          ScaleTransition(
            scale: _pulseAnim,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00ff6a),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00ff6a).withOpacity(0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Center(
                  child: Text('⚽', style: TextStyle(fontSize: 22))),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MI FÚTBOL DANS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              Text(
                '${canales.length} canales en vivo',
                style: const TextStyle(
                    color: Color(0xFF00ff6a), fontSize: 11, letterSpacing: 1),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: _cargarCanales,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF111811),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1e2e1e)),
              ),
              child: const Icon(Icons.refresh,
                  color: Color(0xFF00ff6a), size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return RefreshIndicator(
      color: const Color(0xFF00ff6a),
      backgroundColor: const Color(0xFF111811),
      onRefresh: _cargarCanales,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GridView.builder(
          itemCount: canales.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, index) {
            final canal = canales[index];
            final fuentes = canal['fuentes'] as List<dynamic>? ?? [];
            return _buildCanalCard(canal, fuentes, index);
          },
        ),
      ),
    );
  }

  Widget _buildCanalCard(
      Map<String, dynamic> canal, List<dynamic> fuentes, int index) {
    return GestureDetector(
      onTap: _loading ? null : () => _mostrarFuentes(canal),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 300 + (index * 80)),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.scale(scale: value, child: child);
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1a2e1a), Color(0xFF0d160d)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2a3e2a), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -10,
                right: -10,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00ff6a).withOpacity(0.05),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(canal['emoji'] ?? '📺',
                        style: const TextStyle(fontSize: 38)),
                    const SizedBox(height: 10),
                    Text(
                      canal['nombre'] ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00ff6a),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'EN VIVO',
                          style: TextStyle(
                            color: Color(0xFF00ff6a),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${fuentes.length} fuentes',
                          style: const TextStyle(
                              color: Color(0xFF5a7a5a), fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _pulseAnim,
            child: const Text('⚽', style: TextStyle(fontSize: 48)),
          ),
          const SizedBox(height: 16),
          const CircularProgressIndicator(color: Color(0xFF00ff6a)),
          const SizedBox(height: 16),
          const Text('Cargando canales...',
              style: TextStyle(color: Color(0xFF5a7a5a), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📡', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text('Sin señal',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Revisa tu conexión a internet',
              style: TextStyle(color: Color(0xFF5a7a5a), fontSize: 14)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _cargarCanales,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF00ff6a),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Reintentar',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSabuesoOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _pulseAnim,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00ff6a).withOpacity(0.1),
                  border:
                      Border.all(color: const Color(0xFF00ff6a), width: 2),
                ),
                child:
                    const Center(child: Text('🐕', style: TextStyle(fontSize: 36))),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _loadingMsg,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'El Sabueso está rastreando el stream...',
              style: TextStyle(color: Color(0xFF5a7a5a), fontSize: 13),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                color: Color(0xFF00ff6a),
                backgroundColor: Color(0xFF1e2e1e),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CampoPainter extends CustomPainter {
  final double t;
  _CampoPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke;
    final w = size.width;
    final h = size.height;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFF050a05),
    );

    final grad = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.2,
        colors: [
          const Color(0xFF0a1f0a).withOpacity(0.8 + 0.2 * t),
          const Color(0xFF050a05),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), grad);

    paint.color = const Color(0xFF1a2e1a).withOpacity(0.4);
    paint.strokeWidth = 1;

    canvas.drawLine(Offset(0, h / 2), Offset(w, h / 2), paint);
    canvas.drawCircle(Offset(w / 2, h / 2), 80 + 10 * t, paint);
    canvas.drawCircle(Offset(w / 2, h / 2), 4,
        Paint()..color = const Color(0xFF1a2e1a).withOpacity(0.4));
    canvas.drawRect(Rect.fromLTWH(w * 0.2, 0, w * 0.6, h * 0.2), paint);
    canvas.drawRect(
        Rect.fromLTWH(w * 0.2, h * 0.8, w * 0.6, h * 0.2), paint);
    canvas.drawArc(
        Rect.fromCenter(center: Offset(w / 2, h * 0.2), width: 100, height: 60),
        0, pi, false, paint);
    canvas.drawArc(
        Rect.fromCenter(center: Offset(w / 2, h * 0.8), width: 100, height: 60),
        pi, pi, false, paint);

    paint.color = const Color(0xFF0f1f0f).withOpacity(0.3);
    paint.strokeWidth = 40;
    for (int i = -2; i < 8; i++) {
      final x = w * i / 4;
      canvas.drawLine(Offset(x - h, 0), Offset(x, h), paint);
    }
  }

  @override
  bool shouldRepaint(_CampoPainter old) => old.t != t;
}
