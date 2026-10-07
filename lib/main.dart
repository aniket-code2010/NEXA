import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/nexa_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const url = String.fromEnvironment('SUPABASE_URL');

  // Support both names so Codemagic configuration works.
  const publishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  const anonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  final key = publishableKey.isNotEmpty ? publishableKey : anonKey;

  if (url.isEmpty || key.isEmpty) {
    runApp(const NexaApp(configured: false));
    return;
  }

  await Supabase.initialize(
    url: url,
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
      debugShowCheckedModeBanner: false,
      title: 'NEXA',
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
      ),
      darkTheme: ThemeData.dark(
        useMaterial3: true,
      ).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      home: configured
          ? const AuthGate()
          : const SetupPage(),
    );
  }
}

class SetupPage extends StatelessWidget {
  const SetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'NEXA is ready.\n\n'
            'Supabase configuration is missing.',
            textAlign: TextAlign.center,
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
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (_, snapshot) {
        return NexaService.user == null
            ? const WelcomePage()
            : const Shell();
      },
    );
  }
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'NEXA',
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your interests. Your people. Your internet.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AuthPage(signUp: true),
                    ),
                  );
                },
                child: const Text('Create Account'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AuthPage(signUp: false),
                    ),
                  );
                },
                child: const Text('Log In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthPage extends StatefulWidget {
  final bool signUp;

  const AuthPage({
    super.key,
    required this.signUp,
  });

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  final username = TextEditingController();
  final name = TextEditingController();

  bool busy = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    username.dispose();
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.signUp ? 'Create Account' : 'Log In',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (widget.signUp) ...[
            TextField(
              controller: name,
              decoration: const InputDecoration(
                labelText: 'Display name',
              ),
            ),
            TextField(
              controller: username,
              decoration: const InputDecoration(
                labelText: 'Username',
              ),
            ),
            const SizedBox(height: 8),
          ],
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
            ),
          ),
          TextField(
            controller: password,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: busy ? null : submit,
            child: Text(
              busy
                  ? 'Please wait…'
                  : widget.signUp
                      ? 'Create Account'
                      : 'Log In',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> submit() async {
    setState(() => busy = true);

    try {
      if (widget.signUp) {
        await NexaService.signUp(
          email: email.text.trim(),
          password: password.text,
          username: username.text.trim(),
          displayName: name.text.trim(),
        );
      } else {
        await NexaService.signIn(
          email.text.trim(),
          password.text,
        );
      }

      if (mounted) {
        Navigator.popUntil(
          context,
          (route) => route.isFirst,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'NEXA',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => createPost(context),
          icon: const Icon(
            Icons.add_circle_outline,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none,
            ),
          ),
        ],
      ),
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          setState(() => index = i);
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
            label: 'Messages',
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

  Future<void> createPost(BuildContext context) async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create Post'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'What is on your mind?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await NexaService.createPost(
                controller.text,
              );

              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (mounted) {
      setState(() {});
    }
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (_, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Could not load feed.\n\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final posts = snapshot.data ?? [];

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              future = NexaService.feed();
            });
            await future;
          },
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              const Text(
                'For You',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 45,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: const [
                    Chip(
                      label: Text('Technology'),
                    ),
                    SizedBox(width: 8),
                    Chip(
                      label: Text('Cars'),
                    ),
                    SizedBox(width: 8),
                    Chip(
                      label: Text('Music'),
                    ),
                    SizedBox(width: 8),
                    Chip(
                      label: Text('Travel'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (posts.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No posts yet. Create the first NEXA post!',
                    ),
                  ),
                ),
              ...posts.map(
                (post) => PostCard(post: post),
              ),
            ],
          ),
        );
      },
    );
  }
}

class PostCard extends StatelessWidget {
  final Map<String, dynamic> post;

  const PostCard({
    super.key,
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    final profile =
        post['profiles'] is Map
            ? post['profiles'] as Map
            : {};

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              (profile['display_name'] ??
                      profile['username'] ??
                      'NEXA')
                  .toString(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              (post['text'] ?? '').toString(),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () async {
                    await NexaService.like(
                      post['id'].toString(),
                    );
                  },
                  icon: const Icon(
                    Icons.favorite_border,
                  ),
                ),
                IconButton(
                  onPressed: () => _comment(context),
                  icon: const Icon(
                    Icons.comment_outlined,
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.repeat),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.bookmark_border,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.more_horiz,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _comment(
    BuildContext context,
  ) async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Comment'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Write a comment...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await NexaService.comment(
                post['id'].toString(),
                controller.text,
              );

              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );

    controller.dispose();
  }
}

