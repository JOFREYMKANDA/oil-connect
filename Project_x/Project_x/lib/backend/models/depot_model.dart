class Depot {
  final String id;
  final String depot;
  final List<Source> sources;

  Depot({
    required this.id,
    required this.depot,
    required this.sources,
  });

  factory Depot.fromJson(Map<String, dynamic> json) {
    return Depot(
      id: json['_id'] ?? '',
      depot: json['depot'] ?? '',
      sources: (json['sources'] as List<dynamic>?)
          ?.map((source) => Source.fromJson(source as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'depot': depot,
      'sources': sources.map((source) => source.toJson()).toList(),
    };
  }
}

class Source {
  final String id;
  final String name;
  final List<Company> companies;

  Source({
    required this.id,
    required this.name,
    required this.companies,
  });

  factory Source.fromJson(Map<String, dynamic> json) {
    return Source(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      companies: (json['companies'] as List<dynamic>?)
          ?.map((company) => Company.fromJson(company as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'companies': companies.map((company) => company.toJson()).toList(),
    };
  }
}

class Company {
  final String id;
  final String name;
  final double latitude;
  final double longitude;

  Company({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
