import 'package:flutter/material.dart';

/// Predefined Indian expense + subscription catalogs.
/// Direct port of src/lib/categories.ts.

class ExpenseCategory {
  const ExpenseCategory({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.bg,
    this.group = 'Other',
  });

  final String key;
  final String label;
  final String icon; // lucide icon name (resolved via lucideIcon())
  final Color color; // icon foreground
  final Color bg; // icon chip background
  final String group;
}

const List<ExpenseCategory> expenseCategories = [
  // Daily
  ExpenseCategory(key: 'grocery', label: 'Grocery', icon: 'ShoppingCart', color: Color(0xFF059669), bg: Color(0xFFD1FAE5), group: 'Daily'),
  ExpenseCategory(key: 'dining', label: 'Dining Out', icon: 'Utensils', color: Color(0xFFDB2777), bg: Color(0xFFFCE7F3), group: 'Daily'),
  ExpenseCategory(key: 'petrol', label: 'Petrol', icon: 'Fuel', color: Color(0xFFA16207), bg: Color(0xFFFEF9C3), group: 'Daily'),
  ExpenseCategory(key: 'transport', label: 'Transport / Cab', icon: 'Car', color: Color(0xFF0284C7), bg: Color(0xFFE0F2FE), group: 'Daily'),
  ExpenseCategory(key: 'shopping', label: 'Shopping', icon: 'ShoppingBag', color: Color(0xFFC026D3), bg: Color(0xFFFAE8FF), group: 'Daily'),
  ExpenseCategory(key: 'entertainment', label: 'Entertainment', icon: 'Film', color: Color(0xFF9333EA), bg: Color(0xFFF3E8FF), group: 'Daily'),
  ExpenseCategory(key: 'medical', label: 'Medical', icon: 'Stethoscope', color: Color(0xFFDC2626), bg: Color(0xFFFEE2E2), group: 'Daily'),
  ExpenseCategory(key: 'fitness', label: 'Fitness', icon: 'Dumbbell', color: Color(0xFF4D7C0F), bg: Color(0xFFECFCCB), group: 'Daily'),
  ExpenseCategory(key: 'personal_care', label: 'Personal Care', icon: 'Sparkles', color: Color(0xFFEC4899), bg: Color(0xFFFCE7F3), group: 'Daily'),
  ExpenseCategory(key: 'pet', label: 'Pet Care', icon: 'PawPrint', color: Color(0xFFB45309), bg: Color(0xFFFEF3C7), group: 'Daily'),
  ExpenseCategory(key: 'donation', label: 'Donation', icon: 'HandHeart', color: Color(0xFFE11D48), bg: Color(0xFFFFE4E6), group: 'Daily'),

  // Utilities
  ExpenseCategory(key: 'electricity', label: 'Electricity', icon: 'Zap', color: Color(0xFFD97706), bg: Color(0xFFFEF3C7), group: 'Utilities'),
  ExpenseCategory(key: 'water', label: 'Water Bill', icon: 'Droplets', color: Color(0xFF0891B2), bg: Color(0xFFCFFAFE), group: 'Utilities'),
  ExpenseCategory(key: 'lpg', label: 'LPG Gas', icon: 'Flame', color: Color(0xFFEA580C), bg: Color(0xFFFFEDD5), group: 'Utilities'),
  ExpenseCategory(key: 'jio_fiber', label: 'Internet', icon: 'Wifi', color: Color(0xFF2563EB), bg: Color(0xFFDBEAFE), group: 'Utilities'),
  ExpenseCategory(key: 'mobile', label: 'Mobile Recharge', icon: 'Smartphone', color: Color(0xFF4F46E5), bg: Color(0xFFE0E7FF), group: 'Utilities'),
  ExpenseCategory(key: 'dth', label: 'DTH / Cable', icon: 'Tv', color: Color(0xFF7C3AED), bg: Color(0xFFEDE9FE), group: 'Utilities'),
  ExpenseCategory(key: 'newspaper', label: 'Newspaper', icon: 'Newspaper', color: Color(0xFF475569), bg: Color(0xFFF1F5F9), group: 'Utilities'),

  // Home
  ExpenseCategory(key: 'rent', label: 'Rent', icon: 'Home', color: Color(0xFFE11D48), bg: Color(0xFFFFE4E6), group: 'Home'),
  ExpenseCategory(key: 'society', label: 'Maintenance', icon: 'Building2', color: Color(0xFF0D9488), bg: Color(0xFFCCFBF1), group: 'Home'),
  ExpenseCategory(key: 'repairs', label: 'Home Repairs', icon: 'Wrench', color: Color(0xFF44403C), bg: Color(0xFFF5F5F4), group: 'Home'),
  ExpenseCategory(key: 'household', label: 'Household', icon: 'Sofa', color: Color(0xFFB45309), bg: Color(0xFFFEF3C7), group: 'Home'),

  // Family
  ExpenseCategory(key: 'fees', label: 'Education', icon: 'GraduationCap', color: Color(0xFF7C3AED), bg: Color(0xFFEDE9FE), group: 'Family'),
  ExpenseCategory(key: 'childcare', label: 'Childcare', icon: 'Baby', color: Color(0xFFDB2777), bg: Color(0xFFFCE7F3), group: 'Family'),
  ExpenseCategory(key: 'elder_care', label: 'Elder Care', icon: 'HeartHandshake', color: Color(0xFFBE123C), bg: Color(0xFFFFE4E6), group: 'Family'),
  ExpenseCategory(key: 'insurance', label: 'Insurance', icon: 'ShieldCheck', color: Color(0xFF047857), bg: Color(0xFFD1FAE5), group: 'Family'),
  ExpenseCategory(key: 'gift', label: 'Gifts', icon: 'Gift', color: Color(0xFFF43F5E), bg: Color(0xFFFFE4E6), group: 'Family'),
  ExpenseCategory(key: 'travel', label: 'Travel', icon: 'Plane', color: Color(0xFF1D4ED8), bg: Color(0xFFDBEAFE), group: 'Family'),

  // Investment & SIPs
  ExpenseCategory(key: 'investment', label: 'Investment', icon: 'TrendingUp', color: Color(0xFF15803D), bg: Color(0xFFDCFCE7), group: 'Investments'),
  ExpenseCategory(key: 'sip_mf', label: 'Mutual Fund SIP', icon: 'LineChart', color: Color(0xFF15803D), bg: Color(0xFFDCFCE7), group: 'Investments'),
  ExpenseCategory(key: 'sip_elss', label: 'ELSS SIP', icon: 'Sprout', color: Color(0xFF047857), bg: Color(0xFFD1FAE5), group: 'Investments'),
  ExpenseCategory(key: 'sip_index', label: 'Index Fund SIP', icon: 'BarChart3', color: Color(0xFF0369A1), bg: Color(0xFFE0F2FE), group: 'Investments'),
  ExpenseCategory(key: 'sip_stepup', label: 'Step-up SIP', icon: 'TrendingUp', color: Color(0xFF0F766E), bg: Color(0xFFCCFBF1), group: 'Investments'),
  ExpenseCategory(key: 'stocks', label: 'Stocks', icon: 'CandlestickChart', color: Color(0xFF4338CA), bg: Color(0xFFE0E7FF), group: 'Investments'),
  ExpenseCategory(key: 'fd', label: 'Fixed Deposit', icon: 'PiggyBank', color: Color(0xFFB45309), bg: Color(0xFFFEF3C7), group: 'Investments'),
  ExpenseCategory(key: 'rd', label: 'Recurring Deposit', icon: 'Repeat2', color: Color(0xFFB45309), bg: Color(0xFFFEF3C7), group: 'Investments'),
  ExpenseCategory(key: 'ppf', label: 'PPF', icon: 'Landmark', color: Color(0xFF047857), bg: Color(0xFFD1FAE5), group: 'Investments'),
  ExpenseCategory(key: 'nps', label: 'NPS', icon: 'ShieldCheck', color: Color(0xFF1D4ED8), bg: Color(0xFFDBEAFE), group: 'Investments'),
  ExpenseCategory(key: 'epf', label: 'EPF', icon: 'Briefcase', color: Color(0xFF334155), bg: Color(0xFFF1F5F9), group: 'Investments'),
  ExpenseCategory(key: 'apy', label: 'APY', icon: 'Umbrella', color: Color(0xFF0369A1), bg: Color(0xFFE0F2FE), group: 'Investments'),
  ExpenseCategory(key: 'ssy', label: 'Sukanya Samriddhi', icon: 'HeartHandshake', color: Color(0xFFBE185D), bg: Color(0xFFFCE7F3), group: 'Investments'),
  ExpenseCategory(key: 'nsc', label: 'NSC', icon: 'FileBadge', color: Color(0xFF047857), bg: Color(0xFFD1FAE5), group: 'Investments'),
  ExpenseCategory(key: 'gold', label: 'Digital Gold', icon: 'Coins', color: Color(0xFFA16207), bg: Color(0xFFFEF9C3), group: 'Investments'),
  ExpenseCategory(key: 'crypto', label: 'Crypto', icon: 'Bitcoin', color: Color(0xFFC2410C), bg: Color(0xFFFFEDD5), group: 'Investments'),
  ExpenseCategory(key: 'real_estate', label: 'Real Estate', icon: 'Building', color: Color(0xFF44403C), bg: Color(0xFFF5F5F4), group: 'Investments'),

  // EMIs / Loans
  ExpenseCategory(key: 'emi_home', label: 'Home Loan EMI', icon: 'Home', color: Color(0xFFBE123C), bg: Color(0xFFFFE4E6), group: 'EMIs'),
  ExpenseCategory(key: 'emi_car', label: 'Car Loan EMI', icon: 'Car', color: Color(0xFF0369A1), bg: Color(0xFFE0F2FE), group: 'EMIs'),
  ExpenseCategory(key: 'emi_bike', label: 'Two-wheeler EMI', icon: 'Bike', color: Color(0xFF0E7490), bg: Color(0xFFCFFAFE), group: 'EMIs'),
  ExpenseCategory(key: 'emi_personal', label: 'Personal Loan EMI', icon: 'Wallet', color: Color(0xFF7E22CE), bg: Color(0xFFF3E8FF), group: 'EMIs'),
  ExpenseCategory(key: 'emi_education', label: 'Education Loan EMI', icon: 'GraduationCap', color: Color(0xFF6D28D9), bg: Color(0xFFEDE9FE), group: 'EMIs'),
  ExpenseCategory(key: 'emi_gold', label: 'Gold Loan EMI', icon: 'Coins', color: Color(0xFFA16207), bg: Color(0xFFFEF9C3), group: 'EMIs'),
  ExpenseCategory(key: 'emi_business', label: 'Business Loan EMI', icon: 'Briefcase', color: Color(0xFF334155), bg: Color(0xFFF1F5F9), group: 'EMIs'),
  ExpenseCategory(key: 'emi_cc', label: 'Credit Card EMI', icon: 'CreditCard', color: Color(0xFFB91C1C), bg: Color(0xFFFEE2E2), group: 'EMIs'),
  ExpenseCategory(key: 'emi_bnpl', label: 'BNPL EMI', icon: 'Clock', color: Color(0xFFC2410C), bg: Color(0xFFFFEDD5), group: 'EMIs'),
  ExpenseCategory(key: 'credit_card', label: 'Credit Card Bill', icon: 'CreditCard', color: Color(0xFFB91C1C), bg: Color(0xFFFEE2E2), group: 'EMIs'),

  // Subscriptions
  ExpenseCategory(key: 'sub_ott', label: 'OTT / Streaming', icon: 'Tv2', color: Color(0xFF7E22CE), bg: Color(0xFFF3E8FF), group: 'Subscriptions'),
  ExpenseCategory(key: 'sub_music', label: 'Music', icon: 'Music', color: Color(0xFFBE185D), bg: Color(0xFFFCE7F3), group: 'Subscriptions'),
  ExpenseCategory(key: 'sub_cloud', label: 'Cloud Storage', icon: 'Cloud', color: Color(0xFF0369A1), bg: Color(0xFFE0F2FE), group: 'Subscriptions'),
  ExpenseCategory(key: 'sub_software', label: 'Software / SaaS', icon: 'AppWindow', color: Color(0xFF4338CA), bg: Color(0xFFE0E7FF), group: 'Subscriptions'),
  ExpenseCategory(key: 'sub_news', label: 'News / Magazine', icon: 'Newspaper', color: Color(0xFF334155), bg: Color(0xFFF1F5F9), group: 'Subscriptions'),
  ExpenseCategory(key: 'sub_gaming', label: 'Gaming', icon: 'Gamepad2', color: Color(0xFFA21CAF), bg: Color(0xFFFAE8FF), group: 'Subscriptions'),
  ExpenseCategory(key: 'sub_fitness', label: 'Fitness Club', icon: 'Dumbbell', color: Color(0xFF4D7C0F), bg: Color(0xFFECFCCB), group: 'Subscriptions'),
  ExpenseCategory(key: 'sub_edu', label: 'Learning', icon: 'BookOpen', color: Color(0xFF047857), bg: Color(0xFFD1FAE5), group: 'Subscriptions'),

  // Personal events
  ExpenseCategory(key: 'evt_birthday', label: 'Birthday', icon: 'Cake', color: Color(0xFFDB2777), bg: Color(0xFFFCE7F3), group: 'Events'),
  ExpenseCategory(key: 'evt_anniv', label: 'Anniversary', icon: 'Heart', color: Color(0xFFE11D48), bg: Color(0xFFFFE4E6), group: 'Events'),
  ExpenseCategory(key: 'evt_wedding', label: 'Wedding', icon: 'PartyPopper', color: Color(0xFFA21CAF), bg: Color(0xFFFAE8FF), group: 'Events'),
  ExpenseCategory(key: 'evt_festival', label: 'Festival', icon: 'Sparkles', color: Color(0xFFB45309), bg: Color(0xFFFEF3C7), group: 'Events'),
  ExpenseCategory(key: 'evt_funeral', label: 'Funeral / Punya', icon: 'Flower2', color: Color(0xFF334155), bg: Color(0xFFF1F5F9), group: 'Events'),
  ExpenseCategory(key: 'evt_religious', label: 'Religious', icon: 'Church', color: Color(0xFFB45309), bg: Color(0xFFFEF3C7), group: 'Events'),

  // Income & business
  ExpenseCategory(key: 'salary', label: 'Salary', icon: 'Wallet', color: Color(0xFF047857), bg: Color(0xFFD1FAE5), group: 'Income'),
  ExpenseCategory(key: 'software_saas', label: 'Software / AI / SaaS', icon: 'Bot', color: Color(0xFF4338CA), bg: Color(0xFFE0E7FF), group: 'Subscriptions'),

  // Tax & business
  ExpenseCategory(key: 'tax', label: 'Tax', icon: 'Receipt', color: Color(0xFF334155), bg: Color(0xFFF1F5F9), group: 'Other'),
  ExpenseCategory(key: 'business', label: 'Business', icon: 'Briefcase', color: Color(0xFF44403C), bg: Color(0xFFF5F5F4), group: 'Other'),
  ExpenseCategory(key: 'custom', label: 'Other', icon: 'Tag', color: Color(0xFF475569), bg: Color(0xFFF1F5F9), group: 'Other'),
];

