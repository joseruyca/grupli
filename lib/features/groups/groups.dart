part of grupli_app;

class CreateJoinScreen extends StatelessWidget {
  const CreateJoinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DirectPage(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PageHeader(title: 'Añadir grupo', subtitle: 'Crea un grupo nuevo o entra con invitación.', leading: true),
        const SizedBox(height: 20),
        ChoiceBigCard(icon: Icons.groups_rounded, title: 'Crear un grupo', body: 'Crea tu grupo privado y empieza a organizar.', onTap: () async {
          final result = await Navigator.push<dynamic>(context, MaterialPageRoute(builder: (_) => const CreateGroupScreen()));
          if (context.mounted && result != null) Navigator.pop(context, result);
        }),
        const SizedBox(height: 12),
        ChoiceBigCard(icon: Icons.group_add_rounded, title: 'Unirse a un grupo', body: 'Únete a un grupo con código o enlace.', onTap: () async {
          final result = await Navigator.push<dynamic>(context, MaterialPageRoute(builder: (_) => const JoinGroupScreen()));
          if (context.mounted && result != null) Navigator.pop(context, result);
        }),
      ]),
    );
  }
}



Future<ui.Image> _decodeUiImage(Uint8List bytes) async {
  final completer = Completer<ui.Image>();
  ui.decodeImageFromList(bytes, (image) => completer.complete(image));
  return completer.future;
}

ui.Rect cropSourceRect({
  required ui.Image image,
  required double aspectRatio,
  required double zoom,
  required double offsetX,
  required double offsetY,
}) {
  final iw = image.width.toDouble();
  final ih = image.height.toDouble();
  final imageAspect = iw / ih;
  final baseW = imageAspect > aspectRatio ? ih * aspectRatio : iw;
  final baseH = imageAspect > aspectRatio ? ih : iw / aspectRatio;
  final safeZoom = zoom.clamp(1.0, 5.0).toDouble();
  final minW = min(64.0, iw);
  final minH = min(64.0, ih);
  final cropW = (baseW / safeZoom).clamp(minW, iw).toDouble();
  final cropH = (baseH / safeZoom).clamp(minH, ih).toDouble();
  final centerX = (iw / 2) + offsetX.clamp(-1.0, 1.0) * ((iw - cropW) / 2);
  final centerY = (ih / 2) + offsetY.clamp(-1.0, 1.0) * ((ih - cropH) / 2);
  final left = (centerX - cropW / 2).clamp(0.0, iw - cropW).toDouble();
  final top = (centerY - cropH / 2).clamp(0.0, ih - cropH).toDouble();
  return ui.Rect.fromLTWH(left, top, cropW, cropH);
}

Future<Uint8List> cropImageBytes({
  required Uint8List bytes,
  required double aspectRatio,
  required double zoom,
  required double offsetX,
  required double offsetY,
  required int outputWidth,
}) async {
  final image = await _decodeUiImage(bytes);
  final src = cropSourceRect(
    image: image,
    aspectRatio: aspectRatio,
    zoom: zoom,
    offsetX: offsetX,
    offsetY: offsetY,
  );
  final outputHeight = max(1, (outputWidth / aspectRatio).round());

  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final paint = ui.Paint()..filterQuality = ui.FilterQuality.high;
  canvas.drawImageRect(
    image,
    src,
    ui.Rect.fromLTWH(0, 0, outputWidth.toDouble(), outputHeight.toDouble()),
    paint,
  );
  final picture = recorder.endRecording();
  final cropped = await picture.toImage(outputWidth, outputHeight);
  final data = await cropped.toByteData(format: ui.ImageByteFormat.png);
  if (data == null) throw Exception('No se pudo preparar la imagen.');
  return data.buffer.asUint8List();
}



class ImageFrameEditorScreen extends StatefulWidget {
  final Uint8List bytes;
  final String title;
  final String helper;
  final double aspectRatio;
  final int outputWidth;
  final bool circularPreview;
  const ImageFrameEditorScreen({
    super.key,
    required this.bytes,
    required this.title,
    required this.helper,
    required this.aspectRatio,
    required this.outputWidth,
    this.circularPreview = false,
  });

  @override
  State<ImageFrameEditorScreen> createState() => _ImageFrameEditorScreenState();
}

class _ImageFrameEditorScreenState extends State<ImageFrameEditorScreen> {
  double zoom = 1;
  double offsetX = 0;
  double offsetY = 0;
  double _gestureStartZoom = 1;
  bool saving = false;
  late Future<ui.Image> imageFuture;

  @override
  void initState() {
    super.initState();
    imageFuture = _decodeUiImage(widget.bytes);
  }

