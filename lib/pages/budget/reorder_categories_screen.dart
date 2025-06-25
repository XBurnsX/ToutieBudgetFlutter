import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Définition de la classe Categorie (simplifiée pour cet écran,
// ou importez-la si elle est définie ailleurs et accessible)
class CategorieForReorder {
  final String id;
  final String nom;
  int ordre; // Important: l'ordre doit être mutable ici

  CategorieForReorder(
      {required this.id, required this.nom, required this.ordre});

  factory CategorieForReorder.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    Map<String, dynamic> data = doc.data()!;
    return CategorieForReorder(
      id: doc.id,
      nom: data['nom'] ?? 'Nom inconnu',
      ordre: data['ordre'] as int? ?? 0,
    );
  }
}

class ReorderCategoriesScreen extends StatefulWidget {
  final String userId;

  const ReorderCategoriesScreen({super.key, required this.userId});

  @override
  _ReorderCategoriesScreenState createState() =>
      _ReorderCategoriesScreenState();
}

class _ReorderCategoriesScreenState extends State<ReorderCategoriesScreen> {
  List<CategorieForReorder> _categories = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    try {
      QuerySnapshot<
          Map<String, dynamic>> categoriesSnapshot = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(widget.userId)
          .collection('categories')
          .orderBy('ordre') // Important de récupérer dans l'ordre actuel
          .get();

      if (mounted) {
        setState(() {
          _categories = categoriesSnapshot.docs
              .map((doc) => CategorieForReorder.fromFirestore(doc))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print(
          "Erreur lors de la récupération des catégories pour réorganisation: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement des catégories: $e')),
        );
      }
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (mounted) {
      setState(() {
        if (newIndex > oldIndex) {
          newIndex -= 1; // Ajustement nécessaire si on déplace vers le bas
        }
        final CategorieForReorder item = _categories.removeAt(oldIndex);
        _categories.insert(newIndex, item);

        // Mettre à jour les champs 'ordre' en mémoire
        for (int i = 0; i < _categories.length; i++) {
          _categories[i].ordre = i;
        }
      });
    }
  }

  Future<void> _saveOrder() async {
    if (_isSaving) return;

    if (mounted) {
      setState(() {
        _isSaving = true;
      });
    }

    WriteBatch batch = FirebaseFirestore.instance.batch();
    CollectionReference categoriesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('categories');

    for (int i = 0; i < _categories.length; i++) {
      DocumentReference docRef = categoriesRef.doc(_categories[i].id);
      batch.update(
          docRef, {'ordre': i}); // Sauvegarder le nouvel index comme 'ordre'
    }

    try {
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ordre des catégories sauvegardé !')),
        );
        Navigator.of(context).pop(); // Revenir à l'écran précédent
      }
    } catch (e) {
      print("Erreur lors de la sauvegarde de l'ordre: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sauvegarde: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Réorganiser les Catégories'),
        actions: [
          if (!_isLoading && _categories.isNotEmpty)
            TextButton(
              onPressed: _isSaving ? null : _saveOrder,
              child: _isSaving
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
                  : const Text(
                  'SAUVEGARDER', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
          ? const Center(
        child: Text(
          'Aucune catégorie à réorganiser.',
          style: TextStyle(fontSize: 18),
        ),
      )
          : ReorderableListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final categorie = _categories[index];
          return Card(
            key: ValueKey(categorie.id), // Clé unique pour chaque élément
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: ListTile(
              leading: const Icon(Icons.drag_handle),
              title: Text(categorie.nom),
              // Vous pourriez ajouter un trailing si nécessaire,
              // par exemple, le nombre d'enveloppes ou un autre indicateur.
            ),
          );
        },
        onReorder: _onReorder,
      ),
    );
  }
}