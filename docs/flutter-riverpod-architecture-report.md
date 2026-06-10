# Architecting the Crudo Flutter App with Riverpod, Layered Architecture, and DDD Principles

## Overview

This report proposes a concrete architecture for the Crudo nutrition-tracking app using Flutter, Riverpod, a layered structure (UI, domain, data), and selectively applied Domain-Driven Design (DDD). It synthesizes the Flutter team’s official architecture recommendations, Riverpod-centric architectures, and community practices around clean architecture and feature-first structure to help prevent spaghetti code and keep the app easy to extend over time.[^1][^2][^3][^4]

The suggested approach is: **feature-first folder structure** on top of a **3-layer architecture (Presentation / Domain / Data)** with **Riverpod providers as the glue**, and **lightweight DDD** only where the domain is non-trivial (plans, meals, streaks, subscription state). This balances clarity with pragmatism for a solo/very small team.

## Key Principles from Official Flutter Guidance

The Flutter docs define architecture as how you structure and design the app so it can scale as the codebase and team grow, emphasizing maintainability, scalability, testability, and reduced cognitive load. They recommend building with intentional architecture especially for feature-rich apps with multiple contributors, which aligns with Crudo’s long-term SaaS ambitions.[^2]

On the recommendations page, the Flutter team strongly emphasizes:

- **Separation of concerns**: Distinct UI and data layers; widgets should be “dumb”, with logic moved into ViewModels and data layer classes.[^5][^2]
- **Repository pattern in the data layer**: Repositories abstract persistence and API access and act as the app’s single source of truth.[^2]
- **MVVM in the UI layer**: Views (widgets) + ViewModels (UI logic/state) is strongly recommended; widgets react to state changes and forward user events.[^6][^2]
- **Optional domain layer**: Only introduce a separate domain layer with use-cases if logic is complex or reused; otherwise, it can add overhead.[^6][^2]
- **Unidirectional data flow**: Data flows from data → domain → UI; user events flow back to the data layer via commands or methods.[^2]
- **Immutable models and separate API vs domain models (for larger apps)**: To keep ViewModels clean and avoid leaking persistence concerns into UI.[^2]

The architecture case study (Compass app) shows a combined **feature-first UI** and **layer-first data/domain** structure:

- `lib/ui/` organized by features, each with `view_models/` and `widgets/`.
- `lib/domain/` for domain models.
- `lib/data/` for repositories, services, and API models.[^6]

This hybrid structure is a good baseline for Crudo.

## Riverpod-Centric Architectures

Riverpod is frequently used as the state-management and DI backbone in layered architectures. Community templates and articles emphasize:[^7][^1]

- Riverpod as **both dependency injection and state management**: providers expose repositories, use-cases, and controllers to the UI, replacing Provider-based DI.[^8][^1]
- A **3-layer pattern**: Data (APIs, storage), Domain (business rules, repositories), Presentation (widgets, state controllers/ViewModels).[^1][^7]
- Modular/feature-based folder structure where each feature has its own API, domain, providers, and UI subfolders.[^1]

Code With Andrea’s Riverpod architecture series (referenced in his comparison article) also uses four conceptual layers (Data, Domain, Application/Use-cases, Presentation) but highlights that the **application/domain layer can be omitted for simpler features**. This maps well to Flutter’s own recommendation to make the domain layer optional.[^9][^4][^2]

A Medium article on “Flutter Riverpod Architecture vs Riverpod state management” clarifies that Riverpod itself is not an architecture but a tool that can be integrated into MVC, MVVM, or Clean architectures; the architecture is about how providers and dependencies are organized and how concerns are separated. This supports using Riverpod within the MVVM-style architecture that Flutter now recommends.[^8]

## Feature-First vs Layer-First Project Structure

Code With Andrea’s “Flutter Project Structure: Feature-first or Layer-first?” article compares:

