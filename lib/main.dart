import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/nexa_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('SUPABASE_URL');
  const anon = String.fromEnvironment('SUPABASE_ANON_KEY');
  const publishable = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  final key = publishable.isNotEmpty ? publishable : anon;

  if (url.isNotEmpty && key.isNotEmpty) {
    await Supabase.initialize(url: url, anonKey: key);
  }
  runApp(NexaApp(configured: url.isNotEmpty && key.isNotEmpty));
}

class NexaApp extends StatefulWidget {
  const NexaApp({super.key, required this.configured});
  final bool configured;
  @override
  State<NexaApp> createState() => _NexaAppState();
}

class _NexaAppState extends State<NexaApp> {
  ThemeMode _mode = ThemeMode.system;
  void _setMode(ThemeMode mode) => setState(() => _mode = mode);

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF7657F6);
    return MaterialApp(
      title: 'NEXA',
      debugShowCheckedModeBanner: false,
      themeMode: _mode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
        scaffoldBackgroundColor: const Color(0xFFF8F7FC),
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0, backgroundColor: Color(0xFFF8F7FC)),
        cardTheme: CardThemeData(color: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
        inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: const Color(0xFFF0EDF9),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: seed, width: 1.5)),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
        scaffoldBackgroundColor: const Color(0xFF101018),
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0, backgroundColor: Color(0xFF101018)),
        cardTheme: CardThemeData(color: const Color(0xFF1A1925), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
        inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: const Color(0xFF242231),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: seed, width: 1.5)),
        ),
      ),
      home: widget.configured
          ? AuthGate(setThemeMode: _setMode, themeMode: _mode)
          : const SetupPage(),
    );
  }
}

class NexaLogo extends StatelessWidget {
  const NexaLogo({super.key, this.size = 54, this.wordmark = false});
  final double size;
  final bool wordmark;
  @override
  Widget build(BuildContext context) {
    final mark = Container(
      width: size, height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * .30),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF9B5CFF), Color(0xFF536DFF), Color(0xFF32C8E8)]),
        boxShadow: [BoxShadow(color: const Color(0xFF7657F6).withValues(alpha: .24), blurRadius: 22, offset: const Offset(0, 8))],
      ),
      child: Center(child: Text('N', style: TextStyle(fontSize: size * .63, fontWeight: FontWeight.w900, color: Colors.white, height: 1))),
    );
    if (!wordmark) return mark;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      mark, const SizedBox(width: 12),
      const Text('NEXA', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 24)),
    ]);
  }
}

