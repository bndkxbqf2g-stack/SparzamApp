class ProspectBranch {
  const ProspectBranch({
    required this.storeName,
    required this.branchId,
    required this.postalCode,
    required this.location,
    required this.officialUrl,
  });

  final String storeName;
  final String branchId;
  final String postalCode;
  final String location;
  final String officialUrl;
}

const configuredProspectBranches = <ProspectBranch>[
  ProspectBranch(
    storeName: 'Lidl',
    branchId: 'lidl_zellingen',
    postalCode: '97225',
    location: 'Zellingen',
    officialUrl: 'https://www.lidl.de/c/online-prospekte/s10005610/',
  ),
  ProspectBranch(
    storeName: 'ALDI Süd',
    branchId: 'B384',
    postalCode: '97225',
    location: 'Zellingen',
    officialUrl: 'https://prospekt.aldi-sued.de/kw39-26-op-mp/page/1',
  ),
  ProspectBranch(
    storeName: 'EDEKA',
    branchId: '023738',
    postalCode: '97225',
    location: 'Zellingen',
    officialUrl: 'https://www.edeka.de/markt-id/8002976/prospekt.jsp',
  ),
  ProspectBranch(
    storeName: 'Kaufland',
    branchId: 'DE5103',
    postalCode: '97076',
    location: 'Würzburg',
    officialUrl: 'https://filiale.kaufland.de/prospekte.html',
  ),
  ProspectBranch(
    storeName: 'PENNY',
    branchId: '230061',
    postalCode: '97225',
    location: 'Zellingen',
    officialUrl: 'https://www.penny.de/angebote',
  ),
  ProspectBranch(
    storeName: 'Netto',
    branchId: '4371',
    postalCode: '97291',
    location: 'Thüngersheim',
    officialUrl: 'https://www.netto-online.de/ueber-netto/Online-Prospekte.chtm/4371',
  ),
  ProspectBranch(
    storeName: 'REWE',
    branchId: '461683',
    postalCode: '97209',
    location: 'Veitshöchheim',
    officialUrl:
        'https://www.rewe.de/marktseite/veitshoechheim/461683/rewe-markt-pont-l-eveque-allee-1/',
  ),
];

class ProspectBranchResolver {
  const ProspectBranchResolver();

  String? extractPostalCode(String address) {
    final match = RegExp(r'\b(\d{5})\b').firstMatch(address);
    return match?.group(1);
  }

  List<ProspectBranch> resolve(String address) {
    final postalCode = extractPostalCode(address);
    if (postalCode == null) return const <ProspectBranch>[];

    return configuredProspectBranches
        .where((branch) => branch.postalCode == postalCode)
        .toList(growable: false);
  }

  List<ProspectBranch> resolveOrKeep(
    String address,
    Iterable<ProspectBranch> current,
  ) {
    final resolved = resolve(address);
    return resolved.isEmpty ? current.toList(growable: false) : resolved;
  }
}