- **Layer-first** (features inside layers): group files by type (all repositories together, all models together, etc.).
- **Feature-first** (layers inside features): group files by feature (plan, today, history, profile), each containing its own models, controllers, views, etc.[^10][^4]

The analysis notes that layer-first makes it harder to work on a single feature because its files are scattered, whereas feature-first keeps all relevant files together and still allows internal separation into subfolders per layer. For larger projects with many features, feature-first is preferred because it reduces jumping around and improves navigability.[^4][^10]

Flutter’s Compass case study ends up with a hybrid form: **data & domain by type**, **UI by feature**. Riverpod-based templates such as ApparenceKit explicitly use modular feature modules (`modules/auth`, etc.) with core shared layers. Reddit and community discussions frequently recommend feature-first or hybrid structures for larger apps for the same reasons.[^11][^3][^1][^6]

For Crudo, which will have a clear set of core features (Today, Plan, History, Profile, onboarding, subscription), a **feature-first structure with a small shared core** is well suited.

## Layered Architecture and DDD in Flutter Context

Layered or “clean” architecture brings a separation into **presentation, domain, and data layers**, each with clear responsibilities:[^12][^5][^7]

- **Presentation layer**: UI (widgets), controllers/ViewModels, and state notifiers; no direct data access; responds to user actions and renders state.
- **Domain layer**: Core business rules, domain models, and use-cases/interactors; independent of Flutter and infrastructure.[^12]
- **Data layer**: Repositories, services/clients, persistence models, and external APIs (Supabase, HTTP, local storage).[^5][^12]

Clean Architecture for Flutter with Riverpod typically follows this structure, using domain entities and use-cases at the core, repositories at the data layer, and Riverpod-powered controllers in presentation. However, articles and Reddit discussions warn about **over-engineering small apps** with too many layers and abstractions and recommend using only the layers that add real value.[^13][^14][^7][^8]

Code With Andrea’s comparison article explicitly notes that Clean Architecture adds mental overhead and may not map perfectly to Flutter’s unidirectional data-flow-centric patterns; a simpler Riverpod architecture with clear boundaries may be easier to work with. The Android app architecture guide, which influenced Flutter’s recommendations, states that the domain layer is optional for apps without complex or widely reused business logic.[^9]

For Crudo, certain parts of the domain are central and relatively stable (user, day plan, meals, streaks, subscription), so a **lightweight DDD approach** for these aggregate roots is beneficial, but other parts (e.g., simple settings, theme toggles) can remain simple.

## Recommended High-Level Architecture for Crudo

### Layers and Responsibilities

Given the official guidance and Riverpod ecosystem practices, the following layers are recommended for Crudo:

- **Presentation (UI) layer**
  - Flutter widgets organized by feature (e.g., Today, Plan, History, Profile, Onboarding, Paywall).
  - Riverpod **controllers/notifiers** (analogous to ViewModels) managing UI state and translating domain objects into UI-ready data.
  - No direct Supabase or HTTP calls; dependencies injected via Riverpod providers.

- **Domain layer (selective DDD)**
  - Core domain entities/value objects: `User`, `DayPlan`, `Meal`, `Ingredient`, `Streak`, `Subscription`, `NotificationRule`.
  - Simple **use-cases** / domain services where logic is non-trivial or reused (e.g., `ComputeDailyPlanStatus`, `UpdateMealCompletion`, `ComputeStreak`, `ApplyTrialToSubscription`).
  - Domain logic expressed in pure Dart, independent of Flutter and Supabase.

- **Data layer**
  - Repository interfaces and implementations for `Plans`, `Meals`, `Products`, `UserProfile`, `Subscription`, `Streaks`.
  - Supabase data sources (clients, queries) and possible local cache (e.g., `Hive`/`shared_preferences` for device cache).
  - API/persistence models and mapping from/to domain models.

This mirrors the 3-layer structure advocated in community posts and templates while respecting Flutter’s recommendation that the domain layer be introduced only where needed.[^5][^12][^1][^2]

