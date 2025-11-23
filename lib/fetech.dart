// fetch.dart
import 'package:flutter/material.dart';

// Use firebase_dart only — DO NOT import package:firebase_database/firebase_database.dart
import 'package:firebase_dart/firebase_dart.dart';
import 'package:firebase_dart/database.dart';
import 'package:url_launcher/url_launcher.dart';

class fetch extends StatefulWidget {
  const fetch({super.key});

  @override
  State<fetch> createState() => _fetchState();
}

class _fetchState extends State<fetch> {
  late FirebaseDatabase database;
  late DatabaseReference dbRef;

  @override
  void initState() {
    super.initState();
    final app = Firebase.app(); // must be initialized in main()
    database = FirebaseDatabase(app: app);
    dbRef = database.reference().child('ARM_branch_data_saved').child('Matara');
  }

  Map<String, dynamic> _normalize(dynamic raw) {
    if (raw == null) return {};
    if (raw is Map) {
      final out = <String, dynamic>{};
      raw.forEach((k, v) => out[k.toString()] = v);
      return out;
    }
    return {'value': raw};
  }

  Future<void> _openUrl(String url, BuildContext ctx) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (mounted)
        ScaffoldMessenger.of(
          ctx,
        ).showSnackBar(const SnackBar(content: Text('Invalid URL')));
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted)
      ScaffoldMessenger.of(
        ctx,
      ).showSnackBar(const SnackBar(content: Text('Could not open URL')));
  }

  Future<void> _deleteItem(String key) async {
    try {
      await dbRef.child(key).remove();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Item deleted')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  /// Robust one-time read: handles both Event and DataSnapshot return types.
  Future<Map<String, dynamic>> _readOnce() async {
    final dynamic result = await dbRef.once();
    DataSnapshot ds;

    if (result is Event) {
      ds = result.snapshot;
    } else if (result is DataSnapshot) {
      ds = result;
    } else {
      // unknown shape — try to treat it as something with 'value'
      final val = (result is Map && result.containsKey('value'))
          ? result['value']
          : null;
      if (val is Map) {
        return Map<String, dynamic>.fromIterables(
          val.keys.map((k) => k.toString()),
          val.values,
        );
      }
      return {};
    }

    final rawVal = ds.value;
    if (rawVal is Map) {
      return Map<String, dynamic>.fromIterables(
        rawVal.keys.map((k) => k.toString()),
        rawVal.values,
      );
    }
    return {};
  }

  /// Helper to extract DataSnapshot from either Event or DataSnapshot
  DataSnapshot? _extractSnapshot(dynamic eventOrSnap) {
    if (eventOrSnap == null) return null;
    if (eventOrSnap is Event) return eventOrSnap.snapshot;
    if (eventOrSnap is DataSnapshot) return eventOrSnap;
    // some versions return a wrapper with 'snapshot' property
    try {
      final maybeSnapshot = (eventOrSnap as dynamic).snapshot;
      if (maybeSnapshot is DataSnapshot) return maybeSnapshot;
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fetched Tree Entries'),
        actions: [
          IconButton(
            tooltip: 'Refresh (one-time read)',
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              try {
                final m = await _readOnce();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Loaded ${m.length} items')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Read failed: $e')));
              }
            },
          ),
        ],
      ),
      // Use dynamic here so build works even if stream yields DataSnapshot or Event
      body: StreamBuilder<dynamic>(
        stream: dbRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Stream error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // snapshot.data might be Event or DataSnapshot (or other). Extract DataSnapshot robustly.
          final ds = _extractSnapshot(snapshot.data);

          if (ds == null) {
            // fallback: try if snapshot.data itself has 'value'
            final dynamic maybe = snapshot.data;
            dynamic rawVal;
            try {
              rawVal = (maybe is Map && maybe.containsKey('value'))
                  ? maybe['value']
                  : null;
            } catch (_) {
              rawVal = null;
            }
            if (rawVal == null)
              return const Center(child: Text('No items found'));
            // normalize rawVal below
            final Map<String, dynamic> items = rawVal is Map
                ? Map<String, dynamic>.fromIterables(
                    rawVal.keys.map((k) => k.toString()),
                    rawVal.values,
                  )
                : {'item': rawVal};
            return _buildListFromMap(items);
          }

          final rawVal = ds.value;
          if (rawVal == null)
            return const Center(child: Text('No items found'));

          final Map<String, dynamic> items = rawVal is Map
              ? Map<String, dynamic>.fromIterables(
                  rawVal.keys.map((k) => k.toString()),
                  rawVal.values,
                )
              : {'item': rawVal};

          return _buildListFromMap(items);
        },
      ),
    );
  }

  Widget _buildListFromMap(Map<String, dynamic> items) {
    final entries = items.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return RefreshIndicator(
      onRefresh: () async {
        await _readOnce();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final key = entries[index].key;
          final raw = entries[index].value;
          final entry = _normalize(raw);

          final treeName =
              (entry['Tree Name'] ??
                      entry['treeName'] ??
                      entry['TreeName'] ??
                      'Unknown')
                  .toString();

          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          treeName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        key,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete item?'),
                              content: const Text(
                                'This will remove the item permanently.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) await _deleteItem(key);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: entry.entries
                        .where((e) => e.key != 'fileUrl')
                        .map((e) => Chip(label: Text('${e.key}: ${e.value}')))
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  if (entry.containsKey('fileUrl') &&
                      (entry['fileUrl'] ?? '').toString().trim().isNotEmpty)
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () =>
                              _openUrl(entry['fileUrl'].toString(), context),
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Open file'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry['fileUrl'].toString(),
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
