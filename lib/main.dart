import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'dart:convert';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anime Search',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AnimeHomeScreen(),
    );
  }
}

class AnimeHomeScreen extends StatefulWidget {
  const AnimeHomeScreen({super.key});

  @override
  _AnimeHomeScreenState createState() => _AnimeHomeScreenState();
}

class _AnimeHomeScreenState extends State<AnimeHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _animeList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchAnime();
  }

  // Fetch the default anime list (top airing)
  Future<void> _fetchAnime() async {
    setState(() {
      _isLoading = true;
    });

    const url = 'https://animebasket-api.vercel.app/anime/gogoanime/top-airing';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _animeList = data['results'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      // Handle error here
    }
  }

  // Perform a search when the user enters a query
  Future<void> _searchAnime(String query) async {
    if (query.isEmpty) {
      _fetchAnime(); // If query is empty, fetch the default anime list
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final url = 'https://animebasket-api.vercel.app/anime/gogoanime/$query';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _animeList = data['results'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      // Handle error here
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anime Basket'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search for Anime',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    _searchAnime(_searchController.text);
                  },
                ),
              ),
              onSubmitted: _searchAnime,
            ),
          ),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Expanded(
                  child: _animeList.isEmpty // Check if no results found
                      ? const Center(child: Text('No results found'))
                      : ListView.builder(
                          itemCount: _animeList.length,
                          itemBuilder: (context, index) {
                            final anime = _animeList[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 15),
                              child: ListTile(
                                leading: Image.network(
                                  anime['image'],
                                  width: 50,
                                  height: 75,
                                  fit: BoxFit.cover,
                                ),
                                title: Text(anime['title']),
                                subtitle: _searchController.text.isEmpty
                                    ? Text(anime['genres'].join(', '))
                                    : null, // Hide genres while searching
                                onTap: () {
                                  // Navigate to the anime detail screen
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AnimeDetailScreen(
                                          animeId: anime['id']),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
        ],
      ),
    );
  }
}

class AnimeDetailScreen extends StatefulWidget {
  final String animeId;

  const AnimeDetailScreen({super.key, required this.animeId});

  @override
  _AnimeDetailScreenState createState() => _AnimeDetailScreenState();
}

class _AnimeDetailScreenState extends State<AnimeDetailScreen> {
  late Map<String, dynamic> _animeDetails;
  late List<dynamic> _episodes; // To hold the episode list
  bool _isLoading = true;
  bool _isExpanded = false; // To manage the expansion of the episode list

  @override
  void initState() {
    super.initState();
    _fetchAnimeDetails(widget.animeId);
  }

  Future<void> _fetchAnimeDetails(String animeId) async {
    final url =
        'https://animebasket-api.vercel.app/anime/gogoanime/info/$animeId';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _animeDetails = data;
        _episodes = data['episodes']; // Extract episodes from the response
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        // Handle error here
      });
    }
  }

  // Navigate to AnimeWatchScreen with episode data
  void _navigateToWatchScreen(String episodeId) async {
    final url =
        'https://animebasket-api.vercel.app/anime/gogoanime/watch/$episodeId';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final episodeData = json.decode(response.body);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AnimeWatchScreen(
            videoUrl: episodeData['sources'][0]['url'],
          ),
        ),
      );
    } else {
      // Handle error or show a message if fetching fails
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoading ? 'Loading...' : _animeDetails['title']),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image and title
                    Image.network(
                      _animeDetails['image'],
                      width:
                          double.infinity, // Set width to max available space
                      fit: BoxFit
                          .fitWidth, // Adjust height to maintain aspect ratio
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _animeDetails['title'],
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _animeDetails['description'],
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    // Display genres in boxes
                    const Text(
                      'Genres:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: _animeDetails['genres'].map<Widget>((genre) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 0, 170, 255),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            genre,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Other details
                    Text(
                      'Total Episodes: ${_animeDetails['totalEpisodes']}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Release Date: ${_animeDetails['releaseDate']}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sub or Dub: ${_animeDetails['subOrDub']}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Status: ${_animeDetails['status']}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Type: ${_animeDetails['type']}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Other Names: ${_animeDetails['otherName']}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),

                    // Expandable episodes list
                    ExpansionTile(
                      title: const Text(
                        'Episodes',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      initiallyExpanded: _isExpanded,
                      onExpansionChanged: (bool expanding) {
                        setState(() {
                          _isExpanded = expanding;
                        });
                      },
                      children: _episodes.map<Widget>((episode) {
                        return ListTile(
                          title: Text('Episode ${episode['number']}'),
                          onTap: () => _navigateToWatchScreen(episode['id']),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class AnimeWatchScreen extends StatefulWidget {
  final String videoUrl; // Pass the .m3u8 URL

  const AnimeWatchScreen({super.key, required this.videoUrl});

  @override
  _AnimeWatchScreenState createState() => _AnimeWatchScreenState();
}

class _AnimeWatchScreenState extends State<AnimeWatchScreen> {
  late VideoPlayerController _controller;
  late ChewieController _chewieController;
  final bool _isPlaying = false;

  @override
  void initState() {
    super.initState();

    // Lock screen orientation to landscape
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);

    // Initialize the video player controller with the provided .m3u8 URL
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {}); // Update UI when video is ready to play
      });

    // Initialize Chewie controller with custom settings
    _chewieController = ChewieController(
      videoPlayerController: _controller,
      autoPlay: true,
      looping: true,
      showControlsOnInitialize: true,
      customControls:
          const MaterialControls(), // Default controls (play/pause, seek bar, etc.)
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose(); // Dispose controller when the screen is destroyed

    // Reset the preferred orientations to portrait when leaving the screen
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

    _controller.dispose(); // Dispose the video player controller
    _chewieController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Set the background to black
      body: Center(
        child: _controller.value.isInitialized
            ? Chewie(
                controller:
                    _chewieController, // Use Chewie controller for video playback with controls
              )
            : const Center(
                child:
                    CircularProgressIndicator()), // Show loading spinner while video loads
      ),
    );
  }
}
