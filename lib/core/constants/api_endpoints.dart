/// Path names only. Combine with [ApiConfig.uri].
class ApiEndpoints {
  ApiEndpoints._();

  static const String mobilePrefix = '/mobile';

  static const String login = '/mobile/auth/login';
  static const String changePassword = '/mobile/auth/password';
  static const String logout = '/mobile/auth/logout';
  static const String me = '/mobile/auth/me';
  static const String teacherMyTimetable = '/mobile/teachers/my-timetable';
  static const String teacherMyAttendance = '/mobile/teachers/my-attendance';
  static const String teacherDailyDiaryClasses = '/mobile/teachers/daily-diary/classes';
  static const String teacherDailyDiarySubjects = '/mobile/teachers/daily-diary/subjects';
  static const String teacherDailyDiaryEntry = '/mobile/teachers/daily-diary/entry';
  static const String teacherDailyDiaryStore = '/mobile/teachers/daily-diary';
  static const String teacherClassAttendanceClasses = '/mobile/teachers/class-attendance/classes';
  static const String teacherClassAttendanceMark = '/mobile/teachers/class-attendance/mark';
  static const String teacherClassAttendanceStore = '/mobile/teachers/class-attendance';
  static const String teacherExams = '/mobile/teachers/exams';
  static const String teacherExamShow = '/mobile/teachers/exams/show';
  static const String teacherExamMarks = '/mobile/teachers/exams/marks';
  static const String teacherExamMarksStore = '/mobile/teachers/exams/marks';
  static const String teacherAssessmentClasses = '/mobile/teachers/assessments/classes';
  static const String teacherAssessmentSubjects = '/mobile/teachers/assessments/subjects';
  static const String teacherAssessmentStore = '/mobile/teachers/assessments';
  static const String teacherAssessmentUpdate = '/mobile/teachers/assessments/update';
  static const String teacherAssessmentDelete = '/mobile/teachers/assessments/delete';
  static const String teacherAssessmentMarks = '/mobile/teachers/assessments/marks';
  static const String teacherAssessmentMarksStore = '/mobile/teachers/assessments/marks';
  static const String parentStudentAttendance = '/mobile/parents/students/attendance';
  static const String parentStudentDailyDiary = '/mobile/parents/students/daily-diary';
  static const String parentStudentTimetable = '/mobile/parents/students/timetable';
}
