import 'package:flutter/material.dart';

class PortSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onSearch;
  final VoidCallback? onTap;

  const PortSearchBar({
    Key? key,
    required this.controller,
    required this.onChanged,
    this.onSearch,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F6FA),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.waves_rounded,
                    color: Color(0xFF2563EB),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: onTap,
                    child: AbsorbPointer(
                      child: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Busca un puerto",
                          hintStyle: TextStyle(
                            color: Color(0xFFB0B0B0),
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 0),
                        ),
                        style: const TextStyle(fontSize: 16),
                        onChanged: onChanged,
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withOpacity(0.18),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.search_rounded, color: Colors.white, size: 24),
                    onPressed: onTap,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}