/// Sub-item presets by category key — used in the Add Expense form.
const Map<String, List<String>> subCategories = {
  'sub_ott': ['Netflix', 'Amazon Prime', 'Disney+ Hotstar', 'SonyLIV', 'ZEE5', 'JioCinema', 'YouTube Premium', 'Apple TV+', 'Lionsgate Play', 'MUBI', 'Discovery+', 'Aha', 'Other'],
  'software_saas': ['ChatGPT Plus', 'Claude Pro', 'Lovable', 'GitHub Copilot', 'Cursor', 'Perplexity Pro', 'Gemini Advanced', 'Midjourney', 'Notion', 'Figma', 'Canva Pro', 'Microsoft 365', 'Google Workspace', 'Adobe CC', 'Zoom', 'Slack', 'Linear', 'Vercel', 'Other'],
  'insurance': ['LIC', 'HDFC Life', 'ICICI Prudential', 'SBI Life', 'Term Insurance', 'Health Insurance', 'Motor Insurance', 'Home Insurance', 'Travel Insurance', 'Other'],
  'sip_mf': ['SBI Bluechip', 'HDFC Flexi Cap', 'Axis Long Term Equity', 'Mirae Asset Large Cap', 'Parag Parikh Flexi Cap', 'Nippon Small Cap', 'ICICI Prudential', 'Other'],
  'credit_card': ['HDFC', 'SBI', 'ICICI', 'Axis', 'Kotak', 'AmEx', 'IndusInd', 'RBL', 'Yes Bank', 'Other'],
  'emi_home': ['HDFC', 'SBI', 'ICICI', 'Axis', 'LIC Housing', 'Bajaj Housing', 'PNB Housing', 'Other'],
  'emi_car': ['HDFC', 'SBI', 'ICICI', 'Axis', 'Kotak', 'Tata Capital', 'Bajaj Finserv', 'Other'],
  'emi_personal': ['HDFC', 'SBI', 'ICICI', 'Axis', 'Bajaj Finserv', 'Tata Capital', 'Fullerton', 'Other'],
  'electricity': ['MSEB', 'Tata Power', 'Adani Electricity', 'BSES', 'BESCOM', 'TSSPDCL', 'KSEB', 'Other'],
  'water': ['Municipal', 'Society', 'Tanker', 'Other'],
  'lpg': ['Indane', 'HP Gas', 'Bharat Gas', 'Piped Gas (MGL/IGL)', 'Other'],
  'jio_fiber': ['Jio Fiber', 'Airtel Xstream', 'ACT Fibernet', 'BSNL', 'Excitel', 'Other'],
  'mobile': ['Jio', 'Airtel', 'Vi', 'BSNL', 'Other'],
  'rent': ['House Rent', 'PG', 'Office Rent', 'Shop Rent', 'Other'],
  'fees': ['School Fees', 'College Fees', 'Coaching / Tuition', 'Online Course', 'Certification', 'Books', 'Other'],
  'salary': ['Monthly Salary', 'Bonus', 'Freelance', 'Consulting', 'Business Income', 'Other'],
  'evt_birthday': ['Family', 'Friends', 'Colleague', 'Kids', 'Relatives', 'Neighbours', 'Partner', 'Other'],
  'evt_anniv': ['Wedding Anniversary', 'Death Anniversary', 'Punya Tithi', 'Work Anniversary', 'Friendship Anniversary', 'Other'],
  'evt_wedding': ["Family Wedding", "Friend's Wedding", 'Colleague', 'Relative', 'Other'],
  'evt_festival': ['Diwali', 'Holi', 'Eid', 'Christmas', 'Ganesh Chaturthi', 'Navratri', 'Onam', 'Pongal', 'Raksha Bandhan', 'Dussehra', 'Makar Sankranti', 'Baisakhi', 'Other'],
  'evt_funeral': ['Funeral', 'Punya', 'Prayer Meeting', 'Tehravin', 'Uthavni', 'Other'],
  'evt_religious': ['Puja', 'Temple Visit', 'Havan', 'Kirtan', 'Satsang', 'Pilgrimage', 'Donation', 'Other'],
};