  Future<void> save() async {
    setState(() => saving = true);
    try {
      final cropped = await cropImageBytes(
        bytes: widget.bytes,
        aspectRatio: widget.aspectRatio,
        zoom: zoom,
        offsetX: offsetX,
        offsetY: offsetY,
        outputWidth: widget.outputWidth,
      );
      if (mounted) Navigator.pop(context, cropped);
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _onScaleStart(ScaleStartDetails details) {
    _gestureStartZoom = zoom;
  }

  void _onScaleUpdate(ScaleUpdateDetails details, double frameWidth, double frameHeight, ui.Image image) {
    final nextZoom = (_gestureStartZoom * details.scale).clamp(1.0, 5.0).toDouble();
    final src = cropSourceRect(
      image: image,
      aspectRatio: widget.aspectRatio,
      zoom: nextZoom,
      offsetX: offsetX,
      offsetY: offsetY,
    );

    final rangeX = (image.width.toDouble() - src.width) / 2;
    final rangeY = (image.height.toDouble() - src.height) / 2;

    final deltaSrcX = frameWidth <= 0 ? 0.0 : -details.focalPointDelta.dx / frameWidth * src.width;
    final deltaSrcY = frameHeight <= 0 ? 0.0 : -details.focalPointDelta.dy / frameHeight * src.height;

    setState(() {
      zoom = nextZoom;
      if (rangeX > .5) {
        offsetX = (offsetX + deltaSrcX / rangeX).clamp(-1.0, 1.0).toDouble();
      } else {
        offsetX = 0;
      }
      if (rangeY > .5) {
        offsetY = (offsetY + deltaSrcY / rangeY).clamp(-1.0, 1.0).toDouble();
      } else {
        offsetY = 0;
      }
    });
  }

  void _focusAt(TapUpDetails details, double frameWidth, double frameHeight, ui.Image image) {
    final src = cropSourceRect(
      image: image,
      aspectRatio: widget.aspectRatio,
      zoom: zoom,
      offsetX: offsetX,
      offsetY: offsetY,
    );
    final local = details.localPosition;
    final targetX = src.left + (local.dx / max(1.0, frameWidth)).clamp(0.0, 1.0) * src.width;
    final targetY = src.top + (local.dy / max(1.0, frameHeight)).clamp(0.0, 1.0) * src.height;
    final rangeX = (image.width.toDouble() - src.width) / 2;
    final rangeY = (image.height.toDouble() - src.height) / 2;
    setState(() {
      if (rangeX > .5) {
        offsetX = ((targetX - image.width / 2) / rangeX).clamp(-1.0, 1.0).toDouble();
      }
      if (rangeY > .5) {
        offsetY = ((targetY - image.height / 2) / rangeY).clamp(-1.0, 1.0).toDouble();
      }
    });
  }

  void reset() => setState(() {
    zoom = 1;
    offsetX = 0;
    offsetY = 0;
  });

  void quickFocus(String value) => setState(() {
    switch (value) {
      case 'top':
        offsetY = -1;
        break;
      case 'bottom':
        offsetY = 1;
        break;
      case 'left':
        offsetX = -1;
        break;
      case 'right':
        offsetX = 1;
        break;
      default:
        offsetX = 0;
        offsetY = 0;
    }
  });

  @override
  Widget build(BuildContext context) {
    return DirectPage(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        RoundBackButton(),
        const Spacer(),
        TextButton(onPressed: saving ? null : save, child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.w900))),
      ]),
      const SizedBox(height: 18),
      Text(widget.title, style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 6),
      Text(widget.helper, style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x240B6B8F))),
        child: const Row(children: [
          Icon(Icons.center_focus_strong_rounded, color: AppColors.teal, size: 19),
          SizedBox(width: 8),
          Expanded(child: Text('Nuevo método: toca la cara o zona importante para centrarla. También puedes arrastrar y pellizcar con precisión real.', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 12.5))),
        ]),
      ),
      const SizedBox(height: 14),
      AppCard(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          FutureBuilder<ui.Image>(
            future: imageFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return AspectRatio(
                  aspectRatio: widget.aspectRatio,
                  child: const CenterLoader(label: 'Preparando imagen...'),
                );
              }
              final image = snapshot.data!;
              return LayoutBuilder(builder: (context, constraints) {
                final frameWidth = constraints.maxWidth;
                final frameHeight = frameWidth / widget.aspectRatio;
                return AspectRatio(
                  aspectRatio: widget.aspectRatio,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (details) => _focusAt(details, frameWidth, frameHeight, image),
                    onScaleStart: _onScaleStart,
                    onScaleUpdate: (details) => _onScaleUpdate(details, frameWidth, frameHeight, image),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(widget.circularPreview ? 999 : 22),
                      child: Container(
                        color: AppColors.navHome,
                        child: Stack(children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: CropFramePainter(
                                image: image,
                                aspectRatio: widget.aspectRatio,
                                zoom: zoom,
                                offsetX: offsetX,
                                offsetY: offsetY,
                              ),
                              child: const SizedBox.expand(),
                            ),
                          ),
                          Positioned.fill(
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white.withOpacity(.80), width: widget.circularPreview ? 3 : 2),
                                  borderRadius: BorderRadius.circular(widget.circularPreview ? 999 : 22),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 12,
                            right: 12,
                            bottom: 12,
                            child: IgnorePointer(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(color: const Color(0x99000000), borderRadius: BorderRadius.circular(999)),
                                child: const Text('Toca una zona para centrarla · arrastra para ajustar', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),
                );
              });
            },
          ),
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: [
            ActionChip(label: const Text('Arriba'), avatar: const Icon(Icons.keyboard_arrow_up_rounded, size: 18), onPressed: () => quickFocus('top')),
            ActionChip(label: const Text('Centro'), avatar: const Icon(Icons.filter_center_focus_rounded, size: 18), onPressed: () => quickFocus('center')),
            ActionChip(label: const Text('Abajo'), avatar: const Icon(Icons.keyboard_arrow_down_rounded, size: 18), onPressed: () => quickFocus('bottom')),
            ActionChip(label: const Text('Izquierda'), avatar: const Icon(Icons.keyboard_arrow_left_rounded, size: 18), onPressed: () => quickFocus('left')),
            ActionChip(label: const Text('Derecha'), avatar: const Icon(Icons.keyboard_arrow_right_rounded, size: 18), onPressed: () => quickFocus('right')),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.zoom_in_rounded, color: AppColors.teal),
            Expanded(
              child: Slider(
                value: zoom.clamp(1.0, 5.0).toDouble(),
                min: 1,
                max: 5,
                onChanged: (v) => setState(() => zoom = v),
                activeColor: AppColors.teal,
              ),
            ),
            const SizedBox(width: 8),
            Text('${zoom.toStringAsFixed(1)}x', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
          ]),
          Row(children: [
            const Icon(Icons.swap_vert_rounded, color: AppColors.violet),
            Expanded(
              child: Slider(
                value: offsetY.clamp(-1.0, 1.0).toDouble(),
                min: -1,
                max: 1,
                onChanged: (v) => setState(() => offsetY = v),
                activeColor: AppColors.violet,
              ),
            ),
            const SizedBox(width: 8),
            const Text('alto', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w900, fontSize: 12)),
          ]),
        ]),
      ),
      const SizedBox(height: 16),
      PrimaryButton(label: 'Guardar encuadre', icon: Icons.check_rounded, loading: saving, onTap: save),
      const SizedBox(height: 10),
      SecondaryButton(label: 'Restablecer encuadre', icon: Icons.restart_alt_rounded, onTap: reset),
    ]));
  }
}

