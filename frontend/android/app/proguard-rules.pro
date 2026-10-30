# Flutter ProGuard Rules

# Workaround for shared_preferences_android release crashes
-keep class kotlin.Unit { *; }
-keep class kotlin.Result { *; }
-keep class kotlin.Result$Failure { *; }
-keep class kotlin.coroutines.Continuation { *; }
-keep class kotlin.coroutines.intrinsics.CoroutineSingletons { *; }
-keep class kotlin.coroutines.intrinsics.IntrinsicsKt { *; }

# Keep shared_preferences pigeon/async registrar classes
-keep class io.flutter.plugins.sharedpreferences.** { *; }

