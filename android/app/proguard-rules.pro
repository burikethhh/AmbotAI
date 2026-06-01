## Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

## Keep plugin classes
-keep class io.flutter.plugins.** { *; }

## Keep model classes for JSON parsing
-keepattributes *Annotation*
-keepattributes Signature
