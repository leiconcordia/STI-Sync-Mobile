import 'package:cloud_firestore/cloud_firestore.dart';

class CertificatePosition {
  final double xPercent;
  final double yPercent;
  final double widthPercent;
  final double fontSizePt;
  final String fontFamily;
  final String fontWeight;
  final String textColor;
  final String textAlign;

  const CertificatePosition({
    this.xPercent = 50.0,
    this.yPercent = 45.0,
    this.widthPercent = 60.0,
    this.fontSizePt = 32.0,
    this.fontFamily = 'Montserrat',
    this.fontWeight = 'Bold',
    this.textColor = '#001A4D',
    this.textAlign = 'center',
  });

  factory CertificatePosition.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const CertificatePosition();
    return CertificatePosition(
      xPercent: (map['xPercent'] as num?)?.toDouble() ?? 50.0,
      yPercent: (map['yPercent'] as num?)?.toDouble() ?? 45.0,
      widthPercent: (map['widthPercent'] as num?)?.toDouble() ?? 60.0,
      fontSizePt: (map['fontSizePt'] as num?)?.toDouble() ?? 32.0,
      fontFamily: (map['fontFamily'] as String?) ?? 'Montserrat',
      fontWeight: (map['fontWeight'] as String?) ?? 'Bold',
      textColor: (map['textColor'] as String?) ?? '#001A4D',
      textAlign: (map['textAlign'] as String?) ?? 'center',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'xPercent': xPercent,
      'yPercent': yPercent,
      'widthPercent': widthPercent,
      'fontSizePt': fontSizePt,
      'fontFamily': fontFamily,
      'fontWeight': fontWeight,
      'textColor': textColor,
      'textAlign': textAlign,
    };
  }
}

class CertificateElement {
  final String id;
  final String type;
  final String text;
  final double xPercent;
  final double yPercent;
  final double widthPercent;
  final double fontSizePt;
  final String fontFamily;
  final String fontWeight;
  final String textColor;
  final String textAlign;

  const CertificateElement({
    required this.id,
    this.type = 'custom_text',
    this.text = '',
    this.xPercent = 50.0,
    this.yPercent = 50.0,
    this.widthPercent = 50.0,
    this.fontSizePt = 16.0,
    this.fontFamily = 'Montserrat',
    this.fontWeight = 'Regular',
    this.textColor = '#001A4D',
    this.textAlign = 'center',
  });

  factory CertificateElement.fromMap(Map<String, dynamic> map) {
    return CertificateElement(
      id: (map['id'] as String?) ?? '',
      type: (map['type'] as String?) ?? 'custom_text',
      text: (map['text'] as String?) ?? '',
      xPercent: (map['xPercent'] as num?)?.toDouble() ?? 50.0,
      yPercent: (map['yPercent'] as num?)?.toDouble() ?? 50.0,
      widthPercent: (map['widthPercent'] as num?)?.toDouble() ?? 50.0,
      fontSizePt: (map['fontSizePt'] as num?)?.toDouble() ?? 16.0,
      fontFamily: (map['fontFamily'] as String?) ?? 'Montserrat',
      fontWeight: (map['fontWeight'] as String?) ?? 'Regular',
      textColor: (map['textColor'] as String?) ?? '#001A4D',
      textAlign: (map['textAlign'] as String?) ?? 'center',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'text': text,
      'xPercent': xPercent,
      'yPercent': yPercent,
      'widthPercent': widthPercent,
      'fontSizePt': fontSizePt,
      'fontFamily': fontFamily,
      'fontWeight': fontWeight,
      'textColor': textColor,
      'textAlign': textAlign,
    };
  }
}

/// Represents a visual template from `/certificates` or `/certificate_templates`.
class CertificateTemplateModel {
  final String id;
  final String title;
  final String category;
  final String status;
  final String organizationId;
  final String organizationName;
  final String? eventId;
  final String? eventName;
  final String imageUrl;
  final String designPreset;
  final String paperSize; // 'a4', 'letter', 'short', 'long'
  final String orientation; // 'landscape', 'portrait'
  final CertificatePosition namePosition;
  final List<CertificateElement> elements;
  final String? signatoryName;
  final String? signatoryTitle;
  final String? secondarySignatoryName;
  final String? secondarySignatoryTitle;

  const CertificateTemplateModel({
    required this.id,
    required this.title,
    required this.category,
    required this.status,
    required this.organizationId,
    required this.organizationName,
    this.eventId,
    this.eventName,
    required this.imageUrl,
    this.designPreset = 'classic_gold',
    this.paperSize = 'a4',
    this.orientation = 'landscape',
    this.namePosition = const CertificatePosition(),
    this.elements = const [],
    this.signatoryName,
    this.signatoryTitle,
    this.secondarySignatoryName,
    this.secondarySignatoryTitle,
  });

  factory CertificateTemplateModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return CertificateTemplateModel.fromMap(doc.id, data);
  }

  factory CertificateTemplateModel.fromMap(String docId, Map<String, dynamic> data) {
    final rawElements = data['elements'] as List<dynamic>? ?? [];
    final elements = rawElements
        .whereType<Map<String, dynamic>>()
        .map((e) => CertificateElement.fromMap(e))
        .toList();

    return CertificateTemplateModel(
      id: docId,
      title: (data['title'] as String?) ?? (data['name'] as String?) ?? 'Certificate',
      category: (data['category'] as String?) ?? 'Participation',
      status: (data['status'] as String?) ?? 'Published',
      organizationId: (data['organizationId'] as String?) ?? 'admin',
      organizationName: (data['organizationName'] as String?) ?? 'SAO Admin',
      eventId: data['eventId'] as String?,
      eventName: data['eventName'] as String?,
      imageUrl: (data['imageUrl'] as String?) ?? '',
      designPreset: (data['designPreset'] as String?) ?? 'classic_gold',
      paperSize: (data['paperSize'] as String?)?.toLowerCase() ?? 'a4',
      orientation: (data['orientation'] as String?)?.toLowerCase() ?? 'landscape',
      namePosition: CertificatePosition.fromMap(data['namePosition'] as Map<String, dynamic>?),
      elements: elements,
      signatoryName: data['signatoryName'] as String?,
      signatoryTitle: data['signatoryTitle'] as String?,
      secondarySignatoryName: data['secondarySignatoryName'] as String?,
      secondarySignatoryTitle: data['secondarySignatoryTitle'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'status': status,
      'organizationId': organizationId,
      'organizationName': organizationName,
      'eventId': eventId,
      'eventName': eventName,
      'imageUrl': imageUrl,
      'designPreset': designPreset,
      'paperSize': paperSize,
      'orientation': orientation,
      'namePosition': namePosition.toMap(),
      'elements': elements.map((e) => e.toMap()).toList(),
      'signatoryName': signatoryName,
      'signatoryTitle': signatoryTitle,
      'secondarySignatoryName': secondarySignatoryName,
      'secondarySignatoryTitle': secondarySignatoryTitle,
    };
  }
}
