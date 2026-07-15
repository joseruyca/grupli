part of grupli_app;

class AppData {
  static SupabaseClient get sb => Supabase.instance.client;
  static User? get user => sb.auth.currentUser;

  static Future<void> clearLocalSession() async {
    try {
      await sb.auth.signOut(scope: SignOutScope.local);
    } catch (_) {
      try {
        await sb.auth.signOut();
      } catch (_) {}
    }
  }

  static Future<Session?> recoverStoredSession() async {
    final current = sb.auth.currentSession;
    if (current == null) return null;
    try {
      final refreshed = await sb.auth.refreshSession();
      return refreshed.session ?? sb.auth.currentSession;
    } catch (e) {
      final raw = e.toString();
      if (looksLikeNetworkError(raw)) {
        return current;
      }
      if (looksLikeSessionProblem(raw) || raw.toLowerCase().contains('refresh')) {
        await clearLocalSession();
        return null;
      }
      await clearLocalSession();
      return null;
    }
  }

  static List<Map<String, dynamic>> asList(dynamic value) {
    if (value is List) return value.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    return [];
  }

  static Map<String, dynamic> asMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  static String text(dynamic value, [String fallback = '']) {
    final s = value?.toString().trim() ?? '';
    return s.isEmpty ? fallback : s;
  }


  static bool eventIsCancelled(Map<String, dynamic> event) {
    return text(event['status']).toLowerCase() == 'cancelled';
  }

  static List<Map<String, dynamic>> activeEventsOnly(List<Map<String, dynamic>> rows) {
    return rows.where((event) => !eventIsCancelled(event)).toList();
  }

  static int intValue(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static double doubleValue(dynamic value, [double fallback = 0]) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse((value?.toString() ?? '').replaceAll(',', '.')) ?? fallback;
  }

  static bool _looksLikeLegacyBackendShapeIssue(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('does not exist') ||
        text.contains('could not find the table') ||
        text.contains('could not find the relation') ||
        text.contains('relation') && text.contains('does not exist') ||
        text.contains('column') && text.contains('does not exist') ||
        text.contains('function') && text.contains('does not exist');
  }

  static Exception backendFailure(String operation, Object error) {
    return Exception('$operation: ${error.toString()}');
  }

  static Future<T> _fallbackOnlyForLegacy<T>(String operation, Object error, Future<T> Function() fallback) async {
    if (_looksLikeLegacyBackendShapeIssue(error)) {
      return fallback();
    }
    throw backendFailure(operation, error);
  }

  static Future<void> ensureProfile() async {
    await sb.rpc('ensure_current_profile');
  }

  static Future<Map<String, dynamic>> profile() async {
    await ensureProfile();
    final uid = user?.id;
    if (uid == null) return <String, dynamic>{};
    final res = await sb.from('profiles').select().eq('id', uid).single();
    return asMap(res);
  }

