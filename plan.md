# AMBOT AI — Project Plan

> "I don't know? Now you will."
> Offline-first AI education super-app built with Flutter.

---

## Vision

A modular, offline-first AI super-app where every feature is an AI Role.
Originally focused on education, now expanding into multiple verticals
(Agriculture, Medicine, Law, Business, Creative, and more). Users install
only the roles they need. All AI inference runs on-device. No internet
required. No subscriptions for core features. Minimalist, premium design
language throughout.

---

## Target Users

- Students (high school, college)
- Teachers and instructors
- Self-learners
- Educational institutions
- Farmers and agricultural workers
- Medical and health sciences students, trainees, paramedics
- Legal self-help users and paralegals
- Small business owners, job seekers
- Writers and creatives
- Anyone needing a private, offline AI assistant

---

## Design Principles

- No emojis anywhere in the UI
- Minimalist and premium aesthetic
- Monochrome base with a single accent color
- Clean typography, generous whitespace
- Subtle animations, no visual noise
- Dark mode first, light mode available
- Consistent component library across all roles

---

## Tech Stack

| Layer            | Technology                                  |
|------------------|---------------------------------------------|
| Framework        | Flutter (cross-platform)                    |
| State Management | Riverpod                                    |
| Local Database   | Isar / Hive                                 |
| AI (Flagship)    | Google AI Core / Gemini Nano                |
| AI (Mid-range)   | MediaPipe LLM Inference API                 |
| AI (Low-end)     | Bundled Gemma 2B via llama.cpp              |
| Vision (VLM)     | Gemini Nano MM / MediaPipe Vision / Moondream / SmolVLM (GGUF) |
| Image Gen        | MediaPipe Image Gen / stable-diffusion.cpp  |
| Embeddings       | MiniLM / bge-small via MediaPipe or GGUF    |
| OCR              | Google ML Kit (on-device)                   |
| Documents        | pdfx / syncfusion_flutter_pdf / docx_to_text |
| Theming          | Material 3, custom design system            |
| Export           | PDF generation (local)                      |

---

## Architecture

```
App Layer
  - UI (Material 3, adaptive, dark-first)
  - Feature Modules (1 module per Role)

Core Layer
  - RoleEngine (system prompts, persona management, domain routing)
  - ChatService (conversation state, history, search, export)
  - MemoryService (long-term memory: extract, store, retrieve)
  - GamificationService (XP, badges, streaks)
  - OCR Service (photo to text, on-device)
  - DocumentService (pdf/docx/txt ingestion, chunking, per-chat RAG)
  - StorageService (Isar for structured, Hive for KV)

AI Layer
  - AICapabilityDetector (device tier detection)
  - AIEngine (abstract text LLM interface)
    - GeminiNanoEngine (flagship devices)
    - MediaPipeEngine (mid-range devices)
    - LocalLLMEngine (bundled model, low-end fallback)
  - VisionEngine (abstract VLM interface)
    - GeminiNanoMMEngine (flagship)
    - MediaPipeVisionEngine (mid)
    - MoondreamEngine / SmolVLMEngine (low-end, GGUF)
  - ImageGenEngine (abstract T2I, opt-in, flagship-only)
    - MediaPipeImageGenEngine
    - StableDiffusionCppEngine
  - EmbeddingEngine (abstract)
    - MiniLMEngine / BgeSmallEngine
  - ModelManager (download, cache, version management, per-capability bundles)
```

---

## Roles — Full Feature List

Roles are organized along two axes:

- **Audience** (category): Student, Teacher, Universal
- **Domain**: Education, Agriculture, Medicine, Mental Health, Law,
  Engineering, Business, Languages, Creative, Productivity

Each Role declares what it can consume (text / image / document) and
whether it uses long-term memory. The Role Hub lets users filter by
domain, audience, capability, and device tier.

### Education — Student Roles

1. Tutor
   - Explains any topic at the user's level
   - Adapts to knowledge gaps over time
   - Supports all subjects

