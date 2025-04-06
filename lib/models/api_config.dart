class ApiConfig {
  final String provider;  // 'openai', 'anthropic', 'gemini'
  final String apiKey;
  final String baseUrl;
  final Map<String, String> headers;
  
  ApiConfig({
    required this.provider,
    required this.apiKey,
    required this.baseUrl,
    this.headers = const {},
  });
} 