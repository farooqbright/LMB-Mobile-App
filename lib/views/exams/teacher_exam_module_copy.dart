import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';

class TeacherExamModuleCopy {
  const TeacherExamModuleCopy({
    required this.title,
    required this.heading,
    required this.hint,
    required this.emptyTitle,
    required this.emptyHint,
    required this.datesheetsHint,
    required this.noDatesheets,
    required this.noDatesheetsHint,
    required this.loadError,
    required this.datesheetsError,
    required this.marksError,
    required this.saveError,
    this.listIcon = Icons.quiz_rounded,
    this.emptyIcon = Icons.quiz_outlined,
    this.detailEmptyIcon = Icons.event_note_outlined,
    this.keyPrefix = 'exam',
  });

  final String title;
  final String heading;
  final String hint;
  final String emptyTitle;
  final String emptyHint;
  final String datesheetsHint;
  final String noDatesheets;
  final String noDatesheetsHint;
  final String loadError;
  final String datesheetsError;
  final String marksError;
  final String saveError;
  final IconData listIcon;
  final IconData emptyIcon;
  final IconData detailEmptyIcon;
  final String keyPrefix;

  String sessionKey(int sessionId) => '$keyPrefix-session-$sessionId';

  String examKey(int examId) => '$keyPrefix-$examId';

  String sectionKey(int classId, int sectionId) =>
      '$keyPrefix-class-$classId-section-$sectionId';

  static const exams = TeacherExamModuleCopy(
    title: AppStrings.exams,
    heading: AppStrings.enterExamMarks,
    hint: AppStrings.examsHint,
    emptyTitle: AppStrings.noExams,
    emptyHint: AppStrings.noExamsHint,
    datesheetsHint: AppStrings.examDatesheetsHint,
    noDatesheets: AppStrings.noExamDatesheets,
    noDatesheetsHint: AppStrings.noExamDatesheetsHint,
    loadError: 'Unable to load exams. Please try again.',
    datesheetsError: 'Unable to load exam datesheets. Please try again.',
    marksError: 'Unable to load exam marks. Please try again.',
    saveError: 'Unable to save exam marks. Please try again.',
  );

  static const phaseTests = TeacherExamModuleCopy(
    title: AppStrings.testsAndHw,
    heading: AppStrings.enterPhaseTestMarks,
    hint: AppStrings.testsAndHwHint,
    emptyTitle: AppStrings.noPhaseTests,
    emptyHint: AppStrings.noPhaseTestsHint,
    datesheetsHint: AppStrings.phaseTestDatesheetsHint,
    noDatesheets: AppStrings.noPhaseTestDatesheets,
    noDatesheetsHint: AppStrings.noPhaseTestDatesheetsHint,
    loadError: 'Unable to load phase tests. Please try again.',
    datesheetsError: 'Unable to load phase test datesheets. Please try again.',
    marksError: 'Unable to load phase test marks. Please try again.',
    saveError: 'Unable to save phase test marks. Please try again.',
    listIcon: Icons.assignment_rounded,
    emptyIcon: Icons.assignment_outlined,
    keyPrefix: 'phase-test',
  );
}
