// Modelos del dashboard de administrador.
// Campos = PQRSStatisticsDTO y PriorityComplaintDTO del backend.

Map<String, int> _mapaInt(dynamic raw) {
  if (raw is! Map) return {};
  return raw.map((k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0));
}

double _d(dynamic v) => (v as num?)?.toDouble() ?? 0;
int _i(dynamic v) => (v as num?)?.toInt() ?? 0;

class EmployeeStats {
  final String nombre, email;
  final int asignadas, resueltas;
  final double tiempoPromedio, tasaResolucion;

  EmployeeStats.fromJson(Map<String, dynamic> j)
      : nombre = (j['employeeName'] ?? 'Sin nombre').toString(),
        email = (j['employeeEmail'] ?? '').toString(),
        asignadas = _i(j['totalAssigned']),
        resueltas = _i(j['totalResolved']),
        tiempoPromedio = _d(j['averageResolutionTime']),
        tasaResolucion = _d(j['resolutionRate']);
}

class MonthlyTrend {
  final String month;
  final int recibidas, resueltas;
  final double tiempoPromedio;

  MonthlyTrend.fromJson(Map<String, dynamic> j)
      : month = (j['month'] ?? '').toString(),
        recibidas = _i(j['totalReceived']),
        resueltas = _i(j['totalResolved']),
        tiempoPromedio = _d(j['averageResolutionTime']);

  double get eficiencia => recibidas == 0 ? 0 : resueltas / recibidas * 100;
}

class AdminStats {
  final int total, abiertas, cerradas, enProgreso, vencidas, proximasAVencer;
  final Map<String, int> porEstado, porTipo, porCategoria;
  final double promedioDias, satisfaccion, tasaResolucion;
  final int minDias, maxDias;
  final List<EmployeeStats> empleados;
  final List<MonthlyTrend> tendencias;

  AdminStats.fromJson(Map<String, dynamic> j)
      : total = _i(j['totalPqrs']),
        abiertas = _i(j['openPqrs']),
        cerradas = _i(j['closedPqrs']),
        enProgreso = _i(j['inProgressPqrs']),
        vencidas = _i(j['expiredPqrs']),
        proximasAVencer = _i(j['nearExpirationPqrs']),
        porEstado = _mapaInt(j['pqrsByStatus']),
        porTipo = _mapaInt(j['pqrsByType']),
        porCategoria = _mapaInt(j['pqrsByCategory']),
        promedioDias = _d(j['averageDaysToResolve']),
        minDias = _i(j['minDaysToResolve']),
        maxDias = _i(j['maxDaysToResolve']),
        satisfaccion = _d(j['satisfactionRate']),
        tasaResolucion = _d(j['resolutionRate']),
        empleados = (j['topEmployees'] is List)
            ? (j['topEmployees'] as List)
                .whereType<Map>()
                .map((e) => EmployeeStats.fromJson(Map<String, dynamic>.from(e)))
                .toList()
            : [],
        tendencias = (j['monthlyTrends'] is List)
            ? (j['monthlyTrends'] as List)
                .whereType<Map>()
                .map((e) => MonthlyTrend.fromJson(Map<String, dynamic>.from(e)))
                .toList()
            : [];
}

class PrioridadPqr {
  final String id, reference, subject, level, reason;
  final int score, daysOpen;

  PrioridadPqr.fromJson(Map<String, dynamic> j)
      : id = (j['id'] ?? '').toString(),
        reference = (j['reference'] ?? '').toString(),
        subject = (j['subject'] ?? '').toString(),
        level = (j['priorityLevel'] ?? '').toString().toUpperCase(),
        reason = (j['reason'] ?? '').toString(),
        score = _i(j['priorityScore']),
        daysOpen = _i(j['daysOpen']);
}
