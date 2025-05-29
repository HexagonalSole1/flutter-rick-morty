import 'package:flutter/material.dart';
import '../client/dtos/CharacterRequest.dart';
import '../client/services/RickAndMortyService.dart';
import 'CharacterDetailScreen.dart';

class CharacterListScreen extends StatefulWidget {
  const CharacterListScreen({super.key});

  @override
  State<CharacterListScreen> createState() => _CharacterListScreenState();
}

class _CharacterListScreenState extends State<CharacterListScreen> {
  List<Character> characters = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  String? error;
  int currentPage = 1;
  bool hasMorePages = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadCharacters();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent &&
        !isLoadingMore &&
        hasMorePages) {
      _loadMoreCharacters();
    }
  }

  Future<void> _loadCharacters() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final response = await RickAndMortyService.getCharacters(page: 1);
      final charactersList = (response['results'] as List)
          .map((json) => Character.fromJson(json))
          .toList();

      setState(() {
        characters = charactersList;
        currentPage = 1;
        hasMorePages = response['info']['next'] != null;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _loadMoreCharacters() async {
    if (!hasMorePages || isLoadingMore) return;

    try {
      setState(() {
        isLoadingMore = true;
      });

      final response = await RickAndMortyService.getCharacters(page: currentPage + 1);
      final newCharacters = (response['results'] as List)
          .map((json) => Character.fromJson(json))
          .toList();

      setState(() {
        characters.addAll(newCharacters);
        currentPage++;
        hasMorePages = response['info']['next'] != null;
        isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        isLoadingMore = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar más personajes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rick and Morty'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCharacters,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando personajes...'),
          ],
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error: $error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCharacters,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (characters.isEmpty) {
      return const Center(
        child: Text('No se encontraron personajes'),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: characters.length + (isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= characters.length) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final character = characters[index];
              return _buildCharacterCard(character);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCharacterCard(Character character) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Hero(
          tag: 'character-${character.id}',
          child: CircleAvatar(
            radius: 30,
            backgroundImage: NetworkImage(character.image),
            backgroundColor: Colors.grey[300],
          ),
        ),
        title: Text(
          character.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _getStatusColor(character.status),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text('${character.status} - ${character.species}'),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Ubicación: ${character.location}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CharacterDetailScreen(character: character),
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'alive':
        return Colors.green;
      case 'dead':
        return Colors.red;
      case 'unknown':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}