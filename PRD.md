# Product Requirements Document (PRD): Discovaa

## 1. Executive Summary

**Discovaa** is a cross-platform mobile marketplace that connects customers with trusted service providers for local and on-demand services. The product is designed to help users discover providers, evaluate service quality, communicate directly, place bookings, track work status, and manage ongoing service relationships in one app.

Discovaa is not only a discovery layer. It is intended to operate as a full service lifecycle product spanning:

- provider discovery
- provider trust and profile evaluation
- service selection and booking
- in-app communication
- booking progress tracking
- post-service review and relationship retention

The app currently supports multiple user paths through a role-aware experience model:

- `user` for customers/clients
- `individualProvider` for solo service professionals
- `businessProvider` for registered service businesses

This PRD defines the current product vision, target user experience, feature requirements, quality expectations, success measures, delivery scope, and roadmap priorities for Discovaa.

## 2. Product Vision

Enable people and businesses to confidently find, evaluate, book, and manage artisan and service-provider relationships through a trustworthy, modern, mobile-first marketplace experience.

## 3. Problem Statement

Customers often struggle to find reliable service providers with transparent quality signals, clear availability, and simple communication channels. Service providers, in turn, struggle with visibility, credibility, lead conversion, scheduling coordination, and repeat engagement.

Discovaa addresses these gaps by providing:

- structured provider discovery and filtering
- richer provider and service profiles
- integrated messaging and notifications
- booking workflows and status tracking
- review and trust-building mechanisms
- role-specific dashboards and operational insights

## 4. Product Goals

### 4.1 Business Goals

- Increase successful matches between customers and providers.
- Improve provider conversion from profile view to booking.
- Support repeat engagement and retention through messaging and saved/favorite entities.
- Create a trust-first marketplace foundation that can scale across service categories and geographies.

### 4.2 User Goals

- Help customers find relevant providers quickly.
- Help customers compare providers using visible quality indicators.
- Help providers showcase services and manage demand more effectively.
- Reduce friction in booking, rescheduling, communication, and follow-up.

### 4.3 Product Goals

- Deliver a coherent end-to-end marketplace flow in mobile form.
- Support role-aware experiences without fragmenting the product.
- Maintain a strong offline-tolerant, cached, responsive experience.
- Establish a scalable feature architecture for future iteration.

## 5. Target Users And Personas

### 5.1 Customer / Client

Users seeking trusted artisans or service professionals for personal or business needs.

Typical needs:

- discover providers by category or search
- review ratings, profiles, and offerings
- send pre-booking questions
- book services with confidence
- track booking progress and history

### 5.2 Individual Provider

Solo artisans or freelancers offering one or more services directly to clients.

Typical needs:

- create a credible provider presence
- publish and manage service offerings
- receive and respond to inquiries quickly
- manage upcoming and active bookings
- monitor basic performance and engagement signals

### 5.3 Business Provider

Small or medium service businesses operating with a more formal brand, broader capacity, or multiple service offerings.

Typical needs:

- present a stronger business profile
- manage multiple services and richer descriptions
- handle more client requests and communication volume
- monitor service demand, bookings, and customer sentiment

## 6. Product Principles

- **Trust first**: users should feel confident in the legitimacy and quality of providers.
- **Speed to value**: key actions such as search, provider discovery, and communication should feel immediate.
- **Role-aware, not role-fragmented**: the product should adapt for customers and providers while preserving a cohesive experience.
- **Mobile-native simplicity**: flows should be optimized for mobile completion with minimal friction.
- **Operational clarity**: users should always understand booking state, unread communication, and required next actions.

## 7. Current Product Scope

The current app structure and route surface indicate the following core modules are part of Discovaa:

- authentication and onboarding
- home/discovery experience
- role-based dashboard analytics
- provider discovery and category browsing
- services listing and management
- bookings and booking status transitions
- messaging and chat
- notifications
- profile and account management
- favorites/saved entities
- contact/support flow
- verification/identification flow

## 8. In-Scope User Journeys

### 8.1 Customer Discovery To Booking

