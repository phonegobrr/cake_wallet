class AddressEntry {
  final String address;
  final String? label;
  final String? currencyTitle;
  final int? index;

  const AddressEntry({
    required this.address,
    this.label,
    this.currencyTitle,
    this.index,
  });

  Map<String, dynamic> toJson() => {
        'address': address,
        if (label != null) 'label': label,
        if (currencyTitle != null) 'currency': currencyTitle,
        if (index != null) 'index': index,
      };
}
