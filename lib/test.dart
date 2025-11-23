import 'package:flutter/material.dart';
import 'package:firebase_dart/firebase_dart.dart';
import 'package:firebase_dart/database.dart';

class test extends StatefulWidget {
  const test({super.key});

  @override
  State<test> createState() => _testState();
}

class _testState extends State<test> {
  final TreeName = TextEditingController();
  final District = TextEditingController();
  final CircumferenceOfTree = TextEditingController();
  final HeightOfTree = TextEditingController();
  final AgeOfTree = TextEditingController();
  final DangerLevel = TextEditingController();

  late FirebaseDatabase database;
  late DatabaseReference dbRef;

  @override
  void initState() {
    super.initState();

    // Get default firebase app safely
    final app = Firebase.app();

    database = FirebaseDatabase(app: app);

    dbRef = database.reference().child("ARM_branch_data_saved").child("Matara");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tree Details')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              controller: TreeName,
              decoration: InputDecoration(labelText: 'Tree Name'),
            ),
            TextField(
              controller: District,
              decoration: InputDecoration(labelText: 'District'),
            ),
            TextField(
              controller: CircumferenceOfTree,
              decoration: InputDecoration(labelText: 'Circumference of Tree'),
            ),
            TextField(
              controller: HeightOfTree,
              decoration: InputDecoration(labelText: 'Height of Tree'),
            ),
            TextField(
              controller: AgeOfTree,
              decoration: InputDecoration(labelText: 'Age of Tree'),
            ),
            TextField(
              controller: DangerLevel,
              decoration: InputDecoration(labelText: 'Danger Level'),
            ),

            SizedBox(height: 20),

            ElevatedButton(
              child: Text("Issue Ticket"),
              onPressed: () async {
                Map<String, dynamic> data = {
                  "Tree Name": TreeName.text,
                  "District": District.text,
                  "Circumference of Tree": CircumferenceOfTree.text,
                  "Height of Tree": HeightOfTree.text,
                  "Age of Tree": AgeOfTree.text,
                  "Danger Level": DangerLevel.text,
                };

                try {
                  await dbRef.push().set(data);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Uploaded successfully")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
