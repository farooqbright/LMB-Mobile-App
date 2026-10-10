/// Path names only. Combine with [ApiConfig.uri].
class ApiEndpoints {
  ApiEndpoints._();

  static const String mobilePrefix = '/mobile';

  static const String login = '/mobile/auth/login';
  static const String changePassword = '/mobile/auth/password';
  static const String logout = '/mobile/auth/logout';
  static const String device = '/mobile/auth/device';
  static const String me = '/mobile/auth/me';
  static const String teacherMyTimetable = '/mobile/teachers/my-timetable';
  static const String teacherAnnouncements = '/mobile/teachers/announcements';
  static const String teacherMyAttendance = '/mobile/teachers/my-attendance';
  static const String teacherMyAttendanceLocation =
      '/mobile/teachers/my-attendance/location';
  static const String teacherMyAttendanceMark = '/mobile/teachers/my-attendance/mark';
  static const String teacherMySalary = '/mobile/teachers/my-salary';
  static const String teacherMySalaryShow = '/mobile/teachers/my-salary/show';
  static const String teacherCurriculumSubjects =
      '/mobile/teachers/curriculum/subjects';
  static const String teacherCurriculumWeeks = '/mobile/teachers/curriculum/weeks';
  static const String teacherCurriculumWeekUpdate =
      '/mobile/teachers/curriculum/weeks/update';
  static const String teacherDailyDiaryClasses = '/mobile/teachers/daily-diary/classes';
  static const String teacherDailyDiarySubjects = '/mobile/teachers/daily-diary/subjects';
  static const String teacherDailyDiaryEntry = '/mobile/teachers/daily-diary/entry';
  static const String teacherDailyDiaryStore = '/mobile/teachers/daily-diary';
  static const String teacherSpecialRemarks =
      '/mobile/teachers/daily-diary/special-remarks';
  static const String teacherSpecialRemarksStore =
      '/mobile/teachers/daily-diary/special-remarks';
  static const String teacherClassAttendanceClasses = '/mobile/teachers/class-attendance/classes';
  static const String teacherClassAttendanceMark = '/mobile/teachers/class-attendance/mark';
  static const String teacherClassAttendanceStore = '/mobile/teachers/class-attendance';
  static const String teacherExams = '/mobile/teachers/exams';
  static const String teacherExamShow = '/mobile/teachers/exams/show';
  static const String teacherExamMarks = '/mobile/teachers/exams/marks';
  static const String teacherExamMarksStore = '/mobile/teachers/exams/marks';
  static const String teacherPhaseTests = '/mobile/teachers/phase-tests';
  static const String teacherPhaseTestShow = '/mobile/teachers/phase-tests/show';
  static const String teacherPhaseTestMarks = '/mobile/teachers/phase-tests/marks';
  static const String teacherPhaseTestMarksStore =
      '/mobile/teachers/phase-tests/marks';
  static const String teacherAssessmentClasses = '/mobile/teachers/assessments/classes';
  static const String teacherAssessmentSubjects = '/mobile/teachers/assessments/subjects';
  static const String teacherAssessmentStore = '/mobile/teachers/assessments';
  static const String teacherAssessmentUpdate = '/mobile/teachers/assessments/update';
  static const String teacherAssessmentDelete = '/mobile/teachers/assessments/delete';
  static const String teacherAssessmentMarks = '/mobile/teachers/assessments/marks';
  static const String teacherAssessmentMarksStore = '/mobile/teachers/assessments/marks';
  static const String parentStudentAttendance = '/mobile/parents/students/attendance';
  static const String parentAnnouncements = '/mobile/parents/announcements';
  static const String parentStudentDailyDiary = '/mobile/parents/students/daily-diary';
  static const String parentStudentSpecialRemarks =
      '/mobile/parents/students/special-remarks';
  static const String parentStudentFeeVouchers = '/mobile/parents/students/fee-vouchers';
  static const String parentStudentTimetable = '/mobile/parents/students/timetable';
}
