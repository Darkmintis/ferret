/// One `http(s)://` URL found in captured text.
class FerretLinkMatch {
  const FerretLinkMatch(this.start, this.end, this.url);

  /// Offsets of the matched text in the scanned string.
  final int start;
  final int end;

  /// The URL with JSON-escaped slashes (`\/`) unescaped.
  final String url;
}

/// Finds and classifies URLs in bodies, headers and request URLs.
abstract final class FerretLinks {
  /// Only the first this-many characters are scanned, so very large bodies
  /// (with `maxBodyBytes: null`) can't stall the inspector.
  static const int maxScanChars = 512 * 1024;

  /// Stop after this many links per text.
  static const int maxLinks = 500;

  static final RegExp _pattern = RegExp(
    r'''https?:(?:\\?/){2}[^\s"'<>`]+''',
    caseSensitive: false,
  );

  static const _trailing = '.,;:!?\\';

  static const _imageExtensions = {
    'png',
    'jpg',
    'jpeg',
    'webp',
    'gif',
    'svg',
    'bmp',
    'ico',
    'avif',
  };

  static const _videoExtensions = {
    'mp4',
    'webm',
    'mov',
    'm4v',
    'mkv',
    'avi',
    'ogv',
  };

  /// Bodies larger than this are treated as heavy: video never auto-loads.
  static const int heavyMediaBytes = 2 * 1024 * 1024;

  /// All URL matches in [text], in order.
  static List<FerretLinkMatch> matches(String text) {
    final scanned = text.length > maxScanChars
        ? text.substring(0, maxScanChars)
        : text;
    final result = <FerretLinkMatch>[];
    for (final m in _pattern.allMatches(scanned)) {
      final end = m.start + _trimmedLength(m.group(0)!);
      final url = scanned.substring(m.start, end).replaceAll(r'\/', '/');
      if (Uri.tryParse(url)?.host.isEmpty ?? true) continue;
      result.add(FerretLinkMatch(m.start, end, url));
      if (result.length >= maxLinks) break;
    }
    return result;
  }

  /// Unique URLs in [text], in first-seen order.
  static List<String> find(String text) {
    final seen = <String>{};
    return [
      for (final m in matches(text))
        if (seen.add(m.url)) m.url,
    ];
  }

  /// Whether [url]'s path ends in a common image extension.
  static bool isImageUrl(String url) {
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? '';
    final dot = path.lastIndexOf('.');
    return dot != -1 && _imageExtensions.contains(path.substring(dot + 1));
  }

  /// Whether [url] points at an SVG (can't be decoded by Flutter's `Image`).
  static bool isSvgUrl(String url) =>
      (Uri.tryParse(url)?.path.toLowerCase() ?? '').endsWith('.svg');

  /// Whether [contentType] is `image/*`.
  static bool isImageContentType(String? contentType) =>
      contentType?.trim().toLowerCase().startsWith('image/') ?? false;

  /// Whether [url]'s path ends in a common video extension.
  static bool isVideoUrl(String url) {
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? '';
    final dot = path.lastIndexOf('.');
    return dot != -1 && _videoExtensions.contains(path.substring(dot + 1));
  }

  /// Whether [contentType] is `video/*`.
  static bool isVideoContentType(String? contentType) =>
      contentType?.trim().toLowerCase().startsWith('video/') ?? false;

  /// Image or video URL (kept out of the home call list).
  static bool isMediaUrl(String url) => isImageUrl(url) || isVideoUrl(url);

  /// `image/*` or `video/*`.
  static bool isMediaContentType(String? contentType) =>
      isImageContentType(contentType) || isVideoContentType(contentType);

  /// Drops trailing punctuation and unbalanced closing brackets, which are
  /// almost always sentence / JSON syntax rather than part of the URL.
  static int _trimmedLength(String raw) {
    var end = raw.length;
    while (end > 0) {
      final c = raw[end - 1];
      if (_trailing.contains(c)) {
        end--;
      } else if (c == ')' || c == ']' || c == '}') {
        final open = const {')': '(', ']': '[', '}': '{'}[c]!;
        final body = raw.substring(0, end);
        if (open.allMatches(body).length < c.allMatches(body).length) {
          end--;
        } else {
          break;
        }
      } else {
        break;
      }
    }
    return end;
  }
}
