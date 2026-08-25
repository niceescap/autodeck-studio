import "dart:io";

import "package:flutter/material.dart";

import "../../models/deck_models.dart";

/// Tuile d'un slot de référence : vignette image OU invite "ajouter".
class RefSlotTile extends StatelessWidget {
  const RefSlotTile({
    super.key,
    required this.slot,
    required this.onTap,
    this.enabled = true,
  });

  final RefSlot slot;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final hasImage = slot.hasLocal;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage)
              Image.file(File(slot.localPath!), fit: BoxFit.cover)
            else
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      slot.symbol ?? "＋",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 54,
                        color: Colors.white24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      slot.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      slot.hint,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
            Positioned(
              top: 6,
              right: 6,
              child: hasImage
                  ? const Icon(Icons.check_circle, color: Color(0xFF66BB6A))
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "standard",
                        style: TextStyle(fontSize: 10, color: Colors.white60),
                      ),
                    ),
            ),
            if (!enabled) const ModalBarrier(dismissible: false),
          ],
        ),
      ),
    );
  }
}