1. User opens the app and completes onboarding or authentication.
2. User explores categories or uses search.
3. User filters and sorts providers.
4. User views provider/service information.
5. User messages provider or proceeds to booking.
6. User tracks upcoming, ongoing, completed, or cancelled bookings.
7. User leaves a rating or review after service completion.

### 8.2 Provider Acquisition And Fulfillment

1. Provider selects a role during signup.
2. Provider completes profile and identification steps.
3. Provider publishes service offerings.
4. Provider receives inquiries, messages, and booking requests.
5. Provider confirms, starts, and completes bookings.
6. Provider monitors dashboard metrics, unread messages, and recent activity.

### 8.3 Customer Retention Loop

1. Customer saves favorites or revisits known providers.
2. Customer receives booking and messaging updates.
3. Customer reviews recent bookings and re-engages the provider.

## 9. Functional Requirements

### 9.1 Authentication, Access, And Onboarding

The system must:

- support onboarding and public pre-auth entry points
- support login and sign-up flows
- support role-based sign-up selection
- support OTP verification during registration flow
- support forgot password and password reset flows
- support profile completion before full provider participation
- preserve authenticated state securely across sessions
- redirect unauthenticated users away from protected routes

### 9.2 Role Model

The system must support these effective roles:

- customer/user
- individual provider
- business provider

Role should influence:

- onboarding copy and steps
- profile requirements
- dashboard content
- services management access
- booking management expectations

### 9.3 Discovery And Search

The system must:

- allow browsing by service category
- allow category filtering from the home experience
- allow provider search by text query
- support provider sorting, including ratings and popularity-oriented ordering
- paginate or segment large result sets in a mobile-friendly way
- show loading, empty, and error states during provider retrieval

### 9.4 Home Experience

The home experience must:

- provide a search-first discovery entry point
- expose browse-by-category navigation
- present discoverable service providers in a browsable grid/list experience
- support progressive loading and skeleton states
- help users move efficiently from exploration to provider selection

### 9.5 Provider Profiles And Trust Signals

The product should support provider evaluation using a combination of:

- profile identity and basic contact information
- provider category alignment
- service summaries
- ratings and review indicators where available
- booking history relevance and recent activity indicators
- verification or identification status where applicable

### 9.6 Services Management

The system must allow providers to:

- create service listings
- define service title, category, description, and pricing structure
- support pricing variants such as fixed or range-based pricing where required by the service model
- specify duration and availability/scheduling metadata where applicable
- upload service media
- update, activate/deactivate, and delete services

The system should allow customers to:

- view service offerings
- understand price and availability expectations before booking

### 9.7 Bookings Lifecycle

The bookings system must:

- support booking placement from a selected service
- associate bookings with provider, customer, service, date, and time context
- support key status transitions including pending, upcoming/confirmed, ongoing, completed, and cancelled
- allow providers or system flows to confirm and complete bookings
- allow cancellation flows with clear feedback
- expose booking lists and status-filtered views
- support review submission on completed bookings

### 9.8 Messaging

The system must:

- allow users to view conversation threads
- allow opening a dedicated chat experience per conversation
- support text messaging
- support attachment-oriented messaging flows such as images and files where enabled
- track unread counts and read state
- allow conversation initiation from provider context when needed

### 9.9 Notifications

The system must:

- fetch and display notifications relevant to the user
- support unread count visibility
- support mark-as-read and mark-all-as-read operations
- support filtering notifications by type where applicable
- surface booking, messaging, and operational updates clearly

### 9.10 Dashboard Analytics

The dashboard must provide role-aware summary information.

For providers, the dashboard should emphasize:

- active requests
- upcoming appointments/bookings
- completed and cancelled booking performance
- average rating and review count
- revenue/performance-oriented KPIs
- smart insights and recent activity

For customers, the dashboard should emphasize:

- upcoming bookings
- booking mix/status visibility
- spending overview where available
- recent bookings
- unread and pending communication signals

For all users, the dashboard should:

- support loading, empty, refresh, and error states
- support data refresh without requiring full app restart
- summarize the most important immediate actions

