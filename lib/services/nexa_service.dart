import 'package:supabase_flutter/supabase_flutter.dart';

class NexaService {
  static SupabaseClient get db => Supabase.instance.client;
  static User? get user => db.auth.currentUser;

  static String friendlyError(Object error) {
    final text = error.toString();
    if (text.contains('SocketException') || text.contains('Failed host lookup') || text.contains('Network is unreachable')) {
      return 'Network/DNS problem. Check your internet connection or Private DNS, then try again. No rebuild is needed for a temporary network error.';
    }
    if (text.contains('row-level security') || text.contains('permission denied')) {
      return 'Supabase blocked this action with a database permission rule. Run the safe 002 migration from this pack in Supabase SQL Editor, then try again.';
    }
    if (text.contains('duplicate key') || text.contains('unique constraint')) {
      return 'That username or record is already in use. Try a different username.';
    }
    return text.replaceFirst('Exception: ', '');
  }

  static Future<AuthResponse> signUp({
    required String email, required String password,
    required String username, required String displayName,
  }) {
    return db.auth.signUp(email: email, password: password, data: {
      'username': username, 'display_name': displayName,
    });
  }

  static Future<AuthResponse> signIn(String email, String password) =>
      db.auth.signInWithPassword(email: email, password: password);

  static Future<void> signOut() => db.auth.signOut();

  static Future<void> resetPassword(String email) =>
      db.auth.resetPasswordForEmail(email);