class SetupPage extends StatelessWidget {
  const SetupPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const NexaLogo(size: 78), const SizedBox(height: 22),
        const Text('NEXA', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 4)),
        const SizedBox(height: 12),
        const Text('Supabase configuration is missing. Add SUPABASE_URL and SUPABASE_ANON_KEY to the Codemagic environment group.', textAlign: TextAlign.center),
      ]),
    )),
  );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.setThemeMode, required this.themeMode});
  final ValueChanged<ThemeMode> setThemeMode;
  final ThemeMode themeMode;
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) return const WelcomePage();
        return FutureBuilder<void>(
          future: NexaService.ensureProfile(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.hasError) {
              return MainShell(setThemeMode: setThemeMode, themeMode: themeMode, profileWarning: 'Profile setup needs attention: ${profileSnapshot.error}');
            }
            if (profileSnapshot.connectionState != ConnectionState.done) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            return MainShell(setThemeMode: setThemeMode, themeMode: themeMode);
          },
        );
      },
    );
  }
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF17132B), Color(0xFF28204C), Color(0xFF101018)])),
      child: SafeArea(child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Spacer(), const Center(child: NexaLogo(size: 92)),
          const SizedBox(height: 28),
          const Center(child: Text('Your world, connected.', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, height: 1.15))),
          const SizedBox(height: 12),
          const Center(child: Text('One place. Everything social.', style: TextStyle(color: Colors.white70, fontSize: 16))),
          const SizedBox(height: 42),
          SizedBox(width: double.infinity, height: 54, child: FilledButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AuthPage())),
            child: const Text('Get started', style: TextStyle(fontWeight: FontWeight.bold)),
          )),
          const SizedBox(height: 12),
          const Center(child: Text('Connect with what matters to you.', style: TextStyle(color: Colors.white54, fontSize: 12))),
          const Spacer(),
        ]),
      )),
    ),
  );
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _username = TextEditingController();
  final _displayName = TextEditingController();
  bool _login = true, _loading = false, _hidePassword = true;
  String? _message;

  @override
  void dispose() {
    _email.dispose(); _password.dispose(); _username.dispose(); _displayName.dispose(); super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _loading = true; _message = null; });
    try {
      if (_login) {
        await NexaService.signIn(_email.text.trim(), _password.text);
      } else {
        await NexaService.signUp(
          email: _email.text.trim(), password: _password.text,
          username: _username.text.trim().replaceAll('@', '').toLowerCase(),
          displayName: _displayName.text.trim(),
        );
        if (NexaService.user == null) {
          setState(() => _message = 'Account created. Check your email and verify it, then sign in.');
        } else {
          await NexaService.ensureProfile(displayName: _displayName.text.trim(), username: _username.text.trim().replaceAll('@', '').toLowerCase());
        }
      }
    } on AuthException catch (e) {
      setState(() => _message = e.message);
    } catch (e) {
      setState(() => _message = NexaService.friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _message = 'Enter your email address first.');
      return;
    }
    try {
      await NexaService.resetPassword(email);
      if (mounted) setState(() => _message = 'Password reset email sent if the address is registered.');
    } catch (e) {
      if (mounted) setState(() => _message = NexaService.friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.maybePop(context))),
    body: SafeArea(child: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 30),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440), child: Form(
        key: _form,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Center(child: NexaLogo(size: 68)), const SizedBox(height: 22),
          Text(_login ? 'Welcome back' : 'Create your account', textAlign: TextAlign.center, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(_login ? 'Sign in to continue to NEXA.' : 'Your people. Your interests. Your NEXA.', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 28),
          if (!_login) ...[
            TextFormField(controller: _displayName, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Display name', prefixIcon: Icon(Icons.person_outline)), validator: (v) => !_login && (v == null || v.trim().isEmpty) ? 'Enter your display name' : null),
            const SizedBox(height: 13),
            TextFormField(controller: _username, decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.alternate_email)), validator: (v) {
              if (_login) return null;
              final value = (v ?? '').trim().replaceAll('@', '');
              if (value.length < 3) return 'Use at least 3 characters';
              if (!RegExp(r'^[a-zA-Z0-9_.]+$').hasMatch(value)) return 'Use letters, numbers, _ or .';
              return null;
            }),
            const SizedBox(height: 13),
          ],
          TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, autocorrect: false, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)), validator: (v) => v == null || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim()) ? 'Enter a valid email' : null),
          const SizedBox(height: 13),
          TextFormField(controller: _password, obscureText: _hidePassword, decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(onPressed: () => setState(() => _hidePassword = !_hidePassword), icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined))), validator: (v) => v == null || v.length < 6 ? 'Use at least 6 characters' : null),
          if (_login) Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _resetPassword, child: const Text('Forgot password?'))),
          if (_message != null) ...[
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(14)), child: Text(_message!)),
          ],
          const SizedBox(height: 18),
          SizedBox(height: 52, child: FilledButton(
            onPressed: _loading ? null : _submit,
            child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)) : Text(_login ? 'Sign in' : 'Create account', style: const TextStyle(fontWeight: FontWeight.bold)),
          )),
          const SizedBox(height: 8),
          TextButton(onPressed: _loading ? null : () => setState(() { _login = !_login; _message = null; }), child: Text(_login ? 'New to NEXA? Create account' : 'Already have an account? Sign in')),
        ]),
      )),
    ))),
  );
}

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.setThemeMode, required this.themeMode, this.profileWarning});
  final ValueChanged<ThemeMode> setThemeMode;
  final ThemeMode themeMode;
  final String? profileWarning;
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  int _refreshKey = 0;
  final _searchController = TextEditingController();
  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  void _openCreate() async {
    final result = await showModalBottomSheet<bool>(
      context: context, isScrollControlled: true, useSafeArea: true,
      builder: (_) => const CreatePostSheet(),
    );
    if (result == true && mounted) setState(() => _refreshKey++);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(key: ValueKey('home$_refreshKey'), onCreate: _openCreate),
      const ReelsPage(),
      const MessagesPage(),
      SearchPage(controller: _searchController),
      ProfilePage(setThemeMode: widget.setThemeMode, themeMode: widget.themeMode),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('NEXA', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 3)),
        leading: IconButton(tooltip: 'Create post', onPressed: _openCreate, icon: const Icon(Icons.add_box_outlined)),
        actions: [IconButton(tooltip: 'Notifications', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage())), icon: const Icon(Icons.notifications_none_rounded)), const SizedBox(width: 6)],
      ),
      body: Column(children: [
        if (widget.profileWarning != null) MaterialBanner(content: Text(widget.profileWarning!), actions: [TextButton(onPressed: () {}, child: const Text('OK'))]),
        Expanded(child: AnimatedSwitcher(duration: const Duration(milliseconds: 240), child: KeyedSubtree(key: ValueKey(_index), child: pages[_index]))),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (v) => setState(() => _index = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.play_circle_outline_rounded), selectedIcon: Icon(Icons.play_circle_fill_rounded), label: 'Reels'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline_rounded), selectedIcon: Icon(Icons.chat_bubble_rounded), label: 'Msg'),
          NavigationDestination(icon: Icon(Icons.search_rounded), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

class CreatePostSheet extends StatefulWidget {
  const CreatePostSheet({super.key});
  @override
  State<CreatePostSheet> createState() => _CreatePostSheetState();
}
class _CreatePostSheetState extends State<CreatePostSheet> {
  final _text = TextEditingController();
  bool _busy = false;
  String _visibility = 'public';
  @override
  void dispose() { _text.dispose(); super.dispose(); }
  Future<void> _submit() async {
    if (_text.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await NexaService.createPost(_text.text, visibility: _visibility);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(NexaService.friendlyError(e))));
    } finally { if (mounted) setState(() => _busy = false); }
  }
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 22),
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Center(child: Container(width: 38, height: 4, decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(8)))),
      const SizedBox(height: 20),
      const Text('Create a post', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 14),
      TextField(controller: _text, autofocus: true, maxLines: 5, maxLength: 2000, decoration: const InputDecoration(hintText: 'What’s on your mind?', alignLabelWithHint: true)),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(value: _visibility, decoration: const InputDecoration(labelText: 'Audience'), items: const [
        DropdownMenuItem(value: 'public', child: Text('Public')),
        DropdownMenuItem(value: 'followers', child: Text('Followers (requires follow privacy rules)')),
      ], onChanged: (v) => setState(() => _visibility = v ?? 'public')),
      const SizedBox(height: 14),
      SizedBox(height: 50, child: FilledButton.icon(onPressed: _busy ? null : _submit, icon: const Icon(Icons.send_rounded), label: Text(_busy ? 'Posting…' : 'Publish post'))),
    ]),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.onCreate});
  final VoidCallback onCreate;
  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  late Future<List<Map<String, dynamic>>> _future;
  @override
  void initState() { super.initState(); _future = NexaService.feed(); }
  Future<void> _refresh() async { setState(() => _future = NexaService.feed()); await _future; }
  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: _refresh,
    child: FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return ListView(children: const [SizedBox(height: 150), Center(child: CircularProgressIndicator()), SizedBox(height: 18), Center(child: Text('Loading your feed…'))]);
        if (snap.hasError) return ListView(children: [const SizedBox(height: 90), const Icon(Icons.cloud_off_rounded, size: 50), const SizedBox(height: 14), const Center(child: Text('Could not load the feed')), Padding(padding: const EdgeInsets.all(18), child: Text(NexaService.friendlyError(snap.error!), textAlign: TextAlign.center)), Center(child: FilledButton.tonal(onPressed: _refresh, child: const Text('Try again')))]);
        final posts = snap.data ?? [];
        if (posts.isEmpty) return ListView(padding: const EdgeInsets.all(24), children: [
          const SizedBox(height: 70), const Center(child: NexaLogo(size: 66)), const SizedBox(height: 20),
          const Center(child: Text('Your feed starts here', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
          const SizedBox(height: 8), const Center(child: Text('Be the first to share something with your NEXA community.', textAlign: TextAlign.center)),
          const SizedBox(height: 20), Center(child: FilledButton.icon(onPressed: widget.onCreate, icon: const Icon(Icons.add), label: const Text('Create first post'))),
        ]);
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24), itemCount: posts.length,
          itemBuilder: (context, i) => PostCard(post: posts[i], onChanged: _refresh),
        );
      },
    ),
  );
}

