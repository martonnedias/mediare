import 'package:flutter/material.dart';

class MediareDialog {
  static void showWide({
    required BuildContext context,
    required String title,
    required Widget content,
    List<Widget>? actions,
    bool isDesktop = true,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        titlePadding: const EdgeInsets.all(0),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title, 
                style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 20, fontWeight: FontWeight.bold)
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.grey),
              ),
            ],
          ),
        ),
        content: SizedBox(
          width: isDesktop ? 850 : MediaQuery.of(context).size.width,
          child: Padding(
             padding: const EdgeInsets.only(top: 16.0),
             child: content,
          ),
        ),
        actions: actions ?? [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey))
          ),
          SoftButton(
            text: 'Salvar',
            onPressed: () => Navigator.pop(context),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
      ),
    );
  }
}

class MediareCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const MediareCard({Key? key, required this.child, this.padding}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24), // Squircle
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02), // Soft airy shadow
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: child,
    );
  }
}

class SoftButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isDestructive;
  final IconData? icon;

  const SoftButton({
    super.key, 
    required this.text, 
    required this.onPressed, 
    this.isDestructive = false,
    this.icon
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDestructive ? const Color(0xFFFEE2E2) : Theme.of(context).primaryColor,
        foregroundColor: isDestructive ? const Color(0xFFEF4444) : Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Inner squircle
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
             Icon(icon, size: 20),
             const SizedBox(width: 8),
          ],
          Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}

class SoftInput extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const SoftInput({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.validator
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
           borderRadius: BorderRadius.circular(16),
           borderSide: BorderSide(color: Colors.grey.shade200)
        ),
        enabledBorder: OutlineInputBorder(
           borderRadius: BorderRadius.circular(16),
           borderSide: BorderSide(color: Colors.grey.shade200)
        ),
      ),
    );
  }
}
