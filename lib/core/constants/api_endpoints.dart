class ApiEndpoints {
  // Base URL
  static const String baseUrl =
      'https://p01--discovaa-app--492q2z77g54x.code.run';

  // ============================================================================
  // OPENAPI AUTHENTICATION ENDPOINTS
  // Headless API for Flutter app client
  // Base: /api/identity/app/v1
  // ============================================================================

  // Auth Core
  static const String authLogin = '/api/identity/app/v1/auth/login';
  static const String authSignup = '/api/identity/app/v1/auth/signup';
  static const String authSession = '/api/identity/app/v1/auth/session';
  static const String authLogout = '/api/identity/app/v1/auth/session';
  static const String authCurrentUser = '/api/identity/app/v1/auth/session';

  // Email Verification
  static const String authEmailVerify =
      '/api/identity/app/v1/auth/email/verify';
  static const String authEmailVerifyResend =
      '/api/identity/app/v1/auth/email/verify/resend';

  // Password Management
  static const String authPasswordRequest =
      '/api/identity/app/v1/auth/password/request';
  static const String authPasswordReset =
      '/api/identity/app/v1/auth/password/reset';
  static const String authPasswordChange =
      '/api/identity/app/v1/account/password/change';

  // Token Management
  static const String tokensRefresh = '/api/identity/app/v1/tokens/refresh';

  // ============================================================================
  // LEGACY AUTH ENDPOINTS (commented out - replaced by OpenAPI endpoints above)
  // ============================================================================
  // static const String register = '/auth/register';  // Use authSignup
  // static const String login = '/auth/login';  // Use authLogin
  // static const String logout = '/auth/logout';  // Use authLogout (DELETE)
  // static const String refreshToken = '/auth/refresh';  // Use tokensRefresh
  // static const String forgotPassword = '/auth/forgot-password';  // Use authPasswordRequest
  // static const String resetPassword = '/auth/reset-password';  // Use authPasswordReset
  // static const String verifyEmail = '/auth/verify-email';  // Use authEmailVerify
  // static const String resendVerification = '/auth/resend-verification';  // Use authEmailVerifyResend
  // static const String verifyOtp = '/auth/verify-otp';  // Use authEmailVerify
  // static const String resendOtp = '/auth/resend-otp';  // Use authEmailVerifyResend
  // static const String completeProfile = '/auth/complete-profile';  // Not needed in OpenAPI
  // static const String currentUser = '/auth/me';  // Use authCurrentUser (GET)

  // ============================================================================
  // OPENAPI-BACKED RESOURCE ENDPOINTS
  // These align with the Discovaa API.yaml specification and use /api/* paths.
  // They follow the standard response envelope pattern with {success, data, meta, error}.
  // ============================================================================
  // OpenAPI-backed current app scope
  static const String accountsMe = '/api/accounts/me/';
  static const String accountsMeLocation = '/api/accounts/me/location/';
  static const String accountsMeProfilePhoto =
      '/api/accounts/me/profile-photo/';

  static const String providers = '/api/providers/';
  static const String providersMeProfile = '/api/providers/me/profile/';
  static const String providersMeCompleteProfile =
      '/api/providers/me/complete-profile/';
  static const String providersMeDashboard = '/api/providers/me/dashboard/';
  static const String providersMeProviderPhoto =
      '/api/providers/me/provider-photo/';

  static const String providerLocations = '/api/provider-locations/';
  static const String providerCertifications = '/api/provider-certifications/';
  static const String providerAvailabilityRules =
      '/api/provider-availability-rules/';

  static const String serviceCategories = '/api/service-categories/';
  static const String services = '/api/services/';
  static const String servicesFeatured = '/api/services/featured/';
  static const String serviceMedia = '/api/service-media/';

  static const String bookings = '/api/bookings/';
  static const String bookingItems = '/api/booking-items/';

  static String bookingDetail(String id) => '/api/bookings/$id/';
  static String bookingConfirm(String id) => '/api/bookings/$id/confirm/';
  static String bookingCancel(String id) => '/api/bookings/$id/cancel/';
  static String bookingComplete(String id) => '/api/bookings/$id/complete/';
  static String bookingCharge(String id) => '/api/bookings/$id/charge/';

  static const String messageThreads = '/api/message-threads/';
  static const String messagesV1 = '/api/messages/';
  static String threadDetail(String id) => '/api/message-threads/$id/';
  static String threadMarkRead(String id) =>
      '/api/message-threads/$id/mark_read/';

  static const String notificationsV1 = '/api/notifications/';
  static String notificationDetail(String id) => '/api/notifications/$id/';
  static String notificationMarkRead(String id) =>
      '/api/notifications/$id/mark_read/';
  static const String notificationsMarkAllRead =
      '/api/notifications/mark_all_read/';

  static const String reviewsV1 = '/api/reviews/';

  static const String payments = '/api/payments/';
  static const String paymentsEnsure = '/api/payments/ensure/';
  static const String payoutAccount = '/api/payments/payout-account/';
  static const String payoutAccountBalance =
      '/api/payments/payout-account/balance/';
  static const String payoutAccountResumeOnboarding =
      '/api/payments/payout-account/resume-onboarding/';
  static const String payoutAccountSetup =
      '/api/payments/payout-account/setup/';
  static const String payoutAccountUpdate =
      '/api/payments/payout-account/update/';
  static const String payouts = '/api/payments/payouts/';
  static const String payoutsBalance = '/api/payments/payouts/balance/';
  static const String payoutsBalanceSummary =
      '/api/payments/payouts/balance-summary/';

  // User Profile
  static const String userProfile = '/user/profile';
  static const String updateProfile = '/user/profile';
  static const String uploadAvatar = '/user/avatar';
  static const String deleteAccount = '/user/account';

  // Artisan Profile
  static const String artisanProfile = '/artisan/profile';
  static const String updateArtisanProfile = '/artisan/profile';
  static const String artisanPortfolio = '/artisan/portfolio';
  static const String addPortfolioItem = '/artisan/portfolio';
  static const String updatePortfolioItem = '/artisan/portfolio';
  static const String deletePortfolioItem = '/artisan/portfolio';
  static const String artisanServices = '/artisan/services';
  static const String updateServices = '/artisan/services';

  // Jobs
  static const String jobs = '/jobs';
  static const String jobDetail = '/jobs';
  static const String postJob = '/jobs';
  static const String updateJob = '/jobs';
  static const String deleteJob = '/jobs';
  static const String applyJob = '/jobs/apply';
  static const String jobApplications = '/jobs/applications';
  static const String myJobs = '/jobs/my';
  static const String savedJobs = '/jobs/saved';

  // Job Categories
  static const String categories = '/categories';
  static const String subcategories = '/categories/subcategories';

  // Search
  static const String searchArtisans = '/search/artisans';
  static const String searchJobs = '/search/jobs';
  static const String popularSearches = '/search/popular';
  static const String searchSuggestions = '/search/suggestions';

  // Messaging
  static const String conversations = '/conversations';
  static const String conversationDetail = '/conversations';
  static const String messages = '/conversations/messages';
  static const String sendMessage = '/conversations/messages';
  static const String markAsRead = '/conversations/read';
  static const String deleteMessage = '/conversations/messages';

  // Reviews
  static const String reviews = '/reviews';
  static const String submitReview = '/reviews';
  static const String updateReview = '/reviews';
  static const String deleteReview = '/reviews';
  static const String userReviews = '/reviews/user';
  static const String artisanReviews = '/reviews/artisan';

  // Notifications
  static const String notifications = '/notifications';
  static const String markNotificationRead = '/notifications/read';
  static const String notificationSettings = '/notifications/settings';
  static const String updateNotificationSettings = '/notifications/settings';

  // File Upload
  static const String uploadFile = '/upload';
  static const String deleteFile = '/upload';

  // Analytics
  static const String analytics = '/analytics';
  static const String profileViews = '/analytics/profile-views';
  static const String jobStats = '/analytics/jobs';

  // Support
  static const String contactSupport = '/support/contact';
  static const String faq = '/support/faq';
  static const String reportIssue = '/support/report';

  // Settings
  static const String settings = '/settings';
  static const String updateSettings = '/settings';
  static const String privacySettings = '/settings/privacy';
  static const String notificationSettingsEndpoint = '/settings/notifications';

  // Device Tokens
  static const String deviceTokensRegister = '/api/device-tokens/register/';
}
