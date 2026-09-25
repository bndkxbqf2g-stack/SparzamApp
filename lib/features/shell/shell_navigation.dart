import 'package:flutter/material.dart';

const shellDestinations = <NavigationDestination>[
  NavigationDestination(
    icon: Icon(Icons.home_outlined),
    selectedIcon: Icon(Icons.home),
    label: 'Start',
  ),
  NavigationDestination(
    icon: Icon(Icons.shopping_cart_outlined),
    selectedIcon: Icon(Icons.shopping_cart),
    label: 'Liste',
  ),
  NavigationDestination(
    icon: Icon(Icons.local_offer_outlined),
    selectedIcon: Icon(Icons.local_offer),
    label: 'Angebote',
  ),
  NavigationDestination(
    icon: Icon(Icons.menu_book_outlined),
    selectedIcon: Icon(Icons.menu_book),
    label: 'Prospekte',
  ),
  NavigationDestination(
    icon: Icon(Icons.sell_outlined),
    selectedIcon: Icon(Icons.sell),
    label: 'Preise',
  ),
  NavigationDestination(
    icon: Icon(Icons.more_horiz),
    selectedIcon: Icon(Icons.more),
    label: 'Mehr',
  ),
];
