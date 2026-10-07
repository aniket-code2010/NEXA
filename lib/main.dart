import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/nexa_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const publishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  final key = publishableKey.isNotEmpty ? publishableKey : anonKey;

  if (supabaseUrl.isEmpty || key.isEmpty) {
    runApp(const NexaApp(configured: false));
    return;
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: key,
  );

  runApp(const NexaApp(configured: true));
}

class NexaApp extends StatelessWidget {
  final bool configured;

  const NexaApp({
    super.key,
    required this.configured,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NEXA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: configured ? const AuthGate() : const SetupPage(),
    );
  }
}

class SetupPage extends StatelessWidget {
  const SetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.hub_rounded,
                size: 72,
              ),
              SizedBox(height: 20),
              Text(
                'NEXA',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Supabase configuration is missing.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final user = NexaService.user;

    if (user == null) {
      return const WelcomePage();
    }

    return const Shell();
  }
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.hub_rounded,
                size: 90,
              ),
              const SizedBox(height: 24),
              const Text(
                'NEXA',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'One place. Everything social.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AuthPage(),
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(14),
                    child: Text('Get Started'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final usernameController = TextEditingController();
  final displayNameController = TextEditingController();

  bool isLogin = true;
  bool loading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    usernameController.dispose();
    displayNameController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showMessage('Email and password are required.');
      return;
    }

    if (!isLogin &&
        (usernameController.text.trim().isEmpty ||
            displayNameController.text.trim().isEmpty)) {
      showMessage('Username and display name are required.');
      return;
    }

    setState(() => loading = true);

    try {
      if (isLogin) {
        await NexaService.signIn(email, password);
      } else {
        await NexaService.signUp(
          email: email,
          password: password,
          username: usernameController.text.trim(),
          displayName: displayNameController.text.trim(),
        );
      }

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const Shell(),
        ),
        (_) => false,
      );
    } catch (e) {
      showMessage('Something went wrong: $e');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isLogin ? 'Login' : 'Create account'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (!isLogin) ...[
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Display name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
            ],
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: loading ? null : submit,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Text(isLogin ? 'Login' : 'Sign Up'),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: loading
                  ? null
                  : () {
                      setState(() => isLogin = !isLogin);
                    },
              child: Text(
                isLogin
                    ? 'Create a new account'
                    : 'Already have an account? Login',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int index = 0;

  final pages = const [
    HomePage(),
    ReelsPage(),
    MessagesPage(),
    SearchPage(),
    ProfilePage(),
  ];

  final titles = const [
    'NEXA',
    'Reels',
    'Messages',
    'Search',
    'Profile',
  ];

  Future<void> createPost() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Create post'),
          content: TextField(
            controller: controller,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'What are you thinking?',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                await NexaService.createPost(controller.text);
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                if (mounted) {
                  setState(() {});
                }
              },
              child: const Text('Post'),
            ),
          ],
        );
      },
    );

    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[index]),
        actions: [
          IconButton(
            onPressed: createPost,
            icon: const Icon(Icons.add_box_outlined),
            tooltip: 'Create',
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) {
          setState(() => index = value);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.play_circle_outline),
            selectedIcon: Icon(Icons.play_circle),
            label: 'Reels',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Msg',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    future = NexaService.feed();
  }

  Future<void> refresh() async {
    setState(() {
      future = NexaService.feed();
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: refresh,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return ListView(
              children: [
                const SizedBox(height: 120),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Could not load feed.\n\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            );
          }

          final posts = snapshot.data ?? [];

          if (posts.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 120),
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No posts yet.\nCreate the first post on NEXA!',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 20),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              return PostCard(post: posts[index]);
            },
          );
        },
      ),
    );
  }
}

class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;

  const PostCard({
    super.key,
    required this.post,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool liking = false;
  bool commenting = false;

  Future<void> likePost() async {
    if (liking) return;

    setState(() => liking = true);

    try {
      await NexaService.like(
        widget.post['id'].toString(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Like failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => liking = false);
      }
    }
  }

  Future<void> addComment() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Comment'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Write a comment...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: commenting
                  ? null
                  : () async {
                      setState(() => commenting = true);

                      try {
                        await NexaService.comment(
                          widget.post['id'].toString(),
                          controller.text,
                        );

                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Comment failed: $e'),
                            ),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() => commenting = false);
                        }
                      }
                    },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );

    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.post['profiles'];
    String username = 'NEXA user';
    String displayName = 'NEXA user';

    if (profile is Map<String, dynamic>) {
      username = profile['username']?.toString() ?? 'NEXA user';
      displayName =
          profile['display_name']?.toString() ?? username;
    }

    final text = widget.post['text']?.toString() ?? '';
    final createdAt = widget.post['created_at']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '@$username',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (_) {},
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'not_interested',
                      child: Text('Not interested'),
                    ),
                    PopupMenuItem(
                      value: 'report',
                      child: Text('Report'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (text.isNotEmpty)
              Text(
                text,
                style: const TextStyle(fontSize: 16),
              ),
            if (createdAt.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                createdAt,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: liking ? null : likePost,
                  icon: const Icon(
                    Icons.favorite_border,
                  ),
                ),
                IconButton(
                  onPressed: addComment,
                  icon: const Icon(
                    Icons.comment_outlined,
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.repeat,
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.share_outlined,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ReelsPage extends StatelessWidget {
  const ReelsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.play_circle_outline,
              size: 70,
            ),
            SizedBox(height: 16),
            Text(
              'NEXA Reels',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Short-video system will be added next.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const CircleAvatar(
            child: Icon(Icons.person),
          ),
          title: const Text('NEXA Messages'),
          subtitle: const Text(
            'Chat system will be added next.',
          ),
          trailing: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert),
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.visibility_off_outlined),
          title: const Text('Hidden chats'),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.groups_outlined),
          title: const Text('Communities'),
          onTap: () {},
        ),
      ],
    );
  }
}

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search NEXA',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Icon(
            Icons.travel_explore,
            size: 64,
          ),
          const SizedBox(height: 12),
          const Text(
            'Search everything on NEXA',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> signOut(BuildContext context) async {
    try {
      await NexaService.signOut();

      if (!context.mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const WelcomePage(),
        ),
        (_) => false,
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign out failed: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = NexaService.user;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const CircleAvatar(
          radius: 48,
          child: Icon(
            Icons.person,
            size: 48,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            user?.email ?? 'NEXA User',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit profile'),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Password & Security'),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Settings'),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Log out'),
                onTap: () => signOut(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
