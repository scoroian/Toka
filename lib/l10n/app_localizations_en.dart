// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Toka';

  @override
  String get loading => 'Loading...';

  @override
  String get error_generic => 'Something went wrong. Please try again.';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get done => 'Done';

  @override
  String get skip => 'Skip';

  @override
  String get auth_title => 'Welcome to Toka';

  @override
  String get auth_subtitle => 'Manage household tasks together';

  @override
  String get auth_google => 'Continue with Google';

  @override
  String get auth_apple => 'Continue with Apple';

  @override
  String get auth_email => 'Continue with email';

  @override
  String get auth_email_label => 'Email address';

  @override
  String get auth_password_label => 'Password';

  @override
  String get auth_login => 'Sign in';

  @override
  String get auth_register => 'Create account';

  @override
  String get auth_forgot_password => 'Forgot your password?';

  @override
  String get auth_reset_sent =>
      'We have sent you an email to reset your password';

  @override
  String get onboarding_welcome => 'Welcome';

  @override
  String get onboarding_select_language => 'Choose your language';

  @override
  String get onboarding_create_home => 'Create a home';

  @override
  String get onboarding_join_home => 'Join a home';

  @override
  String get onboarding_your_name => 'What is your name?';

  @override
  String get onboarding_photo_optional => 'Add a photo (optional)';

  @override
  String get settings_title => 'Settings';

  @override
  String get settings_language => 'Language';

  @override
  String get settings_account => 'Account';

  @override
  String get settings_privacy => 'Privacy';

  @override
  String get settings_notifications => 'Notifications';

  @override
  String get settings_subscription => 'Subscription';

  @override
  String get settings_logout => 'Sign out';

  @override
  String get language_select_title => 'Select language';

  @override
  String get language_select_subtitle => 'Choose the app language';

  @override
  String get language_saved => 'Language saved';

  @override
  String get auth_or_divider => 'or';

  @override
  String get auth_confirm_password_label => 'Confirm password';

  @override
  String get auth_password_show => 'Show password';

  @override
  String get auth_password_hide => 'Hide password';

  @override
  String get auth_have_account => 'Already have an account? Sign in';

  @override
  String get auth_no_account => 'Don\'t have an account? Create one';

  @override
  String get auth_validation_email_invalid => 'Enter a valid email address';

  @override
  String get auth_validation_password_min_length =>
      'Password must be at least 8 characters';

  @override
  String get auth_validation_passwords_no_match => 'Passwords do not match';

  @override
  String get auth_validation_required => 'This field is required';

  @override
  String get auth_verify_email_title => 'Verify your email';

  @override
  String auth_verify_email_body(String email) {
    return 'We sent a verification link to $email. Check your inbox.';
  }

  @override
  String get auth_resend_email => 'Resend email';

  @override
  String auth_resend_cooldown(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get auth_error_network => 'Network error. Check your connection.';

  @override
  String get auth_error_invalid_credentials => 'Incorrect email or password.';

  @override
  String get auth_error_email_in_use =>
      'An account with this email already exists.';

  @override
  String get auth_error_user_not_found => 'No account with this email.';

  @override
  String get auth_error_weak_password =>
      'Password is too weak. Use at least 8 characters.';

  @override
  String get auth_error_too_many_requests =>
      'Too many attempts. Please try again later.';

  @override
  String get auth_forgot_password_title => 'Reset password';

  @override
  String get auth_forgot_password_body =>
      'Enter your email and we\'ll send you a link to reset your password.';

  @override
  String get auth_send_reset_link => 'Send reset link';

  @override
  String get onboarding_welcome_title => 'Welcome to Toka';

  @override
  String get onboarding_welcome_subtitle =>
      'Your cooperative household task app';

  @override
  String get onboarding_start => 'Get started';

  @override
  String get onboarding_language_title => 'Which language do you prefer?';

  @override
  String get onboarding_profile_title => 'Tell us about you';

  @override
  String get onboarding_nickname_label => 'What do people call you?';

  @override
  String get onboarding_nickname_hint => 'Your nickname';

  @override
  String get onboarding_nickname_required => 'Nickname is required';

  @override
  String get onboarding_nickname_max_length => 'Maximum 30 characters';

  @override
  String get onboarding_phone_label => 'Phone (optional)';

  @override
  String get onboarding_phone_visible_label =>
      'Show my phone to household members';

  @override
  String get onboarding_home_choice_title => 'What would you like to do?';

  @override
  String get onboarding_create_home_description =>
      'Create your home and add your housemates';

  @override
  String get onboarding_join_home_description =>
      'Join a home with an invitation code';

  @override
  String get onboarding_home_name_label => 'Home name';

  @override
  String get onboarding_home_name_hint => 'The García Home';

  @override
  String get onboarding_home_name_required => 'Home name is required';

  @override
  String get onboarding_home_name_max_length => 'Maximum 40 characters';

  @override
  String get onboarding_create_home_button => 'Create home';

  @override
  String get onboarding_invite_code_label => 'Invitation code';

  @override
  String get onboarding_invite_code_hint => '6 characters';

  @override
  String get onboarding_invite_code_length_error => 'Code must be 6 characters';

  @override
  String get onboarding_join_home_button => 'Join';

  @override
  String get onboarding_error_invalid_invite => 'Invalid invitation code';

  @override
  String get onboarding_error_expired_invite => 'Invitation code has expired';

  @override
  String get onboarding_error_no_slots => 'No home slots available';

  @override
  String get onboarding_add_photo => 'Add photo';

  @override
  String get onboarding_change_photo => 'Change photo';

  @override
  String get homes_my_homes => 'My homes';

  @override
  String get homes_selector_title => 'Switch home';

  @override
  String get homes_settings_title => 'Home settings';

  @override
  String get homes_name_label => 'Home name';

  @override
  String get homes_plan_free => 'Free plan';

  @override
  String get homes_plan_premium => 'Premium';

  @override
  String homes_plan_ends(String date) {
    return 'Ends on $date';
  }

  @override
  String get homes_manage_subscription => 'Manage subscription';

  @override
  String get homes_members => 'Members';

  @override
  String get homes_invite_code => 'Invite code';

  @override
  String get homes_generate_code => 'Generate code';

  @override
  String get homes_leave_home => 'Leave home';

  @override
  String get homes_close_home => 'Close home';

  @override
  String get homes_leave_confirm_title => 'Leave home?';

  @override
  String get homes_leave_confirm_body =>
      'You will lose access to this home\'s tasks.';

  @override
  String get homes_close_confirm_title => 'Close home?';

  @override
  String get homes_close_confirm_body =>
      'All tasks and members will be permanently deleted. This cannot be undone.';

  @override
  String get homes_error_cannot_leave_as_owner =>
      'Transfer ownership before leaving the home';

  @override
  String get homes_role_owner => 'Owner';

  @override
  String get homes_role_admin => 'Admin';

  @override
  String get homes_role_member => 'Member';

  @override
  String get homes_pending_tasks_badge => 'You have pending tasks';

  @override
  String get recurrenceHourly => 'Hour';

  @override
  String get recurrenceDaily => 'Day';

  @override
  String get recurrenceWeekly => 'Week';

  @override
  String get recurrenceMonthly => 'Month';

  @override
  String get recurrenceYearly => 'Year';

  @override
  String get today_screen_title => 'Today';

  @override
  String today_tasks_due(int count) {
    return '$count tasks due today';
  }

  @override
  String today_tasks_done_today(int count) {
    return '$count done today';
  }

  @override
  String get today_section_todo => 'To do';

  @override
  String get today_section_done => 'Done';

  @override
  String get today_overdue => 'Overdue';

  @override
  String today_due_today(String time) {
    return 'Today $time';
  }

  @override
  String today_due_weekday(String weekday, String time) {
    return '$weekday $time';
  }

  @override
  String today_done_by(String name, String time) {
    return 'Done by $name at $time';
  }

  @override
  String get today_btn_done => 'Done';

  @override
  String get today_btn_pass => 'Pass';

  @override
  String get today_empty_title => 'No tasks for today';

  @override
  String get today_empty_body => 'All tasks are up to date';

  @override
  String get complete_task_dialog_body =>
      'Confirm you have completed this task?';

  @override
  String get complete_task_confirm_btn => 'Yes, done ✓';

  @override
  String get pass_turn_dialog_title => 'Pass turn?';

  @override
  String pass_turn_compliance_warning(String before, String after) {
    return 'Your compliance will drop from $before% to ~$after%';
  }

  @override
  String pass_turn_next_assignee(String name) {
    return 'Next responsible: $name';
  }

  @override
  String get pass_turn_no_candidate =>
      'No other member available, you will remain responsible';

  @override
  String get pass_turn_reason_hint => 'Reason (optional)';

  @override
  String get pass_turn_confirm_btn => 'Pass turn';

  @override
  String get members_title => 'Members';

  @override
  String get members_invite_fab => 'Invite';

  @override
  String get members_section_active => 'Active';

  @override
  String get members_section_frozen => 'Frozen';

  @override
  String members_pending_tasks(int count) {
    return '$count pending tasks';
  }

  @override
  String members_compliance(String rate) {
    return 'Compliance: $rate%';
  }

  @override
  String get members_role_badge_owner => 'Owner';

  @override
  String get members_role_badge_admin => 'Admin';

  @override
  String get members_role_badge_member => 'Member';

  @override
  String get members_role_badge_frozen => 'Frozen';

  @override
  String get invite_sheet_title => 'Invite member';

  @override
  String get invite_sheet_share_code => 'Share code';

  @override
  String get invite_sheet_by_email => 'Invite by email';

  @override
  String get invite_sheet_code_label => 'Invitation code';

  @override
  String get invite_sheet_email_hint => 'email@example.com';

  @override
  String get invite_sheet_send => 'Send invitation';

  @override
  String get invite_sheet_copy_code => 'Copy code';

  @override
  String get invite_sheet_code_copied => 'Code copied';

  @override
  String get member_profile_home_stats => 'Stats in this home';

  @override
  String get member_profile_tasks_completed => 'Tasks completed';

  @override
  String get member_profile_compliance => 'Compliance';

  @override
  String get member_profile_streak => 'Current streak';

  @override
  String get member_profile_avg_score => 'Average score';

  @override
  String get member_profile_history_30d => 'Last 30 days';

  @override
  String get member_profile_history_90d => 'Last 90 days';

  @override
  String get profile_title => 'My profile';

  @override
  String get profile_edit => 'Edit profile';

  @override
  String get profile_global_stats => 'My global stats';

  @override
  String get profile_per_home_stats => 'Stats by home';

  @override
  String get profile_access_management => 'Manage access';

  @override
  String get profile_linked_providers => 'Linked providers';

  @override
  String get profile_change_password => 'Change password';

  @override
  String get profile_logout => 'Sign out';

  @override
  String get profile_nickname_label => 'Nickname';

  @override
  String get profile_bio_label => 'Bio';

  @override
  String get profile_phone_label => 'Phone';

  @override
  String get profile_phone_visibility_label => 'Show phone to home members';

  @override
  String get profile_saved => 'Profile saved';

  @override
  String get members_error_max_members => 'Home has reached its member limit';

  @override
  String get members_error_max_admins => 'Free plan only allows 1 admin';

  @override
  String get members_error_cannot_remove_owner =>
      'Cannot remove the home owner';

  @override
  String get history_title => 'History';

  @override
  String get history_filter_all => 'All';

  @override
  String get history_filter_completed => 'Completed';

  @override
  String get history_filter_passed => 'Passes';

  @override
  String get history_empty_title => 'No activity yet';

  @override
  String get history_empty_body => 'No events in the history yet';

  @override
  String history_event_completed(String name) {
    return '$name completed';
  }

  @override
  String get history_event_pass_turn => 'turn pass';

  @override
  String history_event_reason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get history_time_now => 'just now';

  @override
  String history_time_minutes_ago(int minutes) {
    return '$minutes min ago';
  }

  @override
  String history_time_hours_ago(int hours) {
    return '$hours h ago';
  }

  @override
  String history_time_days_ago(int days) {
    return '$days days ago';
  }

  @override
  String get history_load_more => 'Load more';

  @override
  String get history_premium_banner_title => 'More history with Premium';

  @override
  String get history_premium_banner_body => 'Access 90 days of history';

  @override
  String get history_premium_banner_cta => 'Upgrade to Premium';

  @override
  String get subscription_premium => 'Premium';

  @override
  String get subscription_free => 'Free';

  @override
  String get subscription_monthly => 'Monthly';

  @override
  String get subscription_annual => 'Annual';

  @override
  String get subscription_price_monthly => '€3.99/month';

  @override
  String get subscription_price_annual => '€29.99/year';

  @override
  String get subscription_annual_saving => 'Save €17.89';

  @override
  String get paywall_title => 'Make your home Premium';

  @override
  String get paywall_subtitle =>
      'Everything you need to manage your home without limits';

  @override
  String get paywall_cta_annual => 'Start Premium Annual';

  @override
  String get paywall_cta_monthly => 'Monthly plan';

  @override
  String get paywall_restore => 'Restore purchases';

  @override
  String get paywall_terms => 'Terms and privacy policy';

  @override
  String get paywall_feature_members => 'Up to 10 members per home';

  @override
  String get paywall_feature_smart => 'Smart task distribution';

  @override
  String get paywall_feature_vacations => 'Vacation mode';

  @override
  String get paywall_feature_reviews => 'Private ratings';

  @override
  String get paywall_feature_history => '90-day history';

  @override
  String get paywall_feature_no_ads => 'No ads';

  @override
  String rescue_banner_text(int days) {
    return 'Premium expires in $days days';
  }

  @override
  String get rescue_banner_renew => 'Renew';

  @override
  String get subscription_management_title => 'Your subscription';

  @override
  String get subscription_status_active => 'Premium active';

  @override
  String subscription_status_cancelled(String date) {
    return 'Cancelled — active until $date';
  }

  @override
  String subscription_status_rescue(int days) {
    return 'Expires in $days days';
  }

  @override
  String get subscription_status_free => 'Free plan';

  @override
  String subscription_status_restorable(String date) {
    return 'Can be restored until $date';
  }

  @override
  String get subscription_restore_btn => 'Restore Premium';

  @override
  String get subscription_restore_success => 'Premium successfully restored';

  @override
  String get subscription_restore_expired_error =>
      'The restore window has expired';

  @override
  String get subscription_plan_downgrade => 'Plan downgrade';

  @override
  String get downgrade_planner_title => 'Plan downgrade';

  @override
  String get downgrade_planner_members_section =>
      'Which members will continue?';

  @override
  String get downgrade_planner_tasks_section => 'Which tasks will continue?';

  @override
  String get downgrade_planner_max_members_hint =>
      'Maximum 3 members (owner always included)';

  @override
  String get downgrade_planner_max_tasks_hint => 'Maximum 4 tasks';

  @override
  String get downgrade_planner_auto_note =>
      'If you don\'t decide, automatic selection will apply';

  @override
  String get downgrade_planner_save => 'Save plan';

  @override
  String get downgrade_planner_saved => 'Downgrade plan saved';

  @override
  String get premium_gate_title => 'Premium Feature';

  @override
  String premium_gate_body(String featureName) {
    return '$featureName requires Premium';
  }

  @override
  String get premium_gate_upgrade => 'Upgrade to Premium';

  @override
  String get rescue_screen_title => 'Renew your Premium';

  @override
  String get rescue_screen_body =>
      'Your Premium subscription is expiring soon. Renew now to keep access to your features.';

  @override
  String get vacation_title => 'Vacation / Absence';

  @override
  String get vacation_toggle_label => 'I\'m on vacation / absent';

  @override
  String get vacation_start_date => 'Start date (optional)';

  @override
  String get vacation_end_date => 'End date (optional)';

  @override
  String get vacation_reason => 'Reason (optional)';

  @override
  String get vacation_save => 'Save changes';

  @override
  String vacation_chip_until(String date) {
    return 'On vacation until $date';
  }

  @override
  String get vacation_chip_indefinite => 'On vacation';

  @override
  String get notification_settings_title => 'Notifications';

  @override
  String get notification_on_due_label => 'Notify when due';

  @override
  String get notification_before_label => 'Notify before due';

  @override
  String get notification_minutes_before_label => 'Lead time';

  @override
  String get notification_daily_summary_label => 'Daily summary';

  @override
  String get notification_summary_time_label => 'Summary time';

  @override
  String get notification_silenced_types_label => 'Silence task types';

  @override
  String get notification_premium_only => 'Premium only';

  @override
  String get notification_15min => '15 minutes';

  @override
  String get notification_30min => '30 minutes';

  @override
  String get notification_1h => '1 hour';

  @override
  String get notification_2h => '2 hours';

  @override
  String get review_dialog_title => 'Rate task';

  @override
  String get review_score_label => 'Score (1-10)';

  @override
  String get review_note_label => 'Private note (optional, max 300 chars)';

  @override
  String get review_submit => 'Submit review';

  @override
  String get review_premium_required => 'Reviews are a Premium feature';

  @override
  String get review_own_task => 'You cannot rate your own tasks';

  @override
  String get radar_chart_title => 'Strengths';

  @override
  String get radar_no_data => 'No ratings yet';

  @override
  String get radar_other_tasks => 'Other rated tasks';

  @override
  String get review_submit_error => 'Error submitting review';
}
