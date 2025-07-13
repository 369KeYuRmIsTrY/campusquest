import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../../controllers/login_controller.dart';
import '../../../utils/open_file_plus.dart';

class StudentEventsPage extends StatefulWidget {
  const StudentEventsPage({Key? key}) : super(key: key);

  @override
  _StudentEventsPageState createState() => _StudentEventsPageState();
}

class _StudentEventsPageState extends State<StudentEventsPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _upcomingEvents = [];
  bool _isLoadingEvents = true;
  final _refreshKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _fetchUpcomingEvents();
  }

  Future<void> _fetchUpcomingEvents() async {
    setState(() => _isLoadingEvents = true);
    try {
      final loginController = Provider.of<LoginController>(
        context,
        listen: false,
      );
      final programId = loginController.programId;
      if (programId == null) throw Exception('Program ID is null');
      final now = DateTime.now().toIso8601String();
      final response = await _supabase
          .from('event')
          .select(
            'event_id, title, description, event_date, document_path, event_program(program_id)',
          )
          .eq('event_program.program_id', programId.toString())
          .gt('event_date', now)
          .order('event_date', ascending: true);
      if (mounted) {
        setState(() {
          _upcomingEvents = List<Map<String, dynamic>>.from(response);
          _isLoadingEvents = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Error fetching events: $e');
        setState(() => _isLoadingEvents = false);
      }
    }
  }

  Future<void> _showEventDetails(Map<String, dynamic> event) async {
    try {
      showDialog(
        context: context,
        builder:
            (context) => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
              ),
            ),
      );
      final programsResponse = await _supabase
          .from('event_program')
          .select('program_id, program(program_name)')
          .eq('event_id', event['event_id']);
      final List<Map<String, dynamic>> eventPrograms =
          List<Map<String, dynamic>>.from(programsResponse);
      if (!mounted) return;
      Navigator.pop(context);
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder:
            (context) => DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.3,
              maxChildSize: 0.9,
              builder:
                  (_, scrollController) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.deepPurple.shade50,
                          Colors.grey.shade50,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                width: 40,
                                height: 5,
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade400,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    event['title'] ?? 'Untitled Event',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.deepPurple,
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.event,
                                  color: Colors.deepPurple.shade400,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat(
                                    'MMMM dd, yyyy',
                                  ).format(DateTime.parse(event['event_date'])),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (event['description']?.isNotEmpty ?? false) ...[
                              const Text(
                                'Description',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.deepPurple.shade200,
                                  ),
                                ),
                                child: Text(
                                  event['description'],
                                  style: TextStyle(
                                    color: Colors.grey.shade800,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (eventPrograms.isNotEmpty) ...[
                              const Text(
                                'Associated Programs',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children:
                                    eventPrograms
                                        .map(
                                          (program) => Chip(
                                            label: Text(
                                              program['program']['program_name'],
                                            ),
                                            backgroundColor:
                                                Colors.deepPurple.shade100,
                                            labelStyle: const TextStyle(
                                              color: Colors.deepPurple,
                                            ),
                                          ),
                                        )
                                        .toList(),
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (event['document_path'] != null) ...[
                              const Text(
                                'Attachment',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap:
                                    () => _downloadFile(
                                      event['document_path'],
                                      event['document_path'].split('/').last,
                                    ),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.file_present,
                                        color: Colors.deepPurple.shade700,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          event['document_path']
                                              .split('/')
                                              .last,
                                          style: TextStyle(
                                            color: Colors.deepPurple.shade700,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Icon(
                                        Icons.download,
                                        color: Colors.deepPurple.shade700,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
            ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showErrorMessage('Error loading event details: $e');
      }
    }
  }

  Future<void> _downloadFile(String url, String fileName) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      final tempDir = await getTemporaryDirectory();
      final savePath = path.join(tempDir.path, fileName);
      final dio = Dio();
      await dio.download(url, savePath);
      if (mounted) Navigator.pop(context);
      await FileOpener.openEventFile(context, savePath);
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showErrorMessage('Error downloading/opening file: $e');
    }
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(8),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event, int index) {
    final DateTime eventDate = DateTime.parse(event['event_date']);
    final bool isUpcoming = eventDate.isAfter(DateTime.now());
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      shadowColor: Colors.deepPurple.shade200.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showEventDetails(event),
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.deepPurple.shade200.withOpacity(0.3),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isUpcoming ? Icons.event : Icons.event_available,
                  color: Colors.deepPurple.shade700,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event['title'] ?? 'Untitled Event',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM dd, yyyy').format(eventDate),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                    if (event['description']?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 8),
                      Text(
                        event['description'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade800),
                      ),
                    ],
                  ],
                ),
              ),
              if (event['document_path'] != null) ...[
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(
                    Icons.attach_file,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'View',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed:
                      () => _downloadFile(
                        event['document_path'],
                        event['document_path'].split('/').last,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        itemBuilder:
            (context, index) => Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(height: 120, width: double.infinity),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Events'),
        backgroundColor: Colors.deepPurple.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.grey.shade50,
      body:
          _isLoadingEvents
              ? Center(
                child: CircularProgressIndicator(
                  color: Colors.deepPurple.shade700,
                ),
              )
              : RefreshIndicator(
                key: _refreshKey,
                color: Colors.deepPurple.shade700,
                backgroundColor: Colors.white,
                onRefresh: _fetchUpcomingEvents,
                child:
                    _upcomingEvents.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_busy,
                                size: 48,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No upcoming events',
                                style: TextStyle(
                                  color: Colors.grey.shade800,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _upcomingEvents.length,
                          itemBuilder:
                              (context, index) => _buildEventCard(
                                _upcomingEvents[index],
                                index,
                              ),
                        ),
              ),
    );
  }
}
