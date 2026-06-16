part of grupli_app;

class WelcomeScreen extends StatelessWidget {
  final VoidCallback? onShowIntro;
  const WelcomeScreen({super.key, this.onShowIntro});

  Future<void> _openAuth(BuildContext context, {required bool register}) async {
    await PendingInviteStore.save(InviteLinks.currentCode);
    if (!context.mounted) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => AuthScreen(register: register, inviteCode: InviteLinks.currentCode)));
  }

  @override
  Widget build(BuildContext context) {
    final inviteCode = InviteLinks.currentCode;
    return DirectPage(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 30),
      child: Column(
        children: [
          if (inviteCode != null) ...[
            InviteLandingBanner(code: inviteCode),
            const SizedBox(height: 14),
          ],
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 46, 24, 38),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(31),
              gradient: const LinearGradient(colors: [Color(0xFF00A597), Color(0xFF005F66)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: Column(
              children: [
                Wrap(
                  spacing: 26,
                  runSpacing: 19,
                  alignment: WrapAlignment.center,
                  children: List.generate(32, (i) => Icon(_welcomeIcon(i), color: Colors.white.withOpacity(0.11), size: 18)),
                ),
                const SizedBox(height: 18),
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(29)),
                  child: const Icon(Icons.groups_rounded, color: AppColors.teal, size: 42),
                ),
                const SizedBox(height: 22),
                const Text('grupli', style: TextStyle(fontSize: 45, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1.5)),
                const SizedBox(height: 10),
                const Text('Organiza tu grupo.\nDisfruta más.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 18, height: 1.16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 28),
                SizedBox(width: double.infinity, child: WhiteButton(label: inviteCode == null ? 'Comenzar' : 'Crear cuenta y unirme', onTap: () => _openAuth(context, register: true))),
                TextButton(onPressed: () => _openAuth(context, register: false), child: Text(inviteCode == null ? 'Iniciar sesión' : 'Ya tengo cuenta', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
              ],
            ),
          ),
          const SizedBox(height: 23),
          Text('La app privada para coordinar grupos sin caos.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          const Text('Eventos, calendario, finanzas y torneos en un único espacio cerrado.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, fontSize: 15, height: 1.35)),
          if (inviteCode == null && onShowIntro != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onShowIntro,
              icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
              label: const Text('Ver introducción', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ],
      ),
    );
  }

  IconData _welcomeIcon(int index) {
    const icons = [Icons.event_available_rounded, Icons.calendar_month_rounded, Icons.account_balance_wallet_rounded, Icons.emoji_events_rounded, Icons.lock_rounded, Icons.qr_code_rounded];
    return icons[index % icons.length];
  }
}

class InviteLandingBanner extends StatelessWidget {
  final String code;
  const InviteLandingBanner({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.tealSoft,
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Container(width: 42, height: 42, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.mark_email_unread_rounded, color: AppColors.teal)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Te han invitado a un grupo', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 3),
          Text('Código $code · inicia sesión y entraremos automáticamente.', style: Theme.of(context).textTheme.bodyMedium),
        ])),
      ]),
    );
  }
}

