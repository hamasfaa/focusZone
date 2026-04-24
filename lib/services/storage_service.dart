import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  Future<List<String>> uploadActivityNotesImages({
    required String userId,
    required String activityId,
    required List<XFile> imageFiles,
  }) async {
    final List<String> downloadUrls = [];

    for (final imageFile in imageFiles) {
      try {
        final File file = File(imageFile.path);
        
        final String extension = imageFile.name.contains('.') 
            ? imageFile.name.split('.').last 
            : 'jpg';
            
        final String fileName = '${_uuid.v4()}.$extension';
        final String storagePath = 'activities/$userId/$activityId/$fileName';

        final Reference ref = _storage.ref().child(storagePath);
        
        final UploadTask uploadTask = ref.putFile(file);
        
        final TaskSnapshot snapshot = await uploadTask;
        
        final String downloadUrl = await snapshot.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);
      } catch (e) {
        print('Error uploading image $imageFile: $e');
      }
    }

    return downloadUrls;
  }
}