class PostCard extends StatefulWidget {
  const PostCard({super.key, required this.post, required this.onChanged});
  final Map<String, dynamic> post;
  final VoidCallback onChanged;
  @override
  State<PostCard> createState() => _PostCardState();
}
class _PostCardState extends State<PostCard> {
  bool _liked = false, _busy = false;
  int _likeCount = 0;
  String get _id => '${widget.post['id']}';
  String get _name => '${widget.post['display_name'] ?? widget.post['username'] ?? 'NEXA member'}';
  String get _username => '${widget.post['username'] ?? 'member'}';
  @override
  void initState() { super.initState(); _loadLike(); }
  Future<void> _loadLike() async {
    try {
      final value = await NexaService.likeState(_id);
      if (mounted) setState(() { _liked = value['liked'] == true; _likeCount = value['count'] as int? ?? 0; });
    } catch (_) {}
  }
  Future<void> _toggleLike() async {
    if (_busy) return;
    setState(() { _busy = true; _liked = !_liked; _likeCount += _liked ? 1 : -1; });
    try {
      final state = await NexaService.toggleLike(_id);
      if (mounted) setState(() { _liked = state['liked'] == true; _likeCount = state['count'] as int? ?? _likeCount; });
    } catch (e) {
      if (mounted) { setState(() { _liked = !_liked; _likeCount += _liked ? 1 : -1; }); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(NexaService.friendlyError(e)))); }
    } finally { if (mounted) setState(() => _busy = false); }
  }
  Future<void> _comment() async {
    final controller = TextEditingController();
    final body = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Add a comment'),
      content: TextField(controller: controller, autofocus: true, maxLines: 3, decoration: const InputDecoration(hintText: 'Write something kind…')),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Post'))],
    ));
    controller.dispose();
    if (body == null || body.trim().isEmpty) return;
    try { await NexaService.comment(_id, body); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comment added'))); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(NexaService.friendlyError(e)))); }
  }
  Future<void> _menu(String action) async {
    try {
      if (action == 'not_interested') await NexaService.notInterested(_id);
      if (action == 'report') {
        final reason = await showDialog<String>(context: context, builder: (ctx) => SimpleDialog(title: const Text('Report post'), children: [
          for (final r in ['Spam', 'Harassment', 'Harmful content', 'Other']) SimpleDialogOption(onPressed: () => Navigator.pop(ctx, r), child: Text(r)),
        ]));
        if (reason == null) return;
        await NexaService.reportPost(_id, reason);
      }
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(action == 'not_interested' ? 'We’ll show you less like this.' : 'Report submitted for review.'))); if (action == 'not_interested') widget.onChanged(); }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(NexaService.friendlyError(e)))); }
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final created = DateTime.tryParse('${widget.post['created_at'] ?? ''}')?.toLocal();
    final dateLabel = created == null ? '' : '${created.day}/${created.month}';
    return Card(
      margin: const EdgeInsets.only(bottom: 13),
      child: Padding(padding: const EdgeInsets.fromLTRB(15, 14, 15, 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(backgroundColor: theme.colorScheme.primaryContainer, child: Text(_name.isNotEmpty ? _name[0].toUpperCase() : 'N', style: TextStyle(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold))),
          const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_name, style: const TextStyle(fontWeight: FontWeight.w800)),
            Text('@$_username${dateLabel.isEmpty ? '' : ' · $dateLabel'}', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
          ])),
          PopupMenuButton<String>(onSelected: _menu, itemBuilder: (_) => const [
            PopupMenuItem(value: 'not_interested', child: Text('Not interested')),
            PopupMenuItem(value: 'report', child: Text('Report post')),
          ]),
        ]),
        if ('${widget.post['text'] ?? ''}'.trim().isNotEmpty) Padding(padding: const EdgeInsets.only(top: 15, bottom: 10), child: Text('${widget.post['text']}', style: const TextStyle(fontSize: 15, height: 1.45))),
        const Divider(height: 18),
        Row(children: [
          _ActionIcon(icon: _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded, label: '$_likeCount', active: _liked, onTap: _toggleLike),
          const SizedBox(width: 18),
          _ActionIcon(icon: Icons.mode_comment_outlined, label: 'Comment', onTap: _comment),
          const Spacer(),
          IconButton(tooltip: 'Share', onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Share links will be enabled when public post URLs are configured.'))), icon: const Icon(Icons.ios_share_rounded, size: 20)),
        ]),
      ])),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.icon, required this.label, required this.onTap, this.active = false});
  final IconData icon; final String label; final VoidCallback onTap; final bool active;
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(14), onTap: onTap,
    child: Padding(padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2), child: Row(children: [
      Icon(icon, size: 21, color: active ? Colors.pinkAccent : Theme.of(context).colorScheme.onSurfaceVariant),
      const SizedBox(width: 6), Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
    ])),
  );
}

