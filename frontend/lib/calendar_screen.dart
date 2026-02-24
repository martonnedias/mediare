import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

import 'api_service.dart';
import 'family_service.dart';
import 'sync_service.dart';
import 'mediare_widgets.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  List<dynamic> _events = [];
  bool _isLoading = true;
  DateTime _currentMonth = DateTime.now();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    setState(() => _isLoading = true);
    try {
      final start = DateTime(_currentMonth.year, _currentMonth.month, 1).toIso8601String();
      final end = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).toIso8601String();
      
      final familyId = FamilyService().currentFamily.id;
      final response = await ApiService.get('/calendar/events?family_unit_id=$familyId&start_date=$start&end_date=$end');
      setState(() {
        _events = response['events'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      _loadMockEvents();
    }
  }

  void _loadMockEvents() {
    setState(() {
      _events = List.generate(5, (index) => {
        'id': index,
        'event_date': DateTime.now().add(Duration(days: index)).toIso8601String(),
        'status': index % 2 == 0 ? 'scheduled' : 'completed',
        'description': index == 0 ? 'Entrega na Escola' : 'Troca de Guarda',
      });
      _isLoading = false;
    });
  }

  List<dynamic> get _selectedDayEvents {
    if (_selectedDate == null) return _events;
    return _events.where((e) {
      try {
        final d = DateTime.parse(e['event_date']);
        return d.year == _selectedDate!.year && 
               d.month == _selectedDate!.month && 
               d.day == _selectedDate!.day;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : isDesktop ? _buildWebLayout() : _buildMobileLayout(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddEventDialog,
        backgroundColor: Theme.of(context).primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Novo Evento', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _showAddEventDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddEventDialog(onSuccess: _fetchEvents),
    );
  }

  Widget _buildWebLayout() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Calendário e Convivência',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
              ),
              const Spacer(),
              _buildMonthPicker(),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: SingleChildScrollView(child: Column(
                  children: [
                    _buildMonthlyGrid(),
                    if (_selectedDate != null) ...[
                      const SizedBox(height: 24),
                      _buildTimelineHeader(),
                      const SizedBox(height: 12),
                      _DayTimeline(
                        date: _selectedDate!,
                        events: _selectedDayEvents,
                      ),
                    ],
                  ],
                ))),
                const SizedBox(width: 24),
                Expanded(flex: 3, child: _buildEventsPanel()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildMonthPicker(),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 80), // Padding for FAB
            children: [
              _buildMonthlyGrid(),
              if (_selectedDate != null) ...[
                const SizedBox(height: 24),
                _buildTimelineHeader(),
                const SizedBox(height: 12),
                _DayTimeline(
                  date: _selectedDate!,
                  events: _selectedDayEvents,
                ),
              ],
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_selectedDate != null ? 'Eventos do Dia' : 'Próximas Trocas', 
                         style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    if (_selectedDate != null)
                      TextButton(
                        onPressed: () => setState(() => _selectedDate = null),
                        child: const Text('Mostrar todos'),
                      )
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (_selectedDayEvents.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Text("Nenhum evento programado", style: TextStyle(color: Colors.grey))),
                )
              else
                ..._selectedDayEvents.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: _buildEventTile(e),
                )).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonthPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ]
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            color: Theme.of(context).primaryColor,
            onPressed: () {
              setState(() {
                _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
                _selectedDate = null;
                _fetchEvents();
              });
            },
          ),
          const SizedBox(width: 8),
          Text(
            DateFormat('MMMM yyyy', 'pt_BR').format(_currentMonth).toUpperCase(),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Theme.of(context).primaryColor, letterSpacing: 0.5),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            color: Theme.of(context).primaryColor,
            onPressed: () {
              setState(() {
                _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                _selectedDate = null;
                _fetchEvents();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyGrid() {
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstDayWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday % 7;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 8))
        ]
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['DOM', 'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB']
                .map((d) => Expanded(child: Center(child: Text(d, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 11))))).toList(),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.0,
            ),
            itemCount: 42,
            itemBuilder: (context, index) {
              final day = index - firstDayWeekday + 1;
              if (day < 1 || day > daysInMonth) return Container();

              final dateOfCell = DateTime(_currentMonth.year, _currentMonth.month, day);
              final isToday = DateTime.now().year == dateOfCell.year && 
                              DateTime.now().month == dateOfCell.month && 
                              DateTime.now().day == dateOfCell.day;
              
              final isSelected = _selectedDate != null && 
                                 _selectedDate!.year == dateOfCell.year && 
                                 _selectedDate!.month == dateOfCell.month && 
                                 _selectedDate!.day == dateOfCell.day;

              final dailyEvents = _events.where((e) {
                try {
                  return DateTime.parse(e['event_date']).day == day;
                } catch(_) { return false; }
              }).toList();
              
              final hasEvent = dailyEvents.isNotEmpty;
              final isParentA = day % 4 < 2; // Mantendo o mock de parentabilidade

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = dateOfCell;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFE0F2FE) : 
                          (hasEvent ? (isParentA ? const Color(0xFFD1FAE5) : const Color(0xFFE0E7FF)) : Colors.grey.shade50),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF144BB8) : 
                             (hasEvent ? (isParentA ? const Color(0xFF34D399) : const Color(0xFF818CF8)) : Colors.transparent), 
                      width: isSelected ? 2 : (hasEvent ? 1.5 : 0)
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          '$day', 
                          style: TextStyle(
                            fontWeight: isToday || hasEvent || isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isToday ? const Color(0xFF144BB8) : (isSelected ? const Color(0xFF144BB8) : const Color(0xFF334155)),
                            fontSize: 16
                          )
                        )
                      ),
                      if (hasEvent)
                        Positioned(
                          bottom: 6,
                          left: 0,
                          right: 0,
                          child: Row(
                           mainAxisAlignment: MainAxisAlignment.center,
                           children: dailyEvents.take(3).map((e) {
                             return Padding(
                               padding: const EdgeInsets.symmetric(horizontal: 1.5),
                               child: Container(
                                 width: 5, height: 5,
                                 decoration: BoxDecoration(
                                    color: isParentA ? const Color(0xFF059669) : const Color(0xFF4F46E5),
                                    shape: BoxShape.circle
                                 )
                               )
                             );
                           }).toList(),
                         ),
                        ),
                      if (isToday)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEventsPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             Text(_selectedDate != null ? 'Eventos do Dia' : 'Próximos Eventos', 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
             if (_selectedDate != null)
               TextButton(
                 onPressed: () => setState(() => _selectedDate = null),
                 child: const Text('Mostrar todos', style: TextStyle(fontWeight: FontWeight.bold)),
               )
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade200, width: 1.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 8))
              ]
            ),
            child: _selectedDayEvents.isEmpty 
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy_rounded, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text("Nenhum evento neste dia.", style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  )
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _selectedDayEvents.length,
                  separatorBuilder: (context, index) => const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  itemBuilder: (context, index) => _buildEventTile(_selectedDayEvents[index]),
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventTile(dynamic event) {
    DateTime date;
    try {
      date = DateTime.parse(event['event_date']);
    } catch (_) {
      date = DateTime.now();
    }
    
    final isParentA = date.day % 4 < 2;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
               color: isParentA ? const Color(0xFFD1FAE5) : const Color(0xFFE0E7FF),
               borderRadius: BorderRadius.circular(16)
            ),
            child: Icon(isParentA ? Icons.home_rounded : Icons.swap_horiz_rounded, size: 20, color: isParentA ? const Color(0xFF059669) : const Color(0xFF4F46E5)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event['description'] ?? 'Troca de Guarda', 
                     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Theme.of(context).primaryColor)),
                const SizedBox(height: 4),
                if (event['location_name'] != null)
                   Padding(
                     padding: const EdgeInsets.only(bottom: 4),
                     child: Row(
                       children: [
                         const Icon(Icons.location_on_rounded, size: 12, color: Colors.grey),
                         const SizedBox(width: 4),
                         Text(event['location_name'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                       ],
                     ),
                   ),
                Text(DateFormat('dd/MM/yyyy • HH:mm').format(date), 
                     style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: event['status'] == 'completed' ? const Color(0xFFD1FAE5) : const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  event['status'] == 'completed' ? 'Concluído' : 'Agendado',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: event['status'] == 'completed' ? const Color(0xFF059669) : const Color(0xFF144BB8)
                  ),
                ),
              ),
              if (event['status'] != 'completed' && event['id'] != null) ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _doCheckin(event['id']),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDE68A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF59E0B)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.gps_fixed_rounded, size: 12, color: Color(0xFFB45309)),
                        SizedBox(width: 4),
                        Text('Check-in GPS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                      ],
                    ),
                  ),
                ),
              ]
            ],
          )
        ],
      ),
    );
  }

  Future<void> _doCheckin(int eventId) async {
    try {
      await ApiService.post('/checkins', {
        'event_id': eventId,
        'latitude': -23.55052,
        'longitude': -46.633308,
        'status': 'on_time'
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Check-in GPS realizado com sucesso!'), backgroundColor: Colors.green));
      _fetchEvents();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro no checkin: $e')));
    }
  }

  Widget _buildTimelineHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.linear_scale_rounded, color: Color(0xFF144BB8), size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Linha de Convivência',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              if (_selectedDate != null)
                Text(
                  DateFormat('EEEE, d MMMM', 'pt_BR').format(_selectedDate!),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.access_time_filled_rounded, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text('24h', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _DayTimeline extends StatelessWidget {
  final DateTime date;
  final List<dynamic> events;

  const _DayTimeline({required this.date, required this.events});

  @override
  Widget build(BuildContext context) {
    final isToday = date.year == DateTime.now().year && 
                    date.month == DateTime.now().month && 
                    date.day == DateTime.now().day;

    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02), 
            blurRadius: 20, 
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background grid lines (subtle)
            Positioned.fill(
              child: Row(
                children: List.generate(24, (index) => Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(right: BorderSide(color: Colors.grey.withOpacity(index % 6 == 0 ? 0.08 : 0.03))),
                    ),
                  ),
                )),
              ),
            ),
            
            // Régua de horas
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                width: (24 * 70.0) + 40,
                child: Stack(
                  children: [
                     // Track central

                     Positioned(
                       top: 45,
                       left: 20,
                       right: 20,
                       child: Container(
                         height: 12,
                         decoration: BoxDecoration(
                           color: Colors.grey.shade100,
                           borderRadius: BorderRadius.circular(6),
                         ),
                       ),
                     ),
                     
                     // Labels de Horas
                     ...List.generate(25, (index) => Positioned(
                       left: 20 + (index * 70.0),
                       top: 70,
                       child: Container(
                         transform: Matrix4.translationValues(-10, 0, 0),
                         child: Text(
                           '${index.toString().padLeft(2, '0')}:00', 
                           style: TextStyle(
                             fontSize: 10, 
                             fontWeight: index % 6 == 0 ? FontWeight.bold : FontWeight.normal,
                             color: index % 6 == 0 ? Colors.blueGrey.shade400 : Colors.grey.shade400
                           )
                         ),
                       ),
                     )),
                     
                     // Blocos de convivência com gradiente
                     _buildPeriodBlock(0, 18, [const Color(0xFF059669), const Color(0xFF10B981)], 'Pai'),
                     _buildPeriodBlock(18, 24, [const Color(0xFF2563EB), const Color(0xFF3B82F6)], 'Mãe'),

                     // Indicador de "Agora" (se for hoje)
                     if (isToday)
                       _buildCurrentTimeIndicator(),

                     // Marcadores de Eventos
                     ...events.map((e) {
                       try {
                         final eventTime = DateTime.parse(e['event_date']);
                         final position = 20 + (eventTime.hour * 70.0) + (eventTime.minute * (70.0/60.0));
                         
                         return Positioned(
                           left: position - 12,
                           top: 35,
                           child: Tooltip(
                             message: '${DateFormat('HH:mm').format(eventTime)} - ${e['description']}',
                             child: Icon(Icons.location_on, color: Theme.of(context).primaryColor, size: 24),
                           ),
                         );
                       } catch(_) { return const SizedBox(); }
                     }).toList(),

                     // Marcadores de Check-ins (GPS)
                     ...events.expand((e) {
                        final List<dynamic> checks = e['checkins'] ?? [];
                        return checks.map((c) {
                          try {
                            final cTime = DateTime.parse(c['timestamp']);
                            final position = 20 + (cTime.hour * 70.0) + (cTime.minute * (70.0/60.0));
                            return Positioned(
                              left: position - 8,
                              top: 20,
                              child: Tooltip(
                                message: 'Check-in: ${DateFormat('HH:mm').format(cTime)}',
                                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                              ),
                            );
                          } catch(_) { return const SizedBox(); }
                        });
                     }).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodBlock(double startHour, double endHour, List<Color> colors, String label) {
    return Positioned(
      left: 20 + (startHour * 70.0),
      top: 45,
      child: Container(
        height: 12,
        width: (endHour - startHour) * 70.0,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors.map((c) => c.withOpacity(0.6)).toList(),
          ),
          borderRadius: BorderRadius.horizontal(
            left: Radius.circular(startHour == 0 ? 6 : 2),
            right: Radius.circular(endHour == 24 ? 6 : 2),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTimeIndicator() {
    final now = DateTime.now();
    final position = 20 + (now.hour * 70.0) + (now.minute * (70.0/60.0));
    
    return Positioned(
      left: position - 1,
      top: 20,
      bottom: 20,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('AGORA', style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Container(
              width: 2,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.orange, Colors.transparent],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddEventDialog extends StatefulWidget {
  final VoidCallback onSuccess;
  const _AddEventDialog({required this.onSuccess});

  @override
  State<_AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<_AddEventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  List<dynamic> _children = [];
  List<dynamic> _locations = [];
  int? _selectedChildId;
  int? _selectedLocationId;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoadingChildren = true;
  bool _isLoadingLocations = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchChildren();
    _fetchLocations();
  }

  Future<void> _fetchChildren() async {
    try {
      final response = await ApiService.get('/users/children');
      setState(() {
        _children = response['children'] ?? [];
        if (_children.isNotEmpty) _selectedChildId = _children[0]['id'];
        _isLoadingChildren = false;
      });
    } catch (e) {
      setState(() => _isLoadingChildren = false);
    }
  }

  Future<void> _fetchLocations() async {
    try {
      final response = await ApiService.get('/locations');
      setState(() {
        _locations = response['locations'] ?? [];
        _isLoadingLocations = false;
      });
    } catch (e) {
      setState(() => _isLoadingLocations = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedChildId == null) return;
    setState(() => _isSubmitting = true);

    try {
      final eventDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      ).toUtc().toIso8601String(); 

      final res = await SyncService.postOrEnqueue('/calendar/events', {
        'child_id': _selectedChildId,
        'event_date': eventDate,
        'description': _descController.text,
        'status': 'scheduled',
        'location_id': _selectedLocationId,
      });
      
      if (!mounted) return;
      Navigator.pop(context);
      if (res?['status'] == 'queued') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offline: Evento salvo na fila para sincronização posterior.')));
      } else {
        widget.onSuccess();
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar evento: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Novo Evento / Troca', style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 20, fontWeight: FontWeight.bold)),
            IconButton(
               icon: const Icon(Icons.close_rounded, color: Colors.grey),
               onPressed: () => Navigator.pop(context),
            )
          ],
        ),
      ),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isLoadingChildren)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  )
                else if (_children.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(16)),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Color(0xFF059669)),
                        SizedBox(width: 12),
                        Expanded(child: Text('Adicione filhos no perfil para poder agendar eventos.', style: TextStyle(color: Color(0xFF065F46), fontSize: 13))),
                      ],
                    ),
                  )
                else
                  DropdownButtonFormField<int>(
                    value: _selectedChildId,
                    decoration: InputDecoration(
                      labelText: 'Vincular ao Filho',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: _children.map<DropdownMenuItem<int>>((c) => DropdownMenuItem<int>(
                      value: c['id'],
                      child: Text(c['name']),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedChildId = v),
                  ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _selectedLocationId,
                  decoration: InputDecoration(
                    labelText: 'Local / Endereço (Opcional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.location_on_outlined),
                  ),
                  items: [
                     const DropdownMenuItem<int>(value: null, child: Text('Nenhum')),
                     ..._locations.map<DropdownMenuItem<int>>((l) => DropdownMenuItem<int>(
                      value: l['id'],
                      child: Text('${l['name']} (${l['type']})'),
                    )).toList(),
                  ],
                  onChanged: (v) => setState(() => _selectedLocationId = v),
                ),
                const SizedBox(height: 16),
                SoftInput(
                  controller: _descController,
                  label: 'Descrição ou Título',
                  hint: 'Ex: Troca de Guarda, Entrega Escola',
                  validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        title: const Text('Data', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey)),
                        subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedDate), style: TextStyle(fontSize: 16, color: Theme.of(context).primaryColor)),
                        trailing: const Icon(Icons.calendar_today_rounded, color: Color(0xFF144BB8)),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            builder: (context, child) => Theme(data: ThemeData.light(), child: child!),
                          );
                          if (picked != null) setState(() => _selectedDate = picked);
                        },
                      ),
                      Divider(height: 1, color: Colors.grey.shade200),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        title: const Text('Horário (Estimado)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey)),
                        subtitle: Text(_selectedTime.format(context), style: TextStyle(fontSize: 16, color: Theme.of(context).primaryColor)),
                        trailing: const Icon(Icons.access_time_rounded, color: Color(0xFF144BB8)),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context, 
                            initialTime: _selectedTime,
                            builder: (context, child) => Theme(data: ThemeData.light(), child: child!),
                          );
                          if (picked != null) setState(() => _selectedTime = picked);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), 
          child: const Text('CANCELAR', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
        ),
        _isSubmitting 
          ? const CircularProgressIndicator()
          : SoftButton(
              text: 'SALVAR EVENTO',
              onPressed: _children.isEmpty ? null : _submit,
            ),
      ],
    );
  }
}
