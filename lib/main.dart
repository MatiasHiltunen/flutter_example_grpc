import 'dart:async';

import 'package:flutter/material.dart';
import 'package:grpc/grpc.dart';

// Import the generated gRPC files.
import 'generated/movie_match.pb.dart';
import 'generated/movie_match.pbgrpc.dart';

void main() {
  runApp(MyApp());
}

/// The root widget of the app.
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Movie Match',
      home: LoginScreen(),
    );
  }
}

/// A simple login/register screen.
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers for username and password fields.
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Create a gRPC channel. Replace the host with your server's address.
  final channel = ClientChannel(
    'localhost', // Use your server address; 10.0.2.2 works for Android emulator.
    port: 50051,
    options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
  );

  late MovieMatchServiceClient client;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    client = MovieMatchServiceClient(channel);
  }

  @override
  void dispose() {
    channel.shutdown();
    super.dispose();
  }

  /// Call the gRPC login method.
  Future<void> _login() async {
    try {
      final loginResponse = await client.login(
        LoginRequest()
          ..username = _usernameController.text
          ..password = _passwordController.text,
      );
      if (loginResponse.success) {
        // Navigate to the HomeScreen on successful login.
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              userId: loginResponse.userId,
              client: client,
            ),
          ),
        );
      } else {
        setState(() {
          _statusMessage = loginResponse.message;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error during login: $e';
      });
    }
  }

  /// Call the gRPC register method.
  Future<void> _register() async {
    try {
      final registerResponse = await client.register(
        RegisterRequest()
          ..username = _usernameController.text
          ..password = _passwordController.text,
      );
      setState(() {
        _statusMessage = registerResponse.message;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error during registration: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Movie Match - Login/Register'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _login,
              child: Text('Login'),
            ),
            ElevatedButton(
              onPressed: _register,
              child: Text('Register'),
            ),
            const SizedBox(height: 16),
            Text(_statusMessage),
          ],
        ),
      ),
    );
  }
}

/// The HomeScreen where the user can connect with a friend, choose a movie,
/// and receive match notifications.
class HomeScreen extends StatefulWidget {
  final String userId;
  final MovieMatchServiceClient client;

  HomeScreen({required this.userId, required this.client});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _friendIdController = TextEditingController();
  final TextEditingController _movieIdController = TextEditingController();
  String _statusMessage = '';
  String _matchNotification = '';

  late Stream<MatchNotification> _matchStream;
  late StreamSubscription<MatchNotification> _subscription;

  @override
  void initState() {
    super.initState();
    // Subscribe to match notifications from the server.
    _matchStream = widget.client.subscribeMatches(
      SubscribeRequest()..userId = widget.userId,
    );
    _subscription = _matchStream.listen((notification) {
      setState(() {
        _matchNotification =
            '${notification.message} for movie: ${notification.movieTitle}';
      });
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  /// Connect with a friend using their userId.
  Future<void> _connectFriend() async {
    try {
      final response = await widget.client.connectFriend(
        FriendConnectRequest()
          ..userId = widget.userId
          ..friendId = _friendIdController.text,
      );
      setState(() {
        _statusMessage = response.message;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error connecting friend: $e';
      });
    }
  }

  /// Choose a movie by calling the corresponding gRPC method.
  Future<void> _chooseMovie() async {
    try {
      final response = await widget.client.chooseMovie(
        MovieRequest()
          ..userId = widget.userId
          ..movieId = _movieIdController.text,
      );
      setState(() {
        _statusMessage = response.message;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error choosing movie: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Movie Match - Home'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text("Welcome, user ${widget.userId}"),
              const SizedBox(height: 16),
              TextField(
                controller: _friendIdController,
                decoration: InputDecoration(labelText: 'Friend UserId'),
              ),
              ElevatedButton(
                onPressed: _connectFriend,
                child: Text('Connect Friend'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _movieIdController,
                decoration: InputDecoration(labelText: 'Movie ID'),
              ),
              ElevatedButton(
                onPressed: _chooseMovie,
                child: Text('Choose Movie'),
              ),
              const SizedBox(height: 16),
              Text(_statusMessage),
              const SizedBox(height: 16),
              if (_matchNotification.isNotEmpty)
                Card(
                  color: Colors.lightBlueAccent,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      _matchNotification,
                      style: TextStyle(fontSize: 16, color: Colors.white),
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
