part of grupli_app;

class OnboardingStore {
  static const seenKey = 'grupli_onboarding_seen_v1';

  static Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(seenKey, true);
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(seenKey);
  }
}

class OnboardingScreen extends StatefulWidget {
  final Future<void> Function() onFinish;
  const OnboardingScreen({super.key, required this.onFinish});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final controller = PageController();
  int index = 0;

  static const slides = [
    _OnboardingSlideData(
      icon: Icons.groups_rounded,
      titleEs: 'Tu grupo,\nsiempre ordenado',
      titleEn: 'Your group,\nalways organized',
      bodyEs: 'Crea espacios privados para coordinar planes, asistencia, gastos y competiciones sin perder información en chats.',
      bodyEn: 'Create private spaces to coordinate plans, attendance, expenses and competitions without losing information in chats.',
      accent: AppColors.teal,
      soft: AppColors.tealSoft,
    ),
    _OnboardingSlideData(
      icon: Icons.event_available_rounded,
      titleEs: 'Planes claros\ny asistencia rápida',
      titleEn: 'Clear plans\nand quick attendance',
      bodyEs: 'Cada evento muestra fecha, ubicación, quién va, quién duda y si falta gente. Confirmar solo lleva un toque.',
      bodyEn: 'Every event shows date, location, who is going, who is unsure and whether more people are needed. Confirming takes one tap.',
      accent: AppColors.violet,
      soft: AppColors.violetSoft,
    ),
    _OnboardingSlideData(
      icon: Icons.emoji_events_rounded,
      titleEs: 'Gastos, ligas\ny torneos',
      titleEn: 'Expenses, leagues\nand tournaments',
      bodyEs: 'Registra gastos, liquida pagos pendientes y organiza ligas o torneos con calendario, resultados y clasificación.',
      bodyEn: 'Track expenses, settle pending payments and organize leagues or tournaments with calendar, results and standings.',
      accent: AppColors.orange,
      soft: AppColors.orangeSoft,
    ),
  ];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> next() async {
    if (index >= slides.length - 1) {
      await widget.onFinish();
      return;
    }
    await controller.nextPage(duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final last = index == slides.length - 1;
    return DirectPage(
      scroll: false,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: AppColors.tealDark, borderRadius: BorderRadius.circular(15)),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),
          const Expanded(child: Text('Grupli', style: TextStyle(fontSize: 24, color: AppColors.ink, fontWeight: FontWeight.w900, letterSpacing: -.7))),
          TextButton(onPressed: () => widget.onFinish(), child: Text(appIsEnglish ? 'Skip' : 'Saltar', style: const TextStyle(fontWeight: FontWeight.w900))),
        ]),
        const SizedBox(height: 18),
        Expanded(
          child: PageView.builder(
            controller: controller,
            itemCount: slides.length,
            onPageChanged: (value) => setState(() => index = value),
            itemBuilder: (context, i) => OnboardingSlide(data: slides[i], index: i),
          ),
        ),
        const SizedBox(height: 16),
        Row(children: [
          ...List.generate(slides.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: i == index ? 28 : 8,
                height: 8,
                margin: const EdgeInsets.only(right: 7),
                decoration: BoxDecoration(
                  color: i == index ? AppColors.tealDark : AppColors.line,
                  borderRadius: BorderRadius.circular(99),
                ),
              )),
          const Spacer(),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: next,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.tealDark,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              icon: Icon(last ? Icons.check_rounded : Icons.arrow_forward_rounded),
              label: Text(last ? (appIsEnglish ? 'Start' : 'Empezar') : (appIsEnglish ? 'Next' : 'Siguiente'), style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _OnboardingSlideData {
  final IconData icon;
  final String titleEs;
  final String titleEn;
  final String bodyEs;
  final String bodyEn;
  final Color accent;
  final Color soft;
  const _OnboardingSlideData({
    required this.icon,
    required this.titleEs,
    required this.titleEn,
    required this.bodyEs,
    required this.bodyEn,
    required this.accent,
    required this.soft,
  });

  String get title => appIsEnglish ? titleEn : titleEs;
  String get body => appIsEnglish ? bodyEn : bodyEs;
}


class OnboardingSlide extends StatefulWidget {
  final _OnboardingSlideData data;
  final int index;
  const OnboardingSlide({super.key, required this.data, required this.index});

  @override
  State<OnboardingSlide> createState() => _OnboardingSlideState();
}

class _OnboardingSlideState extends State<OnboardingSlide> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 5200))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => _IntroSceneFrame(
            index: widget.index,
            data: widget.data,
            progress: _controller.value,
          ),
        ),
      ),
      const SizedBox(height: 28),
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(offset: Offset(0, 16 * (1 - value)), child: child),
        ),
        child: Text(widget.data.title, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: AppColors.ink, height: 1.02, letterSpacing: -1.1)),
      ),
      const SizedBox(height: 12),
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 620),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(offset: Offset(0, 18 * (1 - value)), child: child),
        ),
        child: Text(widget.data.body, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.muted, height: 1.42)),
      ),
      const SizedBox(height: 4),
    ]);
  }
}