ExpenseCategory getCategory(String key) {
  for (final c in expenseCategories) {
    if (c.key == key) return c;
  }
  return expenseCategories.last;
}

const List<String> categoryGroups = [
  'Income', 'Daily', 'Utilities', 'Home', 'Family',
  'Investments', 'EMIs', 'Subscriptions', 'Events', 'Other',
];

// Category groups where a "Remind before" reminder makes sense.
const Set<String> _reminderGroups = {
  'Daily', 'Home', 'Utilities', 'Family', 'EMIs', 'Subscriptions', 'Investments', 'Other',
};

bool categorySupportsReminder(String categoryKey) {
  for (final c in expenseCategories) {
    if (c.key == categoryKey) return _reminderGroups.contains(c.group);
  }
  return false;
}

// High-level buckets used to group entries in the Activity page.
const List<String> activityBuckets = [
  'Insurance', 'OTT', 'SIP', 'Loans/EMI', 'Credit Card', 'Utility',
  'Rent', 'Education', 'Salary', 'Software/AI/SAAS', 'Personal Events', 'Other',
];

String getActivityBucket(String categoryKey) {
  if (categoryKey == 'insurance') return 'Insurance';
  if (categoryKey == 'sub_ott') return 'OTT';
  if (categoryKey.startsWith('sip_')) return 'SIP';
  if (categoryKey == 'credit_card') return 'Credit Card';
  if (categoryKey.startsWith('emi_')) return 'Loans/EMI';
  if (['electricity', 'water', 'lpg', 'jio_fiber', 'mobile', 'dth', 'newspaper'].contains(categoryKey)) return 'Utility';
  if (categoryKey == 'rent') return 'Rent';
  if (categoryKey == 'fees') return 'Education';
  if (categoryKey == 'salary') return 'Salary';
  if (categoryKey == 'software_saas' || categoryKey == 'sub_software') return 'Software/AI/SAAS';
  if (categoryKey.startsWith('evt_')) return 'Personal Events';
  return 'Other';
}

