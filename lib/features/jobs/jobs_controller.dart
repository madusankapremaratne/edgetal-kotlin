import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/job.dart';

final jobsControllerProvider =
    StateNotifierProvider<JobsController, List<JobRole>>((ref) {
  return JobsController();
});

class JobsController extends StateNotifier<List<JobRole>> {
  JobsController()
      : super(const [
          JobRole(
            id: '1',
            title: 'Senior Backend Engineer',
            company: 'Northwind Systems',
            status: 'Open',
            shortlisted: 3,
            interviewing: 2,
            offer: 1,
            placed: 0,
          ),
          JobRole(
            id: '2',
            title: 'Product Designer',
            company: 'Halo Studio',
            status: 'Open',
            shortlisted: 5,
            interviewing: 1,
            offer: 0,
            placed: 0,
          ),
          JobRole(
            id: '3',
            title: 'Data Scientist',
            company: 'Vantage Analytics',
            status: 'Filled',
            shortlisted: 0,
            interviewing: 0,
            offer: 0,
            placed: 1,
          ),
        ]);

  void addJob(JobRole job) {
    state = [...state, job];
  }
}