class _IntroSceneFrame extends StatelessWidget {
  final int index;
  final _OnboardingSlideData data;
  final double progress;
  const _IntroSceneFrame({required this.index, required this.data, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: LinearGradient(
          colors: index == 0
              ? const [Color(0xFF073A57), Color(0xFF0B6B8F)]
              : index == 1
                  ? const [Color(0xFF123D72), Color(0xFF0C8A8A)]
                  : const [Color(0xFF063346), Color(0xFF0F766E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [BoxShadow(color: Color(0x22073A57), blurRadius: 28, offset: Offset(0, 16))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
        child: Stack(children: [
          Positioned.fill(child: _IntroAnimatedBackground(progress: progress, index: index)),
          if (index == 0)
            _GroupPrivateScene(progress: progress)
          else if (index == 1)
            _AgendaScene(progress: progress)
          else
            _FinanceTournamentScene(progress: progress),
        ]),
      ),
    );
  }
}

class _IntroAnimatedBackground extends StatelessWidget {
  final double progress;
  final int index;
  const _IntroAnimatedBackground({required this.progress, required this.index});

  @override
  Widget build(BuildContext context) {
    final icons = <IconData>[
      Icons.calendar_month_rounded,
      Icons.payments_rounded,
      Icons.emoji_events_rounded,
      Icons.check_circle_rounded,
      Icons.lock_rounded,
      Icons.people_alt_rounded,
    ];
    return Stack(children: [
      Positioned(
        right: -34 + sin(progress * pi * 2) * 10,
        top: -24 + cos(progress * pi * 2) * 8,
        child: _GlowCircle(size: 138, color: Colors.white.withOpacity(.12)),
      ),
      Positioned(
        left: -42 + cos(progress * pi * 2) * 8,
        bottom: -34 + sin(progress * pi * 2) * 10,
        child: _GlowCircle(size: 122, color: Colors.white.withOpacity(.10)),
      ),
      Positioned.fill(
        child: Wrap(
          spacing: 23,
          runSpacing: 22,
          children: List.generate(48, (i) {
            final wave = sin((progress * pi * 2) + i * .55);
            return Transform.translate(
              offset: Offset(0, wave * 2.2),
              child: Icon(icons[(i + index) % icons.length], color: Colors.white.withOpacity(.055 + (wave + 1) * .012), size: 18),
            );
          }),
        ),
      ),
    ]);
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _GroupPrivateScene extends StatelessWidget {
  final double progress;
  const _GroupPrivateScene({required this.progress});

  double _pop(double start, double end) => Curves.easeOutBack.transform(((progress - start) / (end - start)).clamp(0.0, 1.0).toDouble());

  @override
  Widget build(BuildContext context) {
    final invitePulse = .5 + .5 * sin(progress * pi * 2);
    return Center(
      child: Transform.translate(
        offset: Offset(0, sin(progress * pi * 2) * 4),
        child: Container(
          width: 250,
          constraints: const BoxConstraints(maxHeight: 330),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.96),
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 14))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              height: 66,
              decoration: BoxDecoration(
                color: AppColors.tealSoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(children: [
                Positioned(left: 14, top: 14, child: _MiniAvatar(label: 'J', color: AppColors.teal)),
                Positioned(left: 42, top: 14, child: Transform.scale(scale: _pop(.05, .32), child: _MiniAvatar(label: 'M', color: AppColors.orange))),
                Positioned(left: 70, top: 14, child: Transform.scale(scale: _pop(.15, .42), child: _MiniAvatar(label: 'A', color: AppColors.violet))),
                Positioned(
                  right: 12,
                  top: 14,
                  child: Transform.scale(
                    scale: 1 + invitePulse * .05,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.lock_rounded, color: AppColors.teal, size: 14),
                        SizedBox(width: 5),
                        Text(appIsEnglish ? 'Private' : 'Privado', style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w900, fontSize: 11)),
                      ]),
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            Text(appIsEnglish ? 'The Penguins' : 'Los pingüino', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontSize: 20, fontWeight: FontWeight.w900, height: 1)),
            const SizedBox(height: 5),
            Text(appIsEnglish ? 'Agenda, expenses and tournaments for the group' : 'Agenda, gastos y torneos del grupo', style: const TextStyle(color: AppColors.muted, fontSize: 12.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            _SceneMiniTile(icon: Icons.calendar_month_rounded, color: AppColors.teal, title: appIsEnglish ? 'Friday plan' : 'Plan del viernes', subtitle: appIsEnglish ? '4 going · 1 unsure' : '4 van · 1 duda', progress: _pop(.25, .55)),
            const SizedBox(height: 8),
            _SceneMiniTile(icon: Icons.account_balance_wallet_rounded, color: AppColors.green, title: appIsEnglish ? 'Pending payment' : 'Pago pendiente', subtitle: appIsEnglish ? 'Settle € 2.50' : 'Liquidar € 2,50', progress: _pop(.35, .68)),
            const SizedBox(height: 8),
            _SceneMiniTile(icon: Icons.emoji_events_rounded, color: AppColors.red, title: appIsEnglish ? 'Active league' : 'Liga activa', subtitle: appIsEnglish ? 'Round 2 ready' : 'Jornada 2 lista', progress: _pop(.45, .78)),
          ]),
        ),
      ),
    );
  }
}

class _AgendaScene extends StatelessWidget {
  final double progress;
  const _AgendaScene({required this.progress});

  double _ease(double start, double end) => Curves.easeOutCubic.transform(((progress - start) / (end - start)).clamp(0.0, 1.0).toDouble());

  @override
  Widget build(BuildContext context) {
    final selected = progress > .34;
    final confirmed = progress > .62;
    final pulse = .5 + .5 * sin(progress * pi * 2);
    return Center(
      child: Container(
        width: 258,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.97),
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 14))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.calendar_month_rounded, color: AppColors.teal, size: 19),
            SizedBox(width: 7),
            Text('Agenda', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 17)),
          ]),
          const SizedBox(height: 12),
          Row(children: List.generate(5, (i) {
            final active = i == 2;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: active ? 58 : 50,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: active ? AppColors.teal : AppColors.surface,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: active ? AppColors.teal : AppColors.line),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(['L','M','X','J','V'][i], style: TextStyle(color: active ? Colors.white : AppColors.muted, fontWeight: FontWeight.w900, fontSize: 10)),
                  const SizedBox(height: 4),
                  Text('${10 + i}', style: TextStyle(color: active ? Colors.white : AppColors.ink, fontWeight: FontWeight.w900, fontSize: active ? 19 : 16)),
                  const SizedBox(height: 4),
                  Container(width: active ? 18 : 6, height: 5, decoration: BoxDecoration(color: active ? Colors.white : AppColors.line, borderRadius: BorderRadius.circular(99))),
                ]),
              ),
            );
          })),
          const SizedBox(height: 14),
          Transform.translate(
            offset: Offset(0, (1 - _ease(.18, .45)) * 18),
            child: Opacity(
              opacity: _ease(.18, .45),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(21)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(width: 38, height: 38, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.location_on_outlined, color: AppColors.teal, size: 20)),
                    const SizedBox(width: 9),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(appIsEnglish ? 'Group match' : 'Partido del grupo', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
                      SizedBox(height: 2),
                      Text(appIsEnglish ? 'Fri 12 · 20:00' : 'Vie 12 · 20:00', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
                    ])),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      width: confirmed ? 48 : 42,
                      height: 26,
                      decoration: BoxDecoration(color: confirmed ? AppColors.green : AppColors.white, borderRadius: BorderRadius.circular(99)),
                      child: Center(child: Text(confirmed ? '4/4' : '3/4', style: TextStyle(color: confirmed ? Colors.white : AppColors.teal, fontWeight: FontWeight.w900, fontSize: 11))),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _IntroAttendanceButton(label: appIsEnglish ? 'Going' : 'Voy', color: AppColors.green, selected: confirmed || selected, pulse: pulse)),
                    const SizedBox(width: 7),
                    Expanded(child: _IntroAttendanceButton(label: appIsEnglish ? 'Maybe' : 'Duda', color: AppColors.amber, selected: !confirmed && selected, pulse: 0)),
                    const SizedBox(width: 7),
                    Expanded(child: _IntroAttendanceButton(label: 'No', color: AppColors.red, selected: false, pulse: 0)),
                  ]),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _FinanceTournamentScene extends StatelessWidget {
  final double progress;
  const _FinanceTournamentScene({required this.progress});

  double _ease(double start, double end) => Curves.easeOutCubic.transform(((progress - start) / (end - start)).clamp(0.0, 1.0).toDouble());

  @override
  Widget build(BuildContext context) {
    final paid = progress > .46;
    final tableStep = progress > .66;
    return Center(
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.97),
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 14))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Transform.translate(
            offset: Offset(0, (1 - _ease(.05, .32)) * 18),
            child: Opacity(
              opacity: _ease(.05, .32),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.greenSoft, borderRadius: BorderRadius.circular(21)),
                child: Row(children: [
                  Container(width: 39, height: 39, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: Icon(paid ? Icons.verified_rounded : Icons.account_balance_wallet_rounded, color: AppColors.green)),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(paid ? (appIsEnglish ? 'Payment settled' : 'Pago liquidado') : (appIsEnglish ? 'Recommended payment' : 'Pago recomendado'), style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(paid ? (appIsEnglish ? 'Group balance at zero' : 'Balance del grupo a cero') : (appIsEnglish ? 'Marta settles € 2.50 with Javi' : 'Marta liquida € 2,50 a Javi'), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
                  ])),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(color: paid ? AppColors.green : AppColors.teal, borderRadius: BorderRadius.circular(99)),
                    child: Text(paid ? (appIsEnglish ? 'Done' : 'Listo') : (appIsEnglish ? 'Settle' : 'Liquidar'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
                  ),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Transform.translate(
            offset: Offset(0, (1 - _ease(.28, .55)) * 20),
            child: Opacity(
              opacity: _ease(.28, .55),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.orangeSoft, borderRadius: BorderRadius.circular(21)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.emoji_events_rounded, color: AppColors.orange, size: 20),
                    SizedBox(width: 7),
                    Text(appIsEnglish ? 'Group league' : 'Liga del grupo', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
                    Spacer(),
                    Text(appIsEnglish ? 'R2' : 'J2', style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.w900)),
                  ]),
                  const SizedBox(height: 10),
                  _MiniRankingRow(position: 1, name: tableStep ? (appIsEnglish ? 'Four' : 'Cuatro') : (appIsEnglish ? 'Two' : 'Dos'), points: tableStep ? '6 pts' : '3 pts', active: true),
                  const SizedBox(height: 7),
                  _MiniRankingRow(position: 2, name: tableStep ? (appIsEnglish ? 'Two' : 'Dos') : (appIsEnglish ? 'Four' : 'Cuatro'), points: tableStep ? '3 pts' : '3 pts', active: false),
                  const SizedBox(height: 7),
                  _MiniRankingRow(position: 3, name: appIsEnglish ? 'Three' : 'Tres', points: '0 pts', active: false),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _MiniAvatar extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniAvatar({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: 34,
    height: 34,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
    child: Center(child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13))),
  );
}

