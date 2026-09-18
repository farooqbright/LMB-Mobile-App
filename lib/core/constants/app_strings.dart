class AppStrings {
  AppStrings._();

  static const String appName = 'School LMS';
  static const String appTagline = 'School Management Application';

  static const String skip = 'Skip';
  static const String signIn = 'Sign In';
  static const String usernameLabel = 'Username';
  static const String usernameHint = 'Email or CNIC';
  static const String passwordLabel = 'Password';
  static const String passwordHint = 'Enter password';
  static const String changePassword = 'Change Password';
  static const String currentPasswordLabel = 'Current password';
  static const String newPasswordLabel = 'New password';
  static const String confirmPasswordLabel = 'Confirm new password';
  static const String updatePassword = 'Update Password';
  static const String passwordUpdated = 'Password updated.';
  static const String currentPasswordRequired = 'Current password is required';
  static const String newPasswordRequired = 'New password is required';
  static const String newPasswordMin = 'New password must be at least 8 characters';
  static const String confirmPasswordRequired = 'Confirm your new password';
  static const String passwordsDoNotMatch = 'New password confirmation does not match';
  static const String passwordMustDiffer = 'New password must be different from the current password';
  static const String welcomeBack = 'Welcome back';
  static const String signInSubtitle = 'Sign in to continue to your school';
  static const String schoolHostLabel = 'School address';
  static const String subdomainOption = 'Subdomain';
  static const String domainOption = 'Domain';
  static const String subdomainFieldLabel = 'SubDomain';
  static const String domainFieldLabel = 'Domain';
  static const String signOut = 'Sign out';
  static const String profile = 'Profile';
  static const String home = 'Home';
  static const String menu = 'Menu';
  static const String quickAccess = 'Quick access';
  static const String teacherRole = 'Teacher';
  static const String parentRole = 'Parent';
  static const String teacherDashboardSubtitle =
      'Timetable, attendance, diary and tests for your school.';
  static const String parentDashboardSubtitle =
      'Follow your children\'s attendance, fees, diary and notices.';
  static const String myTimetable = 'My Timetable';
  static const String myAttendance = 'My Attendance';
  static const String attendanceToday = 'Today';
  static const String totalDaysMonth = 'Total';
  static const String presentMonth = 'Present';
  static const String absentMonth = 'Absent';
  static const String lateMonth = 'Late';
  static const String leaveMonth = 'Leave';
  static const String shortLeaveMonth = 'Short leave';
  static const String notMarked = 'Not marked';
  static const String status = 'STATUS';
  static const String allStatuses = 'All';
  static const String fromDate = 'FROM';
  static const String toDate = 'TO';
  static const String filter = 'Filter';
  static const String clearFilters = 'Clear filters';
  static const String inTime = 'IN';
  static const String outTime = 'OUT';
  static const String remarks = 'REMARKS';
  static const String markedBy = 'MARKED BY';
  static const String noAttendance = 'No attendance records found';
  static const String noAttendanceHint =
      'No records for the selected period. Try adjusting the date range or status filter.';
  static const String loadMore = 'Load more';
  static const String noTimetable =
      'No timetable is assigned yet. Ask the branch admin if this looks wrong.';
  static const String retry = 'Try again';
  static const String noInternet = 'No internet connection';
  static const String noInternetHint =
      'Connect to the internet to continue. Actions are unavailable until you are back online.';
  static const String freePeriod = 'Free';
  static const String periodNow = 'Now';
  static const String periodUpNext = 'Up next';
  static const String selectBranch = 'Select your branch';
  static const String dailyDiary = 'Daily Diary';
  static const String myClasses = 'My Classes';
  static const String myClassesHint = 'Classes and subjects from your timetable';
  static const String noDiaryClasses = 'No teaching classes found';
  static const String noDiaryClassesHint =
      'No timetable subjects are assigned for this branch. Ask the branch admin if this looks wrong.';
  static const String addDiary = 'Add Diary';
  static const String noDiarySubjects = 'No teaching subjects found';
  static const String noDiarySubjectsHint =
      'You are not assigned to teach any subject in this class and section.';
  static const String applyToSections = 'Apply to sections';
  static const String applyToSectionsHint =
      'Selected sections get the same diary for this date.';
  static const String diaryDate = 'Date';
  static const String workDone = 'Work Done / Topic Taught';
  static const String workDoneHint = 'What was covered in class today?';
  static const String homework = 'Homework';
  static const String homeworkHint = 'Homework given to students';
  static const String diaryRemarks = 'Remarks';
  static const String remarksHint = 'Optional remarks';
  static const String saveDiary = 'Save Diary';
  static const String selectSectionRequired = 'Select at least one section.';
  static const String classAttendance = 'Class Attendance';
  static const String classAttendanceHint = 'Mark attendance for sections where you are class teacher';
  static const String noClassAttendance = 'No class-teacher sections found';
  static const String noClassAttendanceHint =
      'You are not assigned as class teacher for any section in this branch.';
  static const String attendanceDate = 'Attendance Date';
  static const String markAllPresent = 'Mark all Present';
  static const String markAllAbsent = 'Mark all Absent';
  static const String saveAttendance = 'Save Attendance';
  static const String updateAttendance = 'Update Attendance';
  static const String noClassAttendanceStudents = 'No active students found in this class and section.';
  static const String markedLateByManagement = 'Marked late by management';
  static const String exams = 'Exams';
  static const String enterExamMarks = 'Enter exam marks';
  static const String examsHint =
      'Exams for subjects you teach in this branch';
  static const String noExams = 'No exams to mark';
  static const String noExamsHint =
      'No exam papers are assigned to your timetable subjects for this session.';
  static const String enterMarks = 'Enter marks';
  static const String saveMarks = 'Save Marks';
  static const String examMarksSaved = 'Marks saved.';
  static const String examDatesheetsHint =
      'Open a section to enter marks for the subjects you teach.';
  static const String noExamDatesheets = 'No datesheets found';
  static const String noExamDatesheetsHint =
      'There are no exam papers assigned to you for this exam yet.';
  static const String noExamStudents = 'No active students found in this class and section.';
  static const String subjectTotals = 'Total marks';
  static const String subjectTotalsHint =
      'Set total marks for each subject before saving student scores.';
  static const String totalMarks = 'Total';
  static const String examTotalRequired = 'Enter total marks for every subject before saving.';
  static const String absentShort = 'Abs';
  static const String testsAndHw = 'Tests & HW';
  static const String testsAndHwHint =
      'Add tests and homework for subjects you teach';
  static const String noTestsHwClasses = 'No teaching classes found';
  static const String noTestsHwClassesHint =
      'No timetable subjects are assigned for this branch. Ask the branch admin if this looks wrong.';
  static const String noTestsHwSubjects = 'No teaching subjects found';
  static const String noTestsHwSubjectsHint =
      'You are not assigned to teach any subject in this class and section.';
  static const String chooseSubjectHint = 'Choose a subject to add a test or homework';
  static const String addTest = 'Add Test';
  static const String addHw = 'Add HW';
  static const String savedRecords = 'Saved records';
  static const String savedRecordsHint = 'Tests and homework for this class and section';
  static const String noSavedRecords = 'No tests or homework saved for this class yet.';
  static const String deleteRecord = 'Delete record';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String recordDeleted = 'Record deleted successfully.';
  static const String title = 'Title';
  static const String titleRequired = 'Enter a title.';
  static const String assessmentDate = 'Date';
  static const String dueDate = 'Due date';
  static const String optional = 'Optional';
  static const String totalMarksLabel = 'Total marks';
  static const String description = 'Description';
  static const String descriptionHint = 'Topics covered, instructions…';
  static const String recordSaved = 'Record saved.';
  static const String save = 'Save';
  static const String update = 'Update';
  static const String editRecord = 'Edit record';
}
