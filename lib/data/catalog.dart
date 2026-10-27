import 'package:flutter/material.dart';
import 'models.dart';

const languages = <Language>[
  Language('en', 'English', 'English', 'Latin'),
  Language('hi', 'Hindi', 'हिन्दी', 'Devanagari'),
  Language('gu', 'Gujarati', 'ગુજરાતી', 'Gujarati'),
  Language('mr', 'Marathi', 'मराठी', 'Devanagari'),
  Language('bn', 'Bengali', 'বাংলা', 'Bengali'),
  Language('te', 'Telugu', 'తెలుగు', 'Telugu'),
  Language('ta', 'Tamil', 'தமிழ்', 'Tamil'),
  Language('kn', 'Kannada', 'ಕನ್ನಡ', 'Kannada'),
  Language('ml', 'Malayalam', 'മലയാളം', 'Malayalam'),
  Language('or', 'Odia', 'ଓଡ଼ିଆ', 'Odia'),
  Language('as', 'Assamese', 'অসমীয়া', 'Assamese'),
  Language('pa', 'Punjabi', 'ਪੰਜਾਬੀ', 'Gurmukhi'),
  Language('ne', 'Nepali', 'नेपाली', 'Devanagari'),
  Language('ru', 'Russian', 'Русский', 'Cyrillic'),
  Language('es', 'Spanish', 'Español', 'Latin'),
  Language('pt', 'Portuguese', 'Português', 'Latin'),
];

Language langOf(String code) => languages.firstWhere((l) => l.code == code, orElse: () => languages.first);

const categories = <String>[
  "Acharya's Glorification",
  'Vedic Culture',
  'Youth',
  "Beginner's Guide",
  'Philosophy',
  'Epics & Itihasa',
  'Pilgrimage',
  'Women & Family',
  'Posters',
];

const categoryIcons = <String, IconData>{
  "Acharya's Glorification": Icons.auto_awesome,
  'Vedic Culture': Icons.temple_hindu_outlined,
  'Youth': Icons.bolt,
  "Beginner's Guide": Icons.explore_outlined,
  'Philosophy': Icons.psychology_alt_outlined,
  'Epics & Itihasa': Icons.menu_book,
  'Pilgrimage': Icons.landscape_outlined,
  'Women & Family': Icons.diversity_1_outlined,
  'Posters': Icons.image_outlined,
};

class _Work {
  final String key, title, category, author, description;
  final int pages, price, year;
  final String langs;
  final Map<String, String> local;
  final bool featured, isNew, hard;
  final Color color;
  final String aliases;
  const _Work(this.key, this.title, this.category, this.price, this.pages, this.langs, this.color, this.description,
      {this.author = 'HH Bhakti Vikasa Swami',
      this.year = 0,
      this.local = const {},
      this.featured = false,
      this.isNew = false,
      this.hard = false,
      this.aliases = ''});
}

