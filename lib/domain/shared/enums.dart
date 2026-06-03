/// Per-day meal state — always DERIVED from checked flags + time (S05); never stored.
enum MealStatus { done, partial, upcoming, skipped }

/// Meal category tags; a meal may carry several.
enum MealTag { breakfast, lunch, dinner, snack, preWorkout, postWorkout }

/// Product library category. `custom` is the default for user-created products.
enum ProductCategory { meat, fish, eggs, grain, veg, fruit, oil, custom }

/// Profile goal — label only in v1 (no kcal target attached).
enum Goal { cut, maintain, bulk }

/// Display unit. Quantities are always stored as grams.
enum Unit { g, oz }

/// Reminder scheduling mode. `interval` is modeled now, v2-only.
enum ReminderMode { fixed, interval }

/// Day adherence verdict — derived live while open, frozen at midnight-lock (S12).
enum DayState { green, yellow, red }