  static Future<void> updateProfileName(String fullName) async {
    final uid = user?.id;
    if (uid == null) return;
    await ensureProfile();
    final clean = fullName.trim().isEmpty ? (user?.email?.split('@').first ?? 'Usuario') : fullName.trim();
    await sb.from('profiles').update({
      'full_name': clean,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', uid);
  }

  static Future<String> uploadAvatarBytes(Uint8List bytes, String filename) async {
    final uid = user?.id;
    if (uid == null) throw Exception(appIsEnglish ? 'Sign in to change your photo.' : 'Inicia sesión para cambiar la foto.');
    await ensureProfile();
    final ext = filename.toLowerCase().endsWith('.png')
        ? 'png'
        : filename.toLowerCase().endsWith('.webp')
            ? 'webp'
            : 'jpg';
    final path = '$uid/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
    await sb.storage.from('avatars').uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(
        upsert: true,
        contentType: ext == 'png' ? 'image/png' : ext == 'webp' ? 'image/webp' : 'image/jpeg',
      ),
    );
    final publicUrl = sb.storage.from('avatars').getPublicUrl(path);
    final versionedUrl = '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';
    await sb.from('profiles').update({
      'avatar_url': versionedUrl,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', uid);
    return versionedUrl;
  }

  static Future<void> removeAvatar() async {
    final uid = user?.id;
    if (uid == null) return;
    await ensureProfile();
    await sb.from('profiles').update({
      'avatar_url': null,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', uid);
  }

  static Future<void> deleteMyAccount(String confirmation) async {
    final clean = confirmation.trim().toUpperCase();
    if (clean != 'ELIMINAR') {
      throw Exception('confirmation_required');
    }
    await sb.rpc('delete_my_account', params: {'confirm_text': clean});
    try {
      await sb.auth.signOut();
    } catch (_) {}
  }

  static Future<List<Map<String, dynamic>>> myGroups() async {
    try {
      final res = await sb.rpc('get_my_groups');
      return asList(res);
    } catch (e) {
      return await _fallbackOnlyForLegacy('get_my_groups', e, () async {
        final uid = user?.id;
        if (uid == null) return [];
        final res = await sb.from('group_members').select('role, groups(id,name,type,privacy,invite_code,cover_url,created_at)').eq('user_id', uid);
        return asList(res).map((row) {
          final g = asMap(row['groups']);
          return {
            ...g,
            'role': row['role'],
            'members_count': 1,
            'events_count': 0,
            'balance': 0,
          };
        }).toList();
      });
    }
  }

  static Future<String> createGroup(
    String name, {
    String type = 'otro',
    String description = '',
    String currency = 'EUR',
    String timezone = 'Europe/Madrid',
    String language = 'es',
  }) async {
    final cleanName = name.trim();
    final cleanType = groupTypeValue(type);
    final cleanDescription = description.trim();
    try {
      final res = await sb.rpc('create_group_atomic_v2', params: {
        'p_name': cleanName,
        'p_type': cleanType,
        'p_description': cleanDescription.isEmpty ? null : cleanDescription,
        'p_currency': currency.trim().isEmpty ? 'EUR' : currency.trim().toUpperCase(),
        'p_timezone': timezone.trim().isEmpty ? 'Europe/Madrid' : timezone.trim(),
        'p_language': language.trim().isEmpty ? 'es' : language.trim().toLowerCase(),
      });
      return res.toString();
    } catch (e) {
      return await _fallbackOnlyForLegacy('create_group_atomic_v2', e, () async {
        final res = await sb.rpc('create_group_atomic', params: {'p_name': cleanName});
        final groupId = res.toString();
        final payload = <String, dynamic>{
          'type': cleanType,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        };
        if (cleanDescription.isNotEmpty) payload['description'] = cleanDescription;
        await sb.from('groups').update(payload).eq('id', groupId);
        return groupId;
      });
    }
  }

  static Future<String> joinGroup(String code) async {
    final res = await sb.rpc('join_group_with_code', params: {'code': code.trim().toUpperCase()});
    return res.toString();
  }

  static Future<Map<String, dynamic>> group(String groupId) async {
    final res = await sb.from('groups').select().eq('id', groupId).single();
    return asMap(res);
  }

  static Future<void> updateGroupInfo(
    String groupId, {
    required String name,
    String? type,
    String? description,
    String? currency,
    String? timezone,
    String? language,
    String? rules,
  }) async {
    final cleanName = name.trim();
    if (cleanName.length < 2) throw Exception(appIsEnglish ? 'The group name is too short.' : 'El nombre del grupo es demasiado corto.');
    final payload = <String, dynamic>{
      'name': cleanName,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (type != null) payload['type'] = groupTypeValue(type);
    if (description != null) payload['description'] = description.trim().isEmpty ? null : description.trim();
    if (currency != null) payload['currency'] = currency.trim().isEmpty ? 'EUR' : currency.trim().toUpperCase();
    if (timezone != null) payload['timezone'] = timezone.trim().isEmpty ? 'Europe/Madrid' : timezone.trim();
    if (language != null) payload['language'] = language.trim().isEmpty ? 'es' : language.trim().toLowerCase();
    if (rules != null) payload['rules'] = rules.trim().isEmpty ? null : rules.trim();
    await sb.from('groups').update(payload).eq('id', groupId);
  }

  static Future<String> regenerateGroupInviteCode(String groupId) async {
    try {
      final res = await sb.rpc('regenerate_group_invite_code', params: {'p_group_id': groupId});
      return res.toString();
    } catch (_) {
      final code = randomInviteCodeLocal();
      await sb.from('groups').update({
        'invite_code': code,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', groupId);
      return code;
    }
  }

  static Future<String> uploadGroupCoverBytes(String groupId, Uint8List bytes, String filename) async {
    final uid = user?.id;
    if (uid == null) throw Exception(appIsEnglish ? 'Sign in to change the group photo.' : 'Inicia sesión para cambiar la foto del grupo.');
    final ext = filename.toLowerCase().endsWith('.png')
        ? 'png'
        : filename.toLowerCase().endsWith('.webp')
            ? 'webp'
            : 'jpg';
    final path = '$groupId/${uid}_cover_${DateTime.now().millisecondsSinceEpoch}.$ext';
    await sb.storage.from('group-covers').uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(
        upsert: true,
        contentType: ext == 'png' ? 'image/png' : ext == 'webp' ? 'image/webp' : 'image/jpeg',
      ),
    );
    final publicUrl = sb.storage.from('group-covers').getPublicUrl(path);
    final versionedUrl = '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';
    await sb.from('groups').update({
      'cover_url': versionedUrl,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', groupId);
    return versionedUrl;
  }

  static Future<void> removeGroupCover(String groupId) async {
    await sb.from('groups').update({
      'cover_url': null,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', groupId);
  }

  static Future<List<Map<String, dynamic>>> members(String groupId) async {
    final res = await sb.from('group_members').select('id, role, user_id, profiles(id,email,full_name,avatar_url)').eq('group_id', groupId).order('created_at');
    return asList(res);
  }

  static Future<void> updateMemberRole(String memberRowId, String role) async {
    if (!['admin', 'member'].contains(role)) {
      throw Exception(appIsEnglish ? 'Invalid role.' : 'Rol no válido.');
    }
    try {
      await sb.rpc('set_group_member_role', params: {'p_member_row_id': memberRowId, 'p_role': role});
    } catch (_) {
      await sb.from('group_members').update({'role': role}).eq('id', memberRowId);
    }
  }

  static Future<void> removeMember(String memberRowId) async {
    try {
      await sb.rpc('remove_group_member', params: {'p_member_row_id': memberRowId});
    } catch (_) {
      await sb.from('group_members').delete().eq('id', memberRowId);
    }
  }

  static Future<void> leaveGroup(String groupId) async {
    final uid = user?.id;
    if (uid == null) return;
    try {
      await sb.rpc('leave_group_safe', params: {'p_group_id': groupId});
    } catch (_) {
      await sb.from('group_members').delete().eq('group_id', groupId).eq('user_id', uid);
    }
  }

  static Future<void> deleteGroup(String groupId, String confirmation) async {
    final clean = confirmation.trim().toUpperCase();
    if (clean != 'ELIMINAR GRUPO') {
      throw Exception(appIsEnglish ? 'To delete the group, type DELETE GROUP exactly.' : 'Para eliminar el grupo escribe ELIMINAR GRUPO exactamente.');
    }
    try {
      await sb.rpc('delete_group_safe', params: {
        'p_group_id': groupId,
        'p_confirm': clean,
      });
      return;
    } catch (e) {
      final message = e.toString().toLowerCase();
      if (message.contains('function') || message.contains('delete_group_safe')) {
        throw Exception(appIsEnglish ? 'The group could not be deleted safely. Try again later.' : 'No se pudo eliminar el grupo de forma segura. Inténtalo de nuevo más tarde.');
      }
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> events(String groupId) async {
    final cleanGroupId = groupId.trim();
    if (cleanGroupId.isEmpty) return [];

    try {
      final res = await sb.rpc('group_events_with_attendance', params: {'p_group_id': cleanGroupId});
      final rows = activeEventsOnly(asList(res));
      rows.sort((a, b) {
        final da = DateTime.tryParse(a['starts_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        final db = DateTime.tryParse(b['starts_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        return da.compareTo(db);
      });
      return rows;
    } catch (e) {
      return await _fallbackOnlyForLegacy('group_events_with_attendance', e, () async {
        final res = await sb
            .from('events')
            .select('*, event_attendance(status,user_id)')
            .eq('group_id', cleanGroupId)
            .order('starts_at');
        final rows = activeEventsOnly(asList(res));
        rows.sort((a, b) {
          final da = DateTime.tryParse(a['starts_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
          final db = DateTime.tryParse(b['starts_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
          return da.compareTo(db);
        });
        return rows;
      });
    }
  }

  static Future<String> createEvent(String groupId, String title, DateTime startsAt, String location, String notes, int minPeople) async {
    final row = await sb.from('events').insert({
      'group_id': groupId,
      'title': title.trim(),
      'starts_at': startsAt.toUtc().toIso8601String(),
      'location': location.trim().isEmpty ? null : location.trim(),
      'notes': notes.trim().isEmpty ? null : notes.trim(),
      'min_people': minPeople,
      'created_by': user?.id,
    }).select('id').single();
    return row['id'].toString();
  }

  static Future<int> createEventSeries(
    String groupId,
    String title,
    DateTime firstStartsAt,
    String location,
    String notes,
    int minPeople,
    String frequency,
    int occurrences,
  ) async {
    final total = max(2, min(52, occurrences));
    final seriesId = newLocalUuid();
    final cleanTitle = title.trim();
    final cleanLocation = location.trim();
    final frequencyLabel = switch (frequency) {
      'biweekly' => 'cada 2 semanas',
      'monthly' => 'cada mes',
      _ => 'cada semana',
    };
    final routineLine = 'Rutina: $frequencyLabel · $total eventos generados';
    final cleanNotes = notes.trim().isEmpty ? routineLine : '${notes.trim()}\n\n$routineLine';

    DateTime occurrenceDate(int index) {
      if (frequency == 'biweekly') return firstStartsAt.add(Duration(days: 14 * index));
      if (frequency == 'monthly') {
        final monthIndex = firstStartsAt.month + index;
        final year = firstStartsAt.year + ((monthIndex - 1) ~/ 12);
        final month = ((monthIndex - 1) % 12) + 1;
        final lastDay = DateTime(year, month + 1, 0).day;
        final day = min(firstStartsAt.day, lastDay);
        return DateTime(year, month, day, firstStartsAt.hour, firstStartsAt.minute);
      }
      return firstStartsAt.add(Duration(days: 7 * index));
    }

    final rows = List.generate(total, (index) {
      final startsAt = occurrenceDate(index);
      return {
        'group_id': groupId,
        'title': cleanTitle,
        'starts_at': startsAt.toUtc().toIso8601String(),
        'location': cleanLocation.isEmpty ? null : cleanLocation,
        'notes': cleanNotes,
        'min_people': minPeople,
        'event_series_id': seriesId,
        'recurrence_frequency': frequency,
        'recurrence_index': index,
        'recurrence_count': total,
        'created_by': user?.id,
      };
    });

    await sb.from('events').insert(rows);
    return total;
  }

  static Future<Map<String, dynamic>> eventById(String eventId) async {
    final res = await sb.from('events').select('*, event_attendance(status,user_id)').eq('id', eventId).single();
    return asMap(res);
  }

  static Future<void> updateEvent(String eventId, String title, DateTime startsAt, String location, String notes, int minPeople) async {
    await sb.from('events').update({
      'title': title.trim(),
      'starts_at': startsAt.toUtc().toIso8601String(),
      'location': location.trim().isEmpty ? null : location.trim(),
      'notes': notes.trim().isEmpty ? null : notes.trim(),
      'min_people': minPeople,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', eventId);
  }

  static Future<void> updateEventWithScope(String eventId, String scope, String title, DateTime startsAt, String location, String notes, int minPeople) async {
    final current = asMap(await sb.from('events').select('id,group_id,starts_at,event_series_id').eq('id', eventId).single());
    final seriesId = text(current['event_series_id']);
    if (seriesId.isEmpty || scope == 'single') {
      await updateEvent(eventId, title, startsAt, location, notes, minPeople);
      return;
    }

    final currentStart = DateTime.tryParse(text(current['starts_at']))?.toLocal() ?? startsAt;
    final rows = asList(await sb
        .from('events')
        .select('id,starts_at')
        .eq('event_series_id', seriesId)
        .eq('group_id', current['group_id'])
        .neq('status', 'cancelled')
        .order('starts_at'));

    final cleanTitle = title.trim();
    final cleanLocation = location.trim();
    final cleanNotes = notes.trim();
    for (final row in rows) {
      final rowId = text(row['id']);
      final rowDate = DateTime.tryParse(text(row['starts_at']))?.toLocal();
      if (rowId.isEmpty || rowDate == null) continue;
      if (scope == 'future' && rowDate.isBefore(currentStart.subtract(const Duration(minutes: 1)))) continue;
      final nextStart = rowId == eventId
          ? startsAt
          : DateTime(rowDate.year, rowDate.month, rowDate.day, startsAt.hour, startsAt.minute);
      await sb.from('events').update({
        'title': cleanTitle,
        'starts_at': nextStart.toUtc().toIso8601String(),
        'location': cleanLocation.isEmpty ? null : cleanLocation,
        'notes': cleanNotes.isEmpty ? null : cleanNotes,
        'min_people': minPeople,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', rowId);
    }
  }

  static Future<void> cancelEvent(String eventId) async {
    final updated = await sb.from('events').update({
      'status': 'cancelled',
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', eventId).select('id,status');
    final rows = asList(updated);
    if (rows.isEmpty) {
      throw Exception(appIsEnglish ? 'The event could not be cancelled. You may not have permission, or the event may no longer exist.' : 'No se pudo cancelar el evento. Puede que no tengas permiso o que el evento ya no exista.');
    }
  }

  static Future<void> cancelEventWithScope(String eventId, String scope) async {
    final current = asMap(await sb.from('events').select('id,group_id,starts_at,event_series_id').eq('id', eventId).single());
    final seriesId = text(current['event_series_id']);
    if (seriesId.isEmpty || scope == 'single') {
      await cancelEvent(eventId);
      return;
    }
    dynamic query = sb
        .from('events')
        .update({'status': 'cancelled', 'updated_at': DateTime.now().toUtc().toIso8601String()})
        .eq('event_series_id', seriesId)
        .eq('group_id', current['group_id']);
    if (scope == 'future') {
      query = query.gte('starts_at', text(current['starts_at']));
    }
    await query;
  }

  static Future<void> setAttendance(String eventId, String status) async {
    final uid = user?.id;
    if (uid == null) return;
    await sb.from('event_attendance').upsert({
      'event_id': eventId,
      'user_id': uid,
      'status': status,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'event_id,user_id');
  }

  static Future<List<Map<String, dynamic>>> eventContributions(String eventId) async {
    final cleanEventId = eventId.trim();
    if (cleanEventId.isEmpty) return [];
    try {
      final res = await sb
          .from('event_contributions')
          .select('id,event_id,group_id,user_id,items_text,created_at,updated_at,profiles(id,email,full_name,avatar_url)')
          .eq('event_id', cleanEventId)
          .order('updated_at', ascending: false);
      return asList(res);
    } catch (e) {
      if (e.toString().toLowerCase().contains('event_contributions')) return [];
      rethrow;
    }
  }

  static Future<void> saveEventContribution({required String groupId, required String eventId, required String itemsText}) async {
    final uid = user?.id;
    if (uid == null) throw Exception(appIsEnglish ? 'Sign in to say what you are bringing.' : 'Inicia sesión para decir qué vas a llevar.');
    final cleanGroupId = groupId.trim();
    final cleanEventId = eventId.trim();
    final cleanText = itemsText.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (cleanGroupId.isEmpty || cleanEventId.isEmpty) {
      throw Exception(appIsEnglish ? 'The group event was not found.' : 'No se encontró el evento del grupo.');
    }
    if (cleanText.length < 2) {
      throw Exception(appIsEnglish ? 'Write something simple, for example: drinks, food or balls.' : 'Escribe algo sencillo, por ejemplo: bebida, comida o pelotas.');
    }
    if (cleanText.length > 240) {
      throw Exception(appIsEnglish ? 'The text is too long. Keep it to a short sentence.' : 'El texto es demasiado largo. Déjalo en una frase corta.');
    }
    try {
      await sb.from('event_contributions').upsert({
        'group_id': cleanGroupId,
        'event_id': cleanEventId,
        'user_id': uid,
        'items_text': cleanText,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'event_id,user_id');
    } catch (e) {
      if (e.toString().toLowerCase().contains('event_contributions')) {
        throw Exception(appIsEnglish ? 'The database still needs the v16.22 SQL update.' : 'Falta actualizar la base de datos con el SQL v16.22.');
      }
      rethrow;
    }
  }

  static Future<void> deleteMyEventContribution(String eventId) async {
    final uid = user?.id;
    if (uid == null) throw Exception(appIsEnglish ? 'Sign in to change what you are bringing.' : 'Inicia sesión para cambiar lo que llevas.');
    final cleanEventId = eventId.trim();
    if (cleanEventId.isEmpty) return;
    try {
      await sb.from('event_contributions').delete().eq('event_id', cleanEventId).eq('user_id', uid);
    } catch (e) {
      if (e.toString().toLowerCase().contains('event_contributions')) return;
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> expenses(String groupId) async {
    final res = await sb.from('expenses').select('*, profiles!expenses_paid_by_fkey(id,email,full_name,avatar_url), expense_participants(user_id,share_amount,paid)').eq('group_id', groupId).order('created_at', ascending: false);
    return asList(res);
  }

  static Future<String> createExpense(String groupId, String concept, double amount, String paidBy, List<String> participantIds, String note) async {
    final participantSet = <String>{...participantIds, paidBy};
    final participants = participantSet.where((id) => id.trim().isNotEmpty).toList();
    final share = participants.isEmpty ? amount : amount / participants.length;
    return createExpenseWithShares(
      groupId,
      concept,
      amount,
      paidBy,
      {for (final id in participants) id: double.parse(share.toStringAsFixed(2))},
      note,
    );
  }

  static Future<String> createExpenseWithShares(String groupId, String concept, double amount, String paidBy, Map<String, double> shares, String note) async {
    final current = user?.id;
    final cleanShares = <String, double>{};
    shares.forEach((id, value) {
      if (id.trim().isEmpty) return;
      final cleanValue = double.parse(max(0, value).toStringAsFixed(2));
      if (cleanValue > 0 || id == paidBy) cleanShares[id] = cleanValue;
    });
    cleanShares.putIfAbsent(paidBy, () => 0);
    final expense = await sb.from('expenses').insert({
      'group_id': groupId,
      'concept': concept.trim(),
      'amount': double.parse(amount.toStringAsFixed(2)),
      'paid_by': paidBy,
      'created_by': current,
      'note': note.trim().isEmpty ? null : note.trim(),
      'status': 'pending',
    }).select('id').single();
    final expenseId = expense['id'].toString();
    final rows = cleanShares.entries.map((entry) => {
      'expense_id': expenseId,
      'user_id': entry.key,
      'share_amount': double.parse(entry.value.toStringAsFixed(2)),
      'paid': entry.key == paidBy,
    }).toList();
    if (rows.isNotEmpty) await sb.from('expense_participants').insert(rows);
    return expenseId;
  }

  static Future<void> setExpenseParticipantPaid(String expenseId, String userId, bool paid) async {
    await sb.from('expense_participants').update({'paid': paid}).eq('expense_id', expenseId).eq('user_id', userId);
    final rows = asList(await sb.from('expense_participants').select('paid').eq('expense_id', expenseId));
    final allPaid = rows.isNotEmpty && rows.every((row) => row['paid'] == true);
    await sb.from('expenses').update({
      'status': allPaid ? 'paid' : 'pending',
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', expenseId);
  }

  static Future<void> markExpenseSettled(String expenseId) async {
    await sb.from('expense_participants').update({'paid': true}).eq('expense_id', expenseId);
    await sb.from('expenses').update({'status': 'paid', 'updated_at': DateTime.now().toUtc().toIso8601String()}).eq('id', expenseId);
  }

  static Future<void> reopenExpense(String expenseId) async {
    final expense = await sb.from('expenses').select('paid_by').eq('id', expenseId).single();
    final paidBy = expense['paid_by']?.toString();
    await sb.from('expense_participants').update({'paid': false}).eq('expense_id', expenseId);
    if (paidBy != null && paidBy.isNotEmpty) {
      await sb.from('expense_participants').update({'paid': true}).eq('expense_id', expenseId).eq('user_id', paidBy);
    }
    await sb.from('expenses').update({'status': 'pending', 'updated_at': DateTime.now().toUtc().toIso8601String()}).eq('id', expenseId);
  }

  static Future<void> deleteExpense(String expenseId) async {
    await sb.from('expenses').delete().eq('id', expenseId);
  }

  static Future<void> updateExpenseWithShares(
    String expenseId,
    String concept,
    double amount,
    String paidBy,
    Map<String, double> shares,
    String note,
  ) async {
    final cleanShares = <String, double>{};
    shares.forEach((id, value) {
      if (id.trim().isEmpty) return;
      final cleanValue = double.parse(max(0, value).toStringAsFixed(2));
      if (cleanValue > 0 || id == paidBy) cleanShares[id] = cleanValue;
    });
    cleanShares.putIfAbsent(paidBy, () => 0);

    await sb.from('expenses').update({
      'concept': concept.trim(),
      'amount': double.parse(amount.toStringAsFixed(2)),
      'paid_by': paidBy,
      'note': note.trim().isEmpty ? null : note.trim(),
      'status': 'pending',
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', expenseId);

    await sb.from('expense_participants').delete().eq('expense_id', expenseId);

    final rows = cleanShares.entries.map((entry) => {
      'expense_id': expenseId,
      'user_id': entry.key,
      'share_amount': double.parse(entry.value.toStringAsFixed(2)),
      'paid': entry.key == paidBy,
    }).toList();

    if (rows.isNotEmpty) {
      await sb.from('expense_participants').insert(rows);
    }
  }

  static Future<List<Map<String, dynamic>>> settlementPayments(String groupId) async {
    try {
      final res = await sb
          .from('settlement_payments')
          .select()
          .eq('group_id', groupId)
          .eq('status', 'paid')
          .order('paid_at', ascending: false);
      return asList(res);
    } catch (e) {
      throw backendFailure('settlementPayments', e);
    }
  }

  static Future<String> createSettlementPayment(
    String groupId,
    String fromUser,
    String toUser,
    double amount,
  ) async {
    final cleanAmount = double.parse(amount.toStringAsFixed(2));
    if (cleanAmount <= 0) throw Exception(appIsEnglish ? 'The amount must be greater than zero.' : 'El importe debe ser mayor que cero.');

    // Preferimos RPC para evitar fallos de RLS/SQL al registrar una liquidación.
    // Si la base aún no tiene la función del parche, usamos el insert directo como respaldo.
    try {
      final rpcId = await sb.rpc('create_settlement_payment_atomic', params: {
        'p_group_id': groupId,
        'p_from_user': fromUser,
        'p_to_user': toUser,
        'p_amount': cleanAmount,
      });
      final id = rpcId?.toString() ?? '';
      if (id.isNotEmpty) return id;
    } catch (_) {
      // Compatibilidad con instalaciones que todavía no han ejecutado el parche.
    }

    final currentUser = user?.id;
    if (currentUser == null || currentUser.isEmpty) {
      throw Exception(appIsEnglish ? 'Your session is not active. Sign out and sign back in.' : 'Tu sesión no está activa. Cierra sesión y vuelve a entrar.');
    }

    final row = await sb.from('settlement_payments').insert({
      'group_id': groupId,
      'from_user': fromUser,
      'to_user': toUser,
      'amount': cleanAmount,
      'status': 'paid',
      'created_by': currentUser,
      'paid_at': DateTime.now().toUtc().toIso8601String(),
    }).select('id').single();
    return row['id'].toString();
  }

  static Future<void> cancelSettlementPayment(String paymentId) async {
    if (paymentId.trim().isEmpty) throw Exception(appIsEnglish ? 'The payment could not be identified.' : 'No se ha podido identificar el pago.');

    // Preferimos RPC para validar permisos y evitar inconsistencias.
    try {
      await sb.rpc('cancel_settlement_payment_atomic', params: {
        'p_payment_id': paymentId,
      });
      return;
    } catch (_) {
      // Compatibilidad con instalaciones que todavía no han ejecutado el parche.
    }

    await sb.from('settlement_payments').update({
      'status': 'cancelled',
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', paymentId);
  }

  static Future<List<Map<String, dynamic>>> tournaments(String groupId) async {
    try {
      final rows = asList(await sb
          .from('tournaments')
          .select()
          .eq('group_id', groupId)
          .order('created_at', ascending: false));

      final output = <Map<String, dynamic>>[];
      for (final row in rows) {
        final id = row['id'].toString();
        final teams = asList(await sb
            .from('tournament_teams')
            .select('id,name,avatar_url,color,seed,status,captain_id,created_at')
            .eq('tournament_id', id)
            .order('seed', ascending: true)
            .order('created_at', ascending: true));
        final matches = asList(await sb
            .from('matches')
            .select('id,team_a,team_b,score_a,score_b,result_details,round,round_name,order_index,status,scheduled_at,duration_minutes,location,court_name,event_id,winner_team_id,result_status,notes,played_at,created_at,updated_at')
            .eq('tournament_id', id)
            .order('round', ascending: true)
            .order('order_index', ascending: true)
            .order('created_at', ascending: true));
        output.add({...row, 'tournament_teams': teams, 'matches': matches});
      }
      return output;
    } catch (e) {
      return await _fallbackOnlyForLegacy('tournaments', e, () async {
        final rows = asList(await sb
            .from('tournaments')
            .select()
            .eq('group_id', groupId)
            .order('created_at', ascending: false));
        return rows.map((row) => {
          ...row,
          'tournament_teams': <Map<String, dynamic>>[],
          'matches': <Map<String, dynamic>>[],
        }).toList();
      });
    }
  }

  static Future<Map<String, dynamic>> tournament(String tournamentId) async {
    final row = asMap(await sb
        .from('tournaments')
        .select()
        .eq('id', tournamentId)
        .single());
    final teams = asList(await sb
        .from('tournament_teams')
        .select('id,name,avatar_url,color,seed,status,captain_id,created_at')
        .eq('tournament_id', tournamentId)
        .order('seed', ascending: true)
        .order('created_at', ascending: true));
    final matches = asList(await sb
        .from('matches')
        .select('id,team_a,team_b,score_a,score_b,result_details,round,round_name,order_index,status,scheduled_at,duration_minutes,location,court_name,event_id,winner_team_id,result_status,notes,played_at,created_at,updated_at')
        .eq('tournament_id', tournamentId)
        .order('round', ascending: true)
        .order('order_index', ascending: true)
        .order('created_at', ascending: true));
    return {...row, 'tournament_teams': teams, 'matches': matches};
  }

  static Future<String> createTournament(
    String groupId,
    String name, {
    String format = 'liga',
    String teamType = 'equipo',
    String scoringType = 'general',
    Map<String, dynamic>? scoringConfig,
    Map<String, dynamic>? formatConfig,
    Map<String, dynamic>? scheduleConfig,
    List<String>? tieBreakers,
    Map<String, dynamic>? permissionsConfig,
    String status = 'scheduled',
    DateTime? startsAt,
  }) async {
    final payload = {
      'group_id': groupId,
      'name': name.trim(),
      'format': format,
      'team_type': teamType,
      'scoring_type': scoringType,
      'scoring_config': scoringConfig ?? scoringConfigForType(scoringType),
      'format_config': formatConfig ?? <String, dynamic>{},
      'schedule_config': scheduleConfig ?? <String, dynamic>{},
      'tie_breakers': tieBreakers ?? defaultTieBreakers(scoringType),
      'permissions_config': permissionsConfig ?? {'admin_edit': true, 'members_results': false, 'rival_confirmation': false},
      'status': status,
      'starts_at': startsAt?.toUtc().toIso8601String(),
      'created_by': user?.id,
    };

    try {
      final row = await sb.from('tournaments').insert(payload).select('id').single();
      return row['id'].toString();
    } catch (e) {
      final text = e.toString().toLowerCase();
      if (text.contains('tournaments_scoring_type_check')) rethrow;
      if (!text.contains('format_config') && !text.contains('schedule_config') && !text.contains('tie_breakers') && !text.contains('permissions_config') && !text.contains('scoring_type') && !text.contains('scoring_config')) rethrow;
      final fallback = Map<String, dynamic>.from(payload)
        ..remove('scoring_type')
        ..remove('scoring_config')
        ..remove('format_config')
        ..remove('schedule_config')
        ..remove('tie_breakers')
        ..remove('permissions_config')
        ..remove('starts_at');
      final row = await sb.from('tournaments').insert(fallback).select('id').single();
      return row['id'].toString();
    }
  }

  static Future<void> updateTournamentStatus(String tournamentId, String status) async {
    await sb.from('tournaments').update({
      'status': status,
      'finished_at': status == 'finished' ? DateTime.now().toUtc().toIso8601String() : null,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', tournamentId);
  }

  static Future<void> deleteTournament(String tournamentId) async {
    await sb.from('tournaments').delete().eq('id', tournamentId);
  }

  static Future<String> addTournamentTeam(String tournamentId, String name, {int? seed}) async {
    final row = await sb.from('tournament_teams').insert({
      'tournament_id': tournamentId,
      'name': name.trim(),
      'seed': seed,
      'status': 'active',
    }).select('id').single();
    return row['id'].toString();
  }

  static Future<int> addTournamentTeams(String tournamentId, List<String> names) async {
    final clean = parseTournamentParticipantNames(names.join('\n'));
    if (clean.isEmpty) return 0;
    await sb.from('tournament_teams').insert(List.generate(clean.length, (index) => {
      'tournament_id': tournamentId,
      'name': clean[index],
      'seed': index + 1,
      'status': 'active',
    }));
    return clean.length;
  }

  static Future<int> addTournamentTeamsFromMembers(String tournamentId, List<Map<String, dynamic>> members) async {
    if (members.isEmpty) return 0;
    final existing = asList(await sb.from('tournament_teams').select('seed,name,captain_id,status').eq('tournament_id', tournamentId));
    final startSeed = existing.fold<int>(0, (value, row) => max(value, intValue(row['seed']))) + 1;
    final existingCaptains = existing.map((row) => text(row['captain_id'])).where((id) => id.isNotEmpty).toSet();
    final existingNames = existing.map((row) => text(row['name']).trim().toLowerCase()).where((name) => name.isNotEmpty).toSet();
    final payload = <Map<String, dynamic>>[];
    final sourceByUserId = <String, Map<String, dynamic>>{};

    for (final member in members) {
      final profile = asMap(member['profiles']);
      final userId = text(member['user_id'], text(profile['id']));
      final name = memberDisplayName(member).trim();
      if (name.length < 2) continue;
      if (userId.isNotEmpty && existingCaptains.contains(userId)) continue;
      if (existingNames.contains(name.toLowerCase())) continue;
      final avatar = memberAvatarUrl(member);
      sourceByUserId[userId] = member;
      payload.add({
        'tournament_id': tournamentId,
        'name': name,
        'avatar_url': avatar.trim().isEmpty ? null : avatar.trim(),
        'seed': startSeed + payload.length,
        'status': 'active',
        'captain_id': userId.trim().isEmpty ? null : userId,
      });
      if (userId.isNotEmpty) existingCaptains.add(userId);
      existingNames.add(name.toLowerCase());
    }

    if (payload.isEmpty) return 0;
    final inserted = asList(await sb.from('tournament_teams').insert(payload).select('id,name,captain_id'));
    final memberRows = <Map<String, dynamic>>[];
    for (final row in inserted) {
      final userId = text(row['captain_id']);
      memberRows.add({
        'tournament_team_id': row['id'],
        'user_id': userId.trim().isEmpty ? null : userId,
        'display_name': text(row['name']),
        'role': 'player',
      });
    }
    if (memberRows.isNotEmpty) {
      try { await sb.from('tournament_team_members').insert(memberRows); } catch (_) {}
    }
    return inserted.length;
  }

  static Future<String> addTournamentPairFromMembers(String tournamentId, Map<String, dynamic> first, Map<String, dynamic> second, {String? customName}) async {
    final existing = asList(await sb.from('tournament_teams').select('seed,name').eq('tournament_id', tournamentId));
    final seed = existing.fold<int>(0, (value, row) => max(value, intValue(row['seed']))) + 1;
    final existingNames = existing.map((row) => text(row['name']).trim().toLowerCase()).toSet();
    final firstProfile = asMap(first['profiles']);
    final secondProfile = asMap(second['profiles']);
    final firstId = text(first['user_id'], text(firstProfile['id']));
    final secondId = text(second['user_id'], text(secondProfile['id']));
    if (firstId.isNotEmpty && secondId.isNotEmpty && firstId == secondId) throw Exception(appIsEnglish ? 'Choose two different members.' : 'Elige dos miembros distintos.');
    final firstName = memberDisplayName(first);
    final secondName = memberDisplayName(second);
    final pairName = (customName ?? '').trim().isNotEmpty ? customName!.trim() : '$firstName / $secondName';
    if (existingNames.contains(pairName.toLowerCase())) throw Exception(appIsEnglish ? 'A participant with that name already exists.' : 'Ya existe un participante con ese nombre.');
    final avatar = memberAvatarUrl(first).trim().isNotEmpty ? memberAvatarUrl(first) : memberAvatarUrl(second);

    final row = asMap(await sb.from('tournament_teams').insert({
      'tournament_id': tournamentId,
      'name': pairName,
      'avatar_url': avatar.trim().isEmpty ? null : avatar.trim(),
      'seed': seed,
      'status': 'active',
      'captain_id': firstId.trim().isEmpty ? null : firstId,
    }).select('id').single());

    final teamId = text(row['id']);
    try {
      await sb.from('tournament_team_members').insert([
        {
          'tournament_team_id': teamId,
          'user_id': firstId.trim().isEmpty ? null : firstId,
          'display_name': firstName,
          'role': 'player',
        },
        {
          'tournament_team_id': teamId,
          'user_id': secondId.trim().isEmpty ? null : secondId,
          'display_name': secondName,
          'role': 'player',
        },
      ]);
    } catch (_) {}
    return teamId;
  }

  static Future<void> updateTournamentEditor(
    String tournamentId, {
    required String name,
    required String scoringType,
    required Map<String, dynamic> scoringConfig,
    required Map<String, dynamic> formatConfig,
    required List<String> tieBreakers,
  }) async {
    final clean = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.length < 2) throw Exception(appIsEnglish ? 'The name must have at least 2 characters.' : 'El nombre debe tener al menos 2 caracteres.');
    await sb.from('tournaments').update({
      'name': clean,
      'scoring_type': scoringType,
      'scoring_config': scoringConfig,
      'format_config': formatConfig,
      'tie_breakers': tieBreakers,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', tournamentId);
  }

  static Future<void> renameTournamentTeam(String teamId, String name) async {
    final clean = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.length < 2) throw Exception(appIsEnglish ? 'The name must have at least 2 characters.' : 'El nombre debe tener al menos 2 caracteres.');
    await sb.from('tournament_teams').update({
      'name': clean,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', teamId);
  }

  static Future<void> updateTournamentTeamSeed(String teamId, int seed) async {
    await sb.from('tournament_teams').update({
      'seed': max(1, seed),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', teamId);
  }

  static Future<void> retireTournamentTeam(String teamId) async {
    await sb.from('tournament_teams').update({
      'status': 'retired',
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', teamId);
  }

  static Future<void> deleteTournamentTeam(String teamId) async {
    await sb.from('tournament_teams').delete().eq('id', teamId);
  }

  static Future<String> safeRemoveTournamentTeam(String teamId) async {
    final asA = asList(await sb.from('matches').select('id,status,result_details,score_a,score_b').eq('team_a', teamId));
    final asB = asList(await sb.from('matches').select('id,status,result_details,score_a,score_b').eq('team_b', teamId));
    final linked = [...asA, ...asB];
    if (linked.isEmpty) {
      await deleteTournamentTeam(teamId);
      return 'deleted';
    }
    await retireTournamentTeam(teamId);
    return 'retired';
  }

  static Future<void> clearTournamentMatches(String tournamentId) async {
    await sb.from('matches').delete().eq('tournament_id', tournamentId);
  }

  static Future<void> createManualMatches(
    String tournamentId,
    List<Map<String, dynamic>> teams,
    List<TournamentDraftMatch> pairings, {
    Map<String, dynamic>? scheduleConfig,
  }) async {
    if (pairings.isEmpty) throw Exception(appIsEnglish ? 'Add at least one manual pairing.' : 'Añade al menos un emparejamiento manual.');
    await clearTournamentMatches(tournamentId);
    await addManualMatches(tournamentId, teams, pairings, scheduleConfig: scheduleConfig);
  }

  static Future<void> addManualMatches(
    String tournamentId,
    List<Map<String, dynamic>> teams,
    List<TournamentDraftMatch> pairings, {
    Map<String, dynamic>? scheduleConfig,
  }) async {
    if (pairings.isEmpty) throw Exception(appIsEnglish ? 'Add at least one manual pairing.' : 'Añade al menos un emparejamiento manual.');
    final byName = <String, String>{
      for (final team in teams) AppData.text(team['name']).trim().toLowerCase(): team['id'].toString(),
    };
    final rows = <Map<String, dynamic>>[];
    final roundCounters = <int, int>{};
    for (var i = 0; i < pairings.length; i++) {
      final pair = pairings[i];
      final aId = byName[pair.teamAName.trim().toLowerCase()];
      final bId = byName[pair.teamBName.trim().toLowerCase()];
      if (aId == null || bId == null) {
        throw Exception(appIsEnglish ? 'Could not find in participants: ${aId == null ? pair.teamAName : pair.teamBName}.' : 'No encuentro en participantes: ${aId == null ? pair.teamAName : pair.teamBName}.');
      }
      if (aId == bId) throw Exception(appIsEnglish ? 'A team cannot play against itself.' : 'Un equipo no puede jugar contra sí mismo.');
      final round = max(1, pair.round);
      final orderInsideRound = roundCounters[round] ?? 0;
      roundCounters[round] = orderInsideRound + 1;
      final scheduledAt = tournamentScheduledAtForIndex(scheduleConfig, round, orderInsideRound);
      final court = tournamentCourtNameForIndex(scheduleConfig, orderInsideRound);
      rows.add({
        'tournament_id': tournamentId,
        'team_a': aId,
        'team_b': bId,
        'round': round,
        'round_name': 'Jornada $round',
        'order_index': i,
        'status': scheduledAt == null ? 'pending' : 'scheduled',
        'scheduled_at': scheduledAt?.toUtc().toIso8601String(),
        'duration_minutes': max(15, intValue(scheduleConfig?['duration_minutes'], 60)),
        'location': text(scheduleConfig?['location']).trim().isEmpty ? null : text(scheduleConfig?['location']).trim(),
        'court_name': court.isEmpty ? null : court,
      });
    }
    await sb.from('matches').insert(rows);
  }

  static Future<void> createManualMatchRows(
    String tournamentId,
    List<Map<String, dynamic>> teams,
    List<TournamentManualDraftRow> rows, {
    Map<String, dynamic>? scheduleConfig,
  }) async {
    final cleanRows = rows.where((r) => r.teamAName.trim().isNotEmpty && r.teamBName.trim().isNotEmpty).toList();
    if (cleanRows.isEmpty) throw Exception(appIsEnglish ? 'Add at least one manual match.' : 'Añade al menos un partido manual.');
    await clearTournamentMatches(tournamentId);
    final byName = <String, String>{
      for (final team in teams) AppData.text(team['name']).trim().toLowerCase(): team['id'].toString(),
    };
    final payload = <Map<String, dynamic>>[];
    final roundCounters = <int, int>{};
    for (var i = 0; i < cleanRows.length; i++) {
      final row = cleanRows[i];
      final aId = byName[row.teamAName.trim().toLowerCase()];
      final bId = byName[row.teamBName.trim().toLowerCase()];
      if (aId == null || bId == null) {
        throw Exception(appIsEnglish ? 'Could not find in participants: ${aId == null ? row.teamAName : row.teamBName}.' : 'No encuentro en participantes: ${aId == null ? row.teamAName : row.teamBName}.');
      }
      if (aId == bId) throw Exception(appIsEnglish ? 'A team cannot play against itself.' : 'Un equipo no puede jugar contra sí mismo.');
      final round = max(1, row.round);
      final orderInsideRound = roundCounters[round] ?? 0;
      roundCounters[round] = orderInsideRound + 1;
      final fallbackDate = tournamentScheduledAtForIndex(scheduleConfig, round, orderInsideRound);
      final scheduledAt = row.scheduledAt ?? fallbackDate;
      final court = row.courtName.trim().isNotEmpty ? row.courtName.trim() : tournamentCourtNameForIndex(scheduleConfig, orderInsideRound);
      payload.add({
        'tournament_id': tournamentId,
        'team_a': aId,
        'team_b': bId,
        'round': round,
        'round_name': 'Jornada $round',
        'order_index': i,
        'status': scheduledAt == null ? 'pending' : 'scheduled',
        'scheduled_at': scheduledAt?.toUtc().toIso8601String(),
        'duration_minutes': max(15, row.durationMinutes),
        'location': row.location.trim().isEmpty ? (text(scheduleConfig?['location']).trim().isEmpty ? null : text(scheduleConfig?['location']).trim()) : row.location.trim(),
        'court_name': court.isEmpty ? null : court,
        'notes': row.notes.trim().isEmpty ? null : row.notes.trim(),
      });
    }
    await sb.from('matches').insert(payload);
  }

  static Future<Map<String, dynamic>> addTournamentMatch({
    required String tournamentId,
    required String teamAId,
    required String teamBId,
    required int round,
    DateTime? scheduledAt,
    int durationMinutes = 60,
    String location = '',
    String courtName = '',
    String notes = '',
  }) async {
    if (teamAId.trim().isEmpty || teamBId.trim().isEmpty) throw Exception(appIsEnglish ? 'Choose two participants.' : 'Elige dos participantes.');
    if (teamAId == teamBId) throw Exception(appIsEnglish ? 'A participant cannot play against itself.' : 'Un participante no puede jugar contra sí mismo.');
    final existing = asList(await sb
        .from('matches')
        .select('order_index')
        .eq('tournament_id', tournamentId)
        .eq('round', max(1, round))
        .order('order_index', ascending: false)
        .limit(1));
    final nextOrder = existing.isEmpty ? 0 : intValue(existing.first['order_index']) + 1;
    final row = asMap(await sb.from('matches').insert({
      'tournament_id': tournamentId,
      'team_a': teamAId,
      'team_b': teamBId,
      'round': max(1, round),
      'round_name': 'Jornada ${max(1, round)}',
      'order_index': nextOrder,
      'status': scheduledAt == null ? 'pending' : 'scheduled',
      'scheduled_at': scheduledAt?.toUtc().toIso8601String(),
      'duration_minutes': max(15, durationMinutes),
      'location': location.trim().isEmpty ? null : location.trim(),
      'court_name': courtName.trim().isEmpty ? null : courtName.trim(),
      'notes': notes.trim().isEmpty ? null : notes.trim(),
      'updated_by': user?.id,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).select().single());
    return row;
  }

  static Future<void> duplicateTournamentRound(String tournamentId, int sourceRound) async {
    final source = asList(await sb
        .from('matches')
        .select('team_a,team_b,duration_minutes,location,court_name,notes')
        .eq('tournament_id', tournamentId)
        .eq('round', max(1, sourceRound))
        .order('order_index', ascending: true)
        .order('created_at', ascending: true));
    if (source.isEmpty) throw Exception(appIsEnglish ? 'There are no matches in that round.' : 'No hay partidos en esa jornada.');
    final rounds = asList(await sb.from('matches').select('round').eq('tournament_id', tournamentId));
    final nextRound = rounds.fold<int>(0, (value, row) => max(value, intValue(row['round']))) + 1;
    final rows = <Map<String, dynamic>>[];
    for (var i = 0; i < source.length; i++) {
      final match = source[i];
      rows.add({
        'tournament_id': tournamentId,
        'team_a': match['team_a'],
        'team_b': match['team_b'],
        'round': nextRound,
        'round_name': 'Jornada $nextRound',
        'order_index': i,
        'status': 'pending',
        'duration_minutes': max(15, intValue(match['duration_minutes'], 60)),
        'location': text(match['location']).trim().isEmpty ? null : text(match['location']).trim(),
        'court_name': text(match['court_name']).trim().isEmpty ? null : text(match['court_name']).trim(),
        'notes': text(match['notes']).trim().isEmpty ? null : text(match['notes']).trim(),
      });
    }
    await sb.from('matches').insert(rows);
  }

  static Future<void> shiftTournamentMatchOrder(String matchId, List<Map<String, dynamic>> matches, int delta) async {
    Map<String, dynamic>? current;
    for (final match in matches) {
      if (text(match['id']) == matchId) {
        current = match;
        break;
      }
    }
    if (current == null) return;
    final round = intValue(current['round'], 1);
    final sameRound = matches.where((m) => intValue(m['round'], 1) == round).toList()
      ..sort((a, b) {
        final order = intValue(a['order_index']).compareTo(intValue(b['order_index']));
        if (order != 0) return order;
        return text(a['created_at']).compareTo(text(b['created_at']));
      });
    final index = sameRound.indexWhere((m) => text(m['id']) == matchId);
    final targetIndex = index + delta;
    if (index < 0 || targetIndex < 0 || targetIndex >= sameRound.length) return;
    final other = sameRound[targetIndex];
    final currentOrder = intValue(current['order_index']);
    final otherOrder = intValue(other['order_index']);
    await sb.from('matches').update({'order_index': otherOrder, 'updated_at': DateTime.now().toUtc().toIso8601String()}).eq('id', matchId);
    await sb.from('matches').update({'order_index': currentOrder, 'updated_at': DateTime.now().toUtc().toIso8601String()}).eq('id', other['id']);
  }

  static Future<void> createTournamentAgendaEvents(String groupId, String tournamentName, List<TournamentDraftMatch> pairings, DateTime firstStart) async {
    if (pairings.isEmpty) return;
    var index = 0;
    for (final pair in pairings.take(60)) {
      final start = firstStart.add(Duration(minutes: 60 * index));
      await createEvent(
        groupId,
        '$tournamentName: ${pair.teamAName} vs ${pair.teamBName}',
        start,
        '',
        'Partido de torneo · Jornada ${pair.round}',
        2,
      );
      index++;
    }
  }

  static Future<int> createAgendaEventsForTournament(String groupId, String tournamentId, String tournamentName) async {
    final data = await tournament(tournamentId);
    final teams = tournamentTeams(data);
    final names = teamNameMap(teams);
    final matches = tournamentMatches(data).where((m) {
      final status = AppData.text(m['status'], 'pending');
      return AppData.text(m['scheduled_at']).isNotEmpty &&
          AppData.text(m['event_id']).isEmpty &&
          status != 'cancelled' &&
          status != 'bye';
    }).take(120).toList();
    var createdCount = 0;
    for (final match in matches) {
      final start = DateTime.tryParse(AppData.text(match['scheduled_at']))?.toLocal();
      if (start == null) continue;
      final eventId = await createEvent(
        groupId,
        tournamentMatchAgendaTitle(tournamentName, match, names),
        start,
        AppData.text(match['location']),
        tournamentMatchAgendaNotes(match),
        2,
      );
      await sb.from('matches').update({'event_id': eventId, 'updated_at': DateTime.now().toUtc().toIso8601String()}).eq('id', match['id']);
      createdCount++;
    }
    return createdCount;
  }

  static Future<void> generateMatches(
    String tournamentId,
    String format,
    List<Map<String, dynamic>> teams, {
    Map<String, dynamic>? formatConfig,
    Map<String, dynamic>? scheduleConfig,
  }) async {
    if (teams.length < 2) {
      throw Exception(appIsEnglish ? 'Add at least 2 participants.' : 'Añade al menos 2 participantes.');
    }
    if (format == 'manual') {
      throw Exception(appIsEnglish ? 'This tournament uses manual pairings. Add matches from the tournament panel.' : 'Este torneo usa emparejamientos manuales. Añade los partidos desde el panel del torneo.');
    }

    await clearTournamentMatches(tournamentId);

    final rows = <Map<String, dynamic>>[];
    final ordered = teams.map((t) => Map<String, dynamic>.from(t)).toList();
    final randomizePairings = text(formatConfig?['randomize_pairings'], 'true') != 'false';
    if (randomizePairings && format != 'manual') {
      ordered.shuffle(Random.secure());
    }
    var orderIndex = 0;

    final roundCounters = <int, int>{};

    Map<String, dynamic> rowFor(Map<String, dynamic>? a, Map<String, dynamic>? b, int round, {String? status, int? scoreA, int? scoreB, Map<String, dynamic>? details}) {
      final orderInsideRound = roundCounters[round] ?? 0;
      roundCounters[round] = orderInsideRound + 1;
      final scheduledAt = tournamentScheduledAtForIndex(scheduleConfig, round, orderInsideRound);
      final court = tournamentCourtNameForIndex(scheduleConfig, orderInsideRound);
      final row = {
        'tournament_id': tournamentId,
        'team_a': a?['id'],
        'team_b': b?['id'],
        'score_a': scoreA,
        'score_b': scoreB,
        'round': round,
        'round_name': format == 'eliminatoria' ? eliminationRoundName(round, ordered.length) : format == 'americano' ? 'Ronda $round' : 'Jornada $round',
        'order_index': orderIndex,
        'status': status ?? (scheduledAt == null ? 'pending' : 'scheduled'),
        'scheduled_at': scheduledAt?.toUtc().toIso8601String(),
        'duration_minutes': max(15, intValue(scheduleConfig?['duration_minutes'], 60)),
        'location': text(scheduleConfig?['location']).trim().isEmpty ? null : text(scheduleConfig?['location']).trim(),
        'court_name': court.isEmpty ? null : court,
        'result_details': details,
      };
      orderIndex++;
      return row;
    }

    if (format == 'americano') {
      if (ordered.length < 4) {
        throw Exception(appIsEnglish ? 'Americano needs at least 4 players.' : 'El americano necesita al menos 4 jugadores.');
      }
      final rounds = max(1, min(40, intValue(formatConfig?['americano_rounds'], intValue(formatConfig?['rounds'], 5))));
      final courts = max(1, min(12, intValue(formatConfig?['courts_count'], intValue(scheduleConfig?['courts_count'], 1))));
      final generated = generateAmericanoRoundsIds(ordered.map((e) => e['id'].toString()).toList(), rounds: rounds, courts: courts);
      if (generated.isEmpty) {
        throw Exception(appIsEnglish ? 'Could not generate Americano rounds.' : 'No se han podido generar rondas de americano.');
      }
      final teamById = {for (final team in ordered) team['id'].toString(): team};
      for (final item in generated) {
        final a1 = teamById[item.sideA.first];
        final b1 = teamById[item.sideB.first];
        rows.add(rowFor(
          a1,
          b1,
          item.round,
          details: {
            'americano': true,
            'side_a_ids': item.sideA,
            'side_b_ids': item.sideB,
            'rest_ids': item.resting,
            'court_index': item.courtIndex + 1,
            'ranking_mode': 'individual',
          },
        ));
      }
    } else if (format == 'eliminatoria') {
      final targetBracket = nextPowerOfTwoAtLeast(ordered.length);
      final byes = max(0, targetBracket - ordered.length);
      final byeRows = <Map<String, dynamic>>[];
      final playRows = <Map<String, dynamic>>[];

      for (final team in ordered.take(byes)) {
        byeRows.add(rowFor(
          team,
          null,
          1,
          status: 'bye',
          scoreA: 1,
          scoreB: 0,
          details: {'bye': true, 'stage': 'bye', 'seed': intValue(team['seed'])},
        ));
      }

      final playTeams = ordered.skip(byes).toList();
      var left = 0;
      var right = playTeams.length - 1;
      while (left < right) {
        playRows.add(rowFor(
          playTeams[left],
          playTeams[right],
          1,
          details: {
            'stage': 'knockout',
            'seed_a': intValue(playTeams[left]['seed']),
            'seed_b': intValue(playTeams[right]['seed']),
          },
        ));
        left++;
        right--;
      }

      final maxRows = max(byeRows.length, playRows.length);
      for (var i = 0; i < maxRows; i++) {
        if (i < byeRows.length) rows.add(byeRows[i]);
        if (i < playRows.length) rows.add(playRows[i]);
      }
    } else {
      final legs = max(1, min(4, intValue(formatConfig?['legs'], 1)));
      final maxRounds = intValue(formatConfig?['max_rounds']);
      final base = generateRoundRobinIds(ordered.map((e) => e['id'].toString()).toList());
      final limited = maxRounds > 0 ? base.take(maxRounds).toList() : base;
      for (var leg = 1; leg <= legs; leg++) {
        for (var r = 0; r < limited.length; r++) {
          final round = r + 1 + ((leg - 1) * limited.length);
          for (final pair in limited[r]) {
            final a = ordered.firstWhere((t) => t['id'].toString() == pair.$1);
            final b = ordered.firstWhere((t) => t['id'].toString() == pair.$2);
            rows.add(leg.isOdd ? rowFor(a, b, round) : rowFor(b, a, round));
          }
        }
      }
    }

    if (rows.isEmpty) throw Exception(appIsEnglish ? 'Could not generate matches.' : 'No se han podido generar partidos.');
    await sb.from('matches').insert(rows);
  }

  static Future<void> generateNextEliminationRound(String tournamentId, List<Map<String, dynamic>> matches) async {
    final normalMatches = matches.where((m) => AppData.text(AppData.asMap(m['result_details'])['stage']) != 'third_place').toList();
    final latestRound = normalMatches.fold<int>(0, (maxRound, m) => max(maxRound, intValue(m['round'])));
    final latestMatches = normalMatches.where((m) => intValue(m['round']) == latestRound).toList()
      ..sort((a, b) => intValue(a['order_index']).compareTo(intValue(b['order_index'])));
    if (latestMatches.isEmpty) throw Exception(appIsEnglish ? 'There are no matches to generate the next round.' : 'No hay partidos para generar la siguiente ronda.');
    if (latestMatches.any((m) => text(m['status']) != 'played' && text(m['status']) != 'bye' && text(m['status']) != 'walkover' && text(m['status']) != 'no_show')) {
      throw Exception(appIsEnglish ? 'Close every result from the current round before advancing.' : 'Cierra todos los resultados de la ronda actual antes de avanzar.');
    }
    if (latestMatches.length == 1) throw Exception(appIsEnglish ? 'The bracket already has a recorded final.' : 'La eliminatoria ya tiene final registrada.');

    final winners = <String>[];
    for (final match in latestMatches) {
      final winner = tournamentMatchWinnerId(match);
      if (winner.isEmpty) throw Exception(appIsEnglish ? 'There is a match without a valid winner.' : 'Hay un partido sin ganador válido.');
      winners.add(winner);
    }
    if (winners.length % 2 != 0) throw Exception(appIsEnglish ? 'Odd number of winners. Check the results.' : 'Número impar de ganadores. Revisa resultados.');
    final rows = <Map<String, dynamic>>[];
    for (var i = 0; i < winners.length; i += 2) {
      rows.add({
        'tournament_id': tournamentId,
        'team_a': winners[i],
        'team_b': winners[i + 1],
        'round': latestRound + 1,
        'round_name': eliminationRoundNameForRemaining(winners.length),
        'order_index': i ~/ 2,
        'status': 'pending',
        'result_details': {'stage': winners.length == 2 ? 'final' : 'knockout'},
      });
    }
    await sb.from('matches').insert(rows);
  }

  static Future<void> generateThirdPlaceMatch(String tournamentId, List<Map<String, dynamic>> matches) async {
    if (matches.any((m) => text(asMap(m['result_details'])['stage']) == 'third_place' || text(m['round_name']).toLowerCase().contains('tercer'))) {
      throw Exception(appIsEnglish ? 'The third-place match already exists.' : 'El partido por el tercer puesto ya existe.');
    }

    final normalMatches = matches.where((m) => text(asMap(m['result_details'])['stage']) != 'third_place').toList();
    final rounds = normalMatches.map((m) => intValue(m['round'])).toSet().toList()..sort();
    if (rounds.length < 2) {
      throw Exception(appIsEnglish ? 'You need closed semifinals to create the third-place match.' : 'Necesitas tener semifinales cerradas para crear el tercer puesto.');
    }

    List<Map<String, dynamic>> semis = [];
    for (final round in rounds.reversed) {
      final roundMatches = normalMatches.where((m) => intValue(m['round']) == round).toList()
        ..sort((a, b) => intValue(a['order_index']).compareTo(intValue(b['order_index'])));
      if (roundMatches.length == 2) {
        semis = roundMatches;
        break;
      }
    }
    if (semis.length != 2) throw Exception(appIsEnglish ? 'I cannot find two semifinals to create the third-place match.' : 'No encuentro dos semifinales para sacar el tercer puesto.');
    if (semis.any((m) => text(m['status']) != 'played' && text(m['status']) != 'walkover' && text(m['status']) != 'no_show')) {
      throw Exception(appIsEnglish ? 'Close both semifinals before creating the third-place match.' : 'Cierra las dos semifinales antes de crear el tercer puesto.');
    }

    final losers = semis.map(tournamentMatchLoserId).where((id) => id.isNotEmpty).toList();
    if (losers.length != 2) throw Exception(appIsEnglish ? 'Could not detect the two semifinal losers.' : 'No se han podido detectar los dos perdedores de semifinales.');

    final targetRound = normalMatches.fold<int>(0, (value, m) => max(value, intValue(m['round'])));
    await sb.from('matches').insert({
      'tournament_id': tournamentId,
      'team_a': losers[0],
      'team_b': losers[1],
      'round': targetRound,
      'round_name': 'Tercer puesto',
      'order_index': 999,
      'status': 'pending',
      'result_details': {'stage': 'third_place'},
    });
  }

  static Future<void> setMatchResult(String matchId, int scoreA, int scoreB, {Map<String, dynamic>? details}) async {
    final current = asMap(await sb
        .from('matches')
        .select('team_a,team_b,score_a,score_b,status,result_details,winner_team_id')
        .eq('id', matchId)
        .single());
    final winner = scoreA == scoreB ? null : (scoreA > scoreB ? current['team_a'] : current['team_b']);
    final nextDetails = <String, dynamic>{...?details}
      ..remove('special_result')
      ..remove('loser_team_id')
      ..remove('no_show_team_id');
    nextDetails['history'] = matchHistoryWithEntry(current, 'Marcador guardado', '$scoreA - $scoreB');
    await sb.from('matches').update({
      'score_a': scoreA,
      'score_b': scoreB,
      'result_details': nextDetails,
      'winner_team_id': winner,
      'status': 'played',
      'result_status': 'confirmed',
      'played_at': DateTime.now().toUtc().toIso8601String(),
      'updated_by': user?.id,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', matchId);
  }

  static Future<void> setSpecialMatchResult(
    String matchId, {
    required String winnerTeamId,
    required String loserTeamId,
    required String specialResult,
    String note = '',
  }) async {
    final current = asMap(await sb
        .from('matches')
        .select('team_a,team_b,score_a,score_b,status,result_details,winner_team_id')
        .eq('id', matchId)
        .single());
    final aId = text(current['team_a']);
    final bId = text(current['team_b']);
    if (aId.isEmpty || bId.isEmpty) throw Exception(appIsEnglish ? 'This match does not have two participants.' : 'Este partido no tiene dos participantes.');
    if (winnerTeamId != aId && winnerTeamId != bId) throw Exception(appIsEnglish ? 'Invalid winner.' : 'Ganador no válido.');
    final winnerIsA = winnerTeamId == aId;
    final scoreA = winnerIsA ? 3 : 0;
    final scoreB = winnerIsA ? 0 : 3;
    final status = specialResult == 'no_show' ? 'no_show' : 'walkover';
    final label = specialResult == 'no_show' ? 'No presentado' : 'Victoria administrativa';
    final details = <String, dynamic>{
      'special_result': specialResult,
      'label': label,
      'loser_team_id': loserTeamId,
      if (specialResult == 'no_show') 'no_show_team_id': loserTeamId,
      if (note.trim().isNotEmpty) 'note': note.trim(),
      'history': matchHistoryWithEntry(current, label, note.trim().isEmpty ? '$scoreA - $scoreB' : note.trim()),
    };
    await sb.from('matches').update({
      'score_a': scoreA,
      'score_b': scoreB,
      'result_details': details,
      'winner_team_id': winnerTeamId,
      'status': status,
      'result_status': 'confirmed',
      'played_at': DateTime.now().toUtc().toIso8601String(),
      'updated_by': user?.id,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', matchId);
  }

  static Future<void> reopenMatch(String matchId) async {
    final current = asMap(await sb
        .from('matches')
        .select('team_a,team_b,score_a,score_b,status,result_details,winner_team_id')
        .eq('id', matchId)
        .single());
    final details = <String, dynamic>{
      'history': matchHistoryWithEntry(current, 'Resultado borrado', 'El partido vuelve a pendiente.'),
    };
    await sb.from('matches').update({
      'score_a': null,
      'score_b': null,
      'result_details': details,
      'winner_team_id': null,
      'status': 'pending',
      'result_status': 'pending',
      'played_at': null,
      'updated_by': user?.id,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', matchId);
  }

  static Future<void> updateMatchSchedule(String matchId, DateTime? scheduledAt, int durationMinutes, String location, String courtName, String notes) async {
    final current = asMap(await sb.from('matches').select('id,event_id,team_a,team_b,tournament_id,round,round_name,status,score_a,score_b,result_details').eq('id', matchId).single());
    final eventId = text(current['event_id']);
    final nextDetails = Map<String, dynamic>.from(asMap(current['result_details']));
    final action = scheduledAt == null ? 'Fecha eliminada' : 'Fecha actualizada';
    final dateNote = scheduledAt == null
        ? 'El partido queda sin fecha.'
        : '${DateFormat('d MMM yyyy · HH:mm', appDateLocale).format(scheduledAt.toLocal())}${courtName.trim().isEmpty ? '' : ' · ${courtName.trim()}'}';
    nextDetails['history'] = matchHistoryWithEntry(current, action, dateNote);
    await sb.from('matches').update({
      'scheduled_at': scheduledAt?.toUtc().toIso8601String(),
      'duration_minutes': max(15, durationMinutes),
      'location': location.trim().isEmpty ? null : location.trim(),
      'court_name': courtName.trim().isEmpty ? null : courtName.trim(),
      'notes': notes.trim().isEmpty ? null : notes.trim(),
      'event_id': scheduledAt == null ? null : eventId.isEmpty ? null : eventId,
      'status': scheduledAt == null ? 'pending' : 'scheduled',
      'result_details': nextDetails,
      'updated_by': user?.id,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', matchId);

    if (eventId.isNotEmpty && scheduledAt == null) {
      try { await cancelEvent(eventId); } catch (_) {}
      return;
    }

    if (eventId.isNotEmpty && scheduledAt != null) {
      try {
        final tournamentData = await tournament(text(current['tournament_id']));
        final names = teamNameMap(tournamentTeams(tournamentData));
        final updatedMatch = Map<String, dynamic>.from(current)
          ..['scheduled_at'] = scheduledAt.toUtc().toIso8601String()
          ..['duration_minutes'] = max(15, durationMinutes)
          ..['location'] = location.trim()
          ..['court_name'] = courtName.trim()
          ..['notes'] = notes.trim();
        final title = tournamentMatchAgendaTitle(text(tournamentData['name'], 'Torneo'), updatedMatch, names);
        await updateEvent(eventId, title, scheduledAt, location, tournamentMatchAgendaNotes(updatedMatch), 2);
      } catch (_) {}
    }
  }

  static Future<void> updateMatchStatus(String matchId, String status) async {
    final current = asMap(await sb
        .from('matches')
        .select('id,event_id,tournament_id,team_a,team_b,round,round_name,scheduled_at,duration_minutes,location,court_name,notes,status,score_a,score_b,result_details')
        .eq('id', matchId)
        .single());
    final nextDetails = Map<String, dynamic>.from(asMap(current['result_details']));
    nextDetails['history'] = matchHistoryWithEntry(current, 'Estado cambiado', matchStatusLabel(status));
    final payload = {
      'status': status,
      'result_details': nextDetails,
      'updated_by': user?.id,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    final eventId = text(current['event_id']);
    if (status == 'cancelled') {
      if (eventId.isNotEmpty) {
        try { await cancelEvent(eventId); } catch (_) {}
      }
      payload['event_id'] = null;
    }
    await sb.from('matches').update(payload).eq('id', matchId);

    if (eventId.isNotEmpty && status != 'cancelled') {
      try {
        final start = DateTime.tryParse(text(current['scheduled_at']))?.toLocal();
        if (start != null) {
          final tournamentData = await tournament(text(current['tournament_id']));
          final names = teamNameMap(tournamentTeams(tournamentData));
          final updatedMatch = Map<String, dynamic>.from(current)..['status'] = status;
          final title = tournamentMatchAgendaTitle(text(tournamentData['name'], 'Torneo'), updatedMatch, names);
          await updateEvent(eventId, title, start, text(current['location']), tournamentMatchAgendaNotes(updatedMatch), 2);
        }
      } catch (_) {}
    }
  }

  static Future<void> syncMatchAgendaEvent({
    required String groupId,
    required String tournamentName,
    required Map<String, dynamic> match,
    required Map<String, String> teamNames,
  }) async {
    final start = DateTime.tryParse(text(match['scheduled_at']))?.toLocal();
    if (start == null) return;
    final title = tournamentMatchAgendaTitle(tournamentName, match, teamNames);
    final eventId = text(match['event_id']);
    if (eventId.isEmpty) {
      final created = await createEvent(groupId, title, start, text(match['location']), tournamentMatchAgendaNotes(match), 2);
      await sb.from('matches').update({'event_id': created, 'updated_at': DateTime.now().toUtc().toIso8601String()}).eq('id', match['id']);
    } else {
      await updateEvent(eventId, title, start, text(match['location']), tournamentMatchAgendaNotes(match), 2);
    }
  }

  static Future<void> openTournamentMatchEvent(BuildContext context, String eventId, Map<String, dynamic> group) async {
    final event = await eventById(eventId);
    if (!context.mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventDetailScreen(event: event, group: group)));
  }

  static Future<void> bulkScheduleTournamentMatches({
    required String groupId,
    required String tournamentName,
    required List<Map<String, dynamic>> matches,
    required List<Map<String, dynamic>> teams,
    required DateTime firstStart,
    required int durationMinutes,
    required int intervalMinutes,
    required int courtsCount,
    required String location,
    required String courtName,
    required bool syncAgenda,
  }) async {
    if (matches.isEmpty) throw Exception(appIsEnglish ? 'There are no matches to reschedule.' : 'No hay partidos para reprogramar.');
    final names = teamNameMap(teams);
    final ordered = [...matches]..sort((a, b) {
      final round = intValue(a['round']).compareTo(intValue(b['round']));
      if (round != 0) return round;
      return intValue(a['order_index']).compareTo(intValue(b['order_index']));
    });
    final courts = max(1, courtsCount);
    final interval = max(15, intervalMinutes);
    for (var i = 0; i < ordered.length; i++) {
      final match = ordered[i];
      final wave = i ~/ courts;
      final start = firstStart.add(Duration(minutes: wave * interval));
      final court = courts <= 1
          ? courtName.trim()
          : (courtName.trim().isEmpty ? 'Pista ${(i % courts) + 1}' : '${courtName.trim()} ${(i % courts) + 1}');
      final updated = Map<String, dynamic>.from(match)
        ..['scheduled_at'] = start.toUtc().toIso8601String()
        ..['duration_minutes'] = max(15, durationMinutes)
        ..['location'] = location.trim()
        ..['court_name'] = court
        ..['status'] = 'scheduled';
      final nextDetails = Map<String, dynamic>.from(asMap(match['result_details']));
      nextDetails['history'] = matchHistoryWithEntry(match, 'Fecha actualizada en lote', '${DateFormat('d MMM yyyy · HH:mm', appDateLocale).format(start.toLocal())}${court.trim().isEmpty ? '' : ' · ${court.trim()}'}');
      await sb.from('matches').update({
        'scheduled_at': start.toUtc().toIso8601String(),
        'duration_minutes': max(15, durationMinutes),
        'location': location.trim().isEmpty ? null : location.trim(),
        'court_name': court.trim().isEmpty ? null : court.trim(),
        'status': 'scheduled',
        'result_details': nextDetails,
        'updated_by': user?.id,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', match['id']);
      if (syncAgenda) {
        await syncMatchAgendaEvent(groupId: groupId, tournamentName: tournamentName, match: updated, teamNames: names);
      }
    }
  }

  static Future<void> moveTournamentRound({
    required String groupId,
    required String tournamentName,
    required List<Map<String, dynamic>> matches,
    required List<Map<String, dynamic>> teams,
    required int round,
    required DateTime firstStart,
    required int durationMinutes,
    required int intervalMinutes,
    required int courtsCount,
    required String location,
    required String courtName,
    required bool syncAgenda,
  }) async {
    final selected = matches.where((m) => intValue(m['round'], 1) == round && text(m['status']) != 'played' && text(m['status']) != 'cancelled' && text(m['status']) != 'bye').toList();
    if (selected.isEmpty) throw Exception(appIsEnglish ? 'There are no movable matches in this round.' : 'No hay partidos movibles en esta jornada.');
    await bulkScheduleTournamentMatches(
      groupId: groupId,
      tournamentName: tournamentName,
      matches: selected,
      teams: teams,
      firstStart: firstStart,
      durationMinutes: durationMinutes,
      intervalMinutes: intervalMinutes,
      courtsCount: courtsCount,
      location: location,
      courtName: courtName,
      syncAgenda: syncAgenda,
    );
  }

  static Future<Map<String, dynamic>?> tournamentMatchByEventId(String eventId) async {
    final clean = eventId.trim();
    if (clean.isEmpty) return null;
    final rows = asList(await sb
        .from('matches')
        .select('id,tournament_id,group_id,event_id,status,round,round_name,scheduled_at')
        .eq('event_id', clean)
        .limit(1));
    if (rows.isEmpty) return null;
    return asMap(rows.first);
  }

  static Future<List<Map<String, dynamic>>> notifications() async {
    await ensureProfile();
    try {
      final res = await sb.from('notifications').select().order('created_at', ascending: false).limit(80);
      return asList(res);
    } catch (_) {
      return [];
    }
  }

  static Future<int> unreadNotificationCount() async {
    await ensureProfile();
    try {
      final res = await sb.from('notifications').select('id').filter('read_at', 'is', null);
      return asList(res).length;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> markNotificationRead(String notificationId) async {
    await sb.from('notifications').update({'read_at': DateTime.now().toUtc().toIso8601String()}).eq('id', notificationId);
  }

  static Future<void> markAllNotificationsRead() async {
    await sb.from('notifications').update({'read_at': DateTime.now().toUtc().toIso8601String()}).filter('read_at', 'is', null);
  }

  static Future<Map<String, dynamic>> notificationSettings() async {
    await ensureProfile();
    final uid = user?.id;
    if (uid == null) return <String, dynamic>{};
    try {
      final res = await sb.from('user_settings').select().eq('user_id', uid).maybeSingle();
      return asMap(res);
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  static Future<void> updateNotificationSettings(Map<String, bool> values) async {
    await ensureProfile();
    final uid = user?.id;
    if (uid == null) return;
    await sb.from('user_settings').upsert({
      'user_id': uid,
      ...values,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id');
  }

  static Future<void> registerDeviceToken(String token, String platform) async {
    final uid = user?.id;
    if (uid == null || token.trim().isEmpty) return;
    await ensureProfile();
    await sb.from('user_devices').upsert({
      'user_id': uid,
      'fcm_token': token.trim(),
      'platform': platform,
      'device_label': kIsWeb ? 'Web' : platform,
      'app_version': AppConfig.appVersion,
      'enabled': true,
      'last_seen_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'fcm_token');
    await updateNotificationSettings({'push_enabled': true});
  }


  static Future<void> createTestNotification() async {
    await ensureProfile();
    await sb.rpc('create_test_notification');
  }

  static Future<void> disableCurrentDeviceToken(String token) async {
    final uid = user?.id;
    if (uid == null || token.trim().isEmpty) return;
    try {
      await sb.from('user_devices').update({
        'enabled': false,
        'disabled_at': DateTime.now().toUtc().toIso8601String(),
        'last_seen_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('user_id', uid).eq('fcm_token', token.trim());
    } catch (_) {}
  }


  static Future<void> ensureAdminClaim() async {
    await ensureProfile();
    try {
      await sb.rpc('ensure_owner_admin');
    } catch (_) {
      // El panel admin queda oculto si el SQL de v15.21 aún no está ejecutado.
    }
  }

  static Future<String> currentAppAdminRole() async {
    await ensureAdminClaim();
    try {
      final res = await sb.rpc('app_admin_role');
      final role = res?.toString() ?? '';
      return ['owner', 'support', 'viewer'].contains(role) ? role : '';
    } catch (_) {
      try {
        final legacy = await sb.rpc('is_app_admin');
        return legacy == true ? 'owner' : '';
      } catch (_) {
        return '';
      }
    }
  }

  static Future<bool> isSuperAdmin() async {
    final role = await currentAppAdminRole();
    return role.isNotEmpty;
  }

  static Future<String> createSupportTicket({
    String? groupId,
    required String type,
    required String title,
    required String description,
    String priority = 'normal',
    String screen = 'app',
  }) async {
    final uid = user?.id;
    if (uid == null) throw Exception(appIsEnglish ? 'Sign in to send the report.' : 'Inicia sesión para enviar el reporte.');
    await ensureProfile();
    final cleanTitle = title.trim();
    final cleanDescription = description.trim();
    if (cleanTitle.length < 3 || cleanDescription.length < 8) {
      throw Exception(appIsEnglish ? 'Describe the problem in a little more detail.' : 'Describe el problema con un poco más de detalle.');
    }
    final row = await sb.from('support_tickets').insert({
      'user_id': uid,
      'group_id': groupId,
      'type': type,
      'title': cleanTitle,
      'description': cleanDescription,
      'priority': priority,
      'screen': screen,
      'app_version': AppConfig.appVersion,
      'device_info': kIsWeb ? 'web' : defaultTargetPlatform.name,
      'status': 'open',
    }).select('id').single();
    await logQualityEvent('support_ticket_created', screen: screen, groupId: groupId, message: cleanTitle);
    return row['id'].toString();
  }

  static Future<List<Map<String, dynamic>>> mySupportTickets() async {
    final uid = user?.id;
    if (uid == null) return [];
    try {
      final res = await sb
          .from('support_tickets')
          .select('*, groups(id,name)')
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(20);
      return asList(res);
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> adminOverview() async {
    await ensureAdminClaim();
    try {
      return asMap(await sb.rpc('admin_overview'));
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  static Future<List<Map<String, dynamic>>> adminSupportTickets({String status = 'open'}) async {
    await ensureAdminClaim();
    try {
      dynamic query = sb
          .from('support_tickets')
          .select('*, profiles(id,email,full_name,avatar_url), groups(id,name)');
      if (status != 'all') query = query.eq('status', status);
      final res = await query.order('created_at', ascending: false).limit(80);
      return asList(res);
    } catch (_) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> adminQualityEvents() async {
    await ensureAdminClaim();
    try {
      final res = await sb
          .from('app_quality_events')
          .select('*, profiles(id,email,full_name,avatar_url), groups(id,name)')
          .order('created_at', ascending: false)
          .limit(40);
      return asList(res);
    } catch (_) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> adminUsersOverview() async {
    await ensureAdminClaim();
    try {
      final res = await sb.rpc('admin_users_overview');
      return asList(res);
    } catch (_) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> adminGroupsOverview() async {
    await ensureAdminClaim();
    try {
      final res = await sb.rpc('admin_groups_overview');
      return asList(res);
    } catch (_) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> adminDevicesOverview() async {
    await ensureAdminClaim();
    try {
      final res = await sb.rpc('admin_devices_overview');
      return asList(res);
    } catch (_) {
      return [];
    }
  }

  static Future<void> adminSetUserStatus(String email, String status, {String note = ''}) async {
    await ensureAdminClaim();
    await sb.rpc('admin_set_user_status_by_email', params: {
      'target_email': email.trim().toLowerCase(),
      'new_status': status,
      'note': note.trim(),
    });
  }

  static Future<void> updateSupportTicketStatus(String ticketId, String status, {String? note}) async {
    await ensureAdminClaim();
    final payload = <String, dynamic>{
      'status': status,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      if (status == 'resolved' || status == 'closed') 'resolved_at': DateTime.now().toUtc().toIso8601String(),
      if (note != null) 'admin_note': note.trim().isEmpty ? null : note.trim(),
    };
    await sb.from('support_tickets').update(payload).eq('id', ticketId);
  }

  static Future<void> logQualityEvent(String type, {String? groupId, String screen = 'app', String message = '', Map<String, dynamic>? metadata}) async {
    final uid = user?.id;
    if (uid == null) return;
    try {
      await sb.from('app_quality_events').insert({
        'user_id': uid,
        'group_id': groupId,
        'event_type': type,
        'screen': screen,
        'message': message,
        'app_version': AppConfig.appVersion,
        'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
        'metadata': metadata ?? <String, dynamic>{},
      });
    } catch (_) {
      // Nunca bloquear al usuario por telemetría interna.
    }
  }
}
