import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class MediaService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return null;
    return await _compressImage(File(image.path));
  }

  Future<File?> pickVideo() async {
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.gallery, 
      maxDuration: const Duration(minutes: 3), // Enforce 3 minute limit
    );
    if (video == null) return null;
    return await _compressVideo(File(video.path));
  }

  Future<File> _compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath = p.join(dir.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 70, // aggressive compression for free tier
      minWidth: 1024,
      minHeight: 1024,
    );

    return File(result!.path);
  }

  Future<File> _compressVideo(File file) async {
    // MediaInfo? info = await VideoCompress.compressVideo(
    //   file.path,
    //   quality: VideoQuality.MediumQuality, // Balance between size and quality
    //   deleteOrigin: false,
    //   includeAudio: true,
    // );
    
    // return File(info!.path!);
    return file; // Return original for now until video_compress build issues are sorted
  }

  Future<File> generateThumbnail(File videoFile) async {
    final thumbnail = await VideoCompress.getFileThumbnail(
      videoFile.path,
      quality: 50,
      position: -1,
    );
    return thumbnail;
  }
}
