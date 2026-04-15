# Discovaa

Discovaa is a cross-platform Flutter marketplace that connects customers with trusted service providers for local and on-demand services.

It is designed as a full service lifecycle product, covering discovery, provider evaluation, booking, communication, tracking, reviews, and ongoing relationship management.

## Product Overview

- **Trust-first discovery**: help users find credible providers with clear quality signals.
- **Role-aware experience**: adapt the product for customers and providers without fragmenting the app.
- **End-to-end service flow**: support discovery, messaging, booking, fulfillment, and review.
- **Offline-tolerant UX**: prefer cached, responsive, and recoverable experiences where possible.

## Supported Roles

- `user` — customer/client
- `individualProvider` — solo service professional
- `businessProvider` — registered service business

## Core Product Areas

- Authentication and onboarding
- Provider discovery and category browsing
- Search, filtering, and sorting
- Provider profiles and trust signals
- Services listing and management
- Booking placement and booking status tracking
- In-app messaging and notifications
- Role-based dashboard analytics
- Favorites and saved providers/services
- Profile, account, and verification flows
- Support and contact entry points

## Technical Architecture

- **Framework**: Flutter
- **Language**: Dart
- **Navigation**: `go_router`
- **State management**: Riverpod
- **Networking**: `Dio`
- **Local storage / caching**: Hive
- **Dependency injection**: GetIt and supporting injection utilities
- **Architecture**: feature-based modular structure with clean layering

The app is API-first for major marketplace data operations. Firebase packages may support selected flows, but the backend source of truth is a remote API consumed through repository and datasource layers.

## Product Principles

- **Trust first**
- **Speed to value**
- **Role-aware, not role-fragmented**
- **Mobile-native simplicity**
- **Operational clarity**

## Getting Started

1. Install the Flutter SDK.
2. Fetch dependencies:

   ```bash
   flutter pub get
   ```

3. Run the app:

   ```bash
   flutter run
   ```

## Reference

- See `PRD.md` for the full product requirements, scope, and roadmap context.
