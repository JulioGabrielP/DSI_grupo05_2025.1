import 'package:dsi_projeto/components/colors/appColors.dart';
import 'package:dsi_projeto/widgets/flipcard.dart';
import 'package:flutter/material.dart';
import '../models/collection.dart';
import '../models/flashcard.dart';
import '../services/collection_service.dart';
import 'create_collection_screen.dart';
import 'create_flashcard_screen.dart';
import 'collection_edit_screen.dart';

class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  final CollectionService _collectionService = CollectionService();
  final Map<String, bool> _flippedCards = {};
  final TextEditingController _searchController = TextEditingController();
  List<Collection> _filteredCollections = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterCollections);
    _loadCollections();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCollections() async {
    await _collectionService.initialize();
    setState(() {
      _filteredCollections = _collectionService.getAllCollectionsSync();
    });
  }

  void _filterCollections() {
    final collections = _collectionService.getAllCollectionsSync();
    setState(() {
      if (_searchController.text.isEmpty) {
        _filteredCollections = collections;
      } else {
        _filteredCollections = collections.where((collection) {
          return collection.name
                  .toLowerCase()
                  .contains(_searchController.text.toLowerCase()) ||
              collection.flashcards.any((flashcard) =>
                  flashcard.question
                      .toLowerCase()
                      .contains(_searchController.text.toLowerCase()) ||
                  flashcard.answer
                      .toLowerCase()
                      .contains(_searchController.text.toLowerCase()));
        }).toList();
      }
    });
  }

  void _navigateToEditCollection(Collection collection) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CollectionEditPage(
          collection: collection,
          collectionService: _collectionService,
        ),
      ),
    ).then((hasChanges) {
      if (hasChanges == true) {
        setState(() {});
      }
    });
  }

  Future<void> _deleteCollection(Collection collection) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundLogin,
        title: const Text(
          'Excluir Coleção',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Tem certeza que deseja excluir a coleção "${collection.name}"?\n\nTodos os flashcards serão perdidos.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      _collectionService.removeCollection(collection.name);
      setState(() {});
      _filterCollections(); // Add this line after setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Coleção "${collection.name}" excluída'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Updated Scaffold with consistent styling
  @override
  Widget build(BuildContext context) {
    final collections = _collectionService.getAllCollectionsSync();
    if (collections.isEmpty && !_collectionService.isLoading) {
      _loadCollections();
    }

    return Scaffold(
      backgroundColor: AppColors.black, // Match home screen background
      appBar: AppBar(
        title: const Text(
          'Flashcards',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold, // Match home screen font weight
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.blue, // Match home screen app bar color
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search,
                color: Colors.white),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isSearching) _buildSearchBar(),
          Expanded(
            child: _filteredCollections.isEmpty
                ? _buildEmptyState()
                : _buildCollectionsList(_filteredCollections),
          ),
        ],
      ),
      // Add FloatingActionButton like home screen
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Show options to create flashcard or collection
          final result = await showModalBottomSheet<String>(
            context: context,
            backgroundColor: Colors.grey[100],
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (context) => Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text('Criar Flashcard'),
                    onTap: () => Navigator.pop(context, 'flashcard'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.collections_bookmark_outlined),
                    title: const Text('Criar Coleção'),
                    onTap: () => Navigator.pop(context, 'collection'),
                  ),
                ],
              ),
            ),
          );

          if (result == 'flashcard') {
            _navigateToCreateFlashcard(context);
          } else if (result == 'collection') {
            _navigateToCreateCollection(context);
          }
        },
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Botões de criação - Layout minimalista
          Row(
            children: [
              Expanded(
                child: _buildCreateButton(
                  'Criar\nFlashcard',
                  Icons.add,
                  AppColors.blue,
                  () => _navigateToCreateFlashcard(context),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCreateButton(
                  'Criar\nColeção',
                  Icons.add,
                  AppColors.blue,
                  () => _navigateToCreateCollection(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 80),
          Text(
            'Nenhuma coleção criada ainda',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Buscar coleções ou flashcards...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  // Updated collections list method to match home screen style
  Widget _buildCollectionsList(List<Collection> collections) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        itemCount: collections.length,
        itemBuilder: (context, index) {
          return _buildCollectionCard(collections[index]);
        },
      ),
    );
  }

  Widget _buildCreateButton(
      String text, IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollectionCard(Collection collection) {
    return GestureDetector(
      onTap: () => _viewCollection(collection),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Icon similar to task items
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.collections_bookmark_outlined,
                color: AppColors.blue,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    collection.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${collection.flashcards.length} flashcards',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // Action buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Study button (similar to tag in home screen)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Estudar',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // More options button
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                  onSelected: (value) {
                    switch (value) {
                      case 'delete':
                        // Find the original collection from the service
                        final originalCollection = _collectionService
                            .getAllCollectionsSync()
                            .firstWhere((c) => c.name == collection.name);
                        _deleteCollection(originalCollection);
                        break;
                      case 'edit':
                        _navigateToEditCollection(collection);
                        break;
                      case 'delete':
                        _deleteCollection(collection);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 16),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline,
                              size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Excluir', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlashcardPreview(Flashcard flashcard) {
    final cardKey = '${flashcard.question}_${flashcard.answer}';
    final isFlipped = _flippedCards[cardKey] ?? false;

    return FlipCard(
      front: flashcard.question,
      back: flashcard.answer,
      isKnown: flashcard.isKnown,
      showStatusButton: false, // Hide status button in list view
      frontColor: Colors.blue[600],
      backColor: Colors.green[600],
    );
  }

  void _navigateToCreateCollection(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateCollectionScreen(
          collectionService: _collectionService,
        ),
      ),
    ).then((_) {
      setState(() {});
    });
  }

  void _navigateToCreateFlashcard(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateFlashcardScreen(
          collectionService: _collectionService,
        ),
      ),
    ).then((_) {
      setState(() {});
    });
  }

  void _viewCollection(Collection collection) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: AppColors.backgroundLogin,
          appBar: AppBar(
            title: Text(
              collection.name,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.blue,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
          body: ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: collection.flashcards.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final flashcard = collection.flashcards[index];

              return Container(
                height: 300, // Set a fixed height for the FlipCard
                child: FlipCard(
                  front: flashcard.question,
                  back: flashcard.answer,
                  isKnown: flashcard.isKnown,
                  showStatusButton: false, // Hide status button in list view
                  frontColor: Colors.blue[600],
                  backColor: flashcard.isKnown
                      ? Colors.green[600]
                      : Colors.orange[600],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
