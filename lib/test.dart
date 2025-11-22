import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

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

  late DatabaseReference databaseReference;

  @override
  void initState() {
    super.initState();
    databaseReference = FirebaseDatabase.instance
        .ref()
        .child("ARM_branch_data_saved")
        .child("Matara");
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
              onPressed: () {
                Map<String, String> ticketdata = {
                  'Tree Name': TreeName.text,
                  'District': District.text,
                  'Circumference of Tree': CircumferenceOfTree.text,
                  'Height of Tree': HeightOfTree.text,
                  'Age of Tree': AgeOfTree.text,
                  'Danger Level': DangerLevel.text,
                };
                databaseReference
                    .push()
                    .set(ticketdata)
                    .then((_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Data Updated Successfully')),
                      );
                    })
                    .catchError((error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to update data: $error'),
                        ),
                      );
                    });
              },
              child: Text('Issue Ticket'),
            ),
          ],
        ),
      ),
    );
  }
}
