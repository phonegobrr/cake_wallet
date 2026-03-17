class AddressEntry {
  final String address;
  final String? label;
  final int index;

  const AddressEntry({
    required this.address,
    this.label,
    required this.index,
  });

  Map<String, dynamic> toJson() => {
        'address': address,
        if (label != null) 'label': label,
        'index': index,
      };
}