class BucketMeta {
  const BucketMeta(this.icon, this.color, this.bg);
  final String icon;
  final Color color;
  final Color bg;
}

const Map<String, BucketMeta> bucketMeta = {
  'Insurance': BucketMeta('ShieldCheck', Color(0xFF047857), Color(0xFFD1FAE5)),
  'OTT': BucketMeta('Tv2', Color(0xFF7E22CE), Color(0xFFF3E8FF)),
  'SIP': BucketMeta('LineChart', Color(0xFF15803D), Color(0xFFDCFCE7)),
  'Loans/EMI': BucketMeta('Landmark', Color(0xFFBE123C), Color(0xFFFFE4E6)),
  'Credit Card': BucketMeta('CreditCard', Color(0xFFB91C1C), Color(0xFFFEE2E2)),
  'Utility': BucketMeta('Zap', Color(0xFFD97706), Color(0xFFFEF3C7)),
  'Rent': BucketMeta('Home', Color(0xFFE11D48), Color(0xFFFFE4E6)),
  'Education': BucketMeta('GraduationCap', Color(0xFF7C3AED), Color(0xFFEDE9FE)),
  'Salary': BucketMeta('Wallet', Color(0xFF047857), Color(0xFFD1FAE5)),
  'Software/AI/SAAS': BucketMeta('Bot', Color(0xFF4338CA), Color(0xFFE0E7FF)),
  'Personal Events': BucketMeta('PartyPopper', Color(0xFFDB2777), Color(0xFFFCE7F3)),
  'Other': BucketMeta('Tag', Color(0xFF475569), Color(0xFFF1F5F9)),
};