class ReelsPage extends StatelessWidget {
  const ReelsPage({super.key});
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 92, height: 92, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF9B5CFF), Color(0xFF32C8E8)]), borderRadius: BorderRadius.circular(28)), child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 54)),
    const SizedBox(height: 20), const Text('NEXA Reels', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
    const SizedBox(height: 8), const Text('The short-video viewer is ready for the next media phase. Video upload/playback needs a media picker, storage bucket and video URL field.', textAlign: TextAlign.center),
  ])));
}

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.forum_rounded, size: 64, color: Theme.of(context).colorScheme.primary),
    const SizedBox(height: 18), const Text('Your messages', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
    const SizedBox(height: 8), const Text('Messaging UI is prepared, but real 1:1/group chats need conversation and message tables plus their access policies. Those tables are not in the existing schema, so this screen won’t pretend chats are working yet.'),
  ])));
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, required this.controller});
  final TextEditingController controller;
  @override
  State<SearchPage> createState() => _SearchPageState();
}
class _SearchPageState extends State<SearchPage> {
  bool _loading = false;
  List<Map<String, dynamic>> _results = [];
  String? _error;
  Future<void> _search(String value) async {
    if (value.trim().isEmpty) { setState(() { _results = []; _error = null; }); return; }
    setState(() { _loading = true; _error = null; });
    try { final results = await NexaService.searchProfiles(value.trim()); if (mounted) setState(() => _results = results); }
    catch (e) { if (mounted) setState(() => _error = NexaService.friendlyError(e)); }
    finally { if (mounted) setState(() => _loading = false); }
  }
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(16), child: Column(children: [
    TextField(controller: widget.controller, onChanged: _search, decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search people by name or username', suffixIcon: Icon(Icons.tune_rounded))),
    const SizedBox(height: 12),
    if (_loading) const LinearProgressIndicator(),
    if (_error != null) Padding(padding: const EdgeInsets.all(12), child: Text(_error!)),
    Expanded(child: _results.isEmpty ? Center(child: Text(widget.controller.text.isEmpty ? 'Find people on NEXA' : 'No matching people found')) : ListView.separated(
      itemCount: _results.length, separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) { final p = _results[i]; final name = '${p['display_name'] ?? p['username'] ?? 'Member'}'; return ListTile(
        leading: CircleAvatar(child: Text(name.isEmpty ? 'N' : name[0].toUpperCase())),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('@${p['username'] ?? 'member'}'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PublicProfilePage(profile: p))),
      ); },
    )),
  ]));
}