class CropFramePainter extends CustomPainter {
  final ui.Image image;
  final double aspectRatio;
  final double zoom;
  final double offsetX;
  final double offsetY;

  CropFramePainter({
    required this.image,
    required this.aspectRatio,
    required this.zoom,
    required this.offsetX,
    required this.offsetY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final src = cropSourceRect(
      image: image,
      aspectRatio: aspectRatio,
      zoom: zoom,
      offsetX: offsetX,
      offsetY: offsetY,
    );
    final dst = Offset.zero & size;
    final paint = Paint()..filterQuality = FilterQuality.high;
    canvas.drawImageRect(image, src, dst, paint);
  }

  @override
  bool shouldRepaint(covariant CropFramePainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.aspectRatio != aspectRatio ||
        oldDelegate.zoom != zoom ||
        oldDelegate.offsetX != offsetX ||
        oldDelegate.offsetY != offsetY;
  }
}

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final name = TextEditingController();
  final description = TextEditingController();
  String type = 'otro';
  String currency = 'EUR';
  bool loading = false;
  Uint8List? coverBytes;
  String? coverFileName;
  int step = 0;

  @override
  void initState() {
    super.initState();
    description.text = groupTypeDefaultDescription('otro');
  }

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> pickCover() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 88, maxWidth: 2400);
    if (picked == null) return;
    final raw = await picked.readAsBytes();
    if (!mounted) return;
    final framed = await Navigator.of(context).push<Uint8List>(MaterialPageRoute(
      builder: (_) => ImageFrameEditorScreen(
        bytes: raw,
        title: 'Ajustar portada',
        helper: 'Arrastra y pellizca la imagen para encajar la portada como en una app real.',
        aspectRatio: 16 / 7,
        outputWidth: 1600,
      ),
    ));
    if (framed == null) return;
    setState(() {
      coverBytes = framed;
      coverFileName = 'group-cover.png';
    });
  }

  bool validateStep() {
    if (step == 0 && name.text.trim().length < 2) {
      showToast(context, 'Pon un nombre de grupo.', danger: true);
      return false;
    }
    return true;
  }

  Future<void> create() async {
    if (!validateStep()) return;
    setState(() => loading = true);
    try {
      final groupId = await AppData.createGroup(
        name.text,
        type: type,
        description: description.text,
        currency: currency,
      );
      if (coverBytes != null) {
        await AppData.uploadGroupCoverBytes(groupId, coverBytes!, coverFileName ?? 'group-cover.png');
      }
      if (!mounted) return;
      final action = await Navigator.of(context).push<String>(MaterialPageRoute(
        builder: (_) => GroupCreatedScreen(groupId: groupId, groupName: name.text.trim(), groupType: type),
      ));
      if (!mounted) return;
      Navigator.pop(context, {
        'action': action == 'open' ? 'open' : 'home',
        'groupId': groupId,
      });
    } catch (e) {
      await showToast(context, humanError(e), danger: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = step == 0 ? 'Crea tu grupo' : step == 1 ? 'Dale identidad' : 'Primeros pasos';
    final subtitle = step == 0
        ? 'Nombre y privacidad. Todo privado por defecto.'
        : step == 1
            ? 'Añade una portada y una descripción clara.'
            : 'Después de crearlo podrás invitar, crear el primer plan y añadir gastos.';
    return DirectPage(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          RoundBackButton(onTap: () => step == 0 ? Navigator.pop(context) : setState(() => step--)),
          const Spacer(),
          _MiniChip(text: '${step + 1}/3', color: AppColors.teal),
        ]),
        const SizedBox(height: 18),
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 18),
        _CreateGroupStepper(step: step),
        const SizedBox(height: 18),
        if (step == 0) ...[
          AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            FieldLabel('Nombre del grupo'),
            TextField(
              controller: name,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(hintText: 'Ej. Pádel los miércoles'),
            ),
            const SizedBox(height: 12),
            StatusNotice(
              icon: Icons.lock_outline_rounded,
              title: 'Grupo privado',
              body: 'Todos los grupos son privados. Después podrás invitar a miembros con código o enlace.',
            ),
          ])),
        ] else if (step == 1) ...[
          AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: pickCover,
              child: Container(
                height: 138,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(colors: [Color(0xFF041F33), Color(0xFF087A78)]),
                ),
                child: coverBytes == null
                    ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: const [
                        Icon(Icons.add_photo_alternate_rounded, color: Colors.white, size: 34),
                        SizedBox(height: 8),
                        Text('Añadir portada', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                        SizedBox(height: 4),
                        Text('Después podrás encuadrarla', style: TextStyle(color: Color(0xCCFFFFFF), fontWeight: FontWeight.w700, fontSize: 12)),
                      ]))
                    : Stack(children: [
                        Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(22), child: Image.memory(coverBytes!, fit: BoxFit.cover))),
                        Positioned(right: 12, bottom: 12, child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(color: Colors.black.withOpacity(.38), borderRadius: BorderRadius.circular(99)),
                          child: const Text('Cambiar encuadre', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                        )),
                      ]),
              ),
            ),
            const SizedBox(height: 16),
            FieldLabel('Descripción'),
            TextField(controller: description, minLines: 2, maxLines: 4, decoration: const InputDecoration(hintText: '¿Para qué usará el grupo Grupli?')),
            const SizedBox(height: 12),
            StatusNotice(
              icon: Icons.payments_rounded,
              title: 'Moneda del grupo',
              body: 'De momento el grupo usará euros. La selección de moneda se activará cuando Finanzas esté preparada para convertir importes de forma segura.',
            ),
          ])),
        ] else ...[
          AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _SetupTodoRow(icon: Icons.link_rounded, title: 'Invitar miembros', body: 'Comparte código o enlace por WhatsApp al terminar.'),
            const Divider(height: 20, color: AppColors.line),
            _SetupTodoRow(icon: Icons.event_available_rounded, title: 'Crear primer plan', body: 'Una quedada rápida para que todos confirmen asistencia.'),
            const Divider(height: 20, color: AppColors.line),
            _SetupTodoRow(icon: Icons.account_balance_wallet_rounded, title: 'Primer gasto', body: 'Si el grupo ya tiene gastos, Grupli calculará saldos.'),
            const Divider(height: 20, color: AppColors.line),
            _SetupTodoRow(icon: Icons.emoji_events_rounded, title: 'Torneo opcional', body: 'Si el grupo lo necesita, podrás crear liga, eliminatoria, americano o partidos manuales.'),
          ])),
        ],
        const SizedBox(height: 22),
        if (step < 2)
          PrimaryButton(label: 'Continuar', icon: Icons.arrow_forward_rounded, onTap: () { if (validateStep()) setState(() => step++); })
        else
          PrimaryButton(label: 'Crear grupo', icon: Icons.check_rounded, loading: loading, onTap: create),
        const SizedBox(height: 10),
        if (step < 2) SecondaryButton(label: 'Crear rápido', icon: Icons.bolt_rounded, onTap: create),
      ]),
    );
  }
}