  static Future<void> ensureProfile({String? username, String? displayName}) async {
    final u = user;
    if (u == null) return;
    final existing = await db.from('profiles').select('id,username,display_name').eq('id', u.id).maybeSingle();
    if (existing != null) {
      final updates = <String, dynamic>{'updated_at': DateTime.now().toIso8601String()};
      if ((displayName ?? '').trim().isNotEmpty) updates['display_name'] = displayName!.trim();
      if ((username ?? '').trim().isNotEmpty && (existing['username'] == null || '${existing['username']}'.isEmpty)) updates['username'] = username!.trim().toLowerCase();
      await db.from('profiles').update(updates).eq('id', u.id);
      return;
    }
    final meta = u.userMetadata ?? {};
    final rawName = (displayName ?? meta['display_name'] ?? u.email?.split('@').first ?? 'NEXA member').toString().trim();
    var rawUsername = (username ?? meta['username'] ?? u.email?.split('@').first ?? 'member').toString().trim().toLowerCase().replaceAll('@', '');
    rawUsername = rawUsername.replaceAll(RegExp(r'[^a-z0-9_.]'), '_');
    if (rawUsername.length < 3) rawUsername = 'member_${u.id.substring(0, 6)}';
    await db.from('profiles').insert({
      'id': u.id, 'username': rawUsername, 'display_name': rawName,
      'bio': '', 'is_private': false,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<Map<String, dynamic>?> myProfile() async {
    final u = user;
    if (u == null) return null;
    return await db.from('profiles').select('id,username,display_name,bio,profile_photo_url,is_private,created_at').eq('id', u.id).maybeSingle();
  }

  static Future<void> saveProfile(String displayName, String bio) async {
    final u = user;
    if (u == null) throw Exception('Please sign in first.');
    await db.from('profiles').update({
      'display_name': displayName, 'bio': bio,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', u.id);
  }

  static Future<void> setPrivate(bool value) async {
    final u = user;
    if (u == null) throw Exception('Please sign in first.');
    await db.from('profiles').update({'is_private': value, 'updated_at': DateTime.now().toIso8601String()}).eq('id', u.id);
  }

  static Future<List<Map<String, dynamic>>> feed() async {
    final rows = List<Map<String, dynamic>>.from(await db.from('posts')
      .select('id,author_id,text,content_type,visibility,status,created_at')
      .eq('status', 'published').eq('visibility', 'public')
      .order('created_at', ascending: false).limit(50));
    if (rows.isEmpty) return rows;
    final ids = rows.map((r) => '${r['author_id']}').where((id) => id.isNotEmpty).toSet().toList();
    final profiles = ids.isEmpty ? <Map<String, dynamic>>[] : List<Map<String, dynamic>>.from(
      await db.from('profiles').select('id,username,display_name,profile_photo_url,is_private').inFilter('id', ids),
    );
    final byId = {for (final p in profiles) '${p['id']}': p};
    return rows.map((r) {
      final p = byId['${r['author_id']}'] ?? {};
      return {...r, 'username': p['username'], 'display_name': p['display_name'], 'profile_photo_url': p['profile_photo_url'], 'author_is_private': p['is_private']};
    }).toList();
  }

  static Future<void> createPost(String text, {String visibility = 'public'}) async {
    final u = user;
    if (u == null) throw Exception('Please sign in first.');
    if (text.trim().isEmpty) throw Exception('Write something before publishing.');
    await db.from('posts').insert({
      'author_id': u.id, 'text': text.trim(),
      'content_type': 'text', 'visibility': visibility, 'status': 'published',
    });
  }

  static Future<Map<String, dynamic>> likeState(String postId) async {
    final u = user;
    if (u == null) return {'liked': false, 'count': 0};
    final rows = List<Map<String, dynamic>>.from(await db.from('interactions').select('user_id').eq('post_id', postId).eq('kind', 'like'));
    return {'liked': rows.any((r) => r['user_id'] == u.id), 'count': rows.length};
  }

  static Future<Map<String, dynamic>> toggleLike(String postId) async {
    final u = user;
    if (u == null) throw Exception('Please sign in to like posts.');
    final existing = await db.from('interactions').select('user_id').eq('user_id', u.id).eq('post_id', postId).eq('kind', 'like').maybeSingle();
    if (existing != null) {
      await db.from('interactions').delete().eq('user_id', u.id).eq('post_id', postId).eq('kind', 'like');
    } else {
      await db.from('interactions').insert({'user_id': u.id, 'post_id': postId, 'kind': 'like'});
    }
    return likeState(postId);
  }

  static Future<void> comment(String postId, String body) async {
    final u = user;
    if (u == null) throw Exception('Please sign in to comment.');
    if (body.trim().isEmpty) return;
    await db.from('comments').insert({'post_id': postId, 'author_id': u.id, 'body': body.trim()});
  }

  static Future<void> notInterested(String postId) async {
    final u = user;
    if (u == null) throw Exception('Please sign in first.');
    await db.from('recommendation_events').insert({'user_id': u.id, 'content_id': postId, 'event_type': 'not_interested', 'value': -1});
  }

  static Future<void> reportPost(String postId, String reason) async {
    final u = user;
    if (u == null) throw Exception('Please sign in first.');
    await db.from('reports').insert({'reporter_id': u.id, 'target_type': 'post', 'target_id': postId, 'reason': reason});
  }

  static Future<List<Map<String, dynamic>>> searchProfiles(String query) async {
    final safe = query.replaceAll(',', ' ').trim();
    if (safe.isEmpty) return [];
    return List<Map<String, dynamic>>.from(await db.from('profiles')
      .select('id,username,display_name,bio,profile_photo_url,is_private')
      .or('username.ilike.%$safe%,display_name.ilike.%$safe%')
      .limit(30));
  }

  static Future<bool> toggleFollow(String followingId) async {
    final u = user;
    if (u == null) throw Exception('Please sign in to follow people.');
    if (u.id == followingId) throw Exception('You cannot follow your own account.');
    final existing = await db.from('follows').select('follower_id,status').eq('follower_id', u.id).eq('following_id', followingId).maybeSingle();
    if (existing != null) {
      await db.from('follows').delete().eq('follower_id', u.id).eq('following_id', followingId);
      return false;
    }
    await db.from('follows').insert({'follower_id': u.id, 'following_id': followingId, 'status': 'accepted'});
    return true;
  }

  static Future<List<Map<String, dynamic>>> notifications() async {
    final u = user;
    if (u == null) return [];
    return List<Map<String, dynamic>>.from(await db.from('notifications')
      .select('id,type,title,body,is_read,created_at')
      .eq('user_id', u.id).order('created_at', ascending: false).limit(50));
  }
}
