class ApiConfig {
  final String provider;  // 'openai', 'anthropic', 'gemini'
  final String apiKey;
  final String baseUrl;
  final String model;
  final Map<String, String> headers;
  
  ApiConfig({
    required this.provider,
    required this.apiKey,
    required this.baseUrl,
    this.model = 'gpt-3.5-turbo',
    this.headers = const {},
  });
} 