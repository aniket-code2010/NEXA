import 'package:supabase_flutter/supabase_flutter.dart';

class NexaService {
  static SupabaseClient get db => Supabase.instance.client;

  static User? get user => db.auth.currentUser;

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) {
    return db.auth.signUp(
      email: email,
      password: password,
      data: {'username': username, 'display_name': displayName},
    );
  }

  static Future<AuthResponse> signIn(String email, String password) =>
      db.auth.signInWithPassword(email: email, password: password);

  static Future<void> signOut() => db.auth.signOut();

  static Future<void> saveProfile(String displayName, String bio) async {
    final u = user;
    if (u == null) return;
    await db.from('profiles').upsert({
      'id': u.id,
      'display_name': displayName,
      'bio': bio,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> interests() async =>
      List<Map<String, dynamic>>.from(
        await db.from('interests').select().eq('is_active', true).order('name'),
      );

  static Future<void> saveInterests(List<int> ids) async {
    final u = user;
    if (u == null) return;
    await db.from('user_interests').delete().eq('user_id', u.id);
    if (ids.isEmpty) return;
    await db.from('user_interests').insert(
      ids.map((id) => {'user_id': u.id, 'interest_id': id, 'source': 'selected'}).toList(),
    );
  }

  static Future<List<Map<String, dynamic>>> feed() async =>
      List<Map<String, dynamic>>.from(
        await db.from('posts')
          .select('id,text,content_type,visibility,created_at,profiles(username,display_name)')
          .eq('visibility', 'public')
          .eq('status', 'published')
          .order('created_at', ascending: false)
          .limit(30),
      );

  static Future<void> createPost(String text) async {
    final u = user;
    if (u == null || text.trim().isEmpty) return;
    await db.from('posts').insert({'author_id': u.id, 'text': text.trim()});
  }

  static Future<void> like(String postId) async {
    final u = user;
    if (u == null) return;
    await db.from('interactions').upsert({'user_id': u.id, 'post_id': postId, 'kind': 'like'});
  }

  static Future<void> comment(String postId, String body) async {
    final u = user;
    if (u == null || body.trim().isEmpty) return;
    await db.from('comments').insert({'post_id': postId, 'author_id': u.id, 'body': body.trim()});
  }
}

