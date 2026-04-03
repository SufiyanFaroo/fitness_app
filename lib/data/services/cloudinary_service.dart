import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

class CloudinaryService {
  static const String _cloudName = "dhzaii3go";
  static const String _uploadPreset = "fitness";

  // 🔥 Dashboard se nikaal kar yahan sahi keys lagayein (Bohat zaruri hai)
  static const String _apiKey = "YOUR_API_KEY_HERE";
  static const String _apiSecret = "YOUR_API_SECRET_HERE";

  // --- 1. UPLOAD IMAGE ---
  static Future<Map<String, String>?> uploadImage(File imageFile) async {
    try {
      var uri = Uri.parse(
        "https://api.cloudinary.com/v1_1/$_cloudName/image/upload",
      );
      var request = http.MultipartRequest("POST", uri);

      request.fields['upload_preset'] = _uploadPreset;
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var json = jsonDecode(responseData);

        return {'url': json['secure_url'], 'public_id': json['public_id']};
      }
      return null;
    } catch (e) {
      print("Cloudinary Upload Error: $e");
      return null;
    }
  }

  // --- 2. DELETE IMAGE (Fixed Signature Logic) ---
  static Future<bool> deleteImageFromCloudinary(String publicId) async {
    try {
      if (publicId.isEmpty) return false;

      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // 🔥 FIX: Cloudinary mangta hai alphabetical order: public_id phir timestamp
      // Aur aakhir mein API Secret baghair kisi key name ke.
      final String signatureSource =
          "public_id=$publicId&timestamp=$timestamp$_apiSecret";

      // SHA-1 hashing
      final String signature = sha1
          .convert(utf8.encode(signatureSource))
          .toString();

      var uri = Uri.parse(
        "https://api.cloudinary.com/v1_1/$_cloudName/image/destroy",
      );

      var response = await http.post(
        uri,
        body: {
          "public_id": publicId,
          "api_key": _apiKey,
          "timestamp": timestamp.toString(),
          "signature": signature,
        },
      );

      final result = jsonDecode(response.body);

      if (result['result'] == 'ok') {
        print("✅ Cloudinary: Image deleted successfully");
        return true;
      } else {
        print("❌ Cloudinary Error: ${result['error']}");
        return false;
      }
    } catch (e) {
      print("Cloudinary Delete Error: $e");
      return false;
    }
  }
}
