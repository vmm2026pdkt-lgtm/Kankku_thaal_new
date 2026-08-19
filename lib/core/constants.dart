// ============================================================
// SUPABASE CONFIG — same project as the web app (kanakku-thaal)
// Reuses the existing backend: profiles + user_data tables, RLS,
// and the same anon key that is already public in index.html.
// ============================================================
class SupabaseConfig {
  static const String url = 'https://saqwrtwdoncrqygqwdgg.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNhcXdydHdkb25jcnF5Z3F3ZGdnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY4NTQyNDQsImV4cCI6MjEwMjQzMDI0NH0.G0oTh_QEJQihZkKerQYK-PrG5V_ga5FTRA4co7Nu58E';
}

class PrefsKeys {
  static const settings = 'kanakku_settings_v1';
  static const budgets = 'kanakku_budgets_v1';
  static const recurring = 'kanakku_recurring_v1';
  static const setupDone = 'kanakku_setup_done_v1';
  static const pin = 'kanakku_pin_v1';
}

class DefaultCategories {
  static const income = [
    {'id': 'salary', 'icon': '💼', 'name': 'சம்பளம்'},
    {'id': 'business', 'icon': '🏪', 'name': 'வியாபாரம்'},
    {'id': 'freelance', 'icon': '💻', 'name': 'ஃப்ரீலான்ஸ்'},
    {'id': 'rent', 'icon': '🏠', 'name': 'வாடகை வருமானம்'},
    {'id': 'interest', 'icon': '🏦', 'name': 'வட்டி'},
    {'id': 'other_income', 'icon': '➕', 'name': 'மற்ற வருமானம்'},
  ];

  static const expense = [
    {'id': 'food', 'icon': '🍚', 'name': 'உணவு'},
    {'id': 'grocery', 'icon': '🛒', 'name': 'மளிகை சாமான்'},
    {'id': 'petrol', 'icon': '⛽', 'name': 'பெட்ரோல்'},
    {'id': 'transport', 'icon': '🚌', 'name': 'போக்குவரத்து'},
    {'id': 'vehicle', 'icon': '🔧', 'name': 'வாகன பராமரிப்பு'},
    {'id': 'medical', 'icon': '💊', 'name': 'மருத்துவம்'},
    {'id': 'education', 'icon': '📚', 'name': 'கல்வி'},
    {'id': 'electricity', 'icon': '💡', 'name': 'மின்சாரம்'},
    {'id': 'rent_exp', 'icon': '🏡', 'name': 'வாடகை'},
    {'id': 'clothing', 'icon': '👗', 'name': 'ஆடை'},
    {'id': 'postal', 'icon': '📱', 'name': 'தொலைபேசி'},
    {'id': 'others', 'icon': '📦', 'name': 'மற்றவை'},
  ];

  static const catColors = [
    0xFFf0a500, 0xFF3ecf8e, 0xFFf05c5c, 0xFF5b8ff9,
    0xFFa78bfa, 0xFFf472b6, 0xFF22c1c3, 0xFFfbbf24,
    0xFF84cc16, 0xFFfb923c, 0xFF38bdf8, 0xFFc084fc,
  ];
}

const monthNamesTa = [
  'ஜனவரி', 'பிப்ரவரி', 'மார்ச்', 'ஏப்ரல்', 'மே', 'ஜூன்',
  'ஜூலை', 'ஆகஸ்ட்', 'செப்டம்பர்', 'அக்டோபர்', 'நவம்பர்', 'டிசம்பர்'
];

const whatsappNumber = '917825007487';