### 9.11 Favorites And Relationship Retention

The system should support saved or favorite entities so users can:

- bookmark providers or services of interest
- revisit previously considered providers efficiently
- improve repeat engagement and conversion

### 9.12 Profile And Account Management

The system must support:

- customer profile viewing and editing
- provider profile viewing and editing
- account-specific tabs or sections for relevant personal or business information
- login/security-oriented account management
- payout or provider operations sections where applicable to the provider role

### 9.13 Contact And Support

The system should provide a support/contact path so users can:

- reach the team when blocked or confused
- report issues or request help

### 9.14 Verification And Identification

The system should support a provider verification workflow to improve marketplace trust and profile credibility.

## 10. Non-Functional Requirements

### 10.1 Performance

- Core screens should render perceived content quickly with skeleton or loading support.
- Search, filter, and tab changes should feel responsive on standard mobile devices.
- Dashboard and listing screens should support refresh without excessive delay.

### 10.2 Reliability

- The product should fail gracefully when APIs are unavailable.
- Error states should provide a recoverable user path such as retry.
- Cached/local data should be used where appropriate to reduce disruption.

### 10.3 Offline And Low-Connectivity Behavior

- The app should support partial offline resilience via local caching.
- Previously loaded content should be reused when network access is unavailable and feature logic allows it.
- Connectivity-aware behavior should reduce broken experiences during browsing and basic state restoration.

### 10.4 Security

- Authentication tokens must be stored securely.
- Protected routes must not be accessible to unauthenticated users.
- Sensitive user and account flows must avoid exposing credentials or session state.

### 10.5 Scalability

- Feature boundaries should remain modular and maintainable.
- The architecture should support new categories, expanded provider capabilities, and additional operational dashboards.

### 10.6 Maintainability

- The implementation should continue to follow feature-based organization and clean separation of concerns.
- Domain, data, and presentation concerns should remain decoupled enough for testing and iteration.

### 10.7 UX Quality

- The interface should maintain consistency across modules.
- Empty, loading, and error states must be intentional, not accidental.
- Mobile interactions must remain clear and forgiving.

## 11. Technical Architecture Alignment

The current implementation direction is best described as follows:

- **Framework**: Flutter
- **Language**: Dart
- **Navigation**: `go_router`
- **State management**: Riverpod
- **Networking**: `Dio`
- **Local storage / caching**: Hive
- **Dependency injection**: GetIt / service locator pattern with supporting injection utilities
- **UI architecture**: feature-based modular architecture with clean layering patterns in major modules
- **Supporting cloud dependencies**: Firebase packages are present and may support selected flows, but the application is currently API-first for major marketplace data operations

This PRD assumes the backend source of truth for primary marketplace data is a remote API consumed through repository and datasource layers, not a Firebase-only backend.

## 12. Data And Integration Expectations

The product depends on a backend capable of supporting:

- user authentication and current-user retrieval
- provider search and category retrieval
- services CRUD operations
- bookings retrieval and mutation
- conversation and message retrieval
- notifications retrieval and mutation
- provider dashboard aggregation and analytics

Integration expectations:

- APIs should expose stable contracts for mobile consumption.
- Client-side mapping should isolate transport models from UI/domain concerns.
- Local caching should be used selectively for resilience and perceived performance.

## 13. UX And Design Direction

- Use a modern, clean, trust-oriented visual language.
- Preserve strong readability with the `Inter` type family.
- Favor structured cards, clear sectioning, and action visibility.
- Use consistent feedback patterns for success, failure, pending, and empty states.
- Ensure discovery, dashboard, and booking flows remain visually coherent.

## 14. Success Metrics

### 14.1 Acquisition And Activation

- onboarding completion rate
- account registration completion rate
- provider profile completion rate

### 14.2 Engagement

- search-to-profile-view rate
- profile-view-to-message rate
- profile-view-to-booking conversion rate
- repeat session rate

### 14.3 Marketplace Health

- bookings created per active customer
- bookings confirmed per provider
- booking completion rate
- cancellation rate
- review submission rate on completed bookings