// Titles, years, page counts and language availability follow the live
// books.bvks.com catalogue. Prices marked (est.) could not be read from the
// store from this environment and should be confirmed against the live site.
const _works = <_Work>[
  _Work('ramayana', 'Ramayana: The Story of Lord Rama', 'Epics & Itihasa', 450, 600, 'en hi gu mr kn te ru', Color(0xFF1F6F6B),
      'Hardcover, 2012. The Rāmāyaṇa retold by Bhakti Vikāsa Swami. Also available in Hindi, Gujarati, Marathi, Kannada, Telugu and Russian.',
      year: 2012,
      local: {'hi': 'रामायण', 'gu': 'રામાયણ', 'mr': 'रामायण', 'kn': 'ರಾಮಾಯಣ', 'te': 'రామాయణం'},
      featured: true,
      hard: true,
      aliases: 'ramayan ram valmiki sita lord rama'),
  _Work('sri-caitanya-mahaprabhu', 'Śrī Caitanya Mahāprabhu', "Acharya's Glorification", 250, 178, 'en gu', Color(0xFFB5541C),
      'An overview of the life and teachings of Śrī Caitanya Mahāprabhu. First published 2010.',
      year: 2010, local: {'gu': 'શ્રી ચૈતન્ય મહાપ્રભુ'}, featured: true, aliases: 'chaitanya gaurasundara gauranga'),
  _Work('sri-vamsidasa-babaji', 'Śrī Vaṁśīdāsa Bābāji', "Acharya's Glorification", 180, 152, 'en', Color(0xFF8D6E63),
      'The life and glories of Śrī Vaṁśīdāsa Bābāji. Paperback, 2010, 152 pages.',
      year: 2010, aliases: 'vamsidas babaji vamshidas'),
  _Work('mothers-masters', 'Mothers & Masters', 'Women & Family', 180, 240, 'en', Color(0xFF9C4A5A),
      'Presents traditionalist arguments for the direction of the Kṛṣṇa consciousness movement.',
      aliases: 'mothers and masters women'),
  _Work('brahmacarya', 'Brahmacarya in Kṛṣṇa Consciousness', 'Youth', 120, 272, 'en hi', Color(0xFF7B3FA0),
      'A “user’s guide” to brahmacārī life. Paperback, 272 pages. ISBN 978-81-902332-3-1.',
      year: 0, local: {'hi': 'कृष्णभावनामृत में ब्रह्मचर्य'}, aliases: 'brahmachari brahmacharya celibacy krishna krsna'),
  _Work('mood-and-mission', 'The Mood and Mission of Śrīla Prabhupāda', "Acharya's Glorification", 220, 280, 'en', Color(0xFFC25E0C),
      'Covers the life and teachings of Śrīla Prabhupāda from the perspective of his mood and mission.',
      isNew: true, featured: true, aliases: 'prabhupada acbsp'),
  _Work('nectar-of-book-distribution', 'The Nectar of Book Distribution', 'Philosophy', 150, 220, 'en', Color(0xFF3B6EA5),
      'A manual on book distribution, consisting mainly of statements by pioneers, leaders and other experienced devotees in the field of book distribution.',
      author: 'HDG A.C. Bhaktivedanta Swami Prabhupada', aliases: 'book distribution sankirtana'),
  _Work('sri-bhaktisiddhanta-vaibhava', 'Śrī Bhaktisiddhānta Vaibhava', "Acharya's Glorification", 2199, 1576, 'en', Color(0xFF455A64),
      'Hardcover, 2010, 1576 pages. The life and glories of Śrīla Bhaktisiddhānta Sarasvatī Ṭhākura.',
      year: 2010, hard: true, aliases: 'bhaktisiddhanta saraswati thakura'),
  _Work('my-memories-of-prabhupada', 'My Memories of Śrīla Prabhupāda', "Acharya's Glorification", 200, 240, 'en hi', Color(0xFFD9871F),
      'Personal reminiscences of Śrīla Prabhupāda by Bhakti Vikāsa Swami.',
      local: {'hi': 'श्रील प्रभुपाद के बारे में मेरी स्मृतियाँ'}, aliases: 'prabhupada memories smrti'),
  _Work('jaya-prabhupada', 'Jaya Śrīla Prabhupāda!', "Acharya's Glorification", 160, 240, 'en hi gu ru bn', Color(0xFFE0A100),
      'Memories, anecdotes and tributes to Śrīla Prabhupāda. Hindi edition: 2014, 240 pages, paperback. Also available in Gujarati and Russian.',
      year: 2014, local: {'hi': 'जय श्रील प्रभुपाद', 'gu': 'જય શ્રીલ પ્રભુપાદ!', 'bn': 'জয় শ্রীল প্রভুপাদ!'}, featured: true, aliases: 'prabhupada acbsp'),
  _Work('message-to-indian-youth', 'भारतीय नवयुवकों को संदेश', 'Youth', 120, 256, 'hi', Color(0xFF2A8FBD),
      'Hindi, paperback, 2010, 256 pages — a message for India’s youth.',
      year: 2010, aliases: 'bharatiya navayuvakon sandesh youth message'),
  _Work('on-pilgrimage-in-holy-india', 'On Pilgrimage in Holy India', 'Pilgrimage', 220, 128, 'en', Color(0xFF2E7D32),
      'Hardcover, 2009, 128 pages. A pilgrim’s account of holy places in India.',
      year: 2009, hard: true, aliases: 'pilgrimage tirtha yatra holy india'),
  _Work('lekha-mala', 'Lekha-mālā: A Garland of Writings', 'Philosophy', 200, 310, 'en', Color(0xFF8A3B12),
      'Paperback, Bhakti Vikas Trust, 2016. ISBN 978-93-82109-34-1. A collection of essays and articles.',
      year: 2016, aliases: 'lekhamala articles essays'),
  _Work('glimpses', 'Glimpses of Traditional Indian Life', 'Vedic Culture', 220, 280, 'en', Color(0xFF6B7A2B),
      'Customs, etiquette and values of traditional Indian society.', aliases: 'gotil culture'),
  _Work('beginners-guide', 'A Beginner’s Guide to Kṛṣṇa Consciousness', "Beginner's Guide", 120, 160, 'en bn', Color(0xFFB8860B),
      'A practical introduction to the philosophy and practice of Kṛṣṇa consciousness.',
      local: {'bn': 'কৃষ্ণভাবনামৃতের প্রাথমিক নির্দেশিকা'}, featured: true, aliases: 'krishna krsna consciousness beginner intro'),
];

