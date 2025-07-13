import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter/material.dart';

class FileOpener {
  static Future<void> openEventFile(
    BuildContext context,
    String filePath,
  ) async {
    final file = File(filePath);
    if (await file.exists()) {
      final result = await OpenFile.open(filePath);
      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file: ${result.message}')),
        );
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('File does not exist: $filePath')));
    }
  }

  static Future<void> downloadAndOpenFile(
    BuildContext context,
    String url,
  ) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = url.split('/').last;
      final filePath = '${dir.path}/$fileName';

      print('Downloading file from: $url');
      print('Saving to: $filePath');

      // Download the file
      final response = await Dio().download(url, filePath);
      print('Download response: $response');

      // Check if file exists
      final file = File(filePath);
      if (await file.exists()) {
        print('File exists, opening...');
        final result = await OpenFile.open(filePath);
        if (result.type != ResultType.done) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open file: ${result.message}')),
          );
        }
      } else {
        print('File does not exist after download!');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File does not exist: $filePath')),
        );
      }
    } catch (e) {
      print('Error downloading/opening file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading/opening file: $e')),
      );
    }
  }
}
