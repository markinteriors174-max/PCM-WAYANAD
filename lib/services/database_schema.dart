import 'package:sqflite/sqflite.dart';

class DatabaseSchema {
  static Future<void> createDB(Database db, int version) async {
    await db.execute('CREATE TABLE quotations (id INTEGER PRIMARY KEY AUTOINCREMENT, unitNumber TEXT, clientName TEXT, clientPhone TEXT, clientLocation TEXT, locationFolder TEXT, date TEXT, totalAmount REAL, paidAmount REAL, balanceAmount REAL, latitude REAL, longitude REAL, manualAmount REAL DEFAULT 0, manualWeight REAL DEFAULT 0, advancePayment REAL DEFAULT 0, includeWastage INTEGER DEFAULT 0, includeDigitalSignature INTEGER DEFAULT 0, includeBankDetails INTEGER DEFAULT 1, originalAmount REAL, revisionNote TEXT, globalMaterialCost REAL DEFAULT 0, globalMargin REAL DEFAULT 0, discount REAL DEFAULT 0, projectStatus TEXT DEFAULT \'Planning\', approvalSignature TEXT)');
    await db.execute('CREATE TABLE quotation_items (id INTEGER PRIMARY KEY AUTOINCREMENT, quotationId INTEGER, roomName TEXT, ceilingType TEXT, unit TEXT, length REAL, width REAL, height REAL, quantity REAL, area REAL, rate REAL, amount REAL, heightExtra REAL, thickness REAL DEFAULT 0, brandName TEXT, designName TEXT, isCeilingDesign INTEGER DEFAULT 0, hasCentralDesign INTEGER DEFAULT 0, centralArea REAL DEFAULT 0, centralRate REAL DEFAULT 0, hasCove INTEGER DEFAULT 0, coveRft REAL DEFAULT 0, coveRate REAL DEFAULT 0, coveLength REAL DEFAULT 0, coveWidth REAL DEFAULT 0, coveQuantity REAL DEFAULT 1, coveLength2 REAL DEFAULT 0, coveWidth2 REAL DEFAULT 0, coveQuantity2 REAL DEFAULT 1, centralLength REAL DEFAULT 0, centralWidth REAL DEFAULT 0, centralQuantity REAL DEFAULT 1, centralUnit TEXT DEFAULT \'SqFt\', coveUnit TEXT DEFAULT \'RFT\', FOREIGN KEY (quotationId) REFERENCES quotations (id) ON DELETE CASCADE)');
    await db.execute('CREATE TABLE quotation_materials (id INTEGER PRIMARY KEY AUTOINCREMENT, quotationId INTEGER, materialName TEXT, unit TEXT, rate REAL, quantity REAL, amount REAL, FOREIGN KEY (quotationId) REFERENCES quotations (id) ON DELETE CASCADE)');
    await db.execute('CREATE TABLE quotation_rentals (id INTEGER PRIMARY KEY AUTOINCREMENT, quotationId INTEGER, itemName TEXT, siteName TEXT, startDate TEXT, dailyRate REAL, quantity REAL, status TEXT, FOREIGN KEY (quotationId) REFERENCES quotations (id) ON DELETE CASCADE)');
    await db.execute('CREATE TABLE quotation_payments (id INTEGER PRIMARY KEY AUTOINCREMENT, quotationId INTEGER, description TEXT, date TEXT, amount REAL, FOREIGN KEY (quotationId) REFERENCES quotations (id) ON DELETE CASCADE)');
    await db.execute('CREATE TABLE custom_material_categories (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE)');
    await db.execute('CREATE TABLE custom_sub_materials (id INTEGER PRIMARY KEY AUTOINCREMENT, categoryName TEXT, name TEXT, unit TEXT, material_name_malayalam TEXT, rate REAL DEFAULT 0.0, sku TEXT, FOREIGN KEY (categoryName) REFERENCES custom_material_categories (name) ON DELETE CASCADE)');
    await db.execute('CREATE TABLE IF NOT EXISTS workers (id INTEGER PRIMARY KEY AUTOINCREMENT, worker_name TEXT NOT NULL, daily_wage REAL DEFAULT 0.0, total_days REAL DEFAULT 0.0, total_paid REAL DEFAULT 0.0)');
    await preloadMaterialDictionary(db);
  }

