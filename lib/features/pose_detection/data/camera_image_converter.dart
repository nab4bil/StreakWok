import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class ConvertedCameraFrame {
  final InputImage inputImage;
  final Size uprightImageSize;
  final InputImageRotation rotation;

  const ConvertedCameraFrame({
    required this.inputImage,
    required this.uprightImageSize,
    required this.rotation,
  });
}

/// Converts [CameraImage] buffers from `camera` into ML Kit [InputImage]
/// with tightly packed NV21 bytes on Android and accurate rotation metadata.
class CameraImageConverter {
  static const Map<DeviceOrientation, int> _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  static InputImageRotation? resolveRotation({
    required CameraDescription camera,
    required DeviceOrientation deviceOrientation,
    bool? isIosOverride,
  }) {
    final isIos = isIosOverride ?? Platform.isIOS;
    if (isIos) {
      return InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    }

    final rotationCompensation = _orientations[deviceOrientation];
    if (rotationCompensation == null) return null;

    final int compensated;
    if (camera.lensDirection == CameraLensDirection.front) {
      compensated = (camera.sensorOrientation + rotationCompensation) % 360;
    } else {
      compensated =
          (camera.sensorOrientation - rotationCompensation + 360) % 360;
    }
    return InputImageRotationValue.fromRawValue(compensated);
  }

  static Size uprightSizeFor(Size rawSize, InputImageRotation rotation) {
    if (rotation == InputImageRotation.rotation90deg ||
        rotation == InputImageRotation.rotation270deg) {
      return Size(rawSize.height, rawSize.width);
    }
    return rawSize;
  }

  static ConvertedCameraFrame? convert({
    required CameraImage image,
    required CameraDescription camera,
    required DeviceOrientation deviceOrientation,
  }) {
    final rotation = resolveRotation(
      camera: camera,
      deviceOrientation: deviceOrientation,
    );
    if (rotation == null || image.planes.isEmpty) return null;

    final rawSize = Size(image.width.toDouble(), image.height.toDouble());
    final uprightSize = uprightSizeFor(rawSize, rotation);

    if (Platform.isIOS) {
      final plane = image.planes.first;
      return ConvertedCameraFrame(
        inputImage: InputImage.fromBytes(
          bytes: plane.bytes,
          metadata: InputImageMetadata(
            size: rawSize,
            rotation: rotation,
            format: InputImageFormat.bgra8888,
            bytesPerRow: plane.bytesPerRow,
          ),
        ),
        uprightImageSize: uprightSize,
        rotation: rotation,
      );
    }

    // Android ML Kit commons expects tightly packed NV21 bytes.
    final Uint8List? nv21Bytes = _toNv21Bytes(image);
    if (nv21Bytes == null) return null;

    return ConvertedCameraFrame(
      inputImage: InputImage.fromBytes(
        bytes: nv21Bytes,
        metadata: InputImageMetadata(
          size: rawSize,
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: image.width,
        ),
      ),
      uprightImageSize: uprightSize,
      rotation: rotation,
    );
  }

  static Uint8List? _toNv21Bytes(CameraImage image) {
    if (image.planes.length == 1) {
      return packSinglePlaneNv21(
        bytes: image.planes[0].bytes,
        width: image.width,
        height: image.height,
        bytesPerRow: image.planes[0].bytesPerRow,
      );
    }

    if (image.planes.length >= 3) {
      final yPlane = image.planes[0];
      final uPlane = image.planes[1];
      final vPlane = image.planes[2];
      return packYuv420ToNv21(
        width: image.width,
        height: image.height,
        yBytes: yPlane.bytes,
        yRowStride: yPlane.bytesPerRow,
        uBytes: uPlane.bytes,
        uRowStride: uPlane.bytesPerRow,
        uPixelStride: uPlane.bytesPerPixel ?? 1,
        vBytes: vPlane.bytes,
        vRowStride: vPlane.bytesPerRow,
        vPixelStride: vPlane.bytesPerPixel ?? 1,
      );
    }

    return null;
  }

  /// Strips row-stride padding from single-plane NV21 frames when present.
  static Uint8List packSinglePlaneNv21({
    required Uint8List bytes,
    required int width,
    required int height,
    required int bytesPerRow,
  }) {
    final totalRows = height + (height ~/ 2);
    if (bytesPerRow == width && bytes.length >= width * totalRows) {
      return bytes;
    }

    final nv21 = Uint8List(width * totalRows);
    int dstOffset = 0;
    for (int row = 0; row < totalRows; row++) {
      final srcOffset = row * bytesPerRow;
      if (srcOffset >= bytes.length) break;
      final copyLen = (srcOffset + width <= bytes.length)
          ? width
          : (bytes.length - srcOffset);
      nv21.setRange(dstOffset, dstOffset + copyLen, bytes, srcOffset);
      dstOffset += width;
    }
    return nv21;
  }

  /// Packs 3-plane YUV_420_888 into contiguous NV21 (Y followed by interleaved VU).
  static Uint8List packYuv420ToNv21({
    required int width,
    required int height,
    required Uint8List yBytes,
    required int yRowStride,
    required Uint8List uBytes,
    required int uRowStride,
    required int uPixelStride,
    required Uint8List vBytes,
    required int vRowStride,
    required int vPixelStride,
  }) {
    final ySize = width * height;
    final uvHeight = height ~/ 2;
    final uvWidth = width ~/ 2;
    final nv21 = Uint8List(ySize + uvHeight * width);

    // Copy Y plane row by row.
    for (int row = 0; row < height; row++) {
      final srcStart = row * yRowStride;
      final dstStart = row * width;
      if (srcStart < yBytes.length) {
        final available = yBytes.length - srcStart;
        final len = available < width ? available : width;
        nv21.setRange(dstStart, dstStart + len, yBytes, srcStart);
      }
    }

    // Interleave V then U (NV21 order).
    int dst = ySize;
    for (int row = 0; row < uvHeight; row++) {
      final vRowStart = row * vRowStride;
      final uRowStart = row * uRowStride;
      for (int col = 0; col < uvWidth; col++) {
        final vIndex = vRowStart + col * vPixelStride;
        final uIndex = uRowStart + col * uPixelStride;
        nv21[dst++] = vIndex < vBytes.length ? vBytes[vIndex] : 128;
        nv21[dst++] = uIndex < uBytes.length ? uBytes[uIndex] : 128;
      }
    }

    return nv21;
  }
}