### Project Structure (Feature-First + Core)

A practical structure combining Flutter’s case study and Riverpod templates:

```text
lib/
  core/
    data/
      supabase_client.dart
      http_client.dart
      mappers/
    domain/
      models/
        user.dart
        subscription.dart
      services/
        auth_service.dart
    providers/
      app_providers.dart      // e.g., supabaseClientProvider, envProvider
    widgets/
      app_scaffold.dart
      primary_button.dart
    theme/
      app_theme.dart
    routing/
      app_router.dart        // likely go_router

  features/
    onboarding/
      data/
        onboarding_repository.dart
      domain/
        onboarding_models.dart
      presentation/
        controllers/
          onboarding_controller.dart
        widgets/
          onboarding_screen.dart

    auth/
      data/
        auth_repository.dart
      domain/
        auth_models.dart
      presentation/
        controllers/
          auth_controller.dart
        widgets/
          login_screen.dart
          register_screen.dart

    plan/
      data/
        plan_repository.dart
        product_repository.dart
      domain/
        day_plan.dart
        meal.dart
        ingredient.dart
        use_cases/
          create_plan.dart
          update_meal.dart
      presentation/
        controllers/
          plan_controller.dart
        widgets/
          plan_screen.dart
          edit_meal_sheet.dart

    today/
      presentation/
        controllers/
          today_controller.dart
        widgets/
          today_screen.dart

    history/
      data/
        history_repository.dart
      domain/
        history_models.dart
      presentation/
        controllers/
          history_controller.dart
        widgets/
          history_screen.dart

    profile/
      data/
        profile_repository.dart
      domain/
        profile_models.dart
      presentation/
        controllers/
          profile_controller.dart
        widgets/
          profile_screen.dart

main.dart
```

This follows the principle of **features as top-level modules** with internal organization into data/domain/presentation, similar to Riverpod architecture templates and Flutter’s mixed structure. It keeps all feature code close together, which helps avoid spaghetti across unrelated parts of the app.[^10][^4][^1][^6]

## Using Riverpod in this Architecture

### Provider Roles

In this architecture, Riverpod providers serve three main roles:

- **Dependency injection providers**: expose singletons like Supabase clients, repositories, and environment config.
- **Domain/application service providers**: provide access to domain services/use-cases.
- **UI state providers**: manage state for screens and smaller components (e.g., `TodayController`, `PlanController`).

Community examples and templates show Riverpod being used this way to keep each layer testable and decoupled.[^14][^7][^1]

### Example Flow for the Today Screen

For the “Today” feature (show current day plan, progress, upcoming meals, notifications):

1. **User opens Today screen**.
2. `todayControllerProvider` (an `AsyncNotifier` or equivalent) reads `currentUserProvider` and `plansRepositoryProvider` to fetch the current `DayPlan`.
3. `PlansRepository` fetches data from Supabase, maps it into domain `DayPlan` and `Meal` entities.
4. `TodayController` computes derived data such as adherence percentage, next meal countdown, and whether a reminder is due (or delegates to domain services).
5. The UI widgets watch `todayControllerProvider` and rebuild on state changes, displaying data and exposing actions like “Mark meal eaten”, “Skip meal”, or “Edit plan”.
6. Actions call methods on the controller, which call domain use-cases and then repositories to persist changes; the repository may emit new data, causing the controller to update state.

This embodies **unidirectional data flow** and keeps widgets free from business logic, as recommended by Flutter and Riverpod architectures.[^9][^1][^2]

## Applying DDD Selectively for Crudo

DDD encourages modeling the core business concepts as domain entities, value objects, and aggregates, and placing domain logic close to these models. In mobile apps, trying to apply “full” DDD can be overkill, but selective DDD around the core domain works well.[^7][^12]

For Crudo, the core domain includes:

