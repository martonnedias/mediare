import 'package:flutter/material.dart';
import 'api_service.dart';
import 'dart:ui';

class ChildModeScreen extends StatefulWidget {
  const ChildModeScreen({Key? key}) : super(key: key);

  @override
  State<ChildModeScreen> createState() => _ChildModeScreenState();
}

class _ChildModeScreenState extends State<ChildModeScreen> {
  List<dynamic> _tasks = [];
  List<dynamic> _rewards = [];
  bool _isLoading = true;
  int _level = 1;
  int _points = 0;
  int _nextLevelPoints = 100;
  String _encouragementMessage = 'Carregando sua próxima missão...';

  @override
  void initState() {
    super.initState();
    _fetchData();
    _fetchEncouragement();
  }

  Future<void> _fetchEncouragement() async {
    try {
      final res = await ApiService.get('/child-progress/1/encouragement');
      if (mounted) {
        setState(() => _encouragementMessage = res['message'] ?? '');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _encouragementMessage = 'Você é incrível! Continue sua jornada épica! ✨');
      }
    }
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final tasksRes = await ApiService.get('/tasks?child_id=1');
      final progressRes = await ApiService.get('/child-progress/1');
      
      // Fetch dynamic rewards
      final rewardsRes = await ApiService.get('/rewards'); 

