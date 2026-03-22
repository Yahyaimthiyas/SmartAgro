import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';

class OwnerReportsScreen extends StatefulWidget {
  const OwnerReportsScreen({super.key});

  @override
  State<OwnerReportsScreen> createState() => _OwnerReportsScreenState();
}

class _OwnerReportsScreenState extends State<OwnerReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTa = LocalizationService.isTamil;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A1C1E), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isTa ? 'புள்ளிவிவரங்கள் & அறிக்கைகள்' : 'Analytics & Reports',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A1C1E),
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: EdgeInsets.zero,
              labelPadding: const EdgeInsets.symmetric(horizontal: 16),
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                color: const Color(0xFF0EA5E9),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade600,
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                Tab(text: isTa ? 'விற்பனை' : 'Sales'),
                Tab(text: isTa ? 'பொருட்கள்' : 'Products'),
                Tab(text: isTa ? 'வாடிக்கையாளர்கள்' : 'Customers'),
                Tab(text: isTa ? 'இருப்பு' : 'Inventory'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _SalesTab(),
          _ProductsTab(),
          _CustomersTab(),
          _InventoryTab(),
        ],
      ),
    );
  }
}

// --- SALES TAB (REAL DATA) ---
class _SalesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, orderSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('products').snapshots(),
          builder: (context, productSnapshot) {
            if (!orderSnapshot.hasData || !productSnapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = orderSnapshot.data!.docs;
            final products = productSnapshot.data!.docs;
            
            double totalRevenue = 0;
            final Map<String, double> dailyRev = {};
            final Map<int, int> busyHours = {};
            final Set<String> soldProductIds = {};

            // Last 7 days buckets
            final now = DateTime.now();
            final thirtyDaysAgo = now.subtract(const Duration(days: 30));
            for (int i = 6; i >= 0; i--) {
              final date = now.subtract(Duration(days: i));
              dailyRev[DateFormat('MM/dd').format(date)] = 0;
            }

            for (var doc in docs) {
              final data = doc.data();
              final status = data['status'] as String? ?? 'placed';
              if (status == 'cancelled') continue;

              final amt = (data['totalAmount'] as num? ?? 0).toDouble();
              final ts = data['createdAt'] as Timestamp?;
              if (ts == null) continue;
              final date = ts.toDate();
              
              totalRevenue += amt;
              
              final dateKey = DateFormat('MM/dd').format(date);
              if (dailyRev.containsKey(dateKey)) {
                dailyRev[dateKey] = (dailyRev[dateKey] ?? 0) + amt;
              }
              busyHours[date.hour] = (busyHours[date.hour] ?? 0) + 1;

              // Track products sold in last 30 days
              if (date.isAfter(thirtyDaysAgo)) {
                final items = data['items'] as List<dynamic>? ?? [];
                for (var item in items) {
                  final pid = item['productId'] as String?;
                  if (pid != null) soldProductIds.add(pid);
                }
              }
            }

            // Identify dead stock (in stock but 0 sales in 30 days)
            final deadStockCount = products.where((p) {
              final pid = p.id;
              final stock = (p.data()['stock'] as num? ?? 0).toInt();
              return stock > 0 && !soldProductIds.contains(pid);
            }).length;

            List<FlSpot> revenueSpots = [];
            int x = 0;
            dailyRev.forEach((k, v) {
              revenueSpots.add(FlSpot(x.toDouble(), v));
              x++;
            });

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildRevenueCard(totalRevenue, revenueSpots),
                const SizedBox(height: 24),
                _buildBusyHoursCard(busyHours),
                const SizedBox(height: 24),
                _buildDeadStockAlert(deadStockCount),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRevenueCard(double total, List<FlSpot> spots) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TOTAL REVENUE', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(8)),
                child: Text('+LIVE', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0EA5E9))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('₹${NumberFormat('#,##,###').format(total)}', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          SizedBox(
            height: 100,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots.isEmpty ? [const FlSpot(0, 0)] : spots,
                    isCurved: true,
                    color: const Color(0xFF0EA5E9),
                    barWidth: 3,
                    belowBarData: BarAreaData(show: true, color: const Color(0xFF0EA5E9).withOpacity(0.1)),
                    dotData: FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildBusyHoursCard(Map<int, int> hours) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Busiest Hours', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, m) {
                      if (v.toInt() % 4 == 0) return Text('${v.toInt()}:00', style: const TextStyle(fontSize: 10, color: Colors.grey));
                      return const SizedBox();
                    },
                  )),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(24, (i) {
                  return BarChartGroupData(x: i, barRods: [
                    BarChartRodData(
                      toY: (hours[i] ?? 0).toDouble(),
                      color: i >= 10 && i <= 16 ? const Color(0xFF0EA5E9) : const Color(0xFFFFB74D),
                      width: 8,
                      borderRadius: BorderRadius.circular(4),
                    )
                  ]);
                }),
              )
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeadStockAlert(int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F0),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFA39E)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: Color(0xFFFFCCC7), shape: BoxShape.circle),
            child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFF5222D)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(count > 0 ? '$count Products with no sales' : 'No Dead Stock Alert', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF1A1C1E))),
                Text(count > 0 ? 'Not sold in the last 30 days' : 'Real-time stock monitoring active', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade700)),
              ],
            ),
          ),
            Flexible(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5222D),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Flash Sale', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
        ],
      ),
    );
  }
}

