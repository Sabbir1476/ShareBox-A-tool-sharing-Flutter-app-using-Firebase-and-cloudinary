import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'dart:convert';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();

  // Cloudinary configuration
  // TODO: Replace with your actual Cloudinary cloud name and upload preset
  // Get these from your Cloudinary dashboard: https://cloudinary.com/console
  static const String _cloudName = 'dm6nlp1ey'; // Replace with your Cloudinary cloud name
  static const String _uploadPreset = 'sharebox'; // Replace with your upload preset

  // Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (image != null) return File(image.path);
    return null;
  }

  // Pick image from camera
  Future<File?> pickImageFromCamera() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (image != null) return File(image.path);
    return null;
  }

  // Pick multiple images
  Future<List<File>> pickMultipleImages({int maxImages = 5}) async {
    final List<XFile> images = await _picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    return images.take(maxImages).map((x) => File(x.path)).toList();
  }

  // Upload profile image
  Future<String> uploadProfileImage({
    required String userId,
    required File imageFile,
  }) async {
    final ext = path.extension(imageFile.path);
    final ref = _storage.ref().child('profiles/$userId/profile$ext');

    final uploadTask = await ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return await uploadTask.ref.getDownloadURL();
  }

  // Upload tool image
  Future<String> uploadToolImage({
    required String ownerId,
    required File imageFile,
    String? toolId,
  }) async {
    final fileName = '${_uuid.v4()}${path.extension(imageFile.path)}';
    final folder = toolId ?? 'temp_${_uuid.v4()}';
    final ref = _storage.ref().child('tools/$ownerId/$folder/$fileName');

    final uploadTask = await ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return await uploadTask.ref.getDownloadURL();
  }

  // Upload multiple tool images
  Future<List<String>> uploadToolImages({
    required String ownerId,
    required List<File> imageFiles,
    String? toolId,
  }) async {
    final urls = await Future.wait(
      imageFiles.map((file) => uploadToolImage(
            ownerId: ownerId,
            imageFile: file,
            toolId: toolId,
          )),
    );
    return urls;
  }

  // Delete image by URL
  Future<void> deleteImage(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      // Ignore if file doesn't exist
    }
  }

  // Delete multiple images
  Future<void> deleteImages(List<String> downloadUrls) async {
    await Future.wait(downloadUrls.map((url) => deleteImage(url)));
  }

  // Upload with progress tracking
  UploadTask uploadFileWithProgress({
    required String storagePath,
    required File file,
  }) {
    final ref = _storage.ref().child(storagePath);
    return ref.putFile(file);
  }

  // ─── CLOUDINARY METHODS ──────────────────────────────────────────────────

  // Upload image to Cloudinary
  Future<String> uploadToCloudinary(File imageFile) async {
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');

      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      final jsonResponse = json.decode(responseString);

      if (response.statusCode == 200) {
        return jsonResponse['secure_url'];
      } else {
        throw Exception('Cloudinary upload failed: ${jsonResponse['error']['message']}');
      }
    } catch (e) {
      throw Exception('Failed to upload to Cloudinary: $e');
    }
  }

  // Upload multiple images to Cloudinary
  Future<List<String>> uploadMultipleToCloudinary(List<File> imageFiles) async {
    final urls = <String>[];
    for (final file in imageFiles) {
      final url = await uploadToCloudinary(file);
      urls.add(url);
    }
    return urls;
  }

  // Validate Cloudinary URL
  bool isValidCloudinaryUrl(String url) {
    return url.contains('cloudinary.com') &&
           (url.startsWith('http://') || url.startsWith('https://'));
  }
}