      setState(() {
        _tasks = tasksRes['tasks'] ?? [];
        _level = progressRes['level'] ?? 1;
        _points = progressRes['points'] ?? 0;
        _nextLevelPoints = progressRes['next_level_points'] ?? 100;
        _rewards = rewardsRes['rewards'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      _loadMockData();
    }
  }

  void _loadMockData() {
    setState(() {
      _tasks = [
        {'id': 1, 'name': 'Arrumar a Mochila', 'points': 50, 'status': 'pending'},
        {'id': 2, 'name': 'Lição de Matemática', 'points': 80, 'status': 'pending'},
        {'id': 3, 'name': 'Lavar a louça', 'points': 30, 'status': 'completed'},
      ];
      _rewards = [
        {'id': 1, 'name': '1h de Game Extra', 'points_required': 300},
        {'id': 2, 'name': 'Escolher o Jantar', 'points_required': 450},
      ];
      _level = 4;
      _points = 650;
      _nextLevelPoints = 1000;
      _isLoading = false;
    });
  }

  Future<void> _completeTask(int taskId) async {
    try {
      await ApiService.post('/tasks/$taskId/complete', {});
      _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
          ),
        ),
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : CustomScrollView(
            slivers: [
              _buildSliverHeader(isDesktop),
              SliverPadding(
                padding: EdgeInsets.all(isDesktop ? 40 : 20),
                sliver: isDesktop ? _buildWebLayout() : _buildMobileLayout(),
              ),
            ],
          ),
      ),
    );
  }

  Widget _buildSliverHeader(bool isDesktop) {
    return SliverAppBar(
      expandedHeight: isDesktop ? 250 : 200,
      backgroundColor: Colors.transparent,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 50,
              child: Hero(
                tag: 'child_avatar',
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(Icons.rocket_launch, size: 50, color: Colors.white),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              child: Column(
                children: [
                   Text(
                    'João Pedro na Missão! 🚀',
                    style: TextStyle(color: Colors.white, fontSize: isDesktop ? 32 : 24, fontWeight: FontWeight.bold, shadows: const [Shadow(blurRadius: 10, color: Colors.black26)]),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(20)),
                    child: Text('NÍVEL $_level • DEFENSOR DA HARMONIA', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildWebLayout() {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          _buildAIEncouragement(),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildTaskSection()),
              const SizedBox(width: 40),
              Expanded(flex: 1, child: _buildProgressSidePanel()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          _buildAIEncouragement(),
          const SizedBox(height: 20),
          _buildProgressStats(),
          const SizedBox(height: 30),
          _buildTaskSection(),
          const SizedBox(height: 30),
          _buildRewardsCard(),
        ],
      ),
    );
  }

  Widget _buildAIEncouragement() {
    return _GlassCard(
      color: Colors.amber.withValues(alpha: 0.1),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.amber, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CONSELHO DO GUARDIÃO', style: TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  _encouragementMessage,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStats() {
    return _GlassCard(
      child: Column(
        children: [
          const Text('SEU PROGRESSO', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildPointIndicator(),
        ],
      ),
    );
  }

  Widget _buildPointIndicator() {
      double progress = _points / _nextLevelPoints;
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.stars, color: Colors.amber, size: 40),
              const SizedBox(width: 12),
              Text('$_points', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
          ),
          const SizedBox(height: 8),
          Text('Faltam ${_nextLevelPoints - _points} XP para o NÍVEL ${_level + 1}', style: const TextStyle(color: Colors.white60, fontSize: 11)),
        ],
      );
  }

  Widget _buildTaskSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('MISSÕES DE HOJE', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
        const SizedBox(height: 20),
        if (_tasks.isEmpty)
           const Center(child: Text('Nenhuma missão para agora. Aproveite o dia!', style: TextStyle(color: Colors.white70))),
        ..._tasks.map((task) => _buildTaskItem(task)).toList(),
      ],
    );
  }

  Widget _buildTaskItem(dynamic task) {
    bool isCompleted = task['status'] == 'completed';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: _GlassCard(
        color: isCompleted ? Colors.green.withValues(alpha: 0.2) : null,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: IconButton(
            icon: Icon(isCompleted ? Icons.check_circle : Icons.radio_button_unchecked, color: isCompleted ? Colors.greenAccent : Colors.white70, size: 32),
            onPressed: isCompleted ? null : () => _completeTask(task['id']),
          ),
          title: Text(task['name'], style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, decoration: isCompleted ? TextDecoration.lineThrough : null)),
          subtitle: Text('+ ${task['points']} StarPoints', style: TextStyle(color: isCompleted ? Colors.white54 : Colors.amberAccent, fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.chevron_right, color: Colors.white24),
        ),
      ),
    );
  }

  Widget _buildProgressSidePanel() {
    return Column(
      children: [
        _buildProgressStats(),
        const SizedBox(height: 24),
        _buildRewardsCard(),
      ],
    );
  }

  Widget _buildRewardsCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('LOJA DE RECOMPENSAS', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          if (_rewards.isEmpty)
             const Text('Aguardando novos prêmios...', style: TextStyle(color: Colors.white38, fontSize: 12)),
          ..._rewards.map((r) => _rewardTile(
            Icons.card_giftcard, 
            r['name'], 
            '${r['points_required']} pts', 
            r['points_required'], 
            r['id']
          )).toList(),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione um prêmio acima para resgatar.')));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('RESGATAR PREMIOS', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _rewardTile(IconData icon, String title, String val, int pointsCost, int rewardId) {
    bool canRedeem = _points >= pointsCost;
    return InkWell(
      onTap: canRedeem ? () => _redeemReward(rewardId, pointsCost, title) : null,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Icon(icon, color: canRedeem ? Colors.white : Colors.white38, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: TextStyle(color: canRedeem ? Colors.white : Colors.white38, fontWeight: FontWeight.w500))),
            Text(val, style: TextStyle(color: canRedeem ? Colors.amber : Colors.white24, fontWeight: FontWeight.bold)),
            if (canRedeem) ...[
              const SizedBox(width: 8),
              const Icon(Icons.touch_app, color: Colors.amber, size: 16)
            ]
          ],
        ),
      ),
    );
  }

  Future<void> _redeemReward(int rewardId, int cost, String title) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Resgatar $title?'),
        content: Text('Isso vai custar $cost pontos.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Resgatar')),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        await ApiService.post('/rewards/$rewardId/redeem?child_id=1', {}); 
        _fetchData(); 
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Parabéns! $title resgatado.')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao resgatar: $e')));
        }
      }
    }
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  const _GlassCard({required this.child, this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: color ?? Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: child,
        ),
      ),
    );
  }
}