const String _baseUrl = 'http://192.168.33.9:8000';
// const String _baseUrl = 'https://banglamed.net';

const String _prefix = '/api';

Uri getFullUrl(String shortUrl) {
  return Uri.parse(_baseUrl + _prefix + shortUrl);
}