- **User and Subscription**: membership status, trial vs paid, plan limits.
- **DayPlan and Meal**: structure of a day, meal count (up to five), target grams per ingredient.
- **Ingredient/Product**: simple source of truth for ingredient macros.
- **Streak**: Duolingo-style adherence over days.

Recommendations:

- Treat `DayPlan` as an **aggregate root** composed of `Meals`, which contain `MealItems` referencing `Ingredients`. Streak calculations and adherence are functions over a history of `DayPlan`s, not UI concerns.
- Implement domain services/use-cases like `CompleteMeal`, `SkipMeal`, and `ComputeStreak` as pure functions or small classes in the domain layer. The presentation layer calls these instead of implementing the logic in controllers.
- Keep domain models free from Supabase-specific annotations or JSON; use separate persistence models and mapping functions in the data layer, per Flutter’s “separate API and domain models” recommendation for larger apps.[^12][^2]

This keeps business rules consistent across multiple features (Today, History, Profile) and makes them easier to test and evolve without touching widgets or repositories.

## Trade-offs vs Other Architectures

Code With Andrea compares Riverpod architecture with Clean Architecture, MVC, MVVM, Bloc, Stacked, and Android App Architecture. Key trade-offs for Crudo:[^9]

- **Pure Clean Architecture**: Strong separation and testability, but more layers and classes; can be heavy for a single-developer mobile app.[^15][^9]
- **Bloc Architecture**: Clear patterns but verbose; state is always stream-based, and multiple Blocs can depend on each other, which may increase complexity.[^9]
- **Stacked (MVVM-based)**: Rich tooling for Provider-based MVVM, but Crudo is already committed to Riverpod; reusing the same ideas with Riverpod provides similar benefits.[^9]
- **Plain MVVM with ChangeNotifier**: Officially recommended minimal architecture, but Riverpod offers better DI, testing, compile-time safety, and flexibility.[^2][^9]

Given your stack and goals, **Riverpod-based MVVM + light DDD + layered architecture** offers a good balance between structure and flexibility, leveraging official guidance but using Riverpod instead of Provider.[^1][^2][^9]

## Recommended Practices to Avoid Spaghetti Code

Based on the sources and common pitfalls discussed in articles and Reddit threads, the following practices help keep the Crudo codebase clean and extensible:[^3][^11][^5][^2]

- **Do not put business logic in widgets**: keep stateful logic in controllers/notifiers; widgets should just map state to UI and forward events.[^5][^2]
- **Keep feature modules isolated**: each feature’s data/domain/presentation should mostly depend on core and shared abstractions, not on each other, to avoid circular dependencies and tangled imports.[^4][^1]
- **Use immutable domain models and explicit copy/update methods** to enforce unidirectional data flow and avoid accidental in-place mutation in the UI layer.[^12][^2]
- **Adopt consistent naming conventions** (e.g., `TodayController`, `PlanRepository`, `DayPlan`, `DayPlanDto`) to make roles obvious, aligning with Flutter’s recommendations.[^2]
- **Introduce the domain/use-case layer only where logic is complex or reused**, otherwise let controllers call repositories directly (for simple CRUD operations) to avoid over-engineering.[^2][^9]
- **Align test structure with the layer structure**: unit tests for repositories and domain services, widget tests for views, and provider tests for controllers; this mirrors the structure used in the Compass case study.[^6]

## Conclusion

Flutter’s official architecture guidance, combined with Riverpod-focused community patterns, points toward a layered, MVVM-like architecture with clear separation of concerns, repositories in the data layer, and ViewModel/Controller classes in the UI layer. Riverpod is well suited to act as both DI and state-management glue across these layers.[^7][^1][^6][^2]

For the Crudo app, a **feature-first project structure** with **three main layers (Presentation, Domain, Data)** and **selective DDD for core concepts** (plans, meals, streaks, subscription) will support maintainability, make tests straightforward, and allow new features to be added with minimal coupling. This architecture avoids spaghetti code by keeping business logic out of widgets, centralizing data access in repositories, and enforcing unidirectional data flow from data to UI.