// --- PRODUCTS TAB (REAL DATA) ---
class _ProductsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, orderSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('products').snapshots(),
          builder: (context, productSnapshot) {
            if (!orderSnapshot.hasData || !productSnapshot.hasData) return const Center(child: CircularProgressIndicator());
            
            final orders = orderSnapshot.data!.docs;
            final products = productSnapshot.data!.docs;
            final Map<String, Map<String, dynamic>> productMap = {};
            for (var p in products) productMap[p.id] = p.data();

            final Map<String, int> productSalesCount = {};
            final Map<String, double> productRevenue = {};
            final Map<String, double> categoryRevenue = {};
            final Map<String, List<int>> productTrend = {}; // Last 7 days units
            final now_trend = DateTime.now();
            final List<String> last7Days = List.generate(7, (i) => DateFormat('MM/dd').format(now_trend.subtract(Duration(days: 6 - i))));

            for (var doc in orders) {
              final data = doc.data();
              if (data['status'] == 'cancelled') continue;
              final ts = (data['createdAt'] as Timestamp?)?.toDate();
              final dayKey = ts != null ? DateFormat('MM/dd').format(ts) : null;

              final items = data['items'] as List<dynamic>? ?? [];
              for (var item in items) {
                final id = item['productId'] as String? ?? 'unknown';
                final qty = (item['quantity'] as num? ?? 0).toInt();
                final price = (item['price'] as num? ?? 0).toDouble();
                final cat = item['category'] as String? ?? (productMap[id]?['category'] ?? 'Other');

                productSalesCount[id] = (productSalesCount[id] ?? 0) + qty;
                productRevenue[id] = (productRevenue[id] ?? 0) + (qty * price);
                categoryRevenue[cat] = (categoryRevenue[cat] ?? 0) + (qty * price);

                if (dayKey != null && last7Days.contains(dayKey)) {
                  if (!productTrend.containsKey(id)) {
                    productTrend[id] = List.filled(7, 0);
                  }
                  final dayIndex = last7Days.indexOf(dayKey);
                  productTrend[id]![dayIndex] += qty;
                }
              }
            }

            final sortedBySales = productSalesCount.entries.toList()..sort((a,b) => b.value.compareTo(a.value));
            
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (sortedBySales.isNotEmpty)
                  _buildTopSellerCard(productMap[sortedBySales.first.key] ?? {}, sortedBySales.first.value),
                
                const SizedBox(height: 24),
                Text('Top Performers', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ...sortedBySales.take(5).map((e) {
                   final pData = productMap[e.key] ?? {};
                   final trendRaw = productTrend[e.key] ?? List.filled(7, 0);
                   final List<FlSpot> spots = List.generate(7, (i) => FlSpot(i.toDouble(), trendRaw[i].toDouble()));
                   return _buildPerformerTile(pData, productRevenue[e.key] ?? 0, (sortedBySales.indexOf(e) + 1).toString().padLeft(2, '0'), spots);
                }).toList(),
                
                const SizedBox(height: 24),
                _buildCategoryRevenueCard(categoryRevenue),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTopSellerCard(Map<String, dynamic> data, int units) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(12)),
                child: Text('TOP SELLER', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF0369A1))),
              ),
              Text('Overall', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: data['image'] != null 
                  ? Image.network(data['image'], width: 80, height: 80, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.inventory, size: 40))
                  : const Icon(Icons.inventory, size: 40),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['name_en'] ?? 'Unknown Product', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Category: ${data['category'] ?? 'N/A'}', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Flexible(child: Text('₹${data['price'] ?? 0}', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0369A1)), overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 12),
                        Flexible(child: Text('$units Units', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformerTile(Map<String, dynamic> data, double rev, String rank, List<FlSpot> spots) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey.shade50,
            child: Text(rank, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['name_en'] ?? 'Unknown', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                Text('₹${NumberFormat('#,###').format(rev)} Rev', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          SizedBox(
            width: 60, height: 30,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots.isEmpty ? [const FlSpot(0, 0)] : spots,
                    isCurved: true,
                    color: const Color(0xFF0EA5E9),
                    barWidth: 2,
                    dotData: FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRevenueCard(Map<String, double> catRev) {
    final List<PieChartSectionData> sections = [];
    final List<Widget> legendItems = [];
    final colors = [const Color(0xFF0EA5E9), const Color(0xFFFFB74D), const Color(0xFF42A5F5), const Color(0xFFF06292), const Color(0xFFBA68C8)];
    
    double total = catRev.values.fold(0, (sum, v) => sum + v);
    int i = 0;
    catRev.forEach((cat, rev) {
      final color = colors[i % colors.length];
      final percentage = total > 0 ? (rev / total * 100) : 0;
      if (i < 5) { // Show top 5 in chart
        sections.add(PieChartSectionData(value: rev, color: color, radius: 15, showTitle: false));
        legendItems.add(_buildLegendItem(cat, '${percentage.toStringAsFixed(0)}%', color));
      }
      i++;
    });

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Category Revenue', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            children: [
              SizedBox(
                width: 100, height: 100,
                child: PieChart(
                  PieChartData(
                    sections: sections.isEmpty ? [PieChartSectionData(value: 1, color: Colors.grey.shade100, radius: 10, showTitle: false)] : sections,
                    centerSpaceRadius: 35,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(children: legendItems),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, String p, Color c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey), overflow: TextOverflow.ellipsis)),
          Text(p, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// --- CUSTOMERS TAB (REAL DATA) ---
class _CustomersTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        final Map<String, double> customerSpend = {};
        final Map<String, int> customerOrders = {};
        final Map<String, String> customerNames = {};
        final Map<String, DateTime> lastOrderDate = {};
        final Map<String, int> dailyActive = {};
        final now = DateTime.now();
        for (int i = 6; i >= 0; i--) {
          final date = now.subtract(Duration(days: i));
          dailyActive[DateFormat('MM/dd').format(date)] = 0;
        }

        for (var doc in docs) {
          final data = doc.data();
          final uid = data['userId'] as String? ?? data['farmerId'] as String? ?? 'unknown';
          final name = data['customerName'] as String? ?? 'Farmer';
          final amt = (data['totalAmount'] as num? ?? 0).toDouble();
          final ts = data['createdAt'] as Timestamp?;
          
          customerSpend[uid] = (customerSpend[uid] ?? 0) + amt;
          customerOrders[uid] = (customerOrders[uid] ?? 0) + 1;
          customerNames[uid] = name;
          if (ts != null) {
            final date = ts.toDate();
            if (lastOrderDate[uid] == null || date.isAfter(lastOrderDate[uid]!)) {
              lastOrderDate[uid] = date;
            }
            
            final dateKey = DateFormat('MM/dd').format(date);
            if (dailyActive.containsKey(dateKey)) {
              // Note: This counts total orders per day as a proxy for "activity trend" 
              // or we could track unique UIDs per day for true "daily active users"
              dailyActive[dateKey] = (dailyActive[dateKey] ?? 0) + 1;
            }
          }
        }

        List<FlSpot> activitySpots = [];
        int x = 0;
        dailyActive.forEach((k, v) {
          activitySpots.add(FlSpot(x.toDouble(), v.toDouble()));
          x++;
        });

        final sortedBySpend = customerSpend.entries.toList()..sort((a,b) => b.value.compareTo(a.value));
        final uniqueUsers = customerSpend.length;
        final returningUsers = customerOrders.values.where((c) => c > 1).length;
        final retentionRate = uniqueUsers > 0 ? (returningUsers / uniqueUsers * 100) : 0.0;

        final inactiveIds = lastOrderDate.entries
            .where((e) => DateTime.now().difference(e.value).inDays > 60)
            .map((e) => e.key).toList();

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildActiveFarmersCard(uniqueUsers, activitySpots),
            const SizedBox(height: 24),
            Text('Top Loyal Farmers', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...sortedBySpend.take(3).map((e) => 
               _buildLoyalFarmerTile(customerNames[e.key]!, '${customerOrders[e.key]} Orders total', '₹${NumberFormat('#,###').format(e.value)}', sortedBySpend.indexOf(e) == 0 ? 'VIP' : 'TOP')
            ).toList(),
            const SizedBox(height: 24),
            _buildRetentionCard(retentionRate, returningUsers, uniqueUsers - returningUsers),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Inactive Farmers', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Last 60+ Days', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 16),
            if (inactiveIds.isEmpty) 
               Center(child: Text('All farmers are active!', style: GoogleFonts.inter(color: Colors.grey)))
            else
               ...inactiveIds.take(5).map((id) {
                 final days = DateTime.now().difference(lastOrderDate[id]!).inDays;
                 return _buildInactiveFarmerTile(customerNames[id]!, 'Inactive for $days days');
               }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildActiveFarmersCard(int total, List<FlSpot> activitySpots) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TOTAL RECENT BUYERS', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Text(total.toString(), style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          SizedBox(
            height: 60,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: activitySpots.isEmpty ? [const FlSpot(0, 0)] : activitySpots,
                    isCurved: true,
                    color: const Color(0xFF0EA5E9),
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoyalFarmerTile(String name, String subsidy, String spend, String badge) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Stack(
            children: [
              const CircleAvatar(radius: 24, backgroundColor: Color(0xFFE0F2FE), child: Icon(Icons.person, color: Color(0xFF0369A1))),
              Positioned(
                right: 0, top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)),
                  child: Text(badge, style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                Text(subsidy, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(spend, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0369A1))),
              Text('SPEND', style: GoogleFonts.inter(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRetentionCard(double rate, int returning, int newUsers) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Customer Retention', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            children: [
              SizedBox(
                width: 100, height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(value: rate, color: const Color(0xFF0EA5E9), radius: 10, showTitle: false),
                          PieChartSectionData(value: 100-rate, color: const Color(0xFF0EA5E9).withOpacity(0.1), radius: 10, showTitle: false),
                        ],
                        centerSpaceRadius: 35,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Rate', style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
                        Text('${rate.toStringAsFixed(0)}%', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                child: Column(
                  children: [
                    _buildLegendItem('Returning', '$returning Users', const Color(0xFF0EA5E9)),
                    const SizedBox(height: 12),
                    _buildLegendItem('New Users', '$newUsers Users', const Color(0xFF0EA5E9).withOpacity(0.2)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInactiveFarmerTile(String name, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          const CircleAvatar(radius: 20, backgroundColor: Color(0xFFF5F5F5), child: Icon(Icons.person_outline, color: Colors.grey)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                Text(time, style: GoogleFonts.inter(fontSize: 10, color: Colors.red)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE0F2FE),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Send Voucher', style: TextStyle(color: Color(0xFF0369A1), fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, String val, Color c) {
     return Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                Text(val, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ],
     );
  }
}

// --- INVENTORY TAB (REAL DATA) ---
class _InventoryTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final products = snapshot.data!.docs;
        
        double totalValue = 0;
        int healthyCount = 0;
        final List<Map<String, dynamic>> lowStock = [];
        final Map<String, double> catValue = {};

        for (var doc in products) {
          final data = doc.data();
          final stock = (data['stock'] as num? ?? 0).toInt();
          final price = (data['price'] as num? ?? 0).toDouble();
          final cat = data['category'] as String? ?? 'Other';
          
          totalValue += (stock * price);
          catValue[cat] = (catValue[cat] ?? 0) + (stock * price);
          
          if (stock > 10) healthyCount++;
          if (stock <= 10) lowStock.add(data);
        }

        double healthRate = products.isNotEmpty ? (healthyCount / products.length) : 1.0;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildInventoryHealthCard(healthRate),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Low Stock Alerts', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('View All', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF0EA5E9), fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            if (lowStock.isEmpty)
               Center(child: Text('Stock levels are healthy', style: GoogleFonts.inter(color: Colors.grey)))
            else
               SizedBox(
                height: 185,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: lowStock.take(5).map((p) => 
                     _buildLowStockCard(p['category']?.toUpperCase() ?? 'CAT', p['name_en'] ?? 'Product', p['stock']?.toString() ?? '0', p['stock'] <= 0 ? Colors.red : Colors.orange)
                  ).toList(),
                ),
              ),
            const SizedBox(height: 32),
            _buildStockValueCard(totalValue),
            const SizedBox(height: 32),
            _buildCategoryValueList(catValue, totalValue),
          ],
        );
      },
    );
  }

  Widget _buildInventoryHealthCard(double rate) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF38BDF8)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('System Status', style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withOpacity(0.8))),
                const SizedBox(height: 4),
                Text('Inventory Health', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Text('${(rate * 100).toStringAsFixed(0)}% of your stock items are at optimal levels.', style: GoogleFonts.inter(fontSize: 11, color: Colors.white.withOpacity(0.7))),
              ],
            ),
          ),
          SizedBox(
            width: 80, height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(value: rate, strokeWidth: 8, color: Colors.white, backgroundColor: Colors.white.withOpacity(0.2)),
                Text('${(rate * 100).toStringAsFixed(0)}%', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLowStockCard(String cat, String name, String count, Color border) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(cat, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(text: count, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: border)),
                TextSpan(text: ' units left', style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0EA5E9), elevation: 0, padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: const Text('RESTOCK NOW', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockValueCard(double total) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total Warehouse Value', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          Text('₹${NumberFormat('#,##,##,###').format(total)}', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF0369A1))),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(8)),
            child: Text('↑ REAL-TIME ASSET VALUE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF0EA5E9))),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryValueList(Map<String, double> catValue, double total) {
    final sorted = catValue.entries.toList()..sort((a,b) => b.value.compareTo(a.value));
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Value by Category', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          ...sorted.take(5).map((e) => _buildCategoryLine(e.key, '₹${NumberFormat.compact().format(e.value)}', total > 0 ? (e.value / total) : 0)).toList(),
        ],
      ),
    );
  }

  Widget _buildCategoryLine(String label, String val, double p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
              Text(val, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: p, backgroundColor: Colors.grey.shade100, color: const Color(0xFF0EA5E9), minHeight: 6),
        ],
      ),
    );
  }
}