int _hash(String s) {
  var h = 7;
  for (final c in s.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return h;
}

List<Book> _buildBooks() {
  final out = <Book>[];
  var rank = 0;
  for (final w in _works) {
    for (final l in w.langs.split(' ')) {
      final id = '${w.key}-$l';
      final h = _hash(id);
      final title = l == 'en' ? w.title : (w.local[l] ?? w.title);
      final prices = <BookFormat, int>{
        BookFormat.paperback: w.price + (l == 'en' ? 0 : -10 + (h % 3) * 10),
        if (w.hard) BookFormat.hardcover: w.price + 150,
        if (l == 'en' || l == 'hi') BookFormat.ebook: (w.price * 0.4).round(),
      };
      out.add(Book(
        id: id,
        group: w.key,
        title: title,
        language: l,
        author: w.author,
        category: w.category,
        description: w.description,
        isbn: '978-93-82109-${(h % 900 + 100)}-${h % 10}',
        pages: w.pages + (h % 20),
        prices: prices,
        // A few titles are low / out of stock to demo stock states.
        stock: (w.isNew || w.featured || l == 'en') ? 20 + h % 180 : (h % 11 == 0 ? 0 : (h % 7 == 0 ? 4 : 20 + h % 180)),
        rating: 3.9 + (h % 11) / 10,
        ratingCount: 12 + h % 340,
        color: w.color,
        isNew: w.isNew && (l == 'en' || l == 'hi' || l == 'gu'),
        featured: w.featured && (l == 'en' || l == 'hi' || l == 'gu'),
        subEligible: h % 9 != 0,
        aliases: w.aliases,
        newRank: rank++,
      ));
    }
  }
  return out;
}

final List<Book> allBooks = _buildBooks();

const _posterDefs = <(String, String, int, Color, String)>[
  ('Pañca-tattva', 'poster-pancha-tattva', 99, Color(0xFFD9871F), 'pancatattva panch tattva'),
  ('Rādhā-Kṛṣṇa Yugala', 'poster-radha-krishna', 129, Color(0xFFB5541C), 'radha krishna krsna'),
  ('Lord Nṛsiṁha', 'poster-nrsimha', 99, Color(0xFF7A2E0E), 'narasimha nrisimha'),
  ('Jagannātha Ratha-yātrā', 'poster-jagannath', 149, Color(0xFF3B6EA5), 'jagannath rath yatra'),
  ('Tulasī Mahārāṇī', 'poster-tulasi', 79, Color(0xFF2E7D32), 'tulsi tulasi devi'),
  ('Śrīla Prabhupāda', 'poster-prabhupada', 119, Color(0xFFC25E0C), 'prabhupada acbsp'),
  ('Hare Kṛṣṇa Mahā-mantra', 'poster-mahamantra', 89, Color(0xFFE0A100), 'hare krishna mantra'),
  ('Navadvīpa Dhāma Map', 'poster-navadvipa-map', 199, Color(0xFF455A64), 'mayapur map dham'),
];

final List<Book> posters = [
  for (var i = 0; i < _posterDefs.length; i++)
    Book(
      id: _posterDefs[i].$2,
      group: _posterDefs[i].$2,
      title: _posterDefs[i].$1,
      language: 'en',
      author: 'BVT Art Studio',
      category: 'Posters',
      description:
          'Museum-quality A2 art print on 170 GSM matte paper, shipped in a protective tube. Prototype artwork is generated in-app.',
      isbn: 'POSTER-${100 + i}',
      pages: 1,
      prices: {BookFormat.poster: _posterDefs[i].$3},
      stock: i == 4 ? 3 : 60 + i * 9,
      rating: 4.4 + (i % 5) / 10,
      ratingCount: 30 + i * 13,
      color: _posterDefs[i].$4,
      isPoster: true,
      subEligible: false,
      aliases: _posterDefs[i].$5,
    ),
];

final List<Book> catalog = [...allBooks, ...posters];

Book bookById(String id) => catalog.firstWhere((b) => b.id == id);
Book? maybeBook(String id) {
  for (final b in catalog) {
    if (b.id == id) return b;
  }
  return null;
}

List<Book> siblings(Book b) => catalog.where((x) => x.group == b.group).toList();

// ---------------------------------------------------------------------------
// Subscriptions

const plans = <Plan>[
  Plan(
    id: 'book',
    name: 'Per-Book Access',
    kind: 'book',
    blurb: 'Unlock one title in the in-app reader.',
    monthly: 49,
    yearly: 399,
    trialDays: 3,
    perks: ['1 title of your choice', 'Reader with bookmarks & highlights', 'Progress sync across devices', 'Offline chapters'],
  ),
  Plan(
    id: 'lang',
    name: 'Language All-Access',
    kind: 'language',
    blurb: 'Unlimited reading in one language.',
    monthly: 149,
    yearly: 1299,
    trialDays: 7,
    perks: ['Every title in one language', 'New releases included', 'Reader with bookmarks & highlights', 'Offline chapters', 'Cancel any time'],
  ),
  Plan(
    id: 'global',
    name: 'Global All-Access',
    kind: 'global',
    blurb: 'Every book in all 16 languages.',
    monthly: 349,
    yearly: 2999,
    trialDays: 7,
    perks: ['All titles, all 16 languages', 'Early access to new releases', 'Priority WhatsApp support', 'Up to 3 devices', 'Gift to a friend'],
  ),
];

Plan planById(String id) => plans.firstWhere((p) => p.id == id);

// ---------------------------------------------------------------------------
// Content

final reviewSamples = <Review>[
  const Review('Radhika M.', 5, 'Beautifully produced and very easy to follow. The binding is sturdy and the print quality is excellent.', '12 Sep 2026'),
  const Review('Arjun S.', 4, 'Clear explanations with wonderful references. Delivery took a week but everything arrived well packed.', '28 Aug 2026'),
  const Review('Lakshmi N.', 5, 'I gifted this to my family — everyone loved it. Highly recommended for beginners.', '03 Aug 2026'),
  const Review('Govind P.', 4, 'Good content. Would love a larger-print edition.', '17 Jul 2026', verified: false),
];

final testimonials = <(String, String, String)>[
  ('The reading subscription lets me carry the whole library on my phone. A real blessing.', 'Madhavi D.', 'Pune'),
  ('Ordering for our temple’s book table was so easy with the bulk pricing.', 'Kishore Prabhu', 'Surat'),
  ('WhatsApp updates meant I always knew where my parcel was.', 'Anita R.', 'Bengaluru'),
];

final articles = <Article>[
  Article('a1', 'Why Read Daily? The Power of Small Habits',
      'Ten minutes a day can transform your understanding. Here is how to build a sustainable reading routine.',
      'BVT Editorial', '14 Oct 2026', '5 min', const [
        'Habits compound. A modest commitment of ten minutes each morning, before the day’s noise begins, is far easier to sustain than an ambitious weekly marathon.',
        'Choose a fixed place and time. Keep your book — or the reader app — within easy reach. Over weeks, the practice becomes natural.',
        'Mark a few passages that speak to you, and revisit them at the end of the week. Bookmarks and highlights in the reader make this effortless.',
      ], ['beginners-guide', 'brahmacarya'], const Color(0xFFD9871F)),
  Article('a2', 'On Brahmacarya: A Practical Introduction',
      'What brahmacarya means in Kṛṣṇa consciousness and how students can approach it.',
      'BVT Editorial', '02 Oct 2026', '6 min', const [
        'Ekādaśī, the eleventh day of each lunar fortnight, is observed with fasting from grains and increased devotional activity.',
        'Beginners can start by observing a light fast and chanting a few extra rounds. Gradually deepen the practice with guidance from experienced devotees.',
      ], ['brahmacarya', 'beginners-guide'], const Color(0xFFB8860B)),
  Article('a3', 'Planning a Pilgrimage in Holy India',
      'Tips for preparing a pilgrimage to the holy places of India.',
      'BVT Editorial', '21 Sep 2026', '8 min', const [
        'Navadvīpa-dhāma consists of nine islands, each associated with a different aspect of devotional service.',
        'The best season to visit is October to March. Plan to spend at least three days to experience the main sites with a local guide.',
      ], ['on-pilgrimage-in-holy-india', 'sri-caitanya-mahaprabhu'], const Color(0xFF3B6EA5)),
  Article('a4', 'Raising Children with Values: Stories That Stay',
      'How stories from the Itihāsa help children develop character and curiosity.',
      'BVT Editorial', '09 Sep 2026', '4 min', const [
        'Stories carry values more gently than lectures. A bedtime story of Prahlāda or Dhruva can leave a lasting impression.',
      ], ['ramayana', 'mothers-masters'], const Color(0xFF2A8FBD)),
];

final faqs = <(String, String)>[
  ('Can I cancel anytime?', 'Yes. Monthly plans can be paused or cancelled from Account → Subscriptions. Access continues until the end of the billing period.'),
  ('What happens if a payment fails?', 'You get a 7-day grace period with retry prompts over WhatsApp and email. Access is suspended only if all retries fail.'),
  ('Can I read offline?', 'Yes. Download chapters from subscribed titles. Content stays encrypted and is tied to your signed-in account.'),
  ('Is there a free trial?', 'Each plan includes a free trial. Trial length is shown on the plan card and is configurable by BVT.'),
  ('Can I gift a subscription?', 'Yes. Choose “Gift this plan” and enter a registered user’s email or WhatsApp number.'),
  ('Which payment methods are supported?', 'India: UPI, cards, net banking, wallets via Razorpay Subscriptions. International: cards via Stripe Billing, Apple Pay on iOS.'),
];

const readerChapters = <Chapter>[
  Chapter('Preface', [
    'This is placeholder reading content for the clickable prototype. In the production app, chapters are delivered as encrypted, token-gated content tied to the signed-in account.',
    'Use the controls to try font size, brightness, night mode, bookmarks and highlights. Long-press or double-tap a paragraph to highlight it.',
  ]),
  Chapter('Chapter 1 — The Beginning', [
    'Every journey begins with a single step. The reader keeps your place automatically and syncs progress across your devices so you can continue exactly where you stopped.',
    'Paragraphs are laid out with generous line spacing to reduce eye strain. Adjust the text size to whatever feels most comfortable for long reading sessions.',
    'Tap the bookmark icon in the top bar to save this page. All bookmarks are available from the contents sheet.',
    'The content of this section is sample text only and does not reproduce any published work.',
  ]),
  Chapter('Chapter 2 — Daily Practice', [
    'Consistency matters more than intensity. A short, regular session builds understanding steadily over time.',
    'Try highlighting a sentence that stands out. Highlights appear in saffron and are listed alongside your bookmarks.',
    'When the night mode is enabled, the page switches to a warm dark theme which is easier on the eyes after sunset.',
  ]),
  Chapter('Chapter 3 — Going Deeper', [
    'Subscribers can download chapters for offline reading. Downloaded chapters remain encrypted and cannot be exported as raw files.',
    'Reading sessions are validated server-side and signed URLs expire within one hour, so there are no permanent download links.',
    'This marks the end of the sample content. Thank you for exploring the prototype reader.',
  ]),
];

const indianStates = <String>[
  'Andhra Pradesh', 'Assam', 'Bihar', 'Delhi', 'Goa', 'Gujarat', 'Haryana', 'Karnataka', 'Kerala',
  'Madhya Pradesh', 'Maharashtra', 'Odisha', 'Punjab', 'Rajasthan', 'Tamil Nadu', 'Telangana',
  'Uttar Pradesh', 'West Bengal',
];

const countries = <String>['India', 'United States', 'United Kingdom', 'Canada', 'Australia', 'Russia', 'Brazil', 'Nepal', 'Other'];

const ebookStores = <(String, IconData, Color)>[
  ('Kindle', Icons.import_contacts, Color(0xFF232F3E)),
  ('Apple Books', Icons.apple, Color(0xFF1C1C1E)),
  ('Google Play Books', Icons.play_arrow_rounded, Color(0xFF1A73E8)),
];

const promoCodes = <String, (String, double)>{
  'BVT10': ('10% off your order', 0.10),
  'GITA20': ('20% off Gītā titles — demo: 20% off', 0.20),
  'FIRST50': ('Flat ₹50 off first order (demo: 5%)', 0.05),
};