class PublicProfilePage extends StatefulWidget {
  const PublicProfilePage({super.key, required this.profile});
  final Map<String, dynamic> profile;
  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}
class _PublicProfilePageState extends State<PublicProfilePage> {
  bool _busy = false, _following = false;
  Future<void> _follow() async {
    setState(() => _busy = true);
    try { final following = await NexaService.toggleFollow('${widget.profile['id']}'); if (mounted) setState(() => _following = following); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(NexaService.friendlyError(e)))); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  @override
  Widget build(BuildContext context) {
    final name = '${widget.profile['display_name'] ?? widget.profile['username'] ?? 'Member'}';
    return Scaffold(appBar: AppBar(title: Text('@${widget.profile['username'] ?? 'member'}')), body: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      const SizedBox(height: 20), CircleAvatar(radius: 45, child: Text(name.isEmpty ? 'N' : name[0].toUpperCase(), style: const TextStyle(fontSize: 30))),
      const SizedBox(height: 14), Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
      Text('@${widget.profile['username'] ?? 'member'}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      if ('${widget.profile['bio'] ?? ''}'.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text('${widget.profile['bio']}', textAlign: TextAlign.center)),
      const SizedBox(height: 20), SizedBox(width: double.infinity, child: FilledButton(onPressed: _busy ? null : _follow, child: Text(_busy ? 'Please wait…' : _following ? 'Following' : 'Follow'))),
    ])));
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.setThemeMode, required this.themeMode});
  final ValueChanged<ThemeMode> setThemeMode;
  final ThemeMode themeMode;
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}
class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { final p = await NexaService.myProfile(); if (mounted) setState(() => _profile = p); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(NexaService.friendlyError(e)))); }
    finally { if (mounted) setState(() => _loading = false); }
  }
  Future<void> _edit() async {
    final name = TextEditingController(text: '${_profile?['display_name'] ?? ''}');
    final bio = TextEditingController(text: '${_profile?['bio'] ?? ''}');
    final result = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Edit profile'),
      content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, maxLength: 60, decoration: const InputDecoration(labelText: 'Display name')),
        const SizedBox(height: 10), TextField(controller: bio, maxLines: 3, maxLength: 160, decoration: const InputDecoration(labelText: 'Bio')),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), FilledButton(onPressed: () async { try { await NexaService.saveProfile(name.text.trim(), bio.text.trim()); if (ctx.mounted) Navigator.pop(ctx, true); } catch (e) { if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(NexaService.friendlyError(e)))); } }, child: const Text('Save'))],
    ));
    name.dispose(); bio.dispose();
    if (result == true) _load();
  }
  Future<void> _settings() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsPage(setThemeMode: widget.setThemeMode, initialMode: widget.themeMode)));
    _load();
  }
  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final name = '${_profile?['display_name'] ?? NexaService.user?.userMetadata?['display_name'] ?? 'NEXA member'}';
    final username = '${_profile?['username'] ?? NexaService.user?.userMetadata?['username'] ?? 'member'}';
    return RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(22), children: [
      Align(alignment: Alignment.centerRight, child: IconButton(onPressed: _settings, icon: const Icon(Icons.settings_outlined), tooltip: 'Settings')),
      const SizedBox(height: 6), Center(child: CircleAvatar(radius: 48, child: Text(name.isEmpty ? 'N' : name[0].toUpperCase(), style: const TextStyle(fontSize: 32)))),
      const SizedBox(height: 14), Center(child: Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900))),
      Center(child: Text('@$username', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))),
      if ('${_profile?['bio'] ?? ''}'.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Center(child: Text('${_profile?['bio']}', textAlign: TextAlign.center))),
      const SizedBox(height: 18),
      Row(children: [
        Expanded(child: OutlinedButton.icon(onPressed: _edit, icon: const Icon(Icons.edit_outlined), label: const Text('Edit profile'))),
        const SizedBox(width: 10),
        Expanded(child: OutlinedButton.icon(onPressed: _settings, icon: const Icon(Icons.tune_rounded), label: const Text('Settings'))),
      ]),
      const SizedBox(height: 26), const Divider(),
      ListTile(leading: const Icon(Icons.bookmark_border_rounded), title: const Text('Saved posts'), subtitle: const Text('Saved-post storage will be added with the next schema phase.'), onTap: () => _info('Saved posts need a dedicated saved_posts table.')),
      ListTile(leading: const Icon(Icons.people_outline_rounded), title: const Text('Followers and following'), subtitle: const Text('Follow controls are available on public profiles.'), onTap: () => _info('A full follower list screen is planned for the next profile phase.')),
      ListTile(leading: const Icon(Icons.group_outlined), title: const Text('Close Friends'), subtitle: const Text('Audience list not yet connected to a database table.'), onTap: () => _info('Close Friends requires a close_friends table and post audience policy.')),
    ]));
  }
  void _info(String message) => showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: const Text('NEXA'), content: Text(message), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))]));
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}
class _NotificationsPageState extends State<NotificationsPage> {
  late Future<List<Map<String, dynamic>>> _future;
  @override
  void initState() { super.initState(); _future = NexaService.notifications(); }
  Future<void> _refresh() async { setState(() => _future = NexaService.notifications()); await _future; }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Notifications')), body: RefreshIndicator(onRefresh: _refresh, child: FutureBuilder<List<Map<String, dynamic>>>(
    future: _future, builder: (context, snap) {
      if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
      if (snap.hasError) return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text(NexaService.friendlyError(snap.error!))));
      final items = snap.data ?? [];
      if (items.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('You’re all caught up.', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700))));
      return ListView.separated(itemCount: items.length, separatorBuilder: (_, __) => const Divider(height: 1), itemBuilder: (context, i) => ListTile(leading: const CircleAvatar(child: Icon(Icons.notifications_none)), title: Text('${items[i]['title'] ?? 'NEXA notification'}'), subtitle: Text('${items[i]['body'] ?? ''}'), trailing: items[i]['is_read'] == true ? null : const Icon(Icons.circle, size: 9)));
    },
  )));
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.setThemeMode, required this.initialMode});
  final ValueChanged<ThemeMode> setThemeMode;
  final ThemeMode initialMode;
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}
class _SettingsPageState extends State<SettingsPage> {
  late ThemeMode _mode;
  bool _private = false, _loading = true, _busy = false;
  @override
  void initState() { super.initState(); _mode = widget.initialMode; _load(); }
  Future<void> _load() async {
    try { final p = await NexaService.myProfile(); if (mounted) setState(() => _private = p?['is_private'] == true); }
    catch (_) {} finally { if (mounted) setState(() => _loading = false); }
  }
  Future<void> _togglePrivate(bool value) async {
    setState(() { _private = value; _busy = true; });
    try { await NexaService.setPrivate(value); }
    catch (e) { if (mounted) { setState(() => _private = !value); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(NexaService.friendlyError(e)))); } }
    finally { if (mounted) setState(() => _busy = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Settings')), body: ListView(padding: const EdgeInsets.all(16), children: [
    const Text('APPEARANCE', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
    const SizedBox(height: 8),
    RadioListTile<ThemeMode>(value: ThemeMode.system, groupValue: _mode, title: const Text('Use device setting'), onChanged: (v) { if (v != null) { setState(() => _mode = v); widget.setThemeMode(v); } }),
    RadioListTile<ThemeMode>(value: ThemeMode.light, groupValue: _mode, title: const Text('Light'), onChanged: (v) { if (v != null) { setState(() => _mode = v); widget.setThemeMode(v); } }),
    RadioListTile<ThemeMode>(value: ThemeMode.dark, groupValue: _mode, title: const Text('Dark'), onChanged: (v) { if (v != null) { setState(() => _mode = v); widget.setThemeMode(v); } }),
    const Divider(height: 28),
    const Text('PRIVACY', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
    SwitchListTile(value: _private, onChanged: _loading || _busy ? null : _togglePrivate, title: const Text('Private account'), subtitle: const Text('The setting is saved to your profile. Enforcement depends on the database policies in the migration.')),
    const Divider(height: 28),
    ListTile(leading: const Icon(Icons.lock_reset_rounded), title: const Text('Reset password'), subtitle: const Text('Send a reset email to your account'), onTap: () async { final email = NexaService.user?.email; if (email == null) return; try { await NexaService.resetPassword(email); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset email requested.'))); } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(NexaService.friendlyError(e)))); } }),
    ListTile(leading: const Icon(Icons.logout_rounded), title: const Text('Log out'), onTap: () async { try { await NexaService.signOut(); } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(NexaService.friendlyError(e)))); } }),
    const SizedBox(height: 16), const Center(child: Text('NEXA · Build your world', style: TextStyle(fontWeight: FontWeight.w700))),
  ]));
}
