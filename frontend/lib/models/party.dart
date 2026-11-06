enum PartyKind { customer, supplier }

class Party {
  const Party({
    required this.id,
    required this.name,
    required this.isActive,
    this.email,
    this.phone,
    this.address,
  });

  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final bool isActive;

  factory Party.fromJson(Map<String, dynamic> json) => Party(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        address: json['address'] as String?,
        isActive: json['is_active'] as bool? ?? true,
      );

  Map<String, dynamic> toCreateJson() => {
        'name': name,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
      };
}