class _CreateGroupStepper extends StatelessWidget {
  final int step;
  const _CreateGroupStepper({required this.step});
  @override
  Widget build(BuildContext context) => Row(children: List.generate(3, (i) {
    final active = i <= step;
    return Expanded(child: Container(
      height: 6,
      margin: EdgeInsets.only(right: i == 2 ? 0 : 8),
      decoration: BoxDecoration(color: active ? AppColors.teal : AppColors.line, borderRadius: BorderRadius.circular(99)),
    ));
  }));
}

class _SetupTodoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _SetupTodoRow({required this.icon, required this.title, required this.body});
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: AppColors.teal)),
    const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
      const SizedBox(height: 3),
      Text(body, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.28)),
    ])),
  ]);
}

class GroupCreatedScreen extends StatelessWidget {
  final String groupId;
  final String groupName;
  final String groupType;
  const GroupCreatedScreen({super.key, required this.groupId, required this.groupName, required this.groupType});

  @override
  Widget build(BuildContext context) => DirectPage(
    scroll: false,
    child: Center(child: AppCard(padding: const EdgeInsets.all(22), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 82, height: 82, decoration: const BoxDecoration(color: AppColors.greenSoft, shape: BoxShape.circle), child: const Icon(Icons.check_rounded, color: AppColors.green, size: 42)),
      const SizedBox(height: 18),
      Text('Grupo creado', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
      const SizedBox(height: 8),
      Text('$groupName ya está listo. Ahora invita gente o crea el primer plan.', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
      const SizedBox(height: 18),
      PrimaryButton(label: 'Entrar al grupo', icon: Icons.arrow_forward_rounded, onTap: () => Navigator.pop(context, 'open')),
      const SizedBox(height: 10),
      SecondaryButton(label: 'Volver a mis grupos', icon: Icons.home_rounded, onTap: () => Navigator.pop(context, 'home')),
    ]))),
  );
}