class ReelsPage extends StatelessWidget {
  const ReelsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'NEXA Reels\nInterest + AI discovery',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
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
      children: const [
        ListTile(
          leading: CircleAvatar(
            child: Icon(Icons.person),
          ),
          title: Text('Chats'),
          subtitle: Text('1-to-1 messaging'),
        ),
        ListTile(
          leading: CircleAvatar(
            child: Icon(Icons.groups),
          ),
          title: Text('Communities'),
          subtitle: Text(
            'Interest-based spaces',
          ),
        ),
        ListTile(
          leading: CircleAvatar(
            child: Icon(
              Icons.mark_email_unread_outlined,
            ),
          ),
          title: Text('Requests'),
          subtitle: Text('Message requests'),
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
        children: const [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search NEXA or the web',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'AI Overview → Reels → Posts → People → '
            'Communities → Web',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const CircleAvatar(
          radius: 44,
          child: Icon(
            Icons.person,
            size: 44,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          NexaService.user?.email ?? 'NEXA User',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () {},
          child: const Text('Edit Profile'),
        ),
        OutlinedButton(
          onPressed: () async {
            await NexaService.signOut();
          },
          child: const Text('Log Out'),
        ),
        OutlinedButton(
          onPressed: () {},
          child: const Text('Privacy & Security'),
        ),
        OutlinedButton(
          onPressed: () {},
          child: const Text(
            'Feed & AI Personalization',
          ),
        ),
      ],
    );
  }
}
    body: ListView(padding: const EdgeInsets.all(20), children: [
      if (widget.signUp) ...[
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Display name')),
        TextField(controller: username, decoration: const InputDecoration(labelText: 'Username')),
      ],
      TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
      TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
      const SizedBox(height: 20),
      FilledButton(onPressed: busy ? null : submit, child: Text(busy ? 'Please wait…' : widget.signUp ? 'Create Account' : 'Log In')),
    ]),
  );
  Future<void> submit() async {
    setState(() => busy = true);
    try {
      if (widget.signUp) {
        await NexaService.signUp(email: email.text.trim(), password: password.text, username: username.text.trim(), displayName: name.text.trim());
      } else {
        await NexaService.signIn(email.text.trim(), password.text);
      }
      if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally { if (mounted) setState(() => busy = false); }
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override State<Shell> createState() => _ShellState();
}
class _ShellState extends State<Shell> {
  int index = 0;
  final pages = const [HomePage(), ReelsPage(), MessagesPage(), SearchPage(), ProfilePage()];
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('NEXA', style: TextStyle(fontWeight: FontWeight.w900)),
      centerTitle: true,
      leading: IconButton(onPressed: () => createPost(context), icon: const Icon(Icons.add_circle_outline)),
      actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none))],
    ),
    body: pages[index],
    bottomNavigationBar: NavigationBar(
      selectedIndex: index, onDestinationSelected: (i) => setState(() => index = i),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.play_circle_outline), selectedIcon: Icon(Icons.play_circle), label: 'Reels'),
        NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Messages'),
        NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
      ],
    ),
  );
  Future<void> createPost(BuildContext context) async {
    final c = TextEditingController();
    await showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Create Post'),
      content: TextField(controller: c, maxLines: 5, decoration: const InputDecoration(hintText: 'What is on your mind?')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () async { await NexaService.createPost(c.text); if (context.mounted) Navigator.pop(context); }, child: const Text('Post')),
      ],
    ));
    if (mounted) setState(() {});
  }
}