### 14.4 Communication Effectiveness

- unread message response time
- thread-to-booking conversion rate
- unread notification backlog

### 14.5 Quality And Reliability

- crash-free session rate
- API failure recovery rate
- median home/dashboard load time

## 15. Assumptions

- Users prefer a mobile-first marketplace experience over fragmented messaging and scheduling channels.
- Provider trust indicators materially influence conversion.
- Messaging and booking status visibility reduce drop-off between discovery and fulfillment.
- Category-based browsing remains a major discovery pattern alongside free-text search.

## 16. Risks And Mitigations

### 16.1 Trust Risk

Users may hesitate to book if provider quality signals are weak.

Mitigation:

- strengthen profile completeness
- strengthen verification flow
- expose ratings, reviews, and booking-related trust indicators

### 16.2 Fragmented Role Experience Risk

If provider and customer experiences diverge too sharply, maintenance complexity and UX inconsistency will rise.

Mitigation:

- share navigation, design patterns, and component primitives
- keep role-based logic focused on content and permissions, not entirely separate products

### 16.3 Backend Dependency Risk

Marketplace quality depends heavily on API quality, availability, and consistency.

Mitigation:

- use repository boundaries and transport model isolation
- support caching and graceful fallback states
- define measurable API performance expectations

### 16.4 Conversion Risk

Users may browse but fail to message or book.

Mitigation:

- improve clarity of service data
- surface strong CTAs from profile and service screens
- reduce friction between discovery, messaging, and booking flows

## 17. MVP Definition

The Discovaa MVP should deliver a complete and credible service marketplace loop including:

- role-aware onboarding and authentication
- searchable provider discovery
- provider and service visibility
- direct messaging
- booking creation and booking status tracking
- notifications
- profile management
- basic review/rating capability
- provider/customer dashboard summaries

## 18. Post-MVP Opportunities

- stronger recommendation and personalization systems
- advanced provider verification and compliance workflows
- richer scheduling and availability controls
- payments, escrow, or payout automation
- deeper analytics and provider business intelligence
- location-aware ranking and proximity search
- campaign, promotion, or loyalty mechanics
- multi-provider/team business operations support

## 19. Release Roadmap

### Phase 1: Foundation And Core Architecture

- establish app shell, routing, theme, storage, networking, and dependency management
- define feature-based module structure

### Phase 2: Authentication And Access Control

- onboarding, sign-up, login, OTP, reset flows
- secure session persistence and route protection

### Phase 3: Discovery And Marketplace Browsing

- home experience
- category browsing
- search and sorting
- provider listing and profile discovery

### Phase 4: Services And Provider Readiness

- service creation and editing
- provider profile enrichment
- identification/verification support

### Phase 5: Bookings And Fulfillment Lifecycle

- booking placement
- booking management and status transitions
- review submission on completed work

### Phase 6: Messaging, Notifications, And Retention

- conversation list and chat
- unread state management
- notification center and read management
- favorites and repeat-engagement mechanisms

### Phase 7: Dashboard Intelligence And Optimization

- role-based dashboards
- KPI surfacing and recent activity
- caching, reliability, and UX polish

### Phase 8: Quality, Compliance, And Launch Readiness

- unit, widget, and integration testing
- observability and defect hardening
- store-readiness, release preparation, and rollout controls

## 20. Acceptance Criteria For PRD Alignment

This PRD should be considered aligned when:

- it accurately reflects the current role model and feature modules
- it no longer describes the platform as a Firebase-only application
- it defines both functional and non-functional requirements clearly enough for implementation planning
- it can be used by engineering, QA, design, and product stakeholders as a shared reference
- it distinguishes current scope, MVP expectations, and post-MVP opportunities

## 21. Summary

Discovaa is a trust-first, mobile marketplace for customers and service providers built around discovery, communication, booking, and ongoing relationship management. The product direction should continue to emphasize a reliable cross-role experience, a strong provider-quality signal system, and a connected lifecycle from search through fulfillment and review.