class AuthScreen extends StatefulWidget {
  final bool register;
  final String? inviteCode;
  const AuthScreen({super.key, required this.register, this.inviteCode});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  bool hidden = true;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (email.text.trim().isEmpty || password.text.length < 6) {
      await showToast(context, 'Introduce email y contraseña de al menos 6 caracteres.', danger: true);
      return;
    }
    setState(() => loading = true);
    try {
      await PendingInviteStore.save(widget.inviteCode ?? InviteLinks.currentCode);
      if (widget.register) {
        await AppData.sb.auth.signUp(email: email.text.trim(), password: password.text.trim());
      } else {
        // En APK puede quedar una sesión local vieja de otra instalación o de una prueba anterior.
        // La limpiamos solo en el dispositivo antes de iniciar sesión para evitar bucles de sesión caducada.
        await AppData.clearLocalSession();
        await AppData.sb.auth.signInWithPassword(email: email.text.trim(), password: password.text.trim());
      }
      await AppData.ensureProfile();
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      await showToast(context, humanError(e), danger: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> resetPassword() async {
    final mail = email.text.trim();
    if (mail.isEmpty) {
      await showToast(context, 'Introduce tu email y te enviaremos un enlace para cambiar la contraseña.', danger: true);
      return;
    }
    setState(() => loading = true);
    try {
      await AppData.sb.auth.resetPasswordForEmail(
        mail,
        redirectTo: AppConfig.appBaseUrl,
      );
      if (!mounted) return;
      await showToast(context, 'Te hemos enviado un enlace para cambiar la contraseña.');
    } catch (e) {
      if (!mounted) return;
      await showToast(context, humanError(e), danger: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> oauth(OAuthProvider provider) async {
    try {
      await PendingInviteStore.save(widget.inviteCode ?? InviteLinks.currentCode);
      await AppData.clearLocalSession();
      await AppData.sb.auth.signInWithOAuth(provider, redirectTo: Uri.base.origin);
    } catch (e) {
      await showToast(context, humanError(e), danger: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DirectPage(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        RoundBackButton(onTap: () => Navigator.of(context).maybePop()),
        const SizedBox(height: 18),
        Text(widget.register ? 'Crear cuenta' : '¡Bienvenido de nuevo!', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(widget.register ? 'Empieza a organizar tus grupos privados.' : 'Inicia sesión para continuar.', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 24),
        SocialButton(label: 'Continuar con Google', icon: 'G', onTap: () => oauth(OAuthProvider.google)),
        const SizedBox(height: 10),
        SocialButton(label: 'Continuar con Apple', icon: '', onTap: () => oauth(OAuthProvider.apple)),
        const SizedBox(height: 24),
        const OrDivider(),
        const SizedBox(height: 22),
        FieldLabel('Correo electrónico'),
        TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(prefixIcon: Icon(Icons.mail_outline_rounded), hintText: 'tu@email.com')),
        const SizedBox(height: 15),
        FieldLabel('Contraseña'),
        TextField(
          controller: password,
          obscureText: hidden,
          decoration: InputDecoration(prefixIcon: const Icon(Icons.lock_outline_rounded), hintText: '••••••••', suffixIcon: IconButton(icon: Icon(hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined), onPressed: () => setState(() => hidden = !hidden))),
        ),
        if (!widget.register)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: loading ? null : resetPassword,
              child: const Text('¿Olvidaste tu contraseña?'),
            ),
          ),
        const SizedBox(height: 16),
        PrimaryButton(label: widget.register ? 'Crear cuenta' : 'Iniciar sesión', icon: widget.register ? Icons.person_add_alt_1_rounded : Icons.login_rounded, loading: loading, onTap: submit),
        const SizedBox(height: 22),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(widget.register ? '¿Ya tienes cuenta?' : '¿No tienes cuenta?', style: Theme.of(context).textTheme.bodyMedium),
          TextButton(onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => AuthScreen(register: !widget.register, inviteCode: widget.inviteCode))), child: Text(widget.register ? 'Inicia sesión' : 'Regístrate')),
        ]),
      ]),
    );
  }
}

class AuthedShell extends StatefulWidget {
  const AuthedShell({super.key});

  @override
  State<AuthedShell> createState() => _AuthedShellState();
}