class _SceneMiniTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final double progress;
  const _SceneMiniTile({required this.icon, required this.color, required this.title, required this.subtitle, required this.progress});

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: progress.clamp(0.0, 1.0).toDouble(),
    child: Transform.translate(
      offset: Offset(0, 14 * (1 - progress)),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(17), border: Border.all(color: AppColors.lineSoft)),
        child: Row(children: [
          Container(width: 34, height: 34, decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 18)),
          const SizedBox(width: 9),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 12.5)),
            const SizedBox(height: 2),
            Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 11)),
          ])),
        ]),
      ),
    ),
  );
}

class _IntroAttendanceButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final double pulse;
  const _IntroAttendanceButton({required this.label, required this.color, required this.selected, required this.pulse});

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    height: 34,
    decoration: BoxDecoration(
      color: selected ? color.withOpacity(.14 + pulse * .05) : Colors.white,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: selected ? color : AppColors.line),
    ),
    child: Center(child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11.5))),
  );
}

class _MiniRankingRow extends StatelessWidget {
  final int position;
  final String name;
  final String points;
  final bool active;
  const _MiniRankingRow({required this.position, required this.name, required this.points, required this.active});

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 360),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(color: active ? Colors.white : Colors.white.withOpacity(.64), borderRadius: BorderRadius.circular(14)),
    child: Row(children: [
      Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(color: active ? AppColors.orange : AppColors.lineSoft, shape: BoxShape.circle),
        child: Center(child: Text('$position', style: TextStyle(color: active ? Colors.white : AppColors.muted, fontWeight: FontWeight.w900, fontSize: 11))),
      ),
      const SizedBox(width: 8),
      Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 12))),
      Text(points, style: TextStyle(color: active ? AppColors.green : AppColors.muted, fontWeight: FontWeight.w900, fontSize: 11)),
    ]),
  );
}