class JoinGroupScreen extends StatefulWidget {
  final String? initialCode;
  const JoinGroupScreen({super.key, this.initialCode});

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final code = TextEditingController();
  bool loading = false;

  @override
  void initState() {
    super.initState();
    code.text = InviteLinks.normalizeCode(widget.initialCode ?? '');
  }

  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  Future<void> join() async {
    final clean = InviteLinks.codeFromText(code.text);
    if (clean == null || clean.length < 4) {
      await showToast(context, 'Introduce un código o enlace válido.', danger: true);
      return;
    }
    setState(() => loading = true);
    try {
      final groupId = await AppData.joinGroup(clean);
      if (!mounted) return;
      Navigator.pop(context, {
        'action': 'open',
        'groupId': groupId,
      });
    } catch (e) {
      await showToast(context, humanError(e), danger: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DirectPage(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        RoundBackButton(onTap: () => Navigator.pop(context)),
        const SizedBox(height: 28),
        Text('Unirme a un grupo', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text('Pega un código o un enlace de invitación. Si vienes desde un enlace, lo rellenamos automáticamente.', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 26),
        FieldLabel('Código o enlace de invitación'),
        TextField(
          controller: code,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(prefixIcon: Icon(Icons.link_rounded), hintText: 'ABC123 o https://grupli.vercel.app/join/ABC123'),
        ),
        const SizedBox(height: 18),
        PrimaryButton(label: 'Unirme', icon: Icons.login_rounded, loading: loading, onTap: join),
      ]),
    );
  }
}

class JoinInviteScreen extends StatefulWidget {
  final String inviteCode;
  const JoinInviteScreen({super.key, required this.inviteCode});

  @override
  State<JoinInviteScreen> createState() => _JoinInviteScreenState();
}

class _JoinInviteScreenState extends State<JoinInviteScreen> {
  bool loading = true;
  bool joined = false;
  String? groupId;
  String? groupName;
  String? error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _joinFromLink());
  }

  Future<void> _joinFromLink() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final joinedGroupId = await AppData.joinGroup(widget.inviteCode);
      final group = await AppData.group(joinedGroupId);
      if (!mounted) return;
      setState(() {
        groupId = joinedGroupId;
        groupName = AppData.text(group['name'], 'Grupo');
        joined = true;
        loading = false;
      });
      await Future.delayed(const Duration(milliseconds: 650));
      if (!mounted || groupId == null) return;
      Navigator.pop(context, {
        'action': 'open',
        'groupId': groupId!,
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = humanError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DirectPage(
      scroll: false,
      child: Center(
        child: AppCard(
          padding: const EdgeInsets.all(22),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(color: joined ? AppColors.greenSoft : AppColors.tealSoft, shape: BoxShape.circle),
              child: Icon(joined ? Icons.check_rounded : Icons.group_add_rounded, color: joined ? AppColors.green : AppColors.teal, size: 40),
            ),
            const SizedBox(height: 18),
            Text(
              loading ? 'Entrando al grupo...' : joined ? 'Ya estás dentro' : 'No se pudo abrir la invitación',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              loading
                  ? 'Estamos usando el enlace privado ${widget.inviteCode}.'
                  : joined
                      ? 'Te llevamos a ${groupName ?? 'tu grupo'} automáticamente.'
                      : (error ?? 'El enlace puede haber caducado o el código no es válido.'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            if (loading)
              const CircularProgressIndicator(color: AppColors.teal)
            else if (joined && groupId != null)
              PrimaryButton(label: 'Entrar al grupo', icon: Icons.arrow_forward_rounded, onTap: () => Navigator.pop(context, {
                'action': 'open',
                'groupId': groupId!,
              }))
            else ...[
              PrimaryButton(label: 'Intentar otra vez', icon: Icons.refresh_rounded, onTap: _joinFromLink),
              const SizedBox(height: 10),
              SecondaryButton(label: 'Escribir código', icon: Icons.qr_code_rounded, onTap: () async {
                final result = await Navigator.of(context).push<dynamic>(MaterialPageRoute(builder: (_) => JoinGroupScreen(initialCode: widget.inviteCode)));
                if (result != null && mounted) Navigator.pop(context, result);
              }),
            ],
          ]),
        ),
      ),
    );
  }
}