  static Future<void> onUpgrade(Database db, int oldV, int newV) async {
    if (oldV < 2) await db.execute('ALTER TABLE quotation_items ADD COLUMN heightExtra REAL DEFAULT 0');
    if (oldV < 3) {
      await db.execute('CREATE TABLE quotation_materials (id INTEGER PRIMARY KEY AUTOINCREMENT, quotationId INTEGER, materialName TEXT, unit TEXT, rate REAL, quantity REAL, amount REAL, FOREIGN KEY (quotationId) REFERENCES quotations (id) ON DELETE CASCADE)');
      await db.execute('CREATE TABLE quotation_rentals (id INTEGER PRIMARY KEY AUTOINCREMENT, quotationId INTEGER, itemName TEXT, siteName TEXT, startDate TEXT, dailyRate REAL, quantity REAL, status TEXT, FOREIGN KEY (quotationId) REFERENCES quotations (id) ON DELETE CASCADE)');
    }
    if (oldV < 4) {
      await db.execute('ALTER TABLE quotations ADD COLUMN latitude REAL');
      await db.execute('ALTER TABLE quotations ADD COLUMN longitude REAL');
    }
    if (oldV < 5) {
      await db.execute('DROP TABLE IF EXISTS quotation_rentals');
      await db.execute('CREATE TABLE quotation_rentals (id INTEGER PRIMARY KEY AUTOINCREMENT, quotationId INTEGER, itemName TEXT, siteName TEXT, startDate TEXT, dailyRate REAL, quantity REAL, status TEXT, FOREIGN KEY (quotationId) REFERENCES quotations (id) ON DELETE CASCADE)');
    }
    if (oldV < 6) {
      await db.execute('ALTER TABLE quotations ADD COLUMN manualAmount REAL DEFAULT 0');
      await db.execute('ALTER TABLE quotations ADD COLUMN manualWeight REAL DEFAULT 0');
      await db.execute('ALTER TABLE quotations ADD COLUMN advancePayment REAL DEFAULT 0');
    }
    if (oldV < 7) await db.execute('ALTER TABLE quotations ADD COLUMN locationFolder TEXT');
    if (oldV < 8) await db.execute('ALTER TABLE quotation_items ADD COLUMN brandName TEXT');
    if (oldV < 9) await db.execute('ALTER TABLE quotations ADD COLUMN includeWastage INTEGER DEFAULT 0');
    if (oldV < 10) await db.execute('ALTER TABLE quotation_items ADD COLUMN thickness REAL DEFAULT 0');
    if (oldV < 11) await db.execute('ALTER TABLE quotation_items ADD COLUMN designName TEXT DEFAULT \'Standard Design\'');
    if (oldV < 12) {
      await db.execute('CREATE TABLE quotation_payments (id INTEGER PRIMARY KEY AUTOINCREMENT, quotationId INTEGER, description TEXT, date TEXT, amount REAL, FOREIGN KEY (quotationId) REFERENCES quotations (id) ON DELETE CASCADE)');
      final quotes = await db.query('quotations');
      for (var q in quotes) {
        if (q['advancePayment'] != null && (q['advancePayment'] as num) > 0) {
          await db.insert('quotation_payments', {
            'quotationId': q['id'],
            'description': 'Advance Payment',
            'date': q['date'] ?? DateTime.now().toIso8601String(),
            'amount': q['advancePayment'],
          });
        }
      }
    }
    if (oldV < 13) {
      await db.execute('ALTER TABLE quotations ADD COLUMN originalAmount REAL');
      await db.execute('ALTER TABLE quotations ADD COLUMN revisionNote TEXT');
    }
    if (oldV < 14) {
      await db.execute('ALTER TABLE quotations ADD COLUMN globalMaterialCost REAL DEFAULT 0');
      await db.execute('ALTER TABLE quotations ADD COLUMN globalMargin REAL DEFAULT 0');
    }
    if (oldV < 15) {
      await db.execute('ALTER TABLE quotation_items ADD COLUMN isCeilingDesign INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE quotation_items ADD COLUMN hasCentralDesign INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE quotation_items ADD COLUMN centralArea REAL DEFAULT 0');
      await db.execute('ALTER TABLE quotation_items ADD COLUMN centralRate REAL DEFAULT 0');
      await db.execute('ALTER TABLE quotation_items ADD COLUMN hasCove INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE quotation_items ADD COLUMN coveRft REAL DEFAULT 0');
      await db.execute('ALTER TABLE quotation_items ADD COLUMN coveRate REAL DEFAULT 0');
    }
    if (oldV < 16) {
      await db.execute('ALTER TABLE quotation_items ADD COLUMN coveLength REAL DEFAULT 0');
      await db.execute('ALTER TABLE quotation_items ADD COLUMN coveWidth REAL DEFAULT 0');
    }
    if (oldV < 17) await db.execute('ALTER TABLE quotation_items ADD COLUMN coveQuantity REAL DEFAULT 1');
    if (oldV < 18) {
      await db.execute('ALTER TABLE quotation_items ADD COLUMN centralLength REAL DEFAULT 0');
      await db.execute('ALTER TABLE quotation_items ADD COLUMN centralWidth REAL DEFAULT 0');
      await db.execute('ALTER TABLE quotation_items ADD COLUMN centralQuantity REAL DEFAULT 1');
      await db.execute('ALTER TABLE quotation_items ADD COLUMN centralUnit TEXT DEFAULT \'SqFt\'');
      await db.execute('ALTER TABLE quotation_items ADD COLUMN coveUnit TEXT DEFAULT \'RFT\'');
    }
    if (oldV < 19) {
      await db.execute('ALTER TABLE quotation_items ADD COLUMN coveLength2 REAL DEFAULT 0');
      await db.execute('ALTER TABLE quotation_items ADD COLUMN coveWidth2 REAL DEFAULT 0');
      await db.execute('ALTER TABLE quotation_items ADD COLUMN coveQuantity2 REAL DEFAULT 1');
    }
    if (oldV < 20) await db.execute('ALTER TABLE quotations ADD COLUMN discount REAL DEFAULT 0');
    if (oldV < 21) {
      await db.execute('ALTER TABLE quotations ADD COLUMN projectStatus TEXT DEFAULT \'Planning\'');
      await db.execute('ALTER TABLE quotations ADD COLUMN approvalSignature TEXT');
    }
    if (oldV < 22) {
      await db.execute('CREATE TABLE custom_material_categories (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE)');
      await db.execute('CREATE TABLE custom_sub_materials (id INTEGER PRIMARY KEY AUTOINCREMENT, categoryName TEXT, name TEXT, unit TEXT, FOREIGN KEY (categoryName) REFERENCES custom_material_categories (name) ON DELETE CASCADE)');
      await preloadMaterialDictionary(db);
    }
    if (oldV < 23) {
      try { await db.execute('ALTER TABLE custom_sub_materials ADD COLUMN material_name_malayalam TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE custom_sub_materials ADD COLUMN rate REAL DEFAULT 0.0'); } catch (_) {}
    }
    if (oldV < 24) {
      try { await db.execute('CREATE TABLE IF NOT EXISTS workers (id INTEGER PRIMARY KEY AUTOINCREMENT, worker_name TEXT NOT NULL, daily_wage REAL DEFAULT 0.0, total_days REAL DEFAULT 0.0, total_paid REAL DEFAULT 0.0)'); } catch (_) {}
    }
    if (oldV < 25) {
      try { await db.execute('ALTER TABLE custom_sub_materials ADD COLUMN sku TEXT'); } catch (_) {}
    }
    if (oldV < 26) {
      try { await db.execute('ALTER TABLE quotations ADD COLUMN includeDigitalSignature INTEGER DEFAULT 0'); } catch (_) {}
    }
    if (oldV < 27) {
      try { await db.execute('ALTER TABLE quotations ADD COLUMN includeBankDetails INTEGER DEFAULT 1'); } catch (_) {}
    }
  }

