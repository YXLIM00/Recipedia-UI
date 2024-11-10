import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RecipeCard extends StatelessWidget {
  final QueryDocumentSnapshot recipe;

  const RecipeCard({required this.recipe, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final recipeName = recipe['name'];
    final recipeImageUrl = recipe['image'];

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recipe Image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              recipeImageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(Icons.error),
            ),
          ),
          SizedBox(width: 10), // Space between image and text

          // Expanded Recipe Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipeName,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis, // Limit text overflow
                ),
              ],
            ),
          ),

          // Edit and Delete Buttons in a Column
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.edit, color: Colors.greenAccent[400]),
                onPressed: () {
                  _editRecipe(context, recipe); // Edit function
                },
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () {
                  _deleteRecipe(recipe.id); // Delete function
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _deleteRecipe(String recipeId) async {
    await FirebaseFirestore.instance.collection('recipes').doc(recipeId).delete();
  }

  void _editRecipe(BuildContext context, QueryDocumentSnapshot recipe) {
    // Navigate to edit page
  }
}