class GroupShell extends StatefulWidget {
  final String groupId;
  final int initialTab;
  const GroupShell({super.key, required this.groupId, this.initialTab = 0});

  @override
  State<GroupShell> createState() => _GroupShellState();
}

class _GroupShellState extends State<GroupShell> {
  int tab = 0;
  int refreshKey = 0;
  int dashboardRefreshKey = 0;
  int calendarRefreshKey = 0;
  int financeRefreshKey = 0;
  int tournamentsRefreshKey = 0;
  late Future<Map<String, dynamic>> groupFuture;
  Map<String, dynamic>? _cachedGroup;
  RealtimeChannel? _groupRealtimeChannel;
  Timer? _realtimeDebounce;
  final Set<String> _pendingRealtimeScopes = <String>{};

  @override
  void initState() {
    super.initState();
    tab = widget.initialTab.clamp(0, 4).toInt();
    groupFuture = AppData.group(widget.groupId);
    _subscribeGroupRealtime();
  }

  @override
  void dispose() {
    _realtimeDebounce?.cancel();
    final channel = _groupRealtimeChannel;
    if (channel != null) {
      AppData.sb.removeChannel(channel);
    }
    super.dispose();
  }

  void refresh() => _refreshGroupAndAll();

  void selectTab(int nextTab) {
    if (nextTab == tab) return;
    appLightHaptic();
    setState(() => tab = nextTab);
  }

  void _refreshGroupAndAll() {
    if (!mounted) return;
    setState(() {
      refreshKey++;
      dashboardRefreshKey++;
      calendarRefreshKey++;
      financeRefreshKey++;
      tournamentsRefreshKey++;
      groupFuture = AppData.group(widget.groupId);
    });
  }

  void _refreshRealtimeScopes(Set<String> scopes) {
    if (!mounted || scopes.isEmpty) return;
    setState(() {
      if (scopes.contains('group') || scopes.contains('all')) {
        refreshKey++;
        dashboardRefreshKey++;
        calendarRefreshKey++;
        financeRefreshKey++;
        tournamentsRefreshKey++;
        groupFuture = AppData.group(widget.groupId);
        return;
      }
      final touchesDashboard = scopes.contains('dashboard') || scopes.contains('calendar') || scopes.contains('finance') || scopes.contains('tournaments');
      if (touchesDashboard) dashboardRefreshKey++;
      if (scopes.contains('calendar')) calendarRefreshKey++;
      if (scopes.contains('finance')) financeRefreshKey++;
      if (scopes.contains('tournaments')) tournamentsRefreshKey++;
    });
  }

  void _scheduleRealtimeRefresh([String scope = 'all']) {
    _pendingRealtimeScopes.add(scope);
    _realtimeDebounce?.cancel();
    _realtimeDebounce = Timer(const Duration(milliseconds: 700), () {
      final scopes = Set<String>.from(_pendingRealtimeScopes);
      _pendingRealtimeScopes.clear();
      _refreshRealtimeScopes(scopes);
    });
  }

  void _subscribeGroupRealtime() {
    // v15.32: Realtime automático desactivado temporalmente.
    // Evita parpadeos por setState global + refreshKey + FutureBuilder mientras estabilizamos navegación/estado.
    if (!AppConfig.enableRealtimeSubscriptions) return;
    final groupId = widget.groupId;
    final channel = AppData.sb.channel('grupli-group-$groupId-live')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'groups',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'id', value: groupId),
        callback: (_) => _scheduleRealtimeRefresh('group'),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'group_members',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'group_id', value: groupId),
        callback: (_) => _scheduleRealtimeRefresh('group'),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'events',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'group_id', value: groupId),
        callback: (_) => _scheduleRealtimeRefresh('calendar'),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'expenses',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'group_id', value: groupId),
        callback: (_) => _scheduleRealtimeRefresh('finance'),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'settlement_payments',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'group_id', value: groupId),
        callback: (_) => _scheduleRealtimeRefresh('finance'),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'tournaments',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'group_id', value: groupId),
        callback: (_) => _scheduleRealtimeRefresh('tournaments'),
      )
      // Tablas hijas con group_id directo para evitar refrescos globales.
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'event_attendance',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'group_id', value: groupId),
        callback: (_) => _scheduleRealtimeRefresh('calendar'),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'expense_participants',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'group_id', value: groupId),
        callback: (_) => _scheduleRealtimeRefresh('finance'),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'tournament_teams',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'group_id', value: groupId),
        callback: (_) => _scheduleRealtimeRefresh('tournaments'),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'matches',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'group_id', value: groupId),
        callback: (_) => _scheduleRealtimeRefresh('tournaments'),
      )
      ..subscribe();
    _groupRealtimeChannel = channel;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: groupFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
          _cachedGroup = snapshot.data;
        }
        if (snapshot.connectionState == ConnectionState.waiting && _cachedGroup == null) {
          return const DirectPage(child: CenterLoader(label: 'Cargando grupo...'));
        }
        if (snapshot.hasError && _cachedGroup == null) {
          return DirectPage(child: ErrorBlock(message: snapshot.error.toString(), onRetry: refresh));
        }
        final group = snapshot.data ?? _cachedGroup ?? <String, dynamic>{'id': widget.groupId, 'name': 'Grupo'};
        final name = AppData.text(group['name'], 'Grupo');
        final pages = [
          GroupDashboardTab(group: group, refreshSeed: dashboardRefreshKey, onNavigateTab: selectTab, onGroupChanged: refresh),
          CalendarTab(groupId: widget.groupId, group: group, refreshSeed: calendarRefreshKey),
          FinancesTab(group: group, refreshSeed: financeRefreshKey),
          TournamentsTab(group: group, refreshSeed: tournamentsRefreshKey),
          GroupMoreTab(group: group, refresh: refresh),
        ];
        return WillPopScope(
          onWillPop: () async {
            if (tab != 0) {
              selectTab(0);
              return false;
            }
            return true;
          },
          child: Scaffold(
            backgroundColor: AppColors.white,
            body: IndexedStack(index: tab, children: pages),
            bottomNavigationBar: GroupBottomNav(groupName: name, index: tab, onTap: selectTab),
          ),
        );
      },
    );
  }
}