  static Future<void> preloadMaterialDictionary(Database db) async {
    final List<Map<String, dynamic>> schema = [
      {
        'category': 'Gypsum Board Ceiling',
        'items': [
          {'name': 'Gypsum Board (12 mm - 6x4 Ft)', 'unit': 'Nos'},
          {'name': 'Perimeter Channel (Wall Channel)', 'unit': 'Nos'},
          {'name': 'Intermediate Channel (Main Channel)', 'unit': 'Nos'},
          {'name': 'Ceiling Section (Cross Channel)', 'unit': 'Nos'},
          {'name': 'L Angle', 'unit': 'Nos'},
          {'name': 'Soffit Cleat (L-Clamp)', 'unit': 'Nos'},
          {'name': 'Gypsum Screw (1 Inch)', 'unit': 'Box'},
          {'name': 'Gypsum Screw (1.5 Inch)', 'unit': 'Box'},
          {'name': 'Wall Plug & Screw', 'unit': 'Packet'},
          {'name': 'Anchor Bolt / Ceiling Bolt', 'unit': 'Nos'},
          {'name': 'Fiber Joint Tape (Mesh)', 'unit': 'Nos'},
          {'name': 'Gypsum Compound (Putty Powder)', 'unit': 'Bags'},
        ]
      },
      {
        'category': 'PVC Ceiling (Gypsum Channel Frame Setup)',
        'items': [
          {'name': 'PVC Panel (10 Inch Width - 10 Ft Length)', 'unit': 'Nos'},
          {'name': 'PVC Cornice Design (Cornice Profile)', 'unit': 'Nos'},
          {'name': 'PVC H-Profile (for Joints)', 'unit': 'Nos'},
          {'name': 'PVC U-Profile', 'unit': 'Nos'},
          {'name': 'PVC F-Profile', 'unit': 'Nos'},
          {'name': 'PVC L-Angle Beading', 'unit': 'Nos'},
          {'name': 'Perimeter Channel / Intermediate Channel / Ceiling Section / Soffit Cleat', 'unit': 'Nos'},
          {'name': 'Gypsum Screw (1 Inch)', 'unit': 'Box'},
          {'name': 'Wall Plug & Screw', 'unit': 'Packet'},
          {'name': 'Anchor Bolt / Ceiling Bolt', 'unit': 'Nos'},
          {'name': 'Star Screw (0.75 Inch)', 'unit': 'Packet'},
        ]
      },
      {
        'category': 'Grid Ceiling (2x2 Framework)',
        'items': [
          {'name': '2x2 Grid Tiles (Gypsum/PVC/Fiber)', 'unit': 'Nos'},
          {'name': 'Main Tee Channel (12 Ft)', 'unit': 'Nos'},
          {'name': 'Cross Tee Channel (4 Ft)', 'unit': 'Nos'},
          {'name': 'Cross Tee Channel (2 Ft)', 'unit': 'Nos'},
          {'name': 'Wall Angle / L-Angle Channel', 'unit': 'Nos'},
          {'name': 'Hanger Wire / GI Wire', 'unit': 'Nos/kg'},
          {'name': 'Butterfly Clip', 'unit': 'Nos'},
          {'name': 'Anchor Bolt / Ceiling Bolt', 'unit': 'Nos'},
          {'name': 'Wall Plug & Screw', 'unit': 'Packet'},
        ]
      },
      {
        'category': 'V-Board Work (Ceiling & Wall Application)',
        'items': [
          {'name': 'V-Board Sheets (4mm / 6mm / 8mm)', 'unit': 'Nos'},
          {'name': 'Channels (Perimeter / Intermediate / Section / L Angle)', 'unit': 'Nos'},
          {'name': 'Fiber Cement Board Screw (V-Board Screw)', 'unit': 'Box'},
          {'name': 'Wall Plug & Screw / Anchor Bolt', 'unit': 'Nos/Packet'},
          {'name': 'V-Board Joint Filler & Fiber Mesh Tape', 'unit': 'Bags/Nos'},
        ]
      },
      {
        'category': 'Partition Work (Drywall / Framing)',
        'items': [
          {'name': 'Floor Track Channel (Bottom & Top)', 'unit': 'Nos'},
          {'name': 'Stud Channel (Vertical Supports)', 'unit': 'Nos'},
          {'name': 'Gypsum Board (12 mm) / V-Board Sheets', 'unit': 'Nos'},
          {'name': 'Wall Plug & Screw', 'unit': 'Packet'},
          {'name': 'Metal to Metal Screw (Wafer Head Screw)', 'unit': 'Box'},
          {'name': 'Gypsum Screw (1 Inch) / V-Board Screw', 'unit': 'Box'},
        ]
      },
      {
        'category': 'Louver Panels',
        'items': [
          {'name': 'WPC Louver Panel (Indoor)', 'unit': 'Nos'},
          {'name': 'Charcoal Louver Panel (Indoor)', 'unit': 'Nos'},
          {'name': 'Outdoor WPC Cladding Panel', 'unit': 'Nos'},
          {'name': 'Louver Clip (SS Clips)', 'unit': 'Packet'},
          {'name': 'Silicon Glue Tube (Silicon Sealant / MaxBond)', 'unit': 'Nos'},
          {'name': 'Silicon Gun & Star Screw', 'unit': 'Nos/Packet'},
          {'name': 'Wall Plug & Screw', 'unit': 'Packet'},
        ]
      },
      {
        'category': 'Insu Board Heat Proofing',
        'items': [
          {'name': 'InsuBoard Sheets (XPS Sheets)', 'unit': 'Nos'},
          {'name': 'InsuBoard Fixing Glue (PU Foam Spray)', 'unit': 'Nos'},
          {'name': 'Aluminium Foil Tape', 'unit': 'Nos'},
        ]
      },
      {
        'category': 'Soundproofing Work',
        'items': [
          {'name': 'Acoustic Board / Rockwool Slab / Glasswool Roll', 'unit': 'Nos/Roll'},
          {'name': 'Acoustic Foam Sheets / Sound Isolation Tape', 'unit': 'Nos/Roll'},
        ]
      }
    ];

    for (var cat in schema) {
      final name = cat['category'] as String;
      await db.insert('custom_material_categories', {'name': name}, conflictAlgorithm: ConflictAlgorithm.ignore);
      for (var item in List<Map<String, String>>.from(cat['items'])) {
        final iName = item['name'] as String;
        await db.insert('custom_sub_materials', {
          'categoryName': name, 'name': iName, 'unit': item['unit'] as String,
          'material_name_malayalam': getMalayalamTranslation(iName), 'rate': 0.0
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }
  }

  static String getMalayalamTranslation(String name) {
    final map = {
      'Gypsum Board (12 mm - 6x4 Ft)': 'ജിപ്സം ബോർഡ് (12 mm - 6x4 Ft)',
      'Perimeter Channel (Wall Channel)': 'പെരിമീറ്റർ ചാനൽ (വാൾ ചാനൽ)',
      'Intermediate Channel (Main Channel)': 'ഇന്റർമീഡിയറ്റ് ചാനൽ (മെയിൻ ചാനൽ)',
      'Ceiling Section (Cross Channel)': 'സീലിംഗ് സെക്ഷൻ (ക്രോസ് ചാനൽ)',
      'L Angle': 'എൽ ആംഗിൾ',
      'Soffit Cleat (L-Clamp)': 'സോഫിറ്റ് ക്ലീറ്റ് (എൽ-ക്ലാമ്പ്)',
      'Gypsum Screw (1 Inch)': 'ജിപ്സം സ്ക്രൂ (1 ഇഞ്ച്)',
      'Gypsum Screw (1.5 Inch)': 'ജിപ്സം സ്ക്രൂ (1.5 ഇഞ്ച്)',
      'Wall Plug & Screw': 'വാൾ പ്ലഗ് & സ്ക്രൂ',
      'Anchor Bolt / Ceiling Bolt': 'ആങ്കർ ബോൾട്ട് / സീലിംഗ് ബോൾട്ട്',
      'Fiber Joint Tape (Mesh)': 'ഫൈബർ ജോയിന്റ് ടേപ്പ് (മെഷ്)',
      'Gypsum Compound (Putty Powder)': 'ജിപ്സം കോമ്പൗണ്ട് (പുട്ടി പൗഡർ)',
      'PVC Panel (10 Inch Width - 10 Ft Length)': 'PVC പാനൽ (10 ഇഞ്ച് വീതി - 10 അടി നീളം)',
      'PVC Cornice Design (Cornice Profile)': 'PVC കോർണിസ് ഡിസൈൻ (കോർണിസ് പ്രൊഫൈൽ)',
      'PVC H-Profile (for Joints)': 'PVC എച്ച്-പ്രൊഫൈൽ',
      'PVC U-Profile': 'PVC യു-പ്രൊഫൈൽ',
      'PVC F-Profile': 'PVC എഫ്-പ്രൊഫൈൽ',
      'PVC L-Angle Beading': 'PVC എൽ-ആംഗിൾ ബീഡിംഗ്',
      'Perimeter Channel / Intermediate Channel / Ceiling Section / Soffit Cleat': 'പെരിമീറ്റർ / ഇന്റർമീഡിയറ്റ് ചാനലുകൾ',
      'Star Screw (0.75 Inch)': 'സ്റ്റാർ സ്ക്രൂ (0.75 ഇഞ്ച്)',
      '2x2 Grid Tiles (Gypsum/PVC/Fiber)': '2x2 ഗ്രിഡ് ടൈൽസ്',
      'Main Tee Channel (12 Ft)': 'മെയിൻ ടീ ചാനൽ (12 അടി)',
      'Cross Tee Channel (4 Ft)': 'ക്രോസ് ടീ ചാനൽ (4 അടി)',
      'Cross Tee Channel (2 Ft)': 'ക്രോസ് ടീ ചാനൽ (2 അടി)',
      'Wall Angle / L-Angle Channel': 'വാൾ ആംഗിൾ / എൽ-ആംഗിൾ ചാനൽ',
      'Hanger Wire / GI Wire': 'ഹാങ്ങർ വയർ / ജിഐ വയർ',
      'Butterfly Clip': 'ബട്ടർഫ്ലൈ ക്ലിപ്പ്',
      'V-Board Sheets (4mm / 6mm / 8mm)': 'വി-ബോർഡ് ഷീറ്റുകൾ (4mm / 6mm / 8mm)',
      'Channels (Perimeter / Intermediate / Section / L Angle)': 'ചാനലുകൾ (പെരിമീറ്റർ / ഇന്റർമീഡിയറ്റ്)',
      'Fiber Cement Board Screw (V-Board Screw)': 'ഫൈബർ സിമന്റ് ബോർഡ് സ്ക്രൂ',
      'V-Board Joint Filler & Fiber Mesh Tape': 'വി-ബോർഡ് ജോയിന്റ് ഫില്ലർ & ഫൈബർ ടേപ്പ്',
      'Floor Track Channel (Bottom & Top)': 'ഫ്ലോർ ട്രാക്ക് ചാനൽ (ബോട്ടം & ടോപ്പ്)',
      'Stud Channel (Vertical Supports)': 'സ്റ്റഡ് ചാനൽ (വെർട്ടിക്കൽ സപ്പോർട്ട്)',
      'Gypsum Board (12 mm) / V-Board Sheets': 'ജിപ്സം ബോർഡ് / വി-ബോർഡ് ഷീറ്റുകൾ',
      'Metal to Metal Screw (Wafer Head Screw)': 'മെറ്റൽ ടു മെറ്റൽ സ്ക്രൂ',
      'Gypsum Screw (1 Inch) / V-Board Screw': 'ജിപ്സം സ്ക്രൂ / വി-ബോർഡ് സ്ക്രൂ',
      'WPC Louver Panel (Indoor)': 'WPC ലൂവർ പാനൽ (ഇൻഡോർ)',
      'Charcoal Louver Panel (Indoor)': 'ചാർക്കോൾ ലൂവർ പാനൽ (ഇൻഡോർ)',
      'Outdoor WPC Cladding Panel': 'ഔട്ട്ഡോർ WPC ക്ലാഡിംഗ് പാനൽ',
      'Louver Clip (SS Clips)': 'ലൂവർ ക്ലിപ്പ് (എസ്എസ് ക്ലിപ്പ്)',
      'Silicon Glue Tube (Silicon Sealant / MaxBond)': 'സിലിക്കൺ ഗ്ലൂ ട്യൂബ്',
      'Silicon Gun & Star Screw': 'സിലിക്കൺ ഗൺ & സ്റ്റാർ സ്ക്രൂ',
      'InsuBoard Sheets (XPS Sheets)': 'ഇൻസുബോർഡ് ഷീറ്റുകൾ (XPS)',
      'InsuBoard Fixing Glue (PU Foam Spray)': 'ഇൻസുബോർഡ് ഫിക്സിംഗ് ഗ്ലൂ (PU ഫോം)',
      'Aluminium Foil Tape': 'അലുമിനിയം ഫോയിൽ ടേപ്പ്',
      'Acoustic Board / Rockwool Slab / Glasswool Roll': 'അക്കോസ്റ്റിക് ബോർഡ് / റോക്ക്‌വൂൾ',
      'Acoustic Foam Sheets / Sound Isolation Tape': 'അക്കോസ്റ്റിക് ഫോം ഷീറ്റുകൾ / സൗണ്ട് ടേപ്പ്',
    };
    return map[name] ?? name;
  }
}
