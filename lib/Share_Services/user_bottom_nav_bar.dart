import 'package:flutter/material.dart';
import 'package:fyp_recipe/Recommendation/user_home_page.dart';
import 'package:fyp_recipe/Meal_Plan/user_mealplan_page.dart';
import 'package:fyp_recipe/Favourite/user_favourite_page.dart';
import 'package:fyp_recipe/User_Profile/user_profile_page.dart';
import 'package:fyp_recipe/Search/user_search_page.dart';

class UserBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const UserBottomNavBar({super.key, required this.currentIndex});

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return; // Avoid reloading the same page.
    Widget page;
    switch (index) {
      case 0:
        page = const UserHomePage();
        break;
      case 1:
        page = const UserSearchPage();
        break;
      case 2:
        page = const UserFavouritePage();
        break;
      case 3:
        page = const UserMealplanPage();
        break;
      case 4:
        page = const UserProfilePage();
        break;
      default:
        page = const UserHomePage();
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _onItemTapped(context, index),
      backgroundColor: Colors.black,
      selectedItemColor: Colors.indigo,
      unselectedItemColor: Colors.black,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),  // Bold text for selected label
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.bold), // Bold text for unselected label
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite),
          label: 'Favourites',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Meal Plan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
