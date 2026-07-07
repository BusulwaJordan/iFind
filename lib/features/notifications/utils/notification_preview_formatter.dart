import 'dart:convert';

class NotificationPreviewFormatter {
  static const _productInquiryPrefix = 'IFIND_PRODUCT_INQUIRY::';
  static const _mediaInquiryPrefix = '[MEDIA_INQUIRY]|';
  static const _needInquiryPrefix = 'IFIND_NEED_INQUIRY::';
  static const _imagePrefix = 'IFIND_IMAGE::';
  static const _locationPrefix = 'IFIND_LOCATION::';

  static String cleanBody(String body) {
    if (body.startsWith(_productInquiryPrefix)) {
      final raw = body.substring(_productInquiryPrefix.length);
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final title = (data['title'] as String?)?.trim();
        return title == null || title.isEmpty
            ? 'Product inquiry'
            : 'Product inquiry: $title';
      } catch (_) {
        return 'Product inquiry';
      }
    }

    if (body.startsWith(_mediaInquiryPrefix)) {
      final parts = body.split('|');
      final caption = parts.length > 3 ? parts[3].trim() : '';
      return caption.isEmpty ? 'Image inquiry' : caption;
    }

    if (body.startsWith(_needInquiryPrefix)) {
      final raw = body.substring(_needInquiryPrefix.length);
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final title = (data['title'] as String?)?.trim();
        return title == null || title.isEmpty ? 'Posted need' : title;
      } catch (_) {
        return 'Posted need';
      }
    }

    if (body.startsWith(_imagePrefix)) return '📷 Photo';
    if (body.startsWith(_locationPrefix)) return '📍 Location';

    return body;
  }
}
