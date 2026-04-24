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
  String get onboarding_error_network =>
      'No internet connection. Check your network and try again.';

  @override
  String get onboarding_error_unexpected =>
      'An unexpected error occurred. Please try again.';

  @override
  String get onboarding_error_permission_denied =>
      'You don\'t have permission to join this home.';

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
  String get homes_manage_members => 'Manage members';

  @override
  String get homes_payer_info_body =>
      'Your account is paying for this home\'s Premium.';

  @override
  String get homes_payer_info_action => 'Manage in Settings';

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
  String get homes_transfer_ownership_title => 'Transfer home ownership';

  @override
  String get homes_transfer_ownership_body =>
      'To leave the home, select who will become the new owner.';

  @override
  String get homes_transfer_btn => 'Transfer';

  @override
  String get homes_delete_home_title => 'Delete home';

  @override
  String get homes_delete_home_body_sole =>
      'You are the only member. Leaving will permanently delete the home and it cannot be recovered.';

  @override
  String get homes_delete_btn => 'Delete';

  @override
  String get homes_frozen_only_title => 'Leave home';

  @override
  String get homes_frozen_only_body =>
      'There are only frozen members. You can transfer ownership to one of them or permanently delete the home.';

  @override
  String get homes_role_owner => 'Owner';

  @override
  String get homes_role_admin => 'Admin';

  @override
  String get homes_role_member => 'Member';

  @override
  String get homes_pending_tasks_badge => 'You have pending tasks';

  @override
  String get homes_add_home => 'Add home';

  @override
  String get homes_add_create => 'Create a home';

  @override
  String get homes_add_join => 'Join a home';

  @override
  String get homes_add_join_by_code => 'Enter code';

  @override
  String get homes_add_join_by_qr => 'Scan QR';

  @override
  String get homes_create_name_hint => 'Home name';

  @override
  String get homes_create_button => 'Create';

  @override
  String get homes_join_code_title => 'Join with code';

  @override
  String get homes_join_button => 'Join';

  @override
  String get homes_max_reached_title => 'Home limit reached';

  @override
  String get homes_max_reached_body =>
      'You are already in the maximum of 5 homes.';

  @override
  String get homes_upgrade_title => 'Want another home?';

  @override
  String get homes_upgrade_body =>
      'Subscribe to Premium to unlock an additional slot.';

  @override
  String get homes_upgrade_button => 'See plans';

  @override
  String get homes_error_no_slots => 'No available slots';

  @override
  String get homes_error_invalid_code => 'Invalid code';

  @override
  String get homes_error_expired_code => 'The code has expired';

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
  String today_hecho_not_yet(String date) {
    return 'The \'\'Done\'\' button will be active on $date';
  }

  @override
  String get today_empty_title => 'No tasks for today';

  @override
  String get today_empty_body => 'All tasks are up to date';

  @override
  String get today_no_home_title => 'No home';

  @override
  String get today_no_home_body =>
      'Create a home or join one to start managing tasks';

  @override
  String get history_no_home_title => 'No history';

  @override
  String get history_no_home_body =>
      'Create or join a home to see your history';

  @override
  String get tasks_no_home_title => 'No tasks';

  @override
  String get tasks_no_home_body => 'Create or join a home to manage your tasks';

  @override
  String get members_no_home_title => 'No members';

  @override
  String get members_no_home_body => 'Create or join a home to see its members';

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
  String get pass_turn_minimal_impact =>
      'The impact on your compliance will be minimal.';

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
  String get invite_sheet_scan_qr => 'Scan QR';

  @override
  String get invite_sheet_qr_hint => 'Point the camera at the QR code';

  @override
  String get invite_sheet_code_copied => 'Code copied';

  @override
  String invite_code_expires_at(String date) {
    return 'Expires on $date';
  }

  @override
  String get invite_code_regenerate => 'Regenerate code';

  @override
  String get invite_code_expired_error =>
      'This code has expired. The owner must generate a new one.';

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
  String get member_profile_promote_admin => 'Make admin';

  @override
  String get member_profile_demote_admin => 'Remove admin';

  @override
  String member_profile_promote_admin_confirm(String name) {
    return 'Make $name an administrator of this home?';
  }

  @override
  String member_profile_demote_admin_confirm(String name) {
    return 'Remove admin role from $name?';
  }

  @override
  String get member_profile_promoted_ok => 'Member promoted to admin';

  @override
  String get member_profile_demoted_ok => 'Admin demoted to member';

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
  String get members_error_payer_locked =>
      'You cannot be removed or leave while you are the active Premium payer. Cancel the subscription first or wait for it to expire.';

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
  String rescue_banner_title(int days) {
    return 'Your Premium expires in $days days — renew to keep your features';
  }

  @override
  String get rescue_banner_last_day =>
      'Your Premium expires today. Renew before midnight.';

  @override
  String rescue_banner_hours_left(int hours) {
    return '$hours hours left';
  }

  @override
  String get rescue_last_billing_error_title => 'Last billing attempt';

  @override
  String cancelled_ends_banner_title(String date) {
    return 'Won\'t renew after $date. You can reactivate any time.';
  }

  @override
  String get cancelled_ends_banner_cta => 'Reactivate renewal';

  @override
  String expired_free_banner_title(String date) {
    return 'Your Premium expired on $date. Reactivate whenever you want.';
  }

  @override
  String get expired_free_banner_cta => 'Reactivate Premium';

  @override
  String restorable_banner_title(String date) {
    return 'You can restore your Premium until $date';
  }

  @override
  String get restorable_banner_cta => 'Restore';

  @override
  String get paywall_title_from_expired => 'Reactivate Premium';

  @override
  String paywall_subtitle_from_expired(String date) {
    return 'Your Premium expired on $date. Reactivate whenever you want.';
  }

  @override
  String get paywall_title_from_rescue => 'Renew before losing your features';

  @override
  String paywall_subtitle_from_rescue(int days) {
    return '$days days left to renew.';
  }

  @override
  String get paywall_title_from_restorable => 'Restore your Premium';

  @override
  String paywall_subtitle_from_restorable(int days) {
    return '$days days left in the restoration window.';
  }

  @override
  String get paywall_cta_reactivate => 'Reactivate Premium';

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
  String get subscription_free_benefits_title => 'Unlock with Premium';

  @override
  String subscription_counter_members(int used, int max) {
    return '$used/$max members';
  }

  @override
  String subscription_counter_tasks(int used, int max) {
    return '$used/$max automatic tasks';
  }

  @override
  String subscription_next_renewal(String date) {
    return 'Next renewal: $date';
  }

  @override
  String get subscription_no_auto_renew => 'Will not renew automatically';

  @override
  String subscription_premium_until(String date) {
    return 'Premium until $date';
  }

  @override
  String subscription_expired_on(String date) {
    return 'Premium expired on $date';
  }

  @override
  String subscription_restorable_until(String date, int days) {
    return 'You can restore Premium until $date ($days days left)';
  }

  @override
  String subscription_rescue_warning(int days) {
    return 'Your Premium expires in $days days — renew to keep your features';
  }

  @override
  String get subscription_manage_billing => 'Manage billing';

  @override
  String get subscription_cancel_renewal => 'Cancel renewal';

  @override
  String get subscription_reactivate_renewal => 'Reactivate renewal';

  @override
  String get subscription_change_plan => 'Change plan';

  @override
  String get subscription_reactivate_premium => 'Reactivate Premium';

  @override
  String get subscription_payer_label => 'Payer';

  @override
  String get subscription_payer_you => 'you';

  @override
  String get subscription_payer_other => 'another member';

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

  @override
  String get settings_section_account => 'Account';

  @override
  String get settings_edit_profile => 'Edit profile';

  @override
  String get settings_change_password => 'Change password';

  @override
  String get settings_delete_account => 'Delete account';

  @override
  String get settings_section_language => 'Language';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme_light => 'Light';

  @override
  String get theme_dark => 'Dark';

  @override
  String get theme_system => 'System';

  @override
  String get settings_section_notifications => 'Notifications';

  @override
  String get settings_section_privacy => 'Privacy';

  @override
  String get settings_phone_visibility => 'Phone visibility';

  @override
  String get settings_section_subscription => 'Subscription';

  @override
  String get settings_view_plan => 'View current plan';

  @override
  String get settings_restore_purchases => 'Restore purchases';

  @override
  String get settings_manage_subscription => 'Manage subscription';

  @override
  String get settings_section_home => 'Home';

  @override
  String get settings_home_settings => 'Home settings';

  @override
  String get settings_invite_code => 'Invite code';

  @override
  String get settings_leave_home => 'Leave home';

  @override
  String get settings_close_home => 'Close home';

  @override
  String get settings_section_about => 'About';

  @override
  String get settings_app_version => 'App version';

  @override
  String get settings_terms => 'Terms of use';

  @override
  String get settings_privacy_policy => 'Privacy policy';

  @override
  String get settings_sign_out => 'Sign out';

  @override
  String get settings_sign_out_confirm => 'Sign out?';

  @override
  String get settings_plan_free => 'Free plan';

  @override
  String get settings_plan_premium => 'Premium plan';

  @override
  String get tasks_title => 'Tasks';

  @override
  String get tasks_empty_title => 'No tasks';

  @override
  String get tasks_empty_body => 'Create your first task to get started';

  @override
  String get tasks_empty_cta => 'Create first task';

  @override
  String get tasks_create_title => 'Create task';

  @override
  String get tasks_edit_title => 'Edit task';

  @override
  String get tasks_field_visual => 'Icon or emoji';

  @override
  String get tasks_field_title_hint => 'E.g.: Do the dishes';

  @override
  String get tasks_field_description_hint => 'Description (optional)';

  @override
  String get tasks_field_recurrence => 'Recurrence';

  @override
  String get tasks_field_assignment_mode => 'Assignment mode';

  @override
  String get tasks_field_difficulty => 'Difficulty';

  @override
  String get tasks_assignment_basic_rotation => 'Basic rotation';

  @override
  String get tasks_assignment_smart => 'Smart distribution';

  @override
  String get tasks_assignment_members => 'Assigned members';

  @override
  String get tasks_recurrence_every => 'Every';

  @override
  String get tasks_recurrence_hours => 'hours';

  @override
  String get tasks_recurrence_days => 'days';

  @override
  String get tasks_recurrence_start_time => 'Start time';

  @override
  String get tasks_recurrence_end_time => 'End time (optional)';

  @override
  String get tasks_recurrence_time => 'Time';

  @override
  String get tasks_recurrence_day_of_month => 'Day of month';

  @override
  String get tasks_recurrence_week_of_month => 'Week of month';

  @override
  String get tasks_recurrence_weekday => 'Weekday';

  @override
  String get tasks_recurrence_month => 'Month';

  @override
  String get tasks_recurrence_timezone => 'Timezone';

  @override
  String get tasks_recurrence_upcoming => 'Upcoming dates';

  @override
  String get tasks_recurrence_hourly_label => 'Hourly';

  @override
  String get tasks_recurrence_daily_label => 'Daily';

  @override
  String get tasks_recurrence_weekly_label => 'Weekly';

  @override
  String get tasks_recurrence_monthly_fixed_label => 'Monthly (fixed day)';

  @override
  String get tasks_recurrence_monthly_nth_label => 'Monthly (Nth week)';

  @override
  String get tasks_recurrence_yearly_fixed_label => 'Yearly (fixed date)';

  @override
  String get tasks_recurrence_yearly_nth_label => 'Yearly (Nth week)';

  @override
  String get tasks_section_active => 'Active';

  @override
  String get tasks_section_frozen => 'Frozen';

  @override
  String get tasks_status_frozen => 'Frozen';

  @override
  String get tasks_action_edit => 'Edit';

  @override
  String get tasks_action_freeze => 'Freeze';

  @override
  String get tasks_action_unfreeze => 'Unfreeze';

  @override
  String get tasks_action_delete => 'Delete';

  @override
  String get tasks_delete_confirm_title => 'Delete task?';

  @override
  String get tasks_delete_confirm_body => 'This action cannot be undone.';

  @override
  String get tasks_delete_confirm_btn => 'Yes, delete';

  @override
  String get tasks_freeze_success => 'Task frozen';

  @override
  String get tasks_unfreeze_success => 'Task activated';

  @override
  String get tasks_save_error => 'Error saving task';

  @override
  String get tasks_detail_next_occurrences => 'Upcoming dates';

  @override
  String get tasks_detail_assignment_order => 'Assignment order';

  @override
  String get tasks_validation_title_empty => 'Title is required';

  @override
  String get tasks_validation_title_too_long => 'Maximum 60 characters';

  @override
  String get tasks_validation_no_assignees => 'Select at least one member';

  @override
  String get tasks_validation_difficulty_range =>
      'Weight must be between 0.5 and 3.0';

  @override
  String get tasks_validation_recurrence_required => 'Choose a recurrence type';

  @override
  String get weekday_mon => 'Monday';

  @override
  String get weekday_tue => 'Tuesday';

  @override
  String get weekday_wed => 'Wednesday';

  @override
  String get weekday_thu => 'Thursday';

  @override
  String get weekday_fri => 'Friday';

  @override
  String get weekday_sat => 'Saturday';

  @override
  String get weekday_sun => 'Sunday';

  @override
  String get tasks_week_1st => 'First';

  @override
  String get tasks_week_2nd => 'Second';

  @override
  String get tasks_week_3rd => 'Third';

  @override
  String get tasks_week_4th => 'Fourth';

  @override
  String get month_jan => 'January';

  @override
  String get month_feb => 'February';

  @override
  String get month_mar => 'March';

  @override
  String get month_apr => 'April';

  @override
  String get month_may => 'May';

  @override
  String get month_jun => 'June';

  @override
  String get month_jul => 'July';

  @override
  String get month_aug => 'August';

  @override
  String get month_sep => 'September';

  @override
  String get month_oct => 'October';

  @override
  String get month_nov => 'November';

  @override
  String get month_dec => 'December';

  @override
  String tasks_selection_count(int count) {
    return '$count selected';
  }

  @override
  String get tasks_bulk_freeze => 'Freeze';

  @override
  String get tasks_bulk_delete => 'Delete';

  @override
  String tasks_bulk_delete_confirm_title(int count) {
    return 'Delete $count tasks?';
  }

  @override
  String get tasks_bulk_delete_confirm_body => 'This action cannot be undone.';

  @override
  String get history_rate_button => 'Rate';

  @override
  String get history_rate_sheet_title => 'Rate task';

  @override
  String history_rate_score_label(String score) {
    return 'Score: $score';
  }

  @override
  String get history_rate_note_hint => 'Private note (optional)';

  @override
  String get history_rate_submit => 'Submit rating';

  @override
  String get member_profile_overflow_tasks_title => 'More assigned tasks';

  @override
  String get member_profile_manage_role => 'Manage role';

  @override
  String get member_profile_role_manage_unavailable =>
      'Role management coming soon';

  @override
  String get today_home_selector_create => 'Create home';

  @override
  String get today_home_selector_join => 'Join with code';

  @override
  String get today_home_selector_my_homes => 'My homes';

  @override
  String get tasks_fixed_time_label => 'Fixed time';

  @override
  String get tasks_fixed_time_pick => 'Pick time';

  @override
  String get tasks_apply_today_label => 'Create occurrence for today';

  @override
  String get tasks_upcoming_preview_title => 'Next 3 dates';

  @override
  String tasks_upcoming_preview_assignee(String name) {
    return '→ $name';
  }

  @override
  String get tasks_assignment_drag_hint => 'Drag to reorder';

  @override
  String history_event_missed(String name) {
    return '$name didn\'t complete';
  }

  @override
  String get history_filter_missed => 'Missed';

  @override
  String get task_on_miss_label => 'If it expires incomplete';

  @override
  String get task_on_miss_same_assignee => 'Keep assignee';

  @override
  String get task_on_miss_next_rotation => 'Rotate to next';

  @override
  String get tasks_rotation_requires_two_members =>
      'Rotation requires at least 2 members';

  @override
  String get task_detail_assignee => 'Assignee';

  @override
  String get task_detail_next_due => 'Next due';

  @override
  String get task_detail_difficulty => 'Difficulty';

  @override
  String get task_detail_upcoming => 'Upcoming dates';

  @override
  String get editTask => 'Edit task';

  @override
  String get settings_delete_account_confirm_title => 'Delete account?';

  @override
  String get settings_delete_account_confirm_body =>
      'This action is permanent and irreversible. You will lose access to all your homes and data.';

  @override
  String get settings_delete_requires_reauth =>
      'For security, please sign out and sign in again before deleting your account.';

  @override
  String get member_profile_remove_member => 'Remove from home';

  @override
  String member_profile_remove_member_confirm(String name) {
    return 'Remove $name from this home? This action cannot be undone.';
  }

  @override
  String get error_cannot_remove_owner => 'The home owner cannot be removed.';

  @override
  String get free_limit_members_reached =>
      'Your Free plan allows up to 3 members. Go Premium to add more.';

  @override
  String get free_limit_tasks_reached =>
      'Your Free plan allows up to 4 active tasks.';

  @override
  String get free_limit_recurring_reached =>
      'Your Free plan allows up to 3 recurring tasks. Create a one-time task or go Premium.';

  @override
  String get free_admins_locked_to_owner =>
      'Admin roles are available on Premium.';

  @override
  String get free_reviews_disabled => 'Reviews are available on Premium.';

  @override
  String get free_reviews_upgrade_title => 'Reviews only on Premium';

  @override
  String get free_reviews_upgrade_body =>
      'Upgrade to Premium to rate the tasks completed by other home members.';

  @override
  String get free_go_premium_cta => 'Go Premium';

  @override
  String free_members_counter(int current, int limit) {
    return '$current / $limit members — Free plan limit';
  }

  @override
  String get free_unfreeze_blocked_title => 'Task limit reached';

  @override
  String free_unfreeze_blocked_body(int current, int limit) {
    return 'You already have $current of $limit active tasks on your Free plan. Freeze another task before unfreezing this one, or go Premium to have more active tasks.';
  }

  @override
  String get free_unfreeze_blocked_understood => 'Got it';

  @override
  String get recurrence_one_time => 'One-time';

  @override
  String get recurrence_one_time_help =>
      'Completed only once and disappears from the list.';

  @override
  String get notifRationaleTitle =>
      'Toka will only ping you about what matters';

  @override
  String get notifRationaleBullet1 => 'New tasks assigned to you';

  @override
  String get notifRationaleBullet2 => 'Turn changes';

  @override
  String get notifRationaleBullet3 => 'Reviews you receive';

  @override
  String get notifRationaleCtaEnable => 'Enable notifications';

  @override
  String get notifRationaleCtaLater => 'Not now';

  @override
  String get notifSystemBlockedBanner =>
      'Notifications are blocked by the system. Enable permissions in Android settings to receive Toka alerts.';

  @override
  String get notifSystemBlockedAction => 'Open settings';

  @override
  String get notifTestSectionTitle => 'Test notifications';

  @override
  String get notifTestSectionHint =>
      'Send a sample of each type to preview how they look.';

  @override
  String get notifTestDeadline => 'Test \"Task due soon\"';

  @override
  String get notifTestAssignment => 'Test \"Task assigned\"';

  @override
  String get notifTestReminder => 'Test \"Reminder\"';

  @override
  String get notifTestDailySummary => 'Test \"Daily summary\"';

  @override
  String get notifTestFeedback => 'Test \"Feedback received\"';

  @override
  String get notifTestRotation => 'Test \"Rotation change\"';

  @override
  String get notifTestSent => 'Test notification sent';

  @override
  String get historyEventDetailTitle => 'Event detail';

  @override
  String get historyEventUnknownMember => 'unknown member';

  @override
  String get noReviewsOnEvent => 'No reviews yet for this event';

  @override
  String reviewByLabel(String name) {
    return 'Review by $name';
  }

  @override
  String get reviewPrivateNoteLabel => 'Private note';

  @override
  String reviewPrivateNoteHint(String name) {
    return 'Only you and $name can see this note';
  }

  @override
  String get memberProfileLastReviews => 'Latest reviews';

  @override
  String daysUntil(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'in $count days',
      one: 'in 1 day',
      zero: 'today',
    );
    return '$_temp0';
  }

  @override
  String tasksActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count active tasks',
      one: '1 active task',
      zero: 'no active tasks',
    );
    return '$_temp0';
  }

  @override
  String membersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
      zero: 'no members',
    );
    return '$_temp0';
  }

  @override
  String daysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days left',
      one: '1 day left',
      zero: 'last day',
    );
    return '$_temp0';
  }

  @override
  String reviewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews',
      one: '1 review',
      zero: 'no reviews',
    );
    return '$_temp0';
  }
}