class GroupDashboardTab extends StatefulWidget {
  final Map<String, dynamic> group;
  final int refreshSeed;
  final ValueChanged<int>? onNavigateTab;
  final VoidCallback? onGroupChanged;
  const GroupDashboardTab({super.key, required this.group, required this.refreshSeed, this.onNavigateTab, this.onGroupChanged});

  @override
  State<GroupDashboardTab> createState() => _GroupDashboardTabState();
}

class _GroupDashboardTabState extends State<GroupDashboardTab> {
  late Future<_GroupDashboardData> future;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void didUpdateWidget(covariant GroupDashboardTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSeed != widget.refreshSeed) load();
  }

  void load() {
    final groupId = widget.group['id'].toString();
    future = _GroupDashboardData.load(groupId);
  }

  void reload() => setState(load);

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final name = AppData.text(group['name'], 'Grupo');
    return SafeArea(
      bottom: false,
      child: FutureBuilder<_GroupDashboardData>(
        future: future,
        builder: (context, snapshot) {
              final data = snapshot.data;
              final events = data?.events ?? <Map<String, dynamic>>[];
              final upcoming = data?.upcomingEvents ?? <Map<String, dynamic>>[];
              final nextEvent = upcoming.isNotEmpty ? upcoming.first : null;
              final nextDayEvents = eventsOnSameDay(upcoming, nextEvent);
              final myDecisionPending = upcoming.where((event) {
                final mine = myAttendanceStatus(event);
                return mine == null || mine == 'maybe';
              }).toList();
              Future<void> openCreateEvent() async {
                final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => CreateEventScreen(group: group)));
                if (ok == true) reload();
              }

              Future<void> openEventDetail(Map<String, dynamic> event) async {
                await Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventDetailScreen(event: event, group: group)));
                reload();
              }

              Future<void> openGroupSettings() async {
                final result = await Navigator.of(context).push<dynamic>(MaterialPageRoute(
                  builder: (_) => GroupSettingsScreen(
                    group: group,
                    onChanged: () {
                      widget.onGroupChanged?.call();
                      reload();
                    },
                  ),
                ));
                if (result == 'deleted') {
                  widget.onGroupChanged?.call();
                  if (context.mounted) Navigator.of(context).pop(true);
                  return;
                }
                widget.onGroupChanged?.call();
                reload();
              }

              void openGroupActions() {
                showGroupQuickActionsSheet(
                  context,
                  group: group,
                  onSettings: openGroupSettings,
                  onMembers: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MembersScreen(group: group))),
                  onMore: () => widget.onNavigateTab?.call(4),
                  onReport: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SupportTicketScreen(group: group, screen: 'grupo'))),
                );
              }

              return RefreshIndicator(
                color: AppColors.teal,
                onRefresh: () async => reload(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 96),
                  children: [
                    Row(children: [
                      RoundBackButton(onTap: () => Navigator.of(context).pop()),
                      const Spacer(),
                      GroupAlertBell(
                        group: group,
                        pendingEvents: myDecisionPending,
                        onEventOpen: openEventDetail,
                        onChanged: reload,
                      ),
                      const SizedBox(width: 8),
                      OwnProfileButton(
                        onTap: () async {
                          await Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => ProfileScreen(onChanged: () {
                              widget.onGroupChanged?.call();
                              reload();
                            }),
                          ));
                          widget.onGroupChanged?.call();
                          reload();
                        },
                      ),
                    ]),
                    const SizedBox(height: 12),
                    GroupHeroCard(
                      name: name,
                      coverUrl: AppData.text(group['cover_url']),
                      onEdit: openGroupSettings,
                      onMore: openGroupActions,
                    ),
                    const SizedBox(height: 8),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const CenterLoader(label: 'Cargando resumen...')
                    else if (snapshot.hasError)
                      ErrorBlock(message: snapshot.error.toString(), onRetry: reload)
                    else ...[
                      GroupDashboardIntro(nextEvent: nextEvent, pendingCount: myDecisionPending.length),
                      const SizedBox(height: 14),
                      SectionHeader(
                        title: 'Lo próximo',
                        action: nextEvent == null ? 'Crear plan' : 'Ver planes',
                        onTap: nextEvent == null ? openCreateEvent : () => widget.onNavigateTab?.call(1),
                      ),
                      const SizedBox(height: 8),
                      if (nextEvent == null)
                        EmptySlim(
                          icon: Icons.event_available_rounded,
                          title: 'Sin planes todavía',
                          body: 'Crea un plan y el grupo podrá decir si va.',
                        )
                      else if (nextDayEvents.length > 1)
                        DashboardUpcomingEventsCard(events: nextDayEvents, group: group, onChanged: reload)
                      else
                        DashboardEventCard(event: nextEvent, group: group, onChanged: reload),
                      const SizedBox(height: 16),
                      const SectionHeader(title: 'Últimos cambios'),
                      const SizedBox(height: 8),
                      DashboardActivityCard(
                        events: events,
                        expenses: data?.expenses ?? const <Map<String, dynamic>>[],
                        tournaments: data?.tournaments ?? const <Map<String, dynamic>>[],
                        onOpenCalendar: () => widget.onNavigateTab?.call(1),
                        onOpenFinances: () => widget.onNavigateTab?.call(2),
                        onOpenTournaments: () => widget.onNavigateTab?.call(3),
                      ),
                    ],
                  ],
                ),
              );
        },
      ),
    );
  }
}

