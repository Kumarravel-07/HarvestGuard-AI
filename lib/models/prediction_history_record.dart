import 'package:cloud_firestore/cloud_firestore.dart';

class PredictionHistoryRecord {
  const PredictionHistoryRecord({
    required this.createdAt,
    required this.cropName,
    required this.totalImages,
    required this.damagedCount,
    required this.oldCount,
    required this.ripeCount,
    required this.unripeCount,
    required this.overallCondition,
    required this.confidence,
    required this.spoilageRisk,
    required this.shelfLife,
    required this.recommendation,
    this.documentId,
    this.location,
    this.temperature,
    this.humidity,
  });

  final DateTime createdAt;
  final String cropName;
  final int totalImages;
  final int damagedCount;
  final int oldCount;
  final int ripeCount;
  final int unripeCount;
  final String overallCondition;
  final double confidence;
  final String spoilageRisk;
  final String shelfLife;
  final String recommendation;
  final String? documentId;
  final String? location;
  final double? temperature;
  final int? humidity;

  Map<String, dynamic> toFirestore() => {
    'createdAt': Timestamp.fromDate(createdAt.toUtc()),
    'cropName': cropName,
    'totalImages': totalImages,
    'damagedCount': damagedCount,
    'oldCount': oldCount,
    'ripeCount': ripeCount,
    'unripeCount': unripeCount,
    'overallCondition': overallCondition,
    'confidence': confidence,
    'spoilageRisk': spoilageRisk,
    'shelfLife': shelfLife,
    'recommendation': recommendation,
    'location': location,
    'temperature': temperature,
    'humidity': humidity,
  };

  factory PredictionHistoryRecord.fromFirestore(
    Map<String, dynamic> data, {
    String? documentId,
  }) {
    final createdAt = data['createdAt'];
    return PredictionHistoryRecord(
      createdAt: createdAt is Timestamp
          ? createdAt.toDate().toLocal()
          : DateTime.now(),
      cropName: data['cropName'] as String? ?? 'Tomato',
      totalImages: _asInt(data['totalImages']),
      damagedCount: _asInt(data['damagedCount']),
      oldCount: _asInt(data['oldCount']),
      ripeCount: _asInt(data['ripeCount']),
      unripeCount: _asInt(data['unripeCount']),
      overallCondition: data['overallCondition'] as String? ?? 'Unknown',
      confidence: _asDouble(data['confidence']),
      spoilageRisk: data['spoilageRisk'] as String? ?? 'Unknown',
      shelfLife: data['shelfLife'] as String? ?? 'N/A',
      recommendation:
          data['recommendation'] as String? ?? 'No recommendation available.',
      documentId: documentId,
      location: data['location'] as String?,
      temperature: data['temperature'] is num
          ? (data['temperature'] as num).toDouble()
          : null,
      humidity: data['humidity'] is num
          ? (data['humidity'] as num).toInt()
          : null,
    );
  }

  static int _asInt(dynamic value) => value is num ? value.toInt() : 0;

  static double _asDouble(dynamic value) => value is num ? value.toDouble() : 0;
}