2. QuizCraft
   - Converts notes, photos, or pasted text into quizzes
   - Formats: multiple choice, fill-in-the-blank, essay, true/false
   - Spaced repetition scheduling

3. CramMode
   - Input: subject, exam date, available hours
   - Output: optimized study schedule with priorities
   - Generates rapid-fire review from weakest areas

4. DebateBot
   - Takes the opposing side of any argument
   - Scores user responses on logic, evidence, persuasion
   - Tracks improvement over sessions

5. Unstuck
   - Photo a problem (math, science, code)
   - Provides step-by-step hints, not answers
   - Designed to teach methodology

6. MemoryPalace
   - Input any list, concept set, or vocabulary
   - Generates mnemonics, stories, acronyms
   - Daily review with spaced repetition

7. VoiceCoach
   - Practice speeches and presentations
   - AI simulates audience, asks follow-up questions
   - Feedback on clarity, structure, filler words

8. StudyStreaks
   - Pomodoro timer integrated with AI quizzer
   - Quiz during every break on recent study material
   - Streak tracking, daily goals

9. TimeTraveler
   - Converse with historical figures
   - Historically grounded personality and knowledge
   - Educational focus: learn from their perspective

10. WrongBot
    - AI gives intentionally wrong explanations
    - User must identify and correct the errors
    - Builds deep understanding through error detection

11. DungeonScholar
    - RPG game where combat is solved by answering questions
    - AI generates enemies based on weak subjects
    - Boss fights are exam simulations
    - Inventory, leveling, skill trees tied to subjects

12. RapReview
    - Paste notes, AI generates song lyrics with key concepts
    - Multiple styles: rap, poem, rhyme scheme
    - Text-based output for offline use

13. AlibiAI
    - Comedic excuse generator for late homework
    - Clearly labeled as humor/meme feature
    - Entry point to get users exploring real features

### Education — Teacher Roles

14. LessonForge
    - Input: subject, grade, duration, objectives
    - Output: full lesson plan with activities and assessments
    - Export to PDF

15. GradeAssist
    - Photograph or paste student work
    - AI provides suggested grade and written feedback
    - Customizable grading criteria

16. RubricAI
    - Describe assignment, AI generates detailed rubric
    - Apply rubric to student submissions
    - Batch grading support

17. DiffCheck
    - Offline plagiarism detection within a class
    - Compares submissions against each other locally
    - No data leaves the device (FERPA/GDPR safe)

18. IEP Writer
    - Input student needs, goals, accommodations
    - Generates Individualized Education Program drafts
    - Customizable templates per district requirements

19. ParentNote
    - Input situation (behavior, progress, concern)
    - Generates professional parent communication
    - Tone options: formal, friendly, urgent

20. ActivityGen
    - Input: topic, age group, time, available materials
    - Generates interactive classroom activities
    - Filters: indoor/outdoor, low-prep, inclusive

21. TeacherRoast
    - Upload lesson plan or describe your approach
    - AI gives brutally honest but constructive feedback
    - Humor mode and serious mode

### Universal Roles

22. Summarizer
    - Condenses any text into key bullet points
    - Adjustable length: brief, standard, detailed

