import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const CambioApp());

/// Ponto de entrada do MVP. Ele funciona sem Firebase e sem chave da Gemini
/// para que possa ser demonstrado no FlutLab desde o primeiro dia.
class CambioApp extends StatefulWidget {
  const CambioApp({super.key});

  @override
  State<CambioApp> createState() => _CambioAppState();
}

class _CambioAppState extends State<CambioApp> {
  final CambioStore _store = CambioStore.demo();

  @override
  Widget build(BuildContext context) {
    return CambioScope(
      store: _store,
      child: MaterialApp(
        title: 'Escambo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF5B36D6),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF8F7FC),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        home: const SplashPage(),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TELA DE CARREGAMENTO
// Duas "mãos" (pontas coloridas) desenham arcos que se encontram e fecham
// um círculo — assim que a animação completa alguns ciclos, navegamos para
// o AuthGate (login → onboarding → app).
// -----------------------------------------------------------------------------

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
    _scheduleNavigation();
  }

  Future<void> _scheduleNavigation() async {
    await Future.delayed(const Duration(milliseconds: 2400));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthGate()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF5B36D6),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final progress = Curves.easeInOutCubic.transform(
                  _controller.value,
                );
                return SizedBox(
                  width: 150,
                  height: 150,
                  child: CustomPaint(
                    painter: _HandshakeLoaderPainter(progress: progress),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            const Text(
              'Escambo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: .4,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Troque habilidades, não dinheiro',
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

class _HandshakeLoaderPainter extends CustomPainter {
  const _HandshakeLoaderPainter({required this.progress});

  /// 0.0 = mãos totalmente afastadas, 1.0 = círculo completo e mãos unidas.
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 14;

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withOpacity(.18);
    canvas.drawCircle(center, radius, trackPaint);

    final sweep = progress * math.pi; // cada mão "desenha" até meio círculo

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;

    // Mão 1: parte do topo e cresce em sentido horário.
    arcPaint.color = Colors.white;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      arcPaint,
    );

    // Mão 2: parte de baixo e cresce em sentido horário — as duas se
    // encontram exatamente quando progress chega a 1 (círculo fechado).
    arcPaint.color = const Color(0xFFF5A524);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi / 2,
      sweep,
      false,
      arcPaint,
    );

    final tip1Angle = -math.pi / 2 + sweep;
    final tip2Angle = math.pi / 2 + sweep;
    _drawHandTip(canvas, center, radius, tip1Angle, Colors.white);
    _drawHandTip(canvas, center, radius, tip2Angle, const Color(0xFFF5A524));

    if (progress > 0.82) {
      final opacity = ((progress - 0.82) / 0.18).clamp(0.0, 1.0);
      final textPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(Icons.handshake_rounded.codePoint),
          style: TextStyle(
            fontFamily: Icons.handshake_rounded.fontFamily,
            package: Icons.handshake_rounded.fontPackage,
            fontSize: 36,
            color: Colors.white.withOpacity(opacity),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        center - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  void _drawHandTip(
    Canvas canvas,
    Offset center,
    double radius,
    double angle,
    Color color,
  ) {
    final position = center + Offset(math.cos(angle), math.sin(angle)) * radius;
    canvas.drawCircle(position, 7, Paint()..color = color);
    canvas.drawCircle(
      position,
      7,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _HandshakeLoaderPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// -----------------------------------------------------------------------------
// PORTAL DE AUTENTICAÇÃO
// Enquanto o usuário não fizer login, ele só vê a tela de entrada.
// Assim que `CambioStore.signIn` é chamado, este widget reconstrói e libera
// o acesso ao restante do aplicativo (AppShell).
// -----------------------------------------------------------------------------

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final store = CambioScope.of(context);
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        if (!store.isLoggedIn) return const LoginPage();
        if (!store.hasOnboarded) return const OnboardingPage();
        return const AppShell();
      },
    );
  }
}

// -----------------------------------------------------------------------------
// MODELOS E ESTADO (mais tarde, troque CambioStore por um repositório Firebase)
// -----------------------------------------------------------------------------

/// Uma avaliação recebida por um usuário depois de uma troca concluída.
class Review {
  Review({
    required this.id,
    required this.reviewerName,
    required this.stars,
    required this.comment,
    required this.tags,
    required this.createdAt,
  });

  final String id;
  final String reviewerName;
  final int stars; // 1 a 5
  final String comment;
  final List<String> tags;
  final DateTime createdAt;
}

enum ReportReason { spam, badBehavior, scam, other }

extension ReportReasonText on ReportReason {
  String get label => switch (this) {
        ReportReason.spam => 'Spam ou propaganda',
        ReportReason.badBehavior => 'Comportamento inadequado',
        ReportReason.scam => 'Golpe ou fraude',
        ReportReason.other => 'Outro motivo',
      };
}

/// Uma denúncia registrada contra um usuário.
class Report {
  Report({
    required this.id,
    required this.reportedId,
    required this.reportedName,
    required this.reason,
    required this.details,
    required this.createdAt,
  });

  final String id;
  final String reportedId;
  final String reportedName;
  final ReportReason reason;
  final String details;
  final DateTime createdAt;
}

class SkillProfile {
  SkillProfile({
    required this.id,
    required this.name,
    required this.city,
    required this.about,
    required this.offers,
    required this.seeks,
    required this.distanceKm,
    required double rating,
    required this.completedExchanges,
    required this.avatarColor,
    List<Review>? reviews,
  })  : _seedRating = rating,
        reviews = reviews ?? [];

  final String id;
  String name;
  String city;
  String about;
  List<String> offers;
  List<String> seeks;
  final double distanceKm;
  final double _seedRating;
  final List<Review> reviews;
  int completedExchanges;
  final Color avatarColor;

  /// A nota exibida é a média das avaliações reais recebidas. Enquanto o
  /// usuário não tiver nenhuma avaliação detalhada, usamos a nota semente
  /// (útil para os perfis de demonstração).
  double get rating {
    if (reviews.isEmpty) return _seedRating;
    final total = reviews.fold<int>(0, (sum, review) => sum + review.stars);
    return total / reviews.length;
  }
}

class ExchangeProposal {
  ExchangeProposal({
    required this.id,
    required this.from,
    required this.to,
    required this.offer,
    required this.request,
    required this.message,
    this.status = ProposalStatus.pending,
    required this.createdAt,
  });

  final String id;
  final SkillProfile from;
  final SkillProfile to;
  final String offer;
  final String request;
  final String message;
  ProposalStatus status;
  final DateTime createdAt;
}

enum ProposalStatus { pending, accepted, declined }

extension ProposalStatusText on ProposalStatus {
  String get label => switch (this) {
        ProposalStatus.pending => 'Pendente',
        ProposalStatus.accepted => 'Aceita',
        ProposalStatus.declined => 'Recusada',
      };

  Color get color => switch (this) {
        ProposalStatus.pending => const Color(0xFF9A6700),
        ProposalStatus.accepted => const Color(0xFF146C43),
        ProposalStatus.declined => const Color(0xFFB3261E),
      };
}

class MatchResult {
  const MatchResult({
    required this.profile,
    required this.score,
    required this.iCanOffer,
    required this.iNeed,
  });

  final SkillProfile profile;
  final int score;
  final List<String> iCanOffer;
  final List<String> iNeed;
}

class GamificationLevel {
  const GamificationLevel({
    required this.name,
    required this.emoji,
    required this.minimumXp,
    required this.color,
  });

  final String name;
  final String emoji;
  final int minimumXp;
  final Color color;
}

class Achievement {
  const Achievement({
    required this.title,
    required this.description,
    required this.icon,
    required this.unlocked,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool unlocked;
}

class CambioStore extends ChangeNotifier {
  CambioStore.demo()
      : currentUser = SkillProfile(
          id: 'erick',
          name: 'Erick Cauã',
          city: 'Recife, PE',
          about:
              'Estudante de ADS. Gosto de criar soluções bonitas e simples para as pessoas.',
          offers: ['Programação', 'Design'],
          seeks: ['Violão', 'Inglês'],
          distanceKm: 0,
          rating: 4.9,
          completedExchanges: 7,
          avatarColor: const Color(0xFF5B36D6),
        ),
        people = [
          SkillProfile(
            id: 'joao',
            name: 'João Lima',
            city: 'Fortaleza, CE',
            about: 'Fotógrafo de eventos e estudante de audiovisual.',
            offers: ['Fotografia', 'Inglês'],
            seeks: ['Design', 'Flutter'],
            distanceKm: 2.3,
            rating: 4.8,
            completedExchanges: 14,
            avatarColor: const Color(0xFFF07838),
          ),
          SkillProfile(
            id: 'maria',
            name: 'Maria Clara',
            city: 'Fortaleza, CE',
            about:
                'Designer e apaixonada por música. Posso ajudar no seu portfólio.',
            offers: ['Design', 'Violão', 'Fotografia'],
            seeks: ['Edição de vídeo', 'Inglês'],
            distanceKm: 4.1,
            rating: 5.0,
            completedExchanges: 9,
            avatarColor: const Color(0xFFE64C83),
          ),
          SkillProfile(
            id: 'carlos',
            name: 'Carlos Mendes',
            city: 'Caucaia, CE',
            about:
                'Desenvolvedor iniciante e professor de inglês aos fins de semana.',
            offers: ['Inglês', 'Programação'],
            seeks: ['Design', 'Fotografia'],
            distanceKm: 8.6,
            rating: 4.7,
            completedExchanges: 5,
            avatarColor: const Color(0xFF008A92),
          ),
        ];

  final SkillProfile currentUser;
  final List<SkillProfile> people;
  final List<ExchangeProposal> proposals = [];
  double hourBalance = 8.5;
  int xp = 420;
  int _registeredExchanges = 2;
  int _positiveRatings = 1;
  bool isLoggedIn = false;
  String? userEmail;
  bool hasOnboarded = false;
  final Set<String> blockedIds = {};
  final List<Report> reports = [];

  /// Pessoas visíveis nos matches e na busca — usuários bloqueados somem
  /// dos dois lados assim que o bloqueio é registrado.
  List<SkillProfile> get visiblePeople =>
      people.where((person) => !blockedIds.contains(person.id)).toList();

  static const levels = [
    GamificationLevel(
      name: 'Iniciante',
      emoji: '🌱',
      minimumXp: 0,
      color: Color(0xFF6B7280),
    ),
    GamificationLevel(
      name: 'Colaborador',
      emoji: '🔧',
      minimumXp: 150,
      color: Color(0xFF0E7490),
    ),
    GamificationLevel(
      name: 'Especialista',
      emoji: '🚀',
      minimumXp: 350,
      color: Color(0xFF5B36D6),
    ),
    GamificationLevel(
      name: 'Mestre',
      emoji: '💎',
      minimumXp: 650,
      color: Color(0xFF0F766E),
    ),
    GamificationLevel(
      name: 'Lenda',
      emoji: '👑',
      minimumXp: 1000,
      color: Color(0xFFB45309),
    ),
  ];

  int get currentLevelIndex {
    for (var index = levels.length - 1; index >= 0; index--) {
      if (xp >= levels[index].minimumXp) return index;
    }
    return 0;
  }

  GamificationLevel get currentLevel => levels[currentLevelIndex];

  GamificationLevel? get nextLevel => currentLevelIndex < levels.length - 1
      ? levels[currentLevelIndex + 1]
      : null;

  double get levelProgress {
    final next = nextLevel;
    if (next == null) return 1;
    final range = next.minimumXp - currentLevel.minimumXp;
    return ((xp - currentLevel.minimumXp) / range).clamp(0.0, 1.0).toDouble();
  }

  List<Achievement> get achievements => [
        Achievement(
          title: 'Primeira troca',
          description: 'Conclua uma troca de habilidades.',
          icon: Icons.handshake_rounded,
          unlocked: _registeredExchanges >= 1,
        ),
        Achievement(
          title: 'Professor da comunidade',
          description: 'Ensine uma habilidade em 3 trocas.',
          icon: Icons.school_rounded,
          unlocked: _registeredExchanges >= 3,
        ),
        Achievement(
          title: 'Muito recomendado',
          description: 'Receba 3 boas avaliações.',
          icon: Icons.star_rounded,
          unlocked: _positiveRatings >= 3,
        ),
        Achievement(
          title: 'Em evolução',
          description: 'Alcance o nível Especialista.',
          icon: Icons.rocket_launch_rounded,
          unlocked: currentLevelIndex >= 2,
        ),
      ];

  List<MatchResult> findMatches() {
    final results = visiblePeople
        .map((person) {
          final iCanOffer = _intersection(currentUser.offers, person.seeks);
          final iNeed = _intersection(currentUser.seeks, person.offers);
          final wantedFactor = currentUser.seeks.isEmpty
              ? 0.0
              : iNeed.length / currentUser.seeks.length;
          final reciprocalFactor = currentUser.offers.isEmpty
              ? 0.0
              : iCanOffer.length / currentUser.offers.length;
          final proximity = (1 - (person.distanceKm / 25)).clamp(0.0, 1.0);
          final reputation = person.rating / 5;
          final score = (wantedFactor * 45 +
                  reciprocalFactor * 35 +
                  proximity * 12 +
                  reputation * 8)
              .round()
              .clamp(0, 100)
              .toInt();
          return MatchResult(
            profile: person,
            score: score,
            iCanOffer: iCanOffer,
            iNeed: iNeed,
          );
        })
        .where(
          (match) => match.iCanOffer.isNotEmpty && match.iNeed.isNotEmpty,
        )
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return results;
  }

  void updateProfile({
    required String name,
    required String city,
    required String about,
    required List<String> offers,
    required List<String> seeks,
  }) {
    currentUser.name = name.trim();
    currentUser.city = city.trim();
    currentUser.about = about.trim();
    currentUser.offers = offers;
    currentUser.seeks = seeks;
    notifyListeners();
  }

  void sendProposal({
    required SkillProfile to,
    required String offer,
    required String request,
    required String message,
  }) {
    proposals.insert(
      0,
      ExchangeProposal(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        from: currentUser,
        to: to,
        offer: offer,
        request: request,
        message: message,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  /// Usada apenas para cancelar/recusar uma proposta. Concluir uma troca de
  /// verdade passa por [completeExchange], que também registra a avaliação.
  void changeProposalStatus(ExchangeProposal proposal, ProposalStatus status) {
    proposal.status = status;
    notifyListeners();
  }

  /// Conclui a troca e registra a avaliação que o usuário atual deu para a
  /// outra pessoa. É isso que atualiza a nota exibida no perfil dela.
  void completeExchange({
    required ExchangeProposal proposal,
    required Review review,
  }) {
    proposal.status = ProposalStatus.accepted;
    proposal.to.reviews.insert(0, review);
    _registeredExchanges++;
    currentUser.completedExchanges++;
    hourBalance += 1;
    xp += 50; // troca concluída
    xp += 40; // habilidade ensinada
    if (review.stars >= 4) {
      _positiveRatings++;
      xp += 20; // boa avaliação enviada
    }
    if (_registeredExchanges % 3 == 0) xp += 30; // bônus de constância
    notifyListeners();
  }

  void registerPositiveRating() {
    _positiveRatings++;
    xp += 20;
    notifyListeners();
  }

  /// Preenche o card do usuário logo após o primeiro login.
  void completeOnboarding({
    required String name,
    required String city,
    required String about,
    required List<String> offers,
    required List<String> seeks,
  }) {
    currentUser.name = name.trim();
    currentUser.city = city.trim();
    currentUser.about = about.trim();
    currentUser.offers = offers;
    currentUser.seeks = seeks;
    hasOnboarded = true;
    notifyListeners();
  }

  void blockUser(String personId) {
    blockedIds.add(personId);
    notifyListeners();
  }

  void unblockUser(String personId) {
    blockedIds.remove(personId);
    notifyListeners();
  }

  void fileReport({
    required SkillProfile reported,
    required ReportReason reason,
    required String details,
  }) {
    reports.insert(
      0,
      Report(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        reportedId: reported.id,
        reportedName: reported.name,
        reason: reason,
        details: details.trim(),
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void signIn({required String email}) {
    isLoggedIn = true;
    userEmail = email.trim();
    notifyListeners();
  }

  void signOut() {
    isLoggedIn = false;
    userEmail = null;
    notifyListeners();
  }

  static List<String> _intersection(List<String> first, List<String> second) =>
      first.where((item) => second.contains(item)).toList();
}

class CambioScope extends InheritedNotifier<CambioStore> {
  const CambioScope({
    super.key,
    required CambioStore store,
    required super.child,
  }) : super(notifier: store);

  static CambioStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CambioScope>()!.notifier!;
}

// -----------------------------------------------------------------------------
// INTEGRAÇÃO GEMINI
// Para o teste no FlutLab, cole a chave entre as aspas abaixo.
// Em um aplicativo publicado, mova a chamada para uma Cloud Function / backend.
// -----------------------------------------------------------------------------

class GeminiMatchService {
  const GeminiMatchService();

  static const _apiKey = '';
  static const _model = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-3.6-flash',
  );

  bool get isConfigured =>
      _apiKey.isNotEmpty && _apiKey != 'COLE_SUA_CHAVE_AQUI';

  Future<String> explainMatch({
    required SkillProfile me,
    required MatchResult match,
  }) async {
    if (!isConfigured) {
      throw const GeminiConfigurationException();
    }

    final prompt = '''
Você é a IA do aplicativo Escambo, uma plataforma de troca de habilidades sem dinheiro.
Explique em português do Brasil, com no máximo 55 palavras, por que este match é justo.
Não invente informações, não use markdown e fale de modo amigável.

Pessoa 1: ${me.name}
Oferece: ${me.offers.join(', ')}
Procura: ${me.seeks.join(', ')}

Pessoa 2: ${match.profile.name}
Oferece: ${match.profile.offers.join(', ')}
Procura: ${match.profile.seeks.join(', ')}

Troca possível: Pessoa 1 oferece ${match.iCanOffer.join(', ')} e recebe ${match.iNeed.join(', ')}.
Compatibilidade calculada pelo app: ${match.score}%.
''';

    // Endpoint oficial do Gemini REST API: /v1beta/models/{model}:generateContent
    // A chave em query parameter evita bloqueios de preflight em previews Web
    // como o do FlutLab. Para um app publicado, esta chamada deve ir ao backend.
    final endpoint = Uri.https(
      'generativelanguage.googleapis.com',
      '/v1beta/models/$_model:generateContent',
      {'key': _apiKey},
    );
    final response = await http
        .post(
          endpoint,
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt},
                ],
              },
            ],
          }),
        )
        .timeout(const Duration(seconds: 20));

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = body['error'] as Map<String, dynamic>?;
      throw GeminiRequestException(
        response.statusCode,
        (error?['message'] ?? 'A API recusou a solicitação.').toString(),
      );
    }

    final blockReason = body['promptFeedback']?['blockReason'];
    if (blockReason != null) {
      throw GeminiRequestException(
        0,
        'A resposta foi bloqueada pelos filtros de segurança ($blockReason).',
      );
    }

    final text = _readText(body);
    if (text == null || text.trim().isEmpty) {
      throw const GeminiRequestException(
        0,
        'A API respondeu, mas não retornou uma explicação de match.',
      );
    }
    return text.trim();
  }

  /// Formato oficial de resposta do generateContent:
  /// { "candidates": [ { "content": { "parts": [ { "text": "..." } ] } } ] }
  static String? _readText(Map<String, dynamic> body) {
    final candidates = body['candidates'];
    if (candidates is! List || candidates.isEmpty) return null;

    final firstCandidate = candidates.first;
    if (firstCandidate is! Map) return null;
    final content = firstCandidate['content'];
    if (content is! Map) return null;
    final parts = content['parts'];
    if (parts is! List) return null;

    final buffer = StringBuffer();
    for (final part in parts) {
      if (part is Map && part['text'] is String) {
        buffer.write(part['text']);
      }
    }
    return buffer.isEmpty ? null : buffer.toString();
  }
}

class GeminiConfigurationException implements Exception {
  const GeminiConfigurationException();
}

class GeminiRequestException implements Exception {
  const GeminiRequestException(this.statusCode, this.message);
  final int statusCode;
  final String message;
}

// -----------------------------------------------------------------------------
// NAVEGAÇÃO PRINCIPAL
// -----------------------------------------------------------------------------

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

const _navItems = [
  _NavItem(
    icon: Icons.explore_outlined,
    selectedIcon: Icons.explore,
    label: 'Matches',
  ),
  _NavItem(
    icon: Icons.badge_outlined,
    selectedIcon: Icons.badge,
    label: 'Meu card',
  ),
  _NavItem(
    icon: Icons.swap_horiz_outlined,
    selectedIcon: Icons.swap_horiz,
    label: 'Propostas',
  ),
  _NavItem(
    icon: Icons.schedule_outlined,
    selectedIcon: Icons.schedule,
    label: 'Horas',
  ),
  _NavItem(
    icon: Icons.emoji_events_outlined,
    selectedIcon: Icons.emoji_events,
    label: 'Evolução',
  ),
];

/// Acima desta largura (px) trocamos a barra inferior por uma NavigationRail
/// lateral, como convém em telas de computador/tablet.
const _desktopBreakpoint = 900.0;

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final _pages = const [
    MatchesPage(),
    ProfilePage(),
    ProposalsPage(),
    HoursPage(),
    EvolutionPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= _desktopBreakpoint;
        if (!isDesktop) {
          return Scaffold(
            body: SafeArea(child: _pages[_currentIndex]),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) =>
                  setState(() => _currentIndex = index),
              destinations: _navItems
                  .map(
                    (item) => NavigationDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.selectedIcon),
                      label: item.label,
                    ),
                  )
                  .toList(),
            ),
          );
        }

        final extended = constraints.maxWidth >= 1180;
        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                extended: extended,
                minExtendedWidth: 200,
                backgroundColor: Colors.white,
                selectedIndex: _currentIndex,
                onDestinationSelected: (index) =>
                    setState(() => _currentIndex = index),
                leading: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.handshake_rounded,
                        color: Color(0xFF5B36D6),
                        size: 30,
                      ),
                      if (extended) ...[
                        const SizedBox(width: 10),
                        const Text(
                          'Escambo',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                destinations: _navItems
                    .map(
                      (item) => NavigationRailDestination(
                        icon: Icon(item.icon),
                        selectedIcon: Icon(item.selectedIcon),
                        label: Text(item.label),
                      ),
                    )
                    .toList(),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: SafeArea(child: _pages[_currentIndex])),
            ],
          ),
        );
      },
    );
  }
}

