/// Path names only. Combine with [ApiConfig.uri].
class ApiEndpoints {
  ApiEndpoints._();

  static const String mobilePrefix = '/mobile';

  static const String login = '/mobile/auth/login';
  static const String logout = '/mobile/auth/logout';
  static const String me = '/mobile/auth/me';
  static const String teacherMyTimetable = '/mobile/teachers/my-timetable';
  static const String teacherMyAttendance = '/mobile/teachers/my-attendance';
}
