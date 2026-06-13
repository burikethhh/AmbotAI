# Ambot AI

> "I don't know? Now you will."

Offline-first AI education super-app built with Flutter. Run AI entirely on your device -- no internet required for core features.

## Features

### AI Engine
- **Local LLM**: On-device inference via llamadart (llama.cpp bridge)
- **Cloud AI**: NVIDIA Nemotron, OpenRouter, Google Gemini, Qwen support
- **Auto-selection**: Device capability detection for optimal engine choice

### 42 Built-in AI Roles
- **Education**: Tutor, QuizCraft, CramMode, DebateBot, TimeTraveler, WrongBot, MemoryPalace, DungeonScholar
- **Teacher**: LessonForge, GradeAssist, RubricAI, IEP Writer, ParentNote
- **Agriculture**: CropDoctor, SoilSage, PestID, FarmPlanner, MarketPulse
- **Medicine**: SymptomTriage, DrugInfo, AnatomyTutor, FirstAidBot, ClinicalCase
- **Law**: LegalEase, ContractReview, RightsCoach
- **Business**: ResumeForge, InterviewSim, PitchCoach, BizPlanBot
- **Creative**: StoryForge, PoetryLab, WorldBuilder
- **Languages**: PolyglotTutor, TranslatorPro, GrammarGuru

### Core Capabilities
- **General Chat**: Unlimited-purpose AI chat with streaming responses
- **Image Generation**: Text-to-image with local and cloud backends
- **Document Generation**: Study guides, quizzes, flashcards -- export to PDF/DOCX
- **Voice Generation**: Offline TTS via Piper engine
- **Programmer Mode**: HTML/CSS/JS editor with live preview
- **Autonomous Agent**: AI agent with planning and step execution
- **Device Control**: Android Accessibility Service integration
- **Long-term Memory**: Persistent memory with auto-extraction

### Design
- Dark-first, minimalist aesthetic
- No emojis -- clean typography
- Material 3 with custom design system

## Tech Stack

| Layer | Technology |
|-------|------------|
| Framework | Flutter (cross-platform) |
| State Management | Riverpod |
| Local Storage | Hive |
| LLM Inference | llamadart (llama.cpp) |
| Routing | GoRouter |
| Theme | Material 3 |

## Getting Started

### Prerequisites
- Flutter SDK ^3.10.7
- Android Studio / VS Code
- Android SDK (for Android builds)

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/ambot_ai.git
cd ambot_ai

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Build with Cloud API Keys

```bash
flutter run --dart-define=NVIDIA_API_KEY_1=your_key_here
flutter run --dart-define=GEMINI_KEY=your_key_here
```

## Project Structure

```
lib/
├── main.dart              # App entry point
├── app.dart               # MaterialApp.router setup
├── core/                  # Business logic
│   ├── ai/                # AI engines & model management
│   ├── memory/            # Long-term memory system
│   ├── roles/             # Role definitions (42 personas)
│   ├── services/          # Chat, storage, connectivity
│   ├── device_control/    # Android device automation
│   ├── voice/             # STT + TTS
│   └── image_gen/         # Image generation
├── features/              # UI screens (14 modules)
└── shared/                # Theme & reusable widgets
```

## Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

## License

This project is proprietary software. All rights reserved.

## Contact

For support or inquiries, please contact via GitHub Issues.
