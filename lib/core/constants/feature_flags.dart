/// Feature flags for milestone-based feature visibility
/// 
/// Set flags to true/false to control which features are visible
/// based on the current milestone being presented.
/// 
/// Milestone 1: All flags set to false
/// Milestone 2: M2 flags set to true, M3 flags set to false
/// Milestone 3: All flags set to true
class FeatureFlags {
  // Milestone 2 Features
  static bool enableMessaging = true;
  static bool enablePayments = false;
  static bool enableEmailAlerts = false;
  
  // Milestone 3 Features
  static bool enableDashboard = true;
  static bool enableSupportFeatures = false;
  static bool enableLanguageOptions = false;
  
  /// Set all flags for Milestone 1 presentation
  static void setMilestone1() {
    enableMessaging = false;
    enablePayments = false;
    enableEmailAlerts = false;
    enableDashboard = false;
    enableSupportFeatures = false;
    enableLanguageOptions = false;
  }
  
  /// Set all flags for Milestone 2 presentation
  static void setMilestone2() {
    enableMessaging = true;
    enablePayments = false;
    enableEmailAlerts = false;
    enableDashboard = false;
    enableSupportFeatures = false;
    enableLanguageOptions = false;
  }
  
  /// Set all flags for Milestone 3 presentation (full app)
  static void setMilestone3() {
    enableMessaging = true;
    enablePayments = false; // Still incomplete
    enableEmailAlerts = false; // Still incomplete
    enableDashboard = true;
    enableSupportFeatures = false; // Still incomplete
    enableLanguageOptions = false; // Not implemented
  }
}
