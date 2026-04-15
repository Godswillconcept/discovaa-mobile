import 'package:flutter/material.dart';

class SystemUpdateWidget extends StatefulWidget {
  const SystemUpdateWidget({super.key});

  @override
  State<SystemUpdateWidget> createState() => _SystemUpdateWidgetState();
}

class _SystemUpdateWidgetState extends State<SystemUpdateWidget> {
  bool _automaticUpdates = false;
  bool _installOnceDownloaded = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSwitchTile(
          'Automatic Updates',
          _automaticUpdates,
          (value) => setState(() => _automaticUpdates = value),
        ),
        const SizedBox(height: 16),
        Text(
          'This update provides bug fixes for your system including:',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        const SizedBox(height: 16),
        ...List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: Text(
                    'This update provides bug fixes for your system including',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Download in progress',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.downloading, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.7,
              child: Text(
                'System has has started downloading an update automatically. Once completed, system will attempt to install the update later.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSwitchTile(
          'Install once downloaded',
          _installOnceDownloaded,
          (value) => setState(() => _installOnceDownloaded = value),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.black,
        ),
      ],
    );
  }
}