/// Centraliza o conteúdo e limita a largura em telas grandes (desktop/web),
/// para o texto e os cards não esticarem de ponta a ponta da janela.
class ResponsiveBody extends StatelessWidget {
  const ResponsiveBody({super.key, required this.child, this.maxWidth = 760});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    required this.title,
    required this.children,
    this.action,
  });
  final String title;
  final List<Widget> children;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBody(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TELA: MATCHES
// -----------------------------------------------------------------------------

enum MatchSortMode { compatibility, distance, rating }

class MatchesPage extends StatefulWidget {
  const MatchesPage({super.key});

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  final _search = TextEditingController();
  final Set<String> _skillFilters = {};
  double _maxDistance = 25;
  MatchSortMode _sort = MatchSortMode.compatibility;
  bool _showFilters = false;

  static const _filterCatalog = [
    'Design',
    'Flutter',
    'Programação',
    'Fotografia',
    'Inglês',
    'Edição de vídeo',
    'Violão',
    'Culinária',
    'Mecânica',
    'Redes sociais',
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<MatchResult> _applyFilters(List<MatchResult> matches) {
    final query = _search.text.trim().toLowerCase();
    final filtered = matches.where((match) {
      final person = match.profile;
      final matchesQuery = query.isEmpty ||
          person.name.toLowerCase().contains(query) ||
          person.offers.any((skill) => skill.toLowerCase().contains(query)) ||
          person.seeks.any((skill) => skill.toLowerCase().contains(query));
      final matchesSkills = _skillFilters.isEmpty ||
          person.offers.any(_skillFilters.contains) ||
          person.seeks.any(_skillFilters.contains);
      final matchesDistance = person.distanceKm <= _maxDistance;
      return matchesQuery && matchesSkills && matchesDistance;
    }).toList();

    switch (_sort) {
      case MatchSortMode.compatibility:
        filtered.sort((a, b) => b.score.compareTo(a.score));
        break;
      case MatchSortMode.distance:
        filtered.sort(
          (a, b) => a.profile.distanceKm.compareTo(b.profile.distanceKm),
        );
        break;
      case MatchSortMode.rating:
        filtered.sort((a, b) => b.profile.rating.compareTo(a.profile.rating));
        break;
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final store = CambioScope.of(context);
    final allMatches = store.findMatches();
    final matches = _applyFilters(allMatches);
    final hasActiveFilters = _skillFilters.isNotEmpty || _maxDistance < 25;

    return PageFrame(
      title: 'Encontre seu match',
      action: IconButton(
        tooltip: 'Filtros',
        onPressed: () => setState(() => _showFilters = !_showFilters),
        icon: Icon(
          hasActiveFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
          color: const Color(0xFF5B36D6),
        ),
      ),
      children: [
        const Text('Pessoas próximas que podem trocar habilidades com você.'),
        const SizedBox(height: 14),
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Buscar por nome ou habilidade',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        if (_showFilters) ...[
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Habilidades',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _filterCatalog.map((skill) {
                      final selected = _skillFilters.contains(skill);
                      return FilterChip(
                        label: Text(skill),
                        selected: selected,
                        onSelected: (value) => setState(
                          () => value
                              ? _skillFilters.add(skill)
                              : _skillFilters.remove(skill),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Distância máxima: ${_maxDistance.toStringAsFixed(0)} km',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Slider(
                    value: _maxDistance,
                    min: 1,
                    max: 25,
                    divisions: 24,
                    label: '${_maxDistance.toStringAsFixed(0)} km',
                    onChanged: (value) => setState(() => _maxDistance = value),
                  ),
                  const SizedBox(height: 4),
                  const Text('Ordenar por',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Compatibilidade'),
                        selected: _sort == MatchSortMode.compatibility,
                        onSelected: (_) =>
                            setState(() => _sort = MatchSortMode.compatibility),
                      ),
                      ChoiceChip(
                        label: const Text('Mais próximo'),
                        selected: _sort == MatchSortMode.distance,
                        onSelected: (_) =>
                            setState(() => _sort = MatchSortMode.distance),
                      ),
                      ChoiceChip(
                        label: const Text('Melhor avaliação'),
                        selected: _sort == MatchSortMode.rating,
                        onSelected: (_) =>
                            setState(() => _sort = MatchSortMode.rating),
                      ),
                    ],
                  ),
                  if (hasActiveFilters)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => setState(() {
                          _skillFilters.clear();
                          _maxDistance = 25;
                        }),
                        child: const Text('Limpar filtros'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF5B36D6), Color(0xFF8B5CF6)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${matches.length} trocas compatíveis encontradas para você.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (matches.isEmpty)
          EmptyState(
            icon: Icons.search_off_rounded,
            title: allMatches.isEmpty
                ? 'Ainda não há matches'
                : 'Nenhum resultado',
            message: allMatches.isEmpty
                ? 'Edite as habilidades do seu card para encontrar pessoas compatíveis.'
                : 'Ninguém corresponde a esses filtros. Tente ampliar a busca.',
          )
        else
          ...matches.map(
            (match) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: MatchCard(match: match),
            ),
          ),
      ],
    );
  }
}

class MatchCard extends StatelessWidget {
  const MatchCard({super.key, required this.match});
  final MatchResult match;

  @override
  Widget build(BuildContext context) {
    final person = match.profile;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => MatchDetailsPage(match: match)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Avatar(
                    name: person.name,
                    color: person.avatarColor,
                    size: 54,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          person.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${person.distanceKm.toStringAsFixed(1)} km • ⭐ ${person.rating.toStringAsFixed(1)}',
                        ),
                      ],
                    ),
                  ),
                  ScoreBadge(score: match.score),
                ],
              ),
              const Divider(height: 26),
              SkillLine(
                icon: Icons.redeem_rounded,
                label: 'Você oferece',
                skills: match.iCanOffer,
                color: const Color(0xFF146C43),
              ),
              const SizedBox(height: 8),
              SkillLine(
                icon: Icons.favorite_rounded,
                label: 'Você recebe',
                skills: match.iNeed,
                color: const Color(0xFFB3261E),
              ),
              const SizedBox(height: 13),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MatchDetailsPage(match: match),
                    ),
                  ),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Ver match'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MatchDetailsPage extends StatefulWidget {
  const MatchDetailsPage({super.key, required this.match});
  final MatchResult match;

  @override
  State<MatchDetailsPage> createState() => _MatchDetailsPageState();
}