class _GroupDashboardData {
  final List<Map<String, dynamic>> events;
  final List<Map<String, dynamic>> expenses;
  final List<Map<String, dynamic>> tournaments;

  const _GroupDashboardData({required this.events, required this.expenses, required this.tournaments});

  static Future<_GroupDashboardData> load(String groupId) async {
    final results = await Future.wait([
      AppData.events(groupId),
      AppData.expenses(groupId),
      AppData.tournaments(groupId),
    ]);
    return _GroupDashboardData(events: results[0], expenses: results[1], tournaments: results[2]);
  }

  List<Map<String, dynamic>> get upcomingEvents {
    final now = DateTime.now().subtract(const Duration(hours: 2));
    final list = events.where((event) {
      final date = DateTime.tryParse(event['starts_at']?.toString() ?? '')?.toLocal();
      return date != null && date.isAfter(now);
    }).toList();
    list.sort((a, b) {
      final da = DateTime.tryParse(a['starts_at']?.toString() ?? '') ?? DateTime.now();
      final db = DateTime.tryParse(b['starts_at']?.toString() ?? '') ?? DateTime.now();
      return da.compareTo(db);
    });
    return list;
  }

  double get expensesTotal => expenses.fold<double>(0, (sum, e) => sum + AppData.doubleValue(e['amount']));
  int get activeTournaments => tournaments.where((t) => AppData.text(t['status'], 'active') != 'finished').length;
}



class GroupMoreTab extends StatelessWidget {
  final Map<String, dynamic> group;
  final VoidCallback refresh;
  const GroupMoreTab({super.key, required this.group, required this.refresh});

  @override
  Widget build(BuildContext context) {
    final name = AppData.text(group['name'], 'Grupo');
    final code = AppData.text(group['invite_code'], '------');
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 112),
        children: [
          PageHeader(title: 'Más', subtitle: 'Miembros, invitaciones y ajustes.', leading: false),
          const SizedBox(height: 14),
          InviteAccessCard(groupName: name, code: code),
          const SizedBox(height: 14),
          SectionHeader(title: 'Grupo'),
          const SizedBox(height: 8),
          SettingsRow(
            icon: Icons.groups_rounded,
            title: 'Miembros y admins',
            subtitle: 'Roles, admins y expulsiones seguras',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MembersScreen(group: group))),
          ),
          SettingsRow(
            icon: Icons.verified_user_rounded,
            title: 'Permisos',
            subtitle: 'Qué puede hacer cada rol',
            onTap: () => showPermissionSheet(context),
          ),
          SettingsRow(
            icon: Icons.settings_rounded,
            title: 'Ajustes del grupo',
            subtitle: 'Nombre, portada y acciones importantes',
            onTap: () async {
              final result = await Navigator.of(context).push<dynamic>(MaterialPageRoute(builder: (_) => GroupSettingsScreen(group: group, onChanged: refresh)));
              if (result == 'deleted') {
                refresh();
                if (context.mounted) Navigator.of(context).pop(true);
              } else {
                refresh();
              }
            },
          ),
          SettingsRow(
            icon: Icons.support_agent_rounded,
            title: 'Reportar problema',
            subtitle: 'Enviar una incidencia sobre este grupo',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SupportTicketScreen(group: group, screen: 'grupo'))),
          ),
          const SizedBox(height: 16),
          PermissionMatrixCard(compact: true),
        ],
      ),
    );
  }
}
