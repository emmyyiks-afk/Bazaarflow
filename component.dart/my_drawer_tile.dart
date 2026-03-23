import 'package:flutter/material.dart';

class MyDrawerTile extends StatelessWidget {
  final String text;
  final IconData? icon;
  final void Function()? onTap;

  const MyDrawerTile({
    super.key,
    required this.text,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        text,
        style: TextStyle(color: const Color.fromARGB(255, 7, 97, 171)),
      ),
      leading: Icon(icon, color: Color.fromARGB(255, 7, 97, 171)),
      onTap: onTap,
    );
  }
}





