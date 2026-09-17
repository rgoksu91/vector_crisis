# The AdMob SDK pulls in WorkManager, whose Room database is instantiated
# reflectively: Room looks up the generated *_Impl class and calls its default
# constructor. R8 in full mode removes that constructor, so a release build
# crashes on launch with "Failed to create an instance of
# androidx.work.impl.WorkDatabase" before Flutter even starts.
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class androidx.work.impl.WorkDatabase_Impl { <init>(); }
-keep class androidx.work.impl.WorkDatabase_AutoMigration_* { <init>(...); }