class _AuthedShellState extends State<AuthedShell> {
  int tab = 0;
  int refreshKey = 0;
  bool handledInitialInvite = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleInitialInvite();
      PushNotificationService.tryRegisterSilently();
    });
  }

  Future<void> _handleInitialInvite() async {
    if (handledInitialInvite || !mounted) return;
    handledInitialInvite = true;
    final code = InviteLinks.currentCode ?? await PendingInviteStore.read();
    if (code == null || code.length < 4) return;
    await PendingInviteStore.clear();
    if (!mounted) return;
    final result = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(builder: (_) => JoinInviteScreen(inviteCode: code)),
    );
    if (!mounted) return;
    await _handleGroupNavigationResult(result);
  }

  void refresh() => setState(() => refreshKey++);

  void selectTab(int nextTab) {
    if (nextTab == tab) return;
    appLightHaptic();
    setState(() => tab = nextTab);
  }

  Future<void> _handleGroupNavigationResult(dynamic result) async {
    if (!mounted || result == null) return;
    final shouldRefresh = result == true || result is Map;
    if (shouldRefresh) {
      setState(() {
        tab = 0;
        refreshKey++;
      });
    }
    if (result is Map && result['action'] == 'open' && result['groupId'] != null) {
      final groupId = result['groupId'].toString();
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => GroupShell(groupId: groupId)));
      if (mounted) refresh();
    }
  }


  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(key: ValueKey('home-$refreshKey'), onChanged: refresh),
      NotificationsScreen(onChanged: refresh),
      ProfileScreen(onChanged: refresh, onNavigateRoot: selectTab),
    ];
    return Scaffold(
      backgroundColor: AppColors.white,
      body: IndexedStack(index: tab, children: pages),
      bottomNavigationBar: RootBottomNav(index: tab, onTap: selectTab),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final VoidCallback onChanged;
  const HomeScreen({super.key, required this.onChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Map<String, dynamic>>> future;
  RealtimeChannel? _homeRealtimeChannel;
  Timer? _homeRealtimeDebounce;

  @override
  void initState() {
    super.initState();
    future = AppData.myGroups();
    _subscribeHomeRealtime();
  }

  @override
  void dispose() {
    _homeRealtimeDebounce?.cancel();
    final channel = _homeRealtimeChannel;
    if (channel != null) {
      AppData.sb.removeChannel(channel);
    }
    super.dispose();
  }

  void reload() {
    if (!mounted) return;
    setState(() { future = AppData.myGroups(); });
  }

  Future<void> _handleGroupNavigationResult(dynamic result) async {
    if (!mounted || result == null) return;
    if (result is Map && result['action'] == 'open' && result['groupId'] != null) {
      final groupId = result['groupId'].toString();
      reload();
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => GroupShell(groupId: groupId)));
      if (mounted) {
        reload();
        widget.onChanged();
      }
      return;
    }
    if (result == true || result is Map) {
      reload();
      widget.onChanged();
    }
  }

  Future<void> _openCreateJoin() async {
    final result = await Navigator.of(context).push<dynamic>(MaterialPageRoute(builder: (_) => const CreateJoinScreen()));
    await _handleGroupNavigationResult(result);
  }

  Future<void> _openCreateGroup() async {
    final result = await Navigator.of(context).push<dynamic>(MaterialPageRoute(builder: (_) => const CreateGroupScreen()));
    await _handleGroupNavigationResult(result);
  }

  Future<void> _openJoinGroup() async {
    final result = await Navigator.of(context).push<dynamic>(MaterialPageRoute(builder: (_) => const JoinGroupScreen()));
    await _handleGroupNavigationResult(result);
  }

  void _scheduleHomeRealtimeReload() {
    _homeRealtimeDebounce?.cancel();
    _homeRealtimeDebounce = Timer(const Duration(milliseconds: 600), () {
      if (mounted) reload();
    });
  }

  void _subscribeHomeRealtime() {
    // v15.32: Realtime automático desactivado temporalmente.
    // Motivo: varios listeners reconstruían pantallas completas y podían crear bucles de refresco/parpadeo en web/APK.
    // La app refresca de forma explícita tras crear/editar/borrar. Reactivarlo solo con streams por pantalla y QA.
    if (!AppConfig.enableRealtimeSubscriptions) return;
    final userId = AppData.user?.id ?? 'anon';
    final channel = AppData.sb.channel('grupli-home-$userId-live')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'group_members',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: userId),
        callback: (_) => _scheduleHomeRealtimeReload(),
      )
      ..subscribe();
    _homeRealtimeChannel = channel;
  }

  @override
  Widget build(BuildContext context) {
    final email = AppData.user?.email ?? 'usuario@email.com';
    final name = email.split('@').first;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(child: PageHeader(title: 'Mis grupos', subtitle: 'Hola, $name. Aquí tienes tus grupos y planes.')),
            const SizedBox(width: 12),
            CircleIconButton(icon: Icons.add_rounded, filled: true, onTap: _openCreateJoin),
          ]),
          const SizedBox(height: 20),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const HomeLoading();
              if (snapshot.hasError) return ErrorBlock(message: snapshot.error.toString(), onRetry: reload);
              final groups = snapshot.data ?? [];
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('Tus grupos', style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  TextButton(onPressed: reload, child: const Text('Actualizar')),
                ]),
                const SizedBox(height: 10),
                if (groups.isEmpty) ...[
                  EmptyBlock(icon: Icons.groups_rounded, title: 'Aún no tienes grupos', body: 'Crea tu primer grupo o entra con un código.'),
                  const SizedBox(height: 14),
                  PrimaryButton(label: 'Crear grupo', icon: Icons.add_rounded, onTap: _openCreateGroup),
                  const SizedBox(height: 10),
                  SecondaryButton(label: 'Unirme con código', icon: Icons.qr_code_rounded, onTap: _openJoinGroup),
                ] else ...[
                  ...groups.map((g) => GroupHomeCard(group: g, onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => GroupShell(groupId: g['id'].toString())));
                    reload();
                  })),
                  const SizedBox(height: 14),
                  ChoiceBigCard(
                    icon: Icons.add_circle_outline_rounded,
                    title: 'Crear o unirme a un grupo',
                    body: 'Crea uno nuevo o entra con un código.',
                    onTap: _openCreateJoin,
                  ),
                ],
              ]);
            },
          ),
        ],
      ),
    );
  }
}
