// AI Provider Identifiers - canonical enum used across the app
import 'dart:ui' show Color;

enum AIProvider {
  openai('OpenAI', 'GPT-4o, DALL-E, Whisper, TTS', Color(0xFF10A37F)),
  anthropic('Anthropic', 'Claude 3.5 Sonnet, Opus, Haiku', Color(0xFFD97757)),
  google('Google', 'Gemini 1.5 Pro, Flash, Ultra', Color(0xFF4285F4)),
  xai('xAI', 'Grok-2, Grok-Beta', Color(0xFF000000)),
  deepseek('DeepSeek', 'DeepSeek-V3, DeepSeek-R1', Color(0xFF4D6BFE)),
  mistral('Mistral AI', 'Mistral Large, Mixtral, Codestral', Color(0xFFFF7000)),
  meta('Meta', 'Llama 3.1, 3.2, Code Llama', Color(0xFF0866FF)),
  alibaba('Alibaba', 'Qwen 2.5, Qwen-VL, Qwen-Coder', Color(0xFFFF6A00)),
  zhipu('Zhipu AI', 'GLM-5.2, GLM-4-Plus, GLM-4V, CogView', Color(0xFF3B5BFE)),
  openrouter('OpenRouter', '300+ models, unified API', Color(0xFF6467F2)),
  huggingface('Hugging Face', 'Inference API, Spaces', Color(0xFFFFD21E)),
  ollama('Ollama', 'Local Llama, Mistral, Phi-3', Color(0xFF000000)),
  lmstudio('LM Studio', 'Local GGUF models', Color(0xFF00D4AA)),
  stability('Stability AI', 'Stable Diffusion, SDXL', Color(0xFFFF7028)),
  flux('Black Forest Labs', 'FLUX.1 Pro, Dev, Schnell', Color(0xFF000000)),
  ideogram('Ideogram', 'Ideogram v2, Text rendering', Color(0xFFFF3EA3)),
  recraft('Recraft', 'Recraft v3, SVG generation', Color(0xFF000000)),
  leonardo('Leonardo AI', 'Phoenix, Lightning, Vision', Color(0xFFD9A4FF)),
  runway('Runway', 'Gen-3 Alpha, Gen-2', Color(0xFF000000)),
  pika('Pika Labs', 'Pika 1.5, Effects', Color(0xFF000000)),
  luma('Luma AI', 'Dream Machine, Ray2', Color(0xFF00E5FF)),
  kling('Kuaishou', 'Kling 1.5, 1.6 Pro', Color(0xFFFF0050)),
  veo('Google DeepMind', 'Veo 2, Veo 3', Color(0xFF4285F4)),
  pixverse('PixVerse', 'PixVerse v3, Effects', Color(0xFF7C3AED)),
  hailuo('MiniMax', 'Hailuo, video-01', Color(0xFFFF6B35)),
  suno('Suno', 'Suno v4, Bark', Color(0xFFF5F5F5)),
  udio('Udio', 'Udio v1.5', Color(0xFFFF4D4D)),
  elevenlabs('ElevenLabs', 'Voice cloning, TTS', Color(0xFF000000)),
  assemblyai('AssemblyAI', 'Speech-to-Text, LeMUR', Color(0xFF2A2A2A));

  const AIProvider(this.displayName, this.description, this.brandColor);

  final String displayName;
  final String description;
  final Color brandColor;

  bool get requiresApiKey =>
      this != AIProvider.ollama && this != AIProvider.lmstudio;

  bool get isLocal => this == AIProvider.ollama || this == AIProvider.lmstudio;

  bool get isChat => [
        AIProvider.openai,
        AIProvider.anthropic,
        AIProvider.google,
        AIProvider.xai,
        AIProvider.deepseek,
        AIProvider.mistral,
        AIProvider.meta,
        AIProvider.alibaba,
        AIProvider.zhipu,
        AIProvider.openrouter,
        AIProvider.huggingface,
        AIProvider.ollama,
        AIProvider.lmstudio,
      ].contains(this);

  bool get isImage => [
        AIProvider.openai,
        AIProvider.stability,
        AIProvider.flux,
        AIProvider.ideogram,
        AIProvider.recraft,
        AIProvider.leonardo,
        AIProvider.zhipu,
      ].contains(this);

  bool get isVideo => [
        AIProvider.runway,
        AIProvider.pika,
        AIProvider.luma,
        AIProvider.kling,
        AIProvider.veo,
        AIProvider.pixverse,
        AIProvider.hailuo,
      ].contains(this);

  bool get isAudio => [
        AIProvider.openai,
        AIProvider.elevenlabs,
        AIProvider.assemblyai,
      ].contains(this);

  bool get isMusic => [AIProvider.suno, AIProvider.udio].contains(this);
}
