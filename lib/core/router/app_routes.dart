/// Defines all application navigation routes, paths, and names for GoRouter.
enum AppRoute {
  /// Main dashboard overview screen route.
  overview('/', 'overview'),

  /// Interactive calendar screen route.
  calendar('/calendar', 'calendar'),

  /// Health measurements history list route.
  history('/history', 'history'),

  /// User profile and application settings route.
  settings('/settings', 'settings'),

  /// Open-source licenses screen route.
  licenses('licenses', 'licenses'),

  /// Privacy policy screen route.
  privacyPolicy('privacy-policy', 'privacy_policy'),

  /// Route to add a new blood glucose reading.
  addGlucose('/glucose/add', 'add_glucose'),

  /// Route to edit an existing blood glucose reading with path parameter id.
  editGlucose('/glucose/edit/:id', 'edit_glucose'),

  /// Route to synchronize readings with a Bluetooth LE glucometer.
  bleGlucoseSync('/glucose/sync', 'ble_glucose_sync'),

  /// Route to add a new HbA1c reading.
  addHba1c('/hba1c/add', 'add_hba1c'),

  /// Route to edit an existing HbA1c reading with path parameter id.
  editHba1c('/hba1c/edit/:id', 'edit_hba1c'),

  /// Route to add a new blood pressure reading.
  addBloodPressure('/blood-pressure/add', 'add_blood_pressure'),

  /// Route to edit an existing blood pressure reading with path parameter id.
  editBloodPressure('/blood-pressure/edit/:id', 'edit_blood_pressure'),

  /// Route to add a new ketone reading.
  addKetones('/ketones/add', 'add_ketones'),

  /// Route to edit an existing ketone reading with path parameter id.
  editKetones('/ketones/edit/:id', 'edit_ketones'),

  /// Route to add a new cholesterol reading.
  addCholesterol('/cholesterol/add', 'add_cholesterol'),

  /// Route to edit an existing cholesterol reading with path parameter id.
  editCholesterol('/cholesterol/edit/:id', 'edit_cholesterol'),

  /// Route to add a new weight reading.
  addWeight('/weight/add', 'add_weight'),

  /// Route to edit an existing weight reading with path parameter id.
  editWeight('/weight/edit/:id', 'edit_weight'),

  /// Route for the first-run onboarding wizard.
  onboarding('/onboarding', 'onboarding'),

  /// Route to view and manage scheduled measurement reminders.
  reminders('/reminders', 'reminders'),

  /// Route for exporting health measurement data.
  export('/export', 'export'),

  /// Route for the standalone HbA1c conversion calculator utility.
  hba1cCalculator('/hba1c-calculator', 'hba1c_calculator'),

  /// Fallback route shown when the user profile cannot load at startup.
  startupError('/startup-error', 'startup_error');

  const AppRoute(this.path, this.name);

  /// The URL path template for the route.
  final String path;

  /// The unique identifier name for named navigation.
  final String name;
}