class PaymentMethod {
  const PaymentMethod(this.key, this.label);
  final String key;
  final String label;
}

const List<PaymentMethod> paymentMethods = [
  PaymentMethod('upi', 'UPI'),
  PaymentMethod('cash', 'Cash'),
  PaymentMethod('card', 'Card'),
  PaymentMethod('netbanking', 'Net Banking'),
];

const List<String> subscriptionTypes = [
  'OTT', 'Music', 'Cloud', 'SaaS', 'Fitness', 'Gaming', 'News', 'Learning', 'Other',
];

const List<String> loanTypes = [
  'Home', 'Car', 'Two-wheeler', 'Personal', 'Education', 'Student',
  'Gold', 'Business', 'BNPL', 'Credit Card EMI', 'Agricultural', 'Top-up', 'Custom',
];

const List<String> investmentTypes = [
  'SIP', 'Step-up SIP', 'ELSS SIP', 'Index Fund SIP', 'SWP',
  'Mutual Fund', 'Stocks', 'FD', 'RD', 'PPF', 'NPS', 'EPF', 'APY',
  'NSC', 'SSY', 'Digital Gold', 'Sovereign Gold Bond', 'Crypto', 'Real Estate',
  'REITs', 'Bonds', 'Custom',
];

const List<String> eventTypes = [
  'Birthday', 'Wedding Anniversary', 'Wedding', 'Engagement',
  'Death Anniversary', 'Punya Tithi', 'Festival', 'Religious',
  'Housewarming', 'Baby Shower', 'Graduation', 'Custom',
];