class HomePage extends StatefulWidget { const HomePage({super.key}); @override State<HomePage> createState() => _HomePageState(); }
class _HomePageState extends State<HomePage> {
  late Future<List<Map<String,dynamic>>> future;
  @override void initState(){super.initState(); future=NexaService.feed();}
  @override Widget build(BuildContext context)=>FutureBuilder(
    future: future, builder: (_, s) {
      if(!s.hasData) return const Center(child:CircularProgressIndicator());
      final posts=s.data!;
      return RefreshIndicator(onRefresh:() async=>setState(()=>future=NexaService.feed()), child:ListView(
        padding:const EdgeInsets.all(12), children:[
          const Text('For You',style:TextStyle(fontSize:24,fontWeight:FontWeight.bold)),
          const SizedBox(height:12),
          SizedBox(height:45,child:ListView(scrollDirection:Axis.horizontal,children:const[
            Chip(label:Text('Technology')),SizedBox(width:8),Chip(label:Text('Cars')),SizedBox(width:8),Chip(label:Text('Music')),SizedBox(width:8),Chip(label:Text('Travel')),
          ])),
          const SizedBox(height:12),
          if(posts.isEmpty) const Card(child:Padding(padding:EdgeInsets.all(20),child:Text('No posts yet. Create the first NEXA post!'))),
          ...posts.map((p)=>PostCard(post:p)),
        ],
      ));
    });
}
class PostCard extends StatelessWidget {
  final Map<String,dynamic> post; const PostCard({super.key,required this.post});
  @override Widget build(BuildContext context){
    final profile=post['profiles'] is Map ? post['profiles'] as Map : {};
    return Card(margin:const EdgeInsets.only(bottom:12),child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text((profile['display_name']??profile['username']??'NEXA').toString(),style:const TextStyle(fontWeight:FontWeight.bold)),
      const SizedBox(height:8),Text((post['text']??'').toString()),
      Row(children:[
        IconButton(onPressed:()=>NexaService.like(post['id'].toString()),icon:const Icon(Icons.favorite_border)),
        IconButton(onPressed:()=>_comment(context),icon:const Icon(Icons.comment_outlined)),
        IconButton(onPressed:(){},icon:const Icon(Icons.repeat)),
        IconButton(onPressed:(){},icon:const Icon(Icons.bookmark_border)),
        const Spacer(),IconButton(onPressed:(){},icon:const Icon(Icons.more_horiz)),
      ])
    ])));
  }
  Future<void> _comment(BuildContext context) async {
    final c=TextEditingController();
    await showDialog(context:context,builder:(_)=>AlertDialog(title:const Text('Comment'),content:TextField(controller:c),actions:[
      TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Cancel')),
      FilledButton(onPressed:()async{await NexaService.comment(post['id'].toString(),c.text);if(context.mounted)Navigator.pop(context);},child:const Text('Send'))
    ]));
  }
}
class ReelsPage extends StatelessWidget{const ReelsPage({super.key});@override Widget build(BuildContext c)=>const Center(child:Text('NEXA Reels\\nInterest + AI discovery',textAlign:TextAlign.center,style:TextStyle(fontSize:24,fontWeight:FontWeight.bold)));}
class MessagesPage extends StatelessWidget{const MessagesPage({super.key});@override Widget build(BuildContext c)=>ListView(children:const[
  ListTile(leading:CircleAvatar(child:Icon(Icons.person)),title:Text('Chats'),subtitle:Text('1-to-1 messaging')),
  ListTile(leading:CircleAvatar(child:Icon(Icons.groups)),title:Text('Communities'),subtitle:Text('Interest-based spaces')),
  ListTile(leading:CircleAvatar(child:Icon(Icons.mark_email_unread_outlined)),title:Text('Requests'),subtitle:Text('Message requests')),
]);}
class SearchPage extends StatelessWidget{const SearchPage({super.key});@override Widget build(BuildContext c)=>Padding(padding:const EdgeInsets.all(16),child:Column(children:[
  const TextField(decoration:InputDecoration(hintText:'Search NEXA or the web',prefixIcon:Icon(Icons.search),border:OutlineInputBorder())),
  const SizedBox(height:20),const Text('AI Overview → Reels → Posts → People → Communities → Web',textAlign:TextAlign.center)
]));}
class ProfilePage extends StatelessWidget{const ProfilePage({super.key});@override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(16),children:[
  const CircleAvatar(radius:44,child:Icon(Icons.person,size:44)),const SizedBox(height:12),
  Text(NexaService.user?.email??'NEXA User',textAlign:TextAlign.center,style:const TextStyle(fontWeight:FontWeight.bold)),
  const SizedBox(height:20),
  FilledButton(onPressed:(){},child:const Text('Edit Profile')),
  OutlinedButton(onPressed:()=>NexaService.signOut(),child:const Text('Log Out')),
  OutlinedButton(onPressed:(){},child:const Text('Privacy & Security')),
  OutlinedButton(onPressed:(){},child:const Text('Feed & AI Personalization')),
]);}