---

## References

1. [Flutter Architecture Template with Riverpod - ApparenceKit](https://apparencekit.dev/flutter-templates/architecture/) - Start with a battle-tested Flutter architecture. 3-layer pattern (Data, Domain, Presentation), River...

2. [Architecting Flutter apps](https://docs.flutter.dev/app-architecture) - Learn how to structure Flutter apps.

3. [How do you architect your Flutter apps? Research for flutter.dev docs](https://www.reddit.com/r/FlutterDev/comments/192h8l0/how_do_you_architect_your_flutter_apps_research/) - Our architecture reflects the classical division between the Data, Domain, and Presentation layers. ...

4. [Flutter Project Structure: Feature-first or Layer-first?](https://codewithandrea.com/articles/flutter-project-structure/) - In this article we'll explore two common approaches for structuring our project: feature-first and l...

5. [Effective Layered Architecture in Large Flutter Apps - DEV Community](https://dev.to/alaminkarno/effective-layered-architecture-in-large-flutter-apps-2n48) - Layer This is your UI layer. It includes widgets, BLoC, Cubits, or Riverpod providers. This layer sh...

6. [Architecture case study - Flutter documentation](https://docs.flutter.dev/app-architecture/case-study) - This architecture case study demonstrates how to implement those guidelines by walking through the "...

7. [Flutter Riverpod Clean Architecture](https://ssoad.github.io/flutter_riverpod_clean_architecture/) - A production-ready Flutter template for scalable, maintainable, and testable apps. Powered by Riverp...

8. [Flutter Riverpod Architecture and Riverpod State Managementmalshani-wijekoon.medium.com › flutter-riverpod-architecture-and-riverp...](https://malshani-wijekoon.medium.com/flutter-riverpod-architecture-and-riverpod-state-management-56f7c3fa4bd6) - What is the difference between flutter riverpod state management and riverpod architecture?

9. [All content tagged App-architecture - Code With Andrea](https://codewithandrea.com/tags/apparchitecture/) - When building mobile apps, we often need to fetch and mutate data. This article explains how to do i...

10. [Flutter Project Structure: Feature-first or Layer-first? - GitHub](https://github.com/bizz84/flutter-tips-and-tricks/blob/main/tips/0039-flutter-project-structure-feature-first-or-layer-first/index.md) - Let's explore two popular approaches known as "feature-first" and "layer-first" and learn about thei...

11. [Flutter App Architecture with Riverpod: An Introduction (Updated)](https://www.reddit.com/r/FlutterDev/comments/1677nai/flutter_app_architecture_with_riverpod_an/) - Flutter App Architecture with Riverpod: An Introduction (Updated)

12. [Flutter App Architecture and How to Structure Your Folders - ITNEXT](https://itnext.io/flutter-app-architecture-and-how-to-structure-your-folders-7fdc9c269274) - You just have to separate your code into a presentation, a domain, and a data layer. The presentatio...

13. [What do you think about mixing Riverpod with an architecture - Reddit](https://www.reddit.com/r/FlutterDev/comments/180okt9/what_do_you_think_about_mixing_riverpod_with_an/) - I'm used to using clean architecture, where I have three layers: domain, data, and presentation, my ...

14. [Mastering Flutter Riverpod with Clean Architecture - Medium](https://medium.com/@er.janibhargavk/mastering-flutter-riverpod-with-clean-architecture-beginner-to-advanced-portfolio-project-148b564cd0a0) - Why State Management Matters in Flutter

15. [Journey to the clean architecture for my flutter app - DEV Community](https://dev.to/leehack/journey-to-the-clean-architecture-for-my-flutter-app-138n) - The clean architecture was quite famous for the flutter project, too, since it's a recommended archi...