23. ELI5 (Explain Like I'm 5)
    - Explains any concept at adjustable difficulty
    - Levels: elementary, high school, college, expert

24. Custom Role
    - User defines name, personality, instructions, constraints
    - Full control over system prompt
    - Save, edit, share role templates

### Agriculture

25. CropDoctor
    - Photo of a leaf, stem, or fruit
    - Diagnose likely disease, deficiency, or pest damage
    - Suggest organic and chemical treatment options
    - Requires: vision engine

26. SoilSage
    - Advise fertilization, irrigation, pH management
    - Tailored per crop, season, and climate zone

27. PestID
    - Identify pests from description or photo
    - Life cycle info and integrated pest management advice

28. FarmPlanner
    - Crop rotation schedules
    - Planting and harvest calendar per region
    - Land-use optimization for smallholders

29. MarketPulse
    - Offline reference for typical pricing ranges
    - Harvest timing, storage, and post-harvest loss reduction

30. LivestockCare
    - Basic husbandry guidance for common livestock
    - Symptom-to-condition triage (educational, non-veterinary)

### Medicine and Health Sciences

31. SymptomTriage
    - Educational symptom exploration with strong disclaimers
    - Never diagnostic; always recommends professional care
    - Red-flag detection routes user to emergency guidance

32. DrugInfo
    - Local drug database: interactions, dosages, contraindications
    - Pill identifier via photo (shape, color, imprint)
    - Requires: vision engine for identifier feature

33. AnatomyTutor
    - Body systems, structures, functions
    - Quizzes, mnemonics, labeled diagrams

34. MedTerms
    - Medical terminology translator
    - Latin and Greek roots, prefixes, suffixes

35. ClinicalCase
    - Case-based reasoning practice
    - Differential diagnosis training for students

36. FirstAidBot
    - Step-by-step emergency response for common scenarios
    - CPR, bleeding, burns, choking, shock
    - Works fully offline, large-text emergency mode

37. NutritionCoach
    - Macro and micronutrient guidance
    - Meal planning around dietary restrictions

### Mental Health and Wellness

38. MindfulCoach
    - CBT-inspired journaling prompts
    - Breathing, grounding, and reframing exercises
    - Clear non-therapy disclaimer

39. MoodTracker
    - Daily check-ins with private, on-device trend analysis
    - Export personal reports for a real clinician

40. SleepSage
    - Sleep hygiene coaching
    - Wind-down routines and habit tracking

### Law

41. LegalEase
    - Plain-English explanation of common legal concepts
    - Jurisdiction-aware when offline packs are installed

42. ContractReview
    - Upload a contract (PDF or image)
    - Highlights potentially risky clauses
    - Requires: document reading + vision fallback

43. RightsCoach
    - Know-your-rights guidance per jurisdiction
    - Offline packs for common regions

### Engineering and Trades

44. CodeMentor
    - Programming tutor across languages
    - Explains errors, suggests refactors
    - Accepts pasted code or screenshots

45. CircuitSolver
    - Electrical and electronics problem solver
    - Ohm's law, Kirchhoff, component selection

46. BlueprintReader
    - Explains engineering drawings and schematics
    - Requires: vision engine

### Business and Career

47. ResumeForge
    - Tailor resumes to job descriptions
    - ATS-friendly formatting and keyword tuning

48. InterviewSim
    - Role-based mock interviews
    - Feedback on clarity, relevance, confidence cues

49. PitchCoach
    - Refines startup pitches and decks
    - Suggests storytelling structure

50. BizPlanBot
    - Business plan scaffolding with local market templates

### Languages

51. PolyglotTutor
    - Conversational practice in target language
    - Adaptive difficulty, correction-first mode

52. TranslatorPro
    - Offline translation with context preservation
    - Document and image translation via OCR

53. GrammarGuru
    - Rule explanations with examples
    - Error analysis on user-written text

### Creative

54. StoryForge
    - Collaborative fiction writing
    - Optional illustrations via offline image gen

55. PoetryLab
    - Structured poetry: sonnets, haiku, villanelles
    - Meter and rhyme feedback

56. WorldBuilder
    - RPG and novel world design assistant
    - Map, faction, timeline scaffolding

### Productivity and Personal

57. Inbox Triage
    - Summarize and prioritize pasted emails or messages

58. MeetingMuse
    - Turn rough notes or transcripts into clean minutes and actions

59. ReaderBuddy
    - Load a PDF or DOCX and chat with it
    - Per-chat RAG index, no data leaves the device
    - Requires: document reading

60. MemoryJournal
    - Personal journal with long-term memory recall
    - Weekly and monthly reflections generated from entries

---

## Gamification System

- XP earned from all role interactions
- Leveling system with titles (Novice, Scholar, Sage, etc.)
- Badges for milestones across roles
- Daily challenges that rotate between roles
- Streak tracking (consecutive days of usage)
- Optional class leaderboards (teacher-created)
- Profile card: shareable stats summary

---

## Persistent Memory

Ambot separates short-term conversation history from long-term memory so
local models can feel continuous across sessions without bloating context.

### Layers

1. **Conversation history** (per chat)
   - Persisted in Isar via ChatService
   - Auto-titled, searchable, pinnable, exportable (txt, md, pdf)

2. **Long-term memory** (cross-chat, per role or global)
   - Isar collection `MemoryEntry`
     { id, scope, roleId?, key, value, embedding?, importance, createdAt, lastUsedAt }
   - Extraction: after each AI response, a small summarizer pass pulls
     0–3 durable facts ("user is studying for MCAT", "prefers Socratic method")
   - Retrieval: top-K relevant memories injected into the system prompt
     on each new turn
   - Scopes: Global, Per-role, Per-chat (user-configurable)

3. **Model-level continuity**
   - Persist llama.cpp KV cache between sessions where supported
   - Cached last N turns as structured context for all engines

### Retrieval modes

- **Keyword mode** (low-end devices): BM25 / substring match over memories
- **Embedding mode** (mid and flagship): on-device embeddings via MediaPipe
  or a small sentence-transformer in GGUF

### Privacy

- Settings > Memory: view, edit, delete any entry
- Per-role and global wipe
- Export full memory set as JSON
- Memory is never synced off-device unless the user opts into cloud backup

---

## Multimodal Capabilities

### Image input (vision)

- OCR: Google ML Kit for text-in-image
- Visual understanding via a tiered VLM stack:
  - Flagship: Gemini Nano multimodal
  - Mid: MediaPipe Vision task
  - Low-end: Moondream 2 or SmolVLM-256M via llama.cpp (GGUF)
- Roles that benefit: CropDoctor, Unstuck, GradeAssist, BlueprintReader,
  PestID, DrugInfo (pill ID), ContractReview fallback

### Document input

- DocumentService normalizes any input to clean text chunks:
  - PDF via pdfx or syncfusion_flutter_pdf
  - DOCX via docx_to_text
  - TXT and Markdown passthrough
  - Images of documents routed through OCR
- Each chat can attach one or more documents
- Chunks are indexed locally for a per-chat RAG flow so the model can
  answer questions about the file without ever leaving the device
- Powers: ReaderBuddy, ContractReview, GradeAssist, Summarizer

### Image generation (offline, opt-in)

- Flagship-only feature, large model download, clearly opt-in
- Backends:
  - MediaPipe Image Generation task (Android)
  - stable-diffusion.cpp for cross-platform fallback
- Roles that benefit: StoryForge, WorldBuilder, MemoryPalace,
  PoetryLab illustrations
- Lightweight alternative for all tiers: text-to-SVG diagrams and
  concept maps generated by the text LLM

---

## Role Capability Flags

Every role declares what it consumes and produces so the Role Hub can
filter by device tier:

```dart
class Role {
  RoleCategory category;       // student / teacher / universal
  RoleDomain domain;           // education / agriculture / medicine / ...
  List<String> tags;
  bool acceptsText;            // default true
  bool acceptsImage;
  bool acceptsDocument;
  bool producesImage;
  MemoryScope defaultMemoryScope;  // none / chat / role / global
  DeviceTier minimumTier;      // lowEnd / mid / flagship
}
```

---

## Device Control (Android)

Ambot can take control of the device to perform actions on behalf of the
user. This is an Android-first feature using the **Accessibility Service**
API for UI interaction and **MediaProjection** for screen capture.

### Architecture

```
core/
  device_control/
    action.dart                    # DeviceAction model + risk levels
    action_registry.dart           # All available actions, categorized
    device_controller.dart         # Abstract interface (platform-agnostic)
    execution_mode.dart            # Ask / Autopilot / AI Decides
    action_log.dart                # History of executed actions
    safety_rules.dart              # Guardrails, allowlists, blocklists
    engines/
      android_accessibility_engine.dart  # MethodChannel to native
      screen_capture_engine.dart         # MediaProjection + OCR

android/
  app/src/main/
    kotlin/.../
      AmbotAccessibilityService.kt   # Reads screen, performs taps/swipes
      ScreenCaptureService.kt        # Screenshot stream
```

### Action Types

Actions are classified by risk:

**SAFE** (can run in Autopilot)
- Launch app by name or package
- Open URL / deep link
- Search the web
- Set alarm, timer, reminder
- Toggle WiFi, Bluetooth, flashlight, airplane mode
- Adjust volume, brightness
- Read current screen text (via Accessibility or OCR)
- Copy text to clipboard
- Create calendar event

**MODERATE** (Ask before execution by default)
- Send SMS / WhatsApp message (AI drafts, user confirms recipient)
- Send email (AI drafts, user confirms)
- Create note / document
- Install / uninstall app (from Play Store link)
- Change system settings (Do Not Disturb, location)
- Navigate to a specific screen within an app

**DANGEROUS** (Always requires explicit confirmation, never autopilot)
- Delete files, messages, contacts
- Make payments or purchases
- Factory reset, clear data
- Change account passwords
- Grant / revoke app permissions
- Transfer money, crypto operations

### Execution Modes

```dart
enum ExecutionMode {
  /// AI proposes every action. User taps "Allow" or "Deny".
  /// Default for all new users.
  ask,

  /// AI executes SAFE actions immediately. MODERATE actions
  /// still require confirmation. DANGEROUS always blocked.
  autopilot,

  /// AI decides based on risk level and user trust history.
  /// Can escalate to Ask if confidence is low or action is
  /// unusual for this user. DANGEROUS always requires confirm.
  aiDecides,
}
```

### Trust System

- Users earn trust points over time by confirming AI actions
- Higher trust lowers the threshold for Autopilot / AI Decides
- Any dangerous action blocked resets trust partially
- Trust is per-action-category (e.g., high trust for "launch app"
  doesn't mean high trust for "send message")

### Screen Context Pipeline

1. User says "help me do X" or Ambot is in Commander mode
2. Ambot captures current screen (MediaProjection or Accessibility)
3. OCR extracts text + UI element tree from Accessibility Service
4. AI receives: `{ screenText, elementTree, availableActions, userIntent }`
5. AI decides what action(s) to take
6. Actions are routed through the execution mode guardrails
7. Result is fed back to the AI for the next step

### Safety

- Accessibility Service requires explicit user opt-in in Android Settings
- Screen capture requires runtime permission + foreground notification
- All actions are logged with timestamp, AI reasoning, and user response
- "Kill switch" button always visible during automation
- Emergency shake-to-stop gesture
- No network transmission of screen content or action logs
- Dangerous actions have a 5-second countdown before execution (cancelable)

### Commander Role

A dedicated role that serves as the device control interface:
- Full-screen view with live screen preview
- Action log sidebar (scrollable history)
- Execution mode toggle in the header
- Quick-action chips for common tasks
- Voice input support ("open my email and find the latest from boss")
- Trust score display

---

## Voice Integration

Ambot can listen to spoken commands and speak responses back. This creates
a fully hands-free experience when combined with device control.

### Architecture

```
core/
  voice/
    voice_service.dart              # Abstract interface (STT + TTS)
    voice_command_parser.dart       # Speech text -> DeviceAction intent
    voice_settings.dart             # Language, speed, pitch, offline toggle
    engines/
      android_voice_engine.dart     # SpeechRecognizer + TextToSpeech
      mock_voice_engine.dart        # Testing fallback

android/
  app/src/main/
    kotlin/.../
      AmbotVoiceService.kt          # Native STT/TTS bridge
```

### Speech-to-Text (STT)

- **Android 12+**: On-device speech recognition (no network needed)
- **Android 11 and below**: Falls back to Google cloud STT (requires internet)
- **Continuous listening mode**: Listens for commands until explicitly stopped
- **Wake word detection**: Optional "Hey Ambot" trigger (keyword spotting via
  on-device model)
- **Live transcript**: Shows real-time transcription as the user speaks

### Text-to-Speech (TTS)

- Uses Android's built-in `TextToSpeech` engine
- Supports multiple languages and voices
- Adjustable speed and pitch
- Offline-capable with downloaded voice data
- Ambot speaks: action confirmations, results, error messages, and
  conversational responses

### Voice Command Pipeline

1. User speaks: "open WhatsApp and send hello to mom"
2. STT converts to text in real-time
3. VoiceCommandParser extracts intent:
   - Action: `send_sms` or `launch_app` + `type_text`
   - Parameters: `{recipient: "mom", message: "hello"}`
4. SafetyRules checks risk level + execution mode
5. If allowed: execute the action
6. Ambot speaks the result: "Opening WhatsApp for you"

### Voice Commands (Examples)

**Navigation**
- "open [app name]"
- "go back"
- "go home"
- "open settings"
- "search for [query]"

**Communication**
- "send [message] to [contact]"
- "call [contact]"
- "read my last message"
- "open email"

**System Control**
- "turn on WiFi" / "turn off Bluetooth"
- "set brightness to 50%"
- "set volume to max"
- "turn on flashlight"
- "set an alarm for 7 AM"
- "set a timer for 10 minutes"

**Information**
- "what's on my screen?"
- "read this to me"
- "what apps do I have?"
- "what time is it?"

**Conversation**
- "hey Ambot, [question]"
- "explain [topic]"
- "quiz me on [subject]"

### Voice UI

- Floating mic button (always accessible)
- Waveform animation while listening
- Live transcript overlay
- Voice feedback toggle (on/off)
- "Hold to talk" vs "Tap to toggle" modes

---

## UX Flow

1. First launch: select user type (Student / Teacher / Both)
2. Device capability scan (auto-detect AI tier)
3. Model download if needed (background, with progress indicator)
4. Role Hub: pick 3-5 starter roles
5. Home screen shows installed roles as clean cards
6. Tap any role to enter its dedicated interface
7. Browse and install more roles anytime
8. Settings: AI mode toggle, theme, profile, data management

---

## Monetization

- Free tier: all core roles, local AI inference, unlimited usage
- Premium tier: cloud-upgraded AI responses, PDF exports,
  advanced grading rubrics, institution bulk licenses
- No ads. Ever.

---

## Development Phases

### Phase 1 — Foundation (Weeks 1-6)

- [ ] Flutter project setup, design system, theming
- [ ] AI abstraction layer (capability detection, engine interface)
- [ ] Local LLM integration (llama.cpp bridge)
- [ ] MediaPipe LLM integration
- [ ] Role engine (system prompt management)
- [ ] Chat service (conversation UI, history, persistence)
- [ ] Storage layer (Isar/Hive setup)
- [ ] Roles: Tutor, QuizCraft, ELI5, Custom Role
- [ ] Onboarding flow
- [ ] Home screen (Role Hub)

### Phase 2 — Engagement (Weeks 7-9)

- [ ] Roles: WrongBot, TimeTraveler, DebateBot, AlibiAI
- [ ] Gamification: XP, levels, badges, streaks
- [ ] Profile card (shareable)
- [ ] Daily challenges

### Phase 2.5 — Persistent Memory (Weeks 9-10)

- [ ] MemoryEntry model and Isar schema
- [ ] MemoryService (write, read, delete, export)
- [ ] MemoryExtractor (fact summarization pass)
- [ ] MemoryRetriever (keyword + embedding modes)
- [ ] Memory settings screen (view, edit, wipe per scope)
- [ ] Wire memory injection into ChatService prompt pipeline
- [ ] llama.cpp KV cache persistence

### Phase 3 — Teachers and Documents (Weeks 10-12)

- [ ] Roles: LessonForge, GradeAssist, ParentNote, ActivityGen
- [ ] OCR integration (photo to text)
- [ ] DocumentService (pdf, docx, txt ingestion and chunking)
- [ ] Per-chat RAG index for documents
- [ ] ReaderBuddy role
- [ ] PDF export
- [ ] RubricAI, DiffCheck

### Phase 4 — Gamified Learning (Weeks 13-16)

- [ ] DungeonScholar RPG system
- [ ] StudyStreaks (Pomodoro + quizzer)
- [ ] MemoryPalace
- [ ] Class leaderboards

### Phase 5 — Polish and Expand (Weeks 17-19)

- [ ] Roles: RapReview, VoiceCoach, IEP Writer, TeacherRoast
- [ ] Summarizer improvements
- [ ] CramMode
- [ ] Performance optimization for low-end devices
- [ ] Accessibility audit
- [ ] Beta testing

### Phase 6 — Vertical Expansion (Weeks 19-22)

- [ ] RoleDomain system and Role Hub domain filters
- [ ] Agriculture roles: CropDoctor, SoilSage, PestID, FarmPlanner,
      MarketPulse, LivestockCare
- [ ] Medicine roles: SymptomTriage, DrugInfo, AnatomyTutor, MedTerms,
      ClinicalCase, FirstAidBot, NutritionCoach
- [ ] Mental Health roles: MindfulCoach, MoodTracker, SleepSage
- [ ] Law roles: LegalEase, ContractReview, RightsCoach
- [ ] Engineering roles: CodeMentor, CircuitSolver, BlueprintReader
- [ ] Business roles: ResumeForge, InterviewSim, PitchCoach, BizPlanBot
- [ ] Language roles: PolyglotTutor, TranslatorPro, GrammarGuru
- [ ] Creative roles: StoryForge, PoetryLab, WorldBuilder
- [ ] Productivity roles: Inbox Triage, MeetingMuse, MemoryJournal

### Phase 7 — Vision (Weeks 22-24)

- [ ] VisionEngine abstraction and engine selector
- [ ] MediaPipe Vision integration (mid tier)
- [ ] Moondream / SmolVLM GGUF integration (low tier)
- [ ] Gemini Nano multimodal integration (flagship)
- [ ] Wire vision into CropDoctor, Unstuck, BlueprintReader, DrugInfo

### Phase 8 — Image Generation (Weeks 24-26)

- [ ] ImageGenEngine abstraction
- [ ] MediaPipe Image Generation integration (Android flagship)
- [ ] stable-diffusion.cpp fallback
- [ ] Opt-in model download flow
- [ ] Text-to-SVG diagram generator (universal)
- [ ] Wire into StoryForge, WorldBuilder, MemoryPalace

### Phase 9 — Device Control (Android) (Weeks 26-30)

- [ ] DeviceControl abstraction layer + Action model
- [ ] Action registry with risk levels (safe / moderate / dangerous)
- [ ] Execution mode system: Ask, Autopilot, AI Decides
- [ ] Android Accessibility Service native bridge
- [ ] Screen capture (MediaProjection) + OCR pipeline
- [ ] Commander role (device control interface)
- [ ] Control panel UI (action log, trust settings, live preview)
- [ ] Safe action allowlisting (launch app, open URL, toggle settings)
- [ ] Dangerous action guardrails (never auto-exute: delete, payment, send)
- [ ] Action undo / rollback where possible

### Phase 10 — Voice Integration (Weeks 30-32)

- [ ] VoiceService abstraction (STT + TTS + voice commands)
- [ ] Android SpeechRecognizer integration (offline on Android 12+)
- [ ] Android TextToSpeech integration (built-in, offline)
- [ ] Voice command parser (speech -> intent -> device action)
- [ ] Voice UI: mic button, wave animation, live transcript
- [ ] Continuous listening mode with wake word detection
- [ ] Voice settings: language, speed, pitch, offline preference
- [ ] Voice feedback: Ambot speaks action confirmations and results
- [ ] Voice + Commander: full hands-free device control

### Phase 11 — Launch (Week 32+)

- [ ] Play Store submission
- [ ] App Store submission (if iOS ready)
- [ ] Landing page
- [ ] Social media launch content

---

## Branding

- Name: Ambot AI
- Tagline: "I don't know? Now you will."
- Design: minimalist, premium, no emojis
- Palette: monochrome base + single accent
- Typography: clean sans-serif, generous spacing
- Mascot: abstract geometric brain mark (not a cartoon)
- Logo: see /assets/logo/ambot_logo.svg

---

## File Structure

```
ambot/
  lib/
    main.dart
    app.dart
    core/
      ai/
        ai_engine.dart
        ai_capability_detector.dart
        model_manager.dart
        engines/
          gemini_nano_engine.dart
          mediapipe_engine.dart
          local_llm_engine.dart
      multimodal/
        vision_engine.dart
        image_gen_engine.dart
        document_service.dart
        engines/
          gemini_nano_mm_engine.dart
          mediapipe_vision_engine.dart
          moondream_engine.dart
          smolvlm_engine.dart
          mediapipe_imagegen_engine.dart
          sd_cpp_engine.dart
      embeddings/
        embedding_engine.dart
        engines/
          minilm_engine.dart
          bge_small_engine.dart
      memory/
        memory_entry.dart
        memory_service.dart
        memory_extractor.dart
        memory_retriever.dart
      roles/
        role.dart
        role_domain.dart
        role_repository.dart
        role_engine.dart
        default_roles.dart
        seeds/
          education_roles.dart
          agriculture_roles.dart
          medicine_roles.dart
          mental_health_roles.dart
          law_roles.dart
          engineering_roles.dart
          business_roles.dart
          language_roles.dart
          creative_roles.dart
          productivity_roles.dart
      gamification/
        xp_service.dart
        badge_service.dart
        streak_service.dart
        leaderboard_service.dart
      services/
        chat_service.dart
        storage_service.dart
        device_info_service.dart
        ocr_service.dart
        pdf_service.dart
    features/
      onboarding/
      home/
      chat/
      memory/
      documents/
      roles/
        tutor/
        quiz_craft/
        cram_mode/
        debate_bot/
        unstuck/
        memory_palace/
        voice_coach/
        study_streaks/
        time_traveler/
        wrong_bot/
        dungeon_scholar/
        rap_review/
        alibi_ai/
        lesson_forge/
        grade_assist/
        rubric_ai/
        diff_check/
        iep_writer/
        parent_note/
        activity_gen/
        teacher_roast/
        summarizer/
        eli5/
        custom_role/
        crop_doctor/
        soil_sage/
        pest_id/
        farm_planner/
        market_pulse/
        livestock_care/
        symptom_triage/
        drug_info/
        anatomy_tutor/
        med_terms/
        clinical_case/
        first_aid_bot/
        nutrition_coach/
        mindful_coach/
        mood_tracker/
        sleep_sage/
        legal_ease/
        contract_review/
        rights_coach/
        code_mentor/
        circuit_solver/
        blueprint_reader/
        resume_forge/
        interview_sim/
        pitch_coach/
        biz_plan_bot/
        polyglot_tutor/
        translator_pro/
        grammar_guru/
        story_forge/
        poetry_lab/
        world_builder/
        inbox_triage/
        meeting_muse/
        reader_buddy/
        memory_journal/
      settings/
      profile/
    shared/
      theme/
        app_theme.dart
        app_colors.dart
        app_typography.dart
      widgets/
        role_card.dart
        chat_bubble.dart
        stat_card.dart
        badge_widget.dart
      constants.dart
      extensions.dart
  assets/
    logo/
      ambot_logo.svg
    fonts/
    default_roles.json
  pubspec.yaml
  README.md
```