class _MatchDetailsPageState extends State<MatchDetailsPage> {
  final _gemini = const GeminiMatchService();
  String? _explanation;
  bool _loading = false;

  Future<void> _askGemini() async {
    final store = CambioScope.of(context);
    if (!_gemini.isConfigured) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.key_off_outlined),
          title: const Text('Gemini ainda não configurada'),
          content: const Text(
            'O match local já funciona. Quando você receber a chave, execute o projeto com --dart-define=GEMINI_API_KEY=SUA_CHAVE. Nunca publique uma chave dentro do aplicativo.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendi'),
            ),
          ],
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final explanation = await _gemini.explainMatch(
        me: store.currentUser,
        match: widget.match,
      );
      if (mounted) setState(() => _explanation = explanation);
    } on GeminiRequestException catch (error) {
      if (mounted) {
        _showError('Erro da Gemini (${error.statusCode}): ${error.message}');
      }
    } catch (_) {
      if (mounted) {
        _showError(
          'Falha de conexão. Confira a internet e a permissão INTERNET no AndroidManifest.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));

  Future<void> _openReportDialog(SkillProfile person) async {
    final store = CambioScope.of(context);
    final result = await showDialog<ReportResult>(
      context: context,
      builder: (_) => ReportDialog(personName: person.name),
    );
    if (result == null || !mounted) return;
    store.fileReport(
      reported: person,
      reason: result.reason,
      details: result.details,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Denúncia enviada. Nossa equipe vai revisar.'),
      ),
    );
  }

  Future<void> _confirmBlock(SkillProfile person) async {
    final store = CambioScope.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Bloquear ${person.name}?'),
        content: const Text(
          'Vocês não vão mais aparecer nos matches um do outro e não vão poder trocar propostas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Bloquear'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    store.blockUser(person.id);
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${person.name} foi bloqueado.'),
        action: SnackBarAction(
          label: 'Desfazer',
          onPressed: () => store.unblockUser(person.id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final person = widget.match.profile;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do match'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Mais opções',
            onSelected: (value) {
              if (value == 'report') _openReportDialog(person);
              if (value == 'block') _confirmBlock(person);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'report',
                child: ListTile(
                  leading: Icon(Icons.flag_outlined),
                  title: Text('Denunciar'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'block',
                child: ListTile(
                  leading: Icon(Icons.block_outlined),
                  title: Text('Bloquear'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: ResponsiveBody(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            Center(
              child: Avatar(
                name: person.name,
                color: person.avatarColor,
                size: 88,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                person.name,
                style: Theme.of(
                  context,
                )
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                '${person.city} • ${person.distanceKm.toStringAsFixed(1)} km • ⭐ ${person.rating.toStringAsFixed(1)}',
              ),
            ),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  person.about,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Center(child: ScoreBadge(score: widget.match.score, large: true)),
            const SizedBox(height: 22),
            const SectionTitle('Avaliações recebidas'),
            const SizedBox(height: 10),
            ReviewsList(reviews: person.reviews),
            const SizedBox(height: 18),
            const SectionTitle('A troca que vocês podem fazer'),
            const SizedBox(height: 10),
            SkillLine(
              icon: Icons.arrow_upward_rounded,
              label: 'Você pode ensinar',
              skills: widget.match.iCanOffer,
              color: const Color(0xFF146C43),
            ),
            const SizedBox(height: 10),
            SkillLine(
              icon: Icons.arrow_downward_rounded,
              label: 'Você pode aprender',
              skills: widget.match.iNeed,
              color: const Color(0xFFB3261E),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _loading ? null : _askGemini,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_loading ? 'Analisando...' : 'Pedir explicação à IA'),
            ),
            if (_explanation != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0ECFF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.auto_awesome, color: Color(0xFF5B36D6)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_explanation!)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProposalFormPage(match: widget.match),
                ),
              ),
              icon: const Icon(Icons.swap_horiz_rounded),
              label: const Text('Enviar proposta de troca'),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TELA: CARD / PERFIL
// -----------------------------------------------------------------------------

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = CambioScope.of(context);
    final profile = store.currentUser;
    return PageFrame(
      title: 'Meu card',
      action: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Usuários bloqueados',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BlockedUsersPage()),
            ),
            icon: const Icon(Icons.block_outlined),
          ),
          IconButton(
            tooltip: 'Editar perfil',
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const EditProfilePage())),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Avatar(
                  name: profile.name,
                  color: profile.avatarColor,
                  size: 82,
                ),
                const SizedBox(height: 12),
                Text(
                  profile.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(profile.city),
                const SizedBox(height: 10),
                Text(profile.about, textAlign: TextAlign.center),
                const Divider(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    StatItem(
                      value: profile.rating.toStringAsFixed(1),
                      label: 'avaliação',
                      icon: Icons.star_rounded,
                    ),
                    StatItem(
                      value: '${profile.completedExchanges}',
                      label: 'trocas',
                      icon: Icons.handshake_outlined,
                    ),
                    const StatItem(
                      value: '8,5h',
                      label: 'saldo',
                      icon: Icons.schedule_outlined,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const SectionTitle('Eu ofereço'),
        const SizedBox(height: 10),
        SkillWrap(skills: profile.offers, color: const Color(0xFF146C43)),
        const SizedBox(height: 20),
        const SectionTitle('Eu procuro'),
        const SizedBox(height: 10),
        SkillWrap(skills: profile.seeks, color: const Color(0xFFB3261E)),
        const SizedBox(height: 20),
        const SectionTitle('Minhas avaliações'),
        const SizedBox(height: 10),
        ReviewsList(reviews: profile.reviews),
        const SizedBox(height: 24),
        Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.verified_user)),
            title: const Text('Você está conectado'),
            subtitle: Text(store.userEmail ?? ''),
            trailing: TextButton(
              onPressed: store.signOut,
              child: const Text('Sair'),
            ),
          ),
        ),
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const EditProfilePage())),
          icon: const Icon(Icons.edit),
          label: const Text('Editar meu card'),
        ),
      ],
    );
  }
}

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController _name;
  late final TextEditingController _city;
  late final TextEditingController _about;
  late List<String> _offers;
  late List<String> _seeks;
  bool _profileLoaded = false;

  static const catalog = [
    'Design',
    'Flutter',
    'Programação',
    'Fotografia',
    'Inglês',
    'Edição de vídeo',
    'Violão',
    'Culinária',
    'Mecânica',
    'Redes sociais',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_profileLoaded) return;
    final profile = CambioScope.of(context).currentUser;
    _name = TextEditingController(text: profile.name);
    _city = TextEditingController(text: profile.city);
    _about = TextEditingController(text: profile.about);
    _offers = [...profile.offers];
    _seeks = [...profile.seeks];
    _profileLoaded = true;
  }

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _about.dispose();
    super.dispose();
  }

  void _save() {
    if (_name.text.trim().isEmpty || _offers.isEmpty || _seeks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Preencha seu nome e escolha ao menos uma habilidade em cada lista.',
          ),
        ),
      );
      return;
    }
    CambioScope.of(context).updateProfile(
      name: _name.text,
      city: _city.text,
      about: _about.text,
      offers: _offers,
      seeks: _seeks,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar meu card')),
      body: ResponsiveBody(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Seu nome',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _city,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Cidade',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _about,
              maxLines: 3,
              maxLength: 180,
              decoration: const InputDecoration(
                labelText: 'Sobre você',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const SectionTitle('O que você oferece?'),
            const SizedBox(height: 8),
            ChoiceSkillSelector(
              catalog: catalog,
              selected: _offers,
              selectedColor: const Color(0xFF146C43),
              onChanged: (value) => setState(() => _offers = value),
            ),
            const SizedBox(height: 20),
            const SectionTitle('O que você procura?'),
            const SizedBox(height: 8),
            ChoiceSkillSelector(
              catalog: catalog,
              selected: _seeks,
              selectedColor: const Color(0xFFB3261E),
              onChanged: (value) => setState(() => _seeks = value),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _save,
              child: const Text('Salvar alterações'),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TELA: PROPOSTAS
// -----------------------------------------------------------------------------

class ProposalsPage extends StatelessWidget {
  const ProposalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final proposals = CambioScope.of(context).proposals;
    return PageFrame(
      title: 'Minhas propostas',
      children: [
        const Text('Acompanhe as trocas que você já sugeriu.'),
        const SizedBox(height: 18),
        if (proposals.isEmpty)
          const EmptyState(
            icon: Icons.swap_horiz_rounded,
            title: 'Nenhuma proposta enviada',
            message:
                'Abra um match e envie uma proposta de troca para ela aparecer aqui.',
          )
        else
          ...proposals.map(
            (proposal) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ProposalCard(proposal: proposal),
            ),
          ),
      ],
    );
  }
}

class ProposalFormPage extends StatefulWidget {
  const ProposalFormPage({super.key, required this.match});
  final MatchResult match;

  @override
  State<ProposalFormPage> createState() => _ProposalFormPageState();
}

class _ProposalFormPageState extends State<ProposalFormPage> {
  late String _offer;
  late String _request;
  late TextEditingController _message;

  @override
  void initState() {
    super.initState();
    _offer = widget.match.iCanOffer.first;
    _request = widget.match.iNeed.first;
    _message = TextEditingController(
      text:
          'Oi, ${widget.match.profile.name.split(' ').first}! Podemos fazer uma troca de habilidades?',
    );
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  void _send() {
    CambioScope.of(context).sendProposal(
      to: widget.match.profile,
      offer: _offer,
      request: _request,
      message: _message.text.trim(),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Proposta enviada com sucesso!')),
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.match.profile.name;
    return Scaffold(
      appBar: AppBar(title: const Text('Nova proposta')),
      body: ResponsiveBody(
        maxWidth: 560,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Proponha uma troca para $name.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 22),
            DropdownButtonFormField<String>(
              value: _offer,
              decoration: const InputDecoration(
                labelText: 'Eu ofereço',
                border: OutlineInputBorder(),
              ),
              items: widget.match.iCanOffer
                  .map(
                    (skill) =>
                        DropdownMenuItem(value: skill, child: Text(skill)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _offer = value!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _request,
              decoration: const InputDecoration(
                labelText: 'Em troca de',
                border: OutlineInputBorder(),
              ),
              items: widget.match.iNeed
                  .map(
                    (skill) =>
                        DropdownMenuItem(value: skill, child: Text(skill)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _request = value!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _message,
              minLines: 3,
              maxLines: 4,
              maxLength: 240,
              decoration: const InputDecoration(
                labelText: 'Mensagem',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _send,
              icon: const Icon(Icons.send_rounded),
              label: const Text('Enviar proposta'),
            ),
          ],
        ),
      ),
    );
  }
}

class ProposalCard extends StatelessWidget {
  const ProposalCard({super.key, required this.proposal});
  final ExchangeProposal proposal;

  Future<void> _completeExchange(BuildContext context) async {
    final store = CambioScope.of(context);
    final review = await showDialog<Review>(
      context: context,
      builder: (_) => ReviewDialog(personName: proposal.to.name),
    );
    if (review == null) return;
    store.completeExchange(proposal: proposal, review: review);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Troca concluída e avaliação enviada!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = CambioScope.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Avatar(
                  name: proposal.to.name,
                  color: proposal.to.avatarColor,
                  size: 42,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    proposal.to.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                ),
                StatusPill(status: proposal.status),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Você oferece ${proposal.offer} em troca de ${proposal.request}.',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 7),
            Text(
              '"${proposal.message}"',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
            if (proposal.status == ProposalStatus.pending) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => store.changeProposalStatus(
                        proposal,
                        ProposalStatus.declined,
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _completeExchange(context),
                      child: const Text('Concluir troca +90 XP'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TELA: BANCO DE HORAS
// -----------------------------------------------------------------------------

class HoursPage extends StatelessWidget {
  const HoursPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = CambioScope.of(context);
    return PageFrame(
      title: 'Banco de horas',
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF173B8A), Color(0xFF3565CD)],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SEU SALDO DISPONÍVEL',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${store.hourBalance.toStringAsFixed(1).replaceAll('.', ',')} horas',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 34,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Use horas quando a troca não for exatamente equivalente.',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const SectionTitle('Como funciona'),
        const SizedBox(height: 10),
        const InfoTile(
          icon: Icons.add_task_rounded,
          title: 'Realize uma troca',
          message:
              'Ao concluir um serviço, as horas combinadas são registradas.',
        ),
        const InfoTile(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Ganhe ou use horas',
          message: 'Quem ajuda além do combinado ganha saldo para outra troca.',
        ),
        const InfoTile(
          icon: Icons.verified_outlined,
          title: 'Confirme a conclusão',
          message:
              'As duas pessoas confirmam a troca antes de atualizar o saldo.',
        ),
        const SizedBox(height: 22),
        const SectionTitle('Atividade recente'),
        const SizedBox(height: 8),
        const InfoTile(
          icon: Icons.add_circle_outline,
          title: '+ 2,0 h — edição de vídeo',
          message: 'Troca concluída com Beatriz • 12 ago',
        ),
        const InfoTile(
          icon: Icons.remove_circle_outline,
          title: '− 1,5 h — sessão de fotografia',
          message: 'Troca concluída com João • 04 ago',
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// TELA: GAMIFICAÇÃO
// -----------------------------------------------------------------------------

class EvolutionPage extends StatelessWidget {
  const EvolutionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = CambioScope.of(context);
    final level = store.currentLevel;
    final next = store.nextLevel;
    final ranking = <_RankingEntry>[
      const _RankingEntry('Lucas', '👑', 1040),
      const _RankingEntry('Beatriz', '💎', 720),
      _RankingEntry(store.currentUser.name, level.emoji, store.xp),
      const _RankingEntry('João', '🚀', 380),
      const _RankingEntry('Maria', '🔧', 260),
    ]..sort((a, b) => b.xp.compareTo(a.xp));

    return PageFrame(
      title: 'Minha evolução',
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [level.color, const Color(0xFF8B5CF6)],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${level.emoji} ${level.name}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${store.xp} XP acumulados',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: store.levelProgress,
                  minHeight: 10,
                  backgroundColor: Colors.white30,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                next == null
                    ? 'Você chegou ao nível máximo!'
                    : 'Faltam ${next.minimumXp - store.xp} XP para ${next.emoji} ${next.name}.',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const SectionTitle('Como ganhar XP'),
        const SizedBox(height: 10),
        const _XpRule(
            icon: Icons.handshake_rounded,
            title: 'Realizar uma troca',
            points: '+50 XP'),
        const _XpRule(
            icon: Icons.star_rounded,
            title: 'Receber boa avaliação',
            points: '+20 XP'),
        const _XpRule(
            icon: Icons.school_rounded,
            title: 'Ensinar uma habilidade',
            points: '+40 XP'),
        const _XpRule(
            icon: Icons.local_fire_department_rounded,
            title: 'A cada 3 trocas',
            points: '+30 XP bônus'),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            store.registerPositiveRating();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Boa avaliação registrada: +20 XP!')),
            );
          },
          icon: const Icon(Icons.add_task_rounded),
          label: const Text('Simular boa avaliação (+20 XP)'),
        ),
        const SizedBox(height: 24),
        const SectionTitle('Conquistas'),
        const SizedBox(height: 10),
        ...store.achievements.map(
          (achievement) => Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: achievement.unlocked
                    ? const Color(0xFFFFE7A6)
                    : Colors.grey.shade200,
                child: Icon(
                  achievement.icon,
                  color: achievement.unlocked
                      ? const Color(0xFF8A5A00)
                      : Colors.grey,
                ),
              ),
              title: Text(
                achievement.title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: achievement.unlocked ? null : Colors.grey,
                ),
              ),
              subtitle: Text(achievement.description),
              trailing: Icon(
                achievement.unlocked
                    ? Icons.verified_rounded
                    : Icons.lock_outline,
                color: achievement.unlocked
                    ? const Color(0xFF146C43)
                    : Colors.grey,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const SectionTitle('Ranking semanal'),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: List.generate(ranking.length, (index) {
              final entry = ranking[index];
              final isMe = entry.name == store.currentUser.name;
              return Container(
                color: isMe ? const Color(0xFFF0ECFF) : null,
                child: ListTile(
                  leading: SizedBox(
                    width: 28,
                    child: Text('#${index + 1}',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                  title: Text('${entry.emoji} ${entry.name}',
                      style: TextStyle(
                          fontWeight:
                              isMe ? FontWeight.w800 : FontWeight.w600)),
                  trailing: Text('${entry.xp} XP',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _XpRule extends StatelessWidget {
  const _XpRule(
      {required this.icon, required this.title, required this.points});
  final IconData icon;
  final String title;
  final String points;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: Icon(icon, color: const Color(0xFF5B36D6)),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          trailing: Text(points,
              style: const TextStyle(
                  color: Color(0xFF146C43), fontWeight: FontWeight.w800)),
        ),
      );
}

class _RankingEntry {
  const _RankingEntry(this.name, this.emoji, this.xp);
  final String name;
  final String emoji;
  final int xp;
}

// -----------------------------------------------------------------------------
// TELA: LOGIN (obrigatória — controla o acesso ao restante do app via AuthGate)
// -----------------------------------------------------------------------------

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hidePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _enter() {
    final email = _email.text.trim();
    if (!email.contains('@') || _password.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Informe um e-mail válido e uma senha com 4 caracteres ou mais.')),
      );
      return;
    }
    // signIn() notifica o CambioStore, e o AuthGate troca automaticamente
    // esta tela pelo AppShell — não é necessário empilhar/desempilhar rota.
    CambioScope.of(context).signIn(email: email);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Login realizado! Bem-vindo ao Escambo.')),
    );
    // Se esta tela tiver sido aberta empilhada (ex.: a partir de um fluxo
    // futuro de "trocar de conta"), fecha a rota; caso seja a raiz (gate),
    // não há o que desempilhar.
    if (Navigator.of(context).canPop()) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Entrar no Escambo')),
        body: SafeArea(
          child: ResponsiveBody(
            maxWidth: 480,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Icon(Icons.handshake_rounded,
                    size: 64, color: Color(0xFF5B36D6)),
                const SizedBox(height: 14),
                Text('Bem-vindo de volta',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text(
                    'Entre para acessar seu card, seus matches e suas propostas de troca.',
                    textAlign: TextAlign.center),
                const SizedBox(height: 30),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _password,
                  obscureText: _hidePassword,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _hidePassword = !_hidePassword),
                      icon: Icon(_hidePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                    onPressed: _enter,
                    icon: const Icon(Icons.login_rounded),
                    label: const Text('Entrar / criar conta')),
              ],
            ),
          ),
        ),
      );
}

// -----------------------------------------------------------------------------
// TELA: ONBOARDING GUIADO (primeiro acesso após o login)
// -----------------------------------------------------------------------------

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageController = PageController();
  int _step = 0;
  bool _loaded = false;

  late final TextEditingController _name;
  late final TextEditingController _city;
  late final TextEditingController _about;
  late List<String> _offers;
  late List<String> _seeks;

  static const _titles = [
    'Seus dados',
    'O que você oferece',
    'O que você procura',
  ];

  static const catalog = [
    'Design',
    'Flutter',
    'Programação',
    'Fotografia',
    'Inglês',
    'Edição de vídeo',
    'Violão',
    'Culinária',
    'Mecânica',
    'Redes sociais',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    final profile = CambioScope.of(context).currentUser;
    _name = TextEditingController(text: profile.name);
    _city = TextEditingController(text: profile.city);
    _about = TextEditingController(text: profile.about);
    _offers = [...profile.offers];
    _seeks = [...profile.seeks];
    _loaded = true;
  }

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _about.dispose();
    _pageController.dispose();
    super.dispose();
  }

  bool get _canAdvance {
    switch (_step) {
      case 0:
        return _name.text.trim().isNotEmpty && _city.text.trim().isNotEmpty;
      case 1:
        return _offers.isNotEmpty;
      case 2:
        return _seeks.isNotEmpty;
      default:
        return true;
    }
  }

  void _next() {
    if (!_canAdvance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha essa etapa para continuar.')),
      );
      return;
    }
    if (_step == 2) {
      CambioScope.of(context).completeOnboarding(
        name: _name.text,
        city: _city.text,
        about: _about.text,
        offers: _offers,
        seeks: _seeks,
      );
      return;
    }
    setState(() => _step++);
    _pageController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _back() {
    if (_step == 0) return;
    setState(() => _step--);
    _pageController.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete seu card'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ResponsiveBody(
          maxWidth: 560,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Row(
                  children: List.generate(3, (index) {
                    final active = index <= _step;
                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: index == 2 ? 0 : 6),
                        height: 6,
                        decoration: BoxDecoration(
                          color: active
                              ? const Color(0xFF5B36D6)
                              : const Color(0xFFE4E0F7),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _titles[_step],
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        TextField(
                          controller: _name,
                          onChanged: (_) => setState(() {}),
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Seu nome',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _city,
                          onChanged: (_) => setState(() {}),
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Cidade',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _about,
                          maxLines: 3,
                          maxLength: 180,
                          decoration: const InputDecoration(
                            labelText: 'Sobre você',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                    ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        const Text(
                          'Escolha as habilidades que você pode ensinar ou oferecer em troca.',
                        ),
                        const SizedBox(height: 14),
                        ChoiceSkillSelector(
                          catalog: catalog,
                          selected: _offers,
                          selectedColor: const Color(0xFF146C43),
                          onChanged: (value) => setState(() => _offers = value),
                        ),
                      ],
                    ),
                    ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        const Text(
                          'Agora escolha o que você gostaria de aprender ou receber.',
                        ),
                        const SizedBox(height: 14),
                        ChoiceSkillSelector(
                          catalog: catalog,
                          selected: _seeks,
                          selectedColor: const Color(0xFFB3261E),
                          onChanged: (value) => setState(() => _seeks = value),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    if (_step > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _back,
                          child: const Text('Voltar'),
                        ),
                      ),
                    if (_step > 0) const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _next,
                        child: Text(_step == 2 ? 'Concluir' : 'Continuar'),
                      ),
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
}

// -----------------------------------------------------------------------------
// AVALIAÇÕES (estrelas + comentário) exibidas em cada troca concluída
// -----------------------------------------------------------------------------

class ReviewDialog extends StatefulWidget {
  const ReviewDialog({super.key, required this.personName});
  final String personName;

  @override
  State<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  int _stars = 5;
  final Set<String> _tags = {};
  final _comment = TextEditingController();

  static const _availableTags = [
    'Pontual',
    'Boa comunicação',
    'Cumpriu o combinado',
    'Super atencioso',
  ];

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Avaliar ${widget.personName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Como foi a troca?'),
            const SizedBox(height: 4),
            Row(
              children: List.generate(5, (index) {
                final starValue = index + 1;
                return IconButton(
                  onPressed: () => setState(() => _stars = starValue),
                  icon: Icon(
                    starValue <= _stars
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: const Color(0xFFF5A524),
                    size: 30,
                  ),
                );
              }),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableTags.map((tag) {
                final selected = _tags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: selected,
                  onSelected: (value) => setState(
                    () => value ? _tags.add(tag) : _tags.remove(tag),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _comment,
              maxLines: 3,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Comentário (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            Review(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              reviewerName: 'Você',
              stars: _stars,
              comment: _comment.text.trim(),
              tags: _tags.toList(),
              createdAt: DateTime.now(),
            ),
          ),
          child: const Text('Enviar avaliação'),
        ),
      ],
    );
  }
}

class ReviewsList extends StatelessWidget {
  const ReviewsList({super.key, required this.reviews});
  final List<Review> reviews;

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return const EmptyState(
        icon: Icons.reviews_outlined,
        title: 'Ainda sem avaliações',
        message: 'As avaliações aparecem aqui assim que uma troca é concluída.',
      );
    }
    return Column(
      children: reviews.take(5).map((review) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ...List.generate(
                      5,
                      (index) => Icon(
                        index < review.stars
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: const Color(0xFFF5A524),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      review.reviewerName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                if (review.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: review.tags
                        .map(
                          (tag) => Chip(
                            label: Text(
                              tag,
                              style: const TextStyle(fontSize: 11),
                            ),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        )
                        .toList(),
                  ),
                ],
                if (review.comment.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(review.comment),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// -----------------------------------------------------------------------------
// DENÚNCIAS E BLOQUEIO
// -----------------------------------------------------------------------------

class ReportResult {
  const ReportResult(this.reason, this.details);
  final ReportReason reason;
  final String details;
}

class ReportDialog extends StatefulWidget {
  const ReportDialog({super.key, required this.personName});
  final String personName;

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  ReportReason _reason = ReportReason.spam;
  final _details = TextEditingController();

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Denunciar ${widget.personName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...ReportReason.values.map(
              (reason) => RadioListTile<ReportReason>(
                value: reason,
                groupValue: _reason,
                title: Text(reason.label),
                contentPadding: EdgeInsets.zero,
                onChanged: (value) => setState(() => _reason = value!),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _details,
              maxLines: 3,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Descreva o que aconteceu',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            ReportResult(_reason, _details.text),
          ),
          child: const Text('Enviar denúncia'),
        ),
      ],
    );
  }
}

class BlockedUsersPage extends StatelessWidget {
  const BlockedUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = CambioScope.of(context);
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final blocked = store.people
            .where((person) => store.blockedIds.contains(person.id))
            .toList();
        return Scaffold(
          appBar: AppBar(title: const Text('Usuários bloqueados')),
          body: ResponsiveBody(
            child: blocked.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: EmptyState(
                      icon: Icons.block_outlined,
                      title: 'Nenhum usuário bloqueado',
                      message:
                          'Pessoas que você bloquear aparecem aqui e podem ser desbloqueadas quando quiser.',
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: blocked.length,
                    itemBuilder: (context, index) {
                      final person = blocked[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          child: ListTile(
                            leading: Avatar(
                              name: person.name,
                              color: person.avatarColor,
                              size: 44,
                            ),
                            title: Text(person.name),
                            subtitle: Text(person.city),
                            trailing: TextButton(
                              onPressed: () => store.unblockUser(person.id),
                              child: const Text('Desbloquear'),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// COMPONENTES REUTILIZÁVEIS
// -----------------------------------------------------------------------------

class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    required this.name,
    required this.color,
    required this.size,
  });
  final String name;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => CircleAvatar(
        radius: size / 2,
        backgroundColor: color,
        child: Text(
          name.split(' ').map((part) => part[0]).take(2).join(),
          style: TextStyle(
            color: Colors.white,
            fontSize: size * .32,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
}

class ScoreBadge extends StatelessWidget {
  const ScoreBadge({super.key, required this.score, this.large = false});
  final int score;
  final bool large;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(
          horizontal: large ? 18 : 10,
          vertical: large ? 10 : 6,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F7ED),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          '⚡ $score%',
          style: TextStyle(
            color: const Color(0xFF146C43),
            fontWeight: FontWeight.w800,
            fontSize: large ? 19 : 14,
          ),
        ),
      );
}

class SkillLine extends StatelessWidget {
  const SkillLine({
    super.key,
    required this.icon,
    required this.label,
    required this.skills,
    required this.color,
  });
  final IconData icon;
  final String label;
  final List<String> skills;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: TextStyle(color: color, fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: skills.join(', ')),
                ],
              ),
            ),
          ),
        ],
      );
}

class SkillWrap extends StatelessWidget {
  const SkillWrap({super.key, required this.skills, required this.color});
  final List<String> skills;
  final Color color;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: skills
            .map(
              (skill) => Chip(
                label: Text(skill),
                side: BorderSide(color: color.withOpacity(.25)),
                backgroundColor: color.withOpacity(.09),
                labelStyle:
                    TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            )
            .toList(),
      );
}

class ChoiceSkillSelector extends StatelessWidget {
  const ChoiceSkillSelector({
    super.key,
    required this.catalog,
    required this.selected,
    required this.selectedColor,
    required this.onChanged,
  });
  final List<String> catalog;
  final List<String> selected;
  final Color selectedColor;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: catalog.map((skill) {
          final isSelected = selected.contains(skill);
          return FilterChip(
            label: Text(skill),
            selected: isSelected,
            selectedColor: selectedColor.withOpacity(.16),
            checkmarkColor: selectedColor,
            onSelected: (value) {
              final next = [...selected];
              value ? next.add(skill) : next.remove(skill);
              onChanged(next);
            },
          );
        }).toList(),
      );
}

class StatItem extends StatelessWidget {
  const StatItem({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
  });
  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Icon(icon, color: const Color(0xFF5B36D6)),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
          ),
          Text(label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ],
      );
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status});
  final ProposalStatus status;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: status.color.withOpacity(.1),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Text(
          status.label,
          style: TextStyle(
            color: status.color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title;
  final String message;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              Icon(icon, size: 48, color: const Color(0xFF5B36D6)),
              const SizedBox(height: 12),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}

class InfoTile extends StatelessWidget {
  const InfoTile({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title;
  final String message;
  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: Icon(icon, color: const Color(0xFF5B36D6)),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(message),
        ),
      );
}
