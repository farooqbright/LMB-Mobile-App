import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import 'teacher_exam_service.dart';

class TeacherPhaseTestService extends TeacherExamService {
  TeacherPhaseTestService({ApiClient? client})
      : super(
          client: client,
          listPath: ApiEndpoints.teacherPhaseTests,
          showPath: ApiEndpoints.teacherPhaseTestShow,
          marksPath: ApiEndpoints.teacherPhaseTestMarks,
          marksStorePath: ApiEndpoints.teacherPhaseTestMarksStore,
          idKey: 'phase_exam_id',
          missingBranchMessage: 'Select a branch to enter phase test marks.',
          unexpectedResponseMessage: 'Unexpected phase test response.',
        );
}
