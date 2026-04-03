import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_app/data/services/cloudinary_service.dart';
import 'package:fitness_app/data/services/progress_service.dart';
import 'package:fitness_app/data/services/local_storage_service.dart';
import 'package:fitness_app/core/utils/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class CameraCaptureView extends StatefulWidget {
  const CameraCaptureView({super.key});

  @override
  State<CameraCaptureView> createState() => _CameraCaptureViewState();
}

class _CameraCaptureViewState extends State<CameraCaptureView> {
  // 🔥 Service initialized here to fix red lines
  final ProgressService _progressService = ProgressService();
  File? _capturedImage;
  bool _isFrontCamera = false;
  bool _isUploading = false;
  int selectedPoseIndex = 0;

  final List<String> poseImages = [
    "assets/images/pick1.png",
    "assets/images/right.png",
    "assets/images/left.png",
    "assets/images/pick1.png",
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedPose();
  }

  Future<void> _loadSavedPose() async {
    try {
      int? savedIndex = await _progressService.getLastSelectedPose();
      if (savedIndex != null &&
          savedIndex >= 0 &&
          savedIndex < poseImages.length) {
        setState(() => selectedPoseIndex = savedIndex);
      }
    } catch (e) {
      debugPrint("Error loading pose: $e");
    }
  }

  Future<void> _capturePhoto() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: _isFrontCamera
            ? CameraDevice.front
            : CameraDevice.rear,
        imageQuality: 85,
      );

      if (photo != null) {
        HapticFeedback.mediumImpact();
        setState(() {
          _capturedImage = File(photo.path);
        });
      }
    } catch (e) {
      _showSnackBar("❌ Camera Error: $e", Colors.redAccent);
    }
  }

  Future<void> _confirmAndUpload() async {
    if (_capturedImage == null) return;

    setState(() => _isUploading = true);
    try {
      final dynamic result = await CloudinaryService.uploadImage(
        _capturedImage!,
      );

      if (result != null && result is Map) {
        final Map<String, dynamic> cloudData = Map<String, dynamic>.from(
          result,
        );
        String userId = FirebaseAuth.instance.currentUser?.uid ?? "";

        if (userId.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('progress_photos')
              .add({
                'imageUrl': cloudData['url'].toString(),
                'publicId': cloudData['public_id'].toString(),
                'createdAt': FieldValue.serverTimestamp(),
                'poseIndex': selectedPoseIndex,
              });

          await LocalStorageService.saveProgressPhotoLocally(_capturedImage!);

          if (mounted) {
            _showSnackBar("✅ Progress Saved!", Colors.green);
            Navigator.pop(context);
          }
        }
      } else {
        throw "Cloudinary upload failed";
      }
    } catch (e) {
      _showSnackBar("❌ Upload Failed: $e", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var themeProvider = Provider.of<ThemeProvider>(context);
    bool isDark = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      // 🔥 Image ke mutabiq Background Gradient
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF2D1B4E), const Color(0xFF121212)]
                : [
                    const Color(0xFFF7A8D1),
                    const Color(0xFFFCE4EC),
                  ], // Pinkish Theme
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // _buildTopBar(),
              const Spacer(),
              _buildCharacterOverlay(),
              const Spacer(),
              _buildCameraControls(isDark),
              _buildPoseSelector(isDark),
              //const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCharacterOverlay() {
    return Center(
      child: _capturedImage != null
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  _capturedImage!,
                  height: 450,
                  width: 320,
                  fit: BoxFit.cover,
                ),
              ),
            )
          : Image.asset(
              poseImages[selectedPoseIndex],
              height: 450,
              fit: BoxFit.contain,
              // Ghost effect jaisa image mein hai
              color: Colors.white.withValues(alpha: 0.4),
              colorBlendMode: BlendMode.modulate,
            ),
    );
  }

  Widget _buildCameraControls(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.9,
        ), // 🔥 Image jaisa Light Container
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              if (_capturedImage != null) setState(() => _capturedImage = null);
            },
            icon: Icon(
              _capturedImage != null ? Icons.refresh : Icons.flash_off,
              color: const Color(0xFF9B81FF).withValues(alpha: 0.5),
            ),
          ),
          GestureDetector(
            onTap: _isUploading
                ? null
                : (_capturedImage == null ? _capturePhoto : _confirmAndUpload),
            child: Container(
              height: 60,
              width: 60,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF9B81FF), Color(0xFF8E71FF)],
                ),
              ),
              child: _isUploading
                  ? const Padding(
                      padding: EdgeInsets.all(15),
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      _capturedImage == null
                          ? Icons.camera_alt_outlined
                          : Icons.check,
                      color: Colors.white,
                    ),
            ),
          ),
          IconButton(
            onPressed: () {
              if (_capturedImage == null)
                setState(() => _isFrontCamera = !_isFrontCamera);
            },
            icon: Icon(
              Icons.camera_front,
              color: const Color(0xFF9B81FF).withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoseSelector(bool isDark) {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white, // 🔥 White bottom area jaisa image mein hai
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: poseImages.length,
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
        itemBuilder: (context, index) {
          bool isSelected = selectedPoseIndex == index;
          return GestureDetector(
            onTap: () async {
              setState(() => selectedPoseIndex = index);
              await _progressService.saveSelectedPose(index);
            },
            child: Container(
              width: 65,
              margin: const EdgeInsets.only(right: 15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: const Color(0xFF9B81FF), width: 1.5)
                    : null,
                color: Colors.grey.shade100,
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(poseImages[index], fit: BoxFit.contain),
              ),
            ),
          );
        },
      ),
    );
  }
}
