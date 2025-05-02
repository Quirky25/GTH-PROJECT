import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class SDCardPage extends StatefulWidget {
  @override
  _SDCardPageState createState() => _SDCardPageState();
}

class _SDCardPageState extends State<SDCardPage> {
  String esp32IP = "Fetching...";
  List<String> files = [];
  String fileContent = "";
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchESP32IPFromFirebase();
  }

  // Fetch the ESP32's IP address from Firebase
  Future<void> fetchESP32IPFromFirebase() async {
    setState(() {
      isLoading = true;
    });
    try {
      DatabaseReference ref = FirebaseDatabase.instance.ref("esp32/ip_address");
      final snapshot = await ref.get();
      if (snapshot.exists) {
        setState(() {
          esp32IP = snapshot.value.toString().trim();
        });
        await fetchFileList();
      } else {
        setState(() {
          esp32IP = "No IP address found in Firebase.";
        });
      }
    } catch (e) {
      setState(() {
        esp32IP = "Error: $e";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fetch the list of files from the ESP32
  Future<void> fetchFileList() async {
    setState(() {
      isLoading = true;
      files = [];
    });
    try {
      final response = await http.get(Uri.parse("http://$esp32IP/list"));
      if (response.statusCode == 200) {
        final lines = response.body
            .split("\n")
            .where((line) => line.trim().isNotEmpty && line.trim() != "System Volume Information" && line.trim() != "contact.txt")
            .toList();
        setState(() {
          files = lines;
        });
      } else {
        showSnackBar("Failed to fetch file list: ${response.statusCode}");
      }
    } catch (e) {
      showSnackBar("Error fetching file list: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Read the content of a specific file
  Future<void> readFile(String fileName) async {
    setState(() {
      isLoading = true;
      fileContent = "";
    });
    try {
      final response = await http.get(Uri.parse("http://$esp32IP/read?file=$fileName"));
      if (response.statusCode == 200) {
        setState(() {
          fileContent = response.body;
        });
      } else {
        showSnackBar("Failed to read file: ${response.statusCode}");
      }
    } catch (e) {
      showSnackBar("Error reading file: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Confirm before deleting a file
  Future<void> confirmDeleteFile(String fileName) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete File"),
          content: const Text(
              "Are you sure you want to delete this file? This action cannot be undone."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("No"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Yes"),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await deleteFile(fileName);
    }
  }

  // Delete a specific file
  Future<void> deleteFile(String fileName) async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await http.get(Uri.parse("http://$esp32IP/delete?file=$fileName"));
      if (response.statusCode == 200) {
        showSnackBar("File deleted successfully");
        await fetchFileList();
      } else {
        showSnackBar("Failed to delete file: ${response.statusCode}");
      }
    } catch (e) {
      showSnackBar("Error deleting file: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Show a Snackbar with a message
  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Sort the file list alphabetically
  void sortFiles() {
    setState(() {
      files.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    });
  }

  // Download the file from the ESP32 and save it to the device storage
  Future<void> downloadFile(String fileName) async {
    // Request permission for storage access
    PermissionStatus status = await Permission.storage.request();
    if (!status.isGranted) {
      showSnackBar("Storage permission denied!");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Fetch the file content from the ESP32
      final response = await http.get(Uri.parse("http://$esp32IP/read?file=$fileName"));
      if (response.statusCode == 200) {
        // Get the local directory to save the file
        Directory? appDocDir = await getExternalStorageDirectory();

        // Check if the directory is valid
        if (appDocDir != null) {
          String filePath = "${appDocDir.path}/$fileName";

          // Save the file to the device
          File file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);

          showSnackBar("File downloaded successfully to $filePath");
        } else {
          showSnackBar("Failed to get external storage directory.");
        }
      } else {
        showSnackBar("Failed to download file: ${response.statusCode}");
      }
    } catch (e) {
      showSnackBar("Error downloading file: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent navigation if loading is in progress
        if (isLoading) {
          showSnackBar("Please wait until the files are loaded.");
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.transparent, // Make the page display transparent
        appBar: AppBar(
          backgroundColor: Colors.transparent, // Transparent AppBar
          elevation: 0, // Remove shadow
          automaticallyImplyLeading: false,
          title: const Text(
            "Files on SD Card",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          centerTitle: false, // Align title to the left
          actions: [
            IconButton(
              icon: const Icon(Icons.sort),
              onPressed: sortFiles,
              tooltip: "Sort Files",
            ),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: files.isEmpty
                          ? const Text("No files found.")
                          : ListView.builder(
                              itemCount: files.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  title: Text(files[index]),
                                  onTap: () => readFile(files[index]),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => confirmDeleteFile(files[index]),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.download, color: Colors.blue),
                                        onPressed: () => downloadFile(files[index]),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    if (fileContent.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text(
                        "File Content:",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            fileContent,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}