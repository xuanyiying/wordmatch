/// 轻量规则式词形还原（本地标注判定与 AI 结果对齐用）
///
/// 词书/学习状态表存原形（test/run），正文出现屈折形式（tests/ran）时
/// 需还原后再查表，否则同一个词既可能误标、也可能漏判。
/// 还原只影响「查集合是否命中」，界面展示仍用原文词形。
///
/// 使用方式：调用方先查原形，未命中再遍历 [candidates] 逐个尝试——
/// 规则可能产生多个候选（如 coding → code / cod），由目标集合决定取舍。
/// 误还原的最坏影响只是个别词漏命中，不会造成错误标注。
class WordLemmatizer {
  WordLemmatizer._();

  /// 不规则变化全表（屈折形式 → 原形）。
  ///
  /// 原形与屈折同形的动词（cut/hit/put/read/set/shut/let/cost/hurt/
  /// spread/thrust/burst/cast/broadcast 等）无需列出——调用方先查原形
  /// 必命中，走不到还原分支。多义词（saw/found/left/rose/wound 等）
  /// 先查原形兜底，还原候选只在原形未命中时生效。
  static const Map<String, String> _irregular = {
    // ===== be / have / do / go 系 =====
    'was': 'be', 'were': 'be', 'been': 'be', 'being': 'be',
    'has': 'have', 'had': 'have',
    'does': 'do', 'did': 'do', 'done': 'do', 'doing': 'do',
    'went': 'go', 'gone': 'go', 'goes': 'go', 'going': 'go',

    // ===== 高频不规则动词：过去式/过去分词 =====
    'arose': 'arise', 'arisen': 'arise',
    'awoke': 'awake', 'awoken': 'awake',
    'bore': 'bear', 'born': 'bear', 'borne': 'bear',
    'beaten': 'beat',
    'became': 'become', 'begun': 'begin', 'began': 'begin',
    'beheld': 'behold',
    'bent': 'bend', 'bade': 'bid', 'bidden': 'bid',
    'bound': 'bind', 'unbound': 'unbind',
    'bit': 'bite', 'bitten': 'bite',
    'blew': 'blow', 'blown': 'blow',
    'broke': 'break', 'broken': 'break',
    'bred': 'breed',
    'brought': 'bring',
    'built': 'build', 'rebuilt': 'rebuild',
    'burnt': 'burn',
    'bought': 'buy',
    'caught': 'catch',
    'chose': 'choose', 'chosen': 'choose',
    'clung': 'cling',
    'came': 'come',
    'crept': 'creep',
    'dealt': 'deal',
    'dove': 'dive', 'dived': 'dive',
    'dug': 'dig',
    'drew': 'draw', 'drawn': 'draw',
    'dreamt': 'dream',
    'drove': 'drive', 'driven': 'drive',
    'drank': 'drink', 'drunk': 'drink',
    'dwelt': 'dwell',
    'ate': 'eat', 'eaten': 'eat',
    'fell': 'fall', 'fallen': 'fall',
    'fed': 'feed',
    'felt': 'feel',
    'fought': 'fight',
    'found': 'find',
    'fled': 'flee',
    'flew': 'fly', 'flown': 'fly',
    'flung': 'fling',
    'forgot': 'forget', 'forgotten': 'forget',
    'forgave': 'forgive', 'forgiven': 'forgive',
    'forsook': 'forsake', 'forsaken': 'forsake',
    'froze': 'freeze', 'frozen': 'freeze',
    'got': 'get', 'gotten': 'get',
    'gave': 'give', 'given': 'give',
    'ground': 'grind',
    'grew': 'grow', 'grown': 'grow',
    'hung': 'hang',
    'heard': 'hear', 'overheard': 'overhear',
    'held': 'hold',
    'kept': 'keep',
    'knelt': 'kneel',
    'knew': 'know', 'known': 'know',
    'laid': 'lay', 'mislaid': 'mislay',
    'led': 'lead', 'misled': 'mislead',
    'leant': 'lean', 'leapt': 'leap',
    'learnt': 'learn',
    'left': 'leave',
    'lent': 'lend',
    'lay': 'lie', 'lain': 'lie',
    // 去 e 变 y-ing 的特殊词：规则 -ing 还原会产生错误候选（dying→dy）
    'dying': 'die', 'lying': 'lie', 'tying': 'tie', 'vying': 'vie',
    'lit': 'light',
    'lost': 'lose',
    'made': 'make',
    'meant': 'mean',
    'met': 'meet',
    'molten': 'melt',
    'mistook': 'mistake', 'mistaken': 'mistake',
    'mown': 'mow',
    'overcame': 'overcome',
    'overtook': 'overtake', 'overtaken': 'overtake',
    'paid': 'pay',
    'pled': 'plead',
    'proven': 'prove',
    'rode': 'ride', 'ridden': 'ride',
    'rang': 'ring', 'rung': 'ring',
    'rose': 'rise', 'risen': 'rise',
    'ran': 'run',
    'saw': 'see', 'seen': 'see',
    'sought': 'seek',
    'said': 'say',
    'sold': 'sell',
    'sent': 'send',
    'sewn': 'sew',
    'shook': 'shake', 'shaken': 'shake',
    'shaven': 'shave', 'shorn': 'shear',
    'shone': 'shine',
    'shot': 'shoot',
    'shown': 'show',
    'shrank': 'shrink', 'shrunk': 'shrink',
    'sang': 'sing', 'sung': 'sing',
    'sank': 'sink', 'sunk': 'sink',
    'sat': 'sit',
    'slew': 'slay', 'slain': 'slay',
    'slept': 'sleep',
    'slid': 'slide',
    'slung': 'sling',
    'smelt': 'smell',
    'snuck': 'sneak',
    'spoke': 'speak', 'spoken': 'speak',
    'sped': 'speed',
    'spelt': 'spell',
    'spent': 'spend',
    'spilt': 'spill',
    'spun': 'spin',
    'spat': 'spit',
    'spoilt': 'spoil',
    'sprang': 'spring', 'sprung': 'spring',
    'stood': 'stand',
    'stole': 'steal', 'stolen': 'steal',
    'stuck': 'stick',
    'stung': 'sting',
    'stank': 'stink', 'stunk': 'stink',
    'strode': 'stride', 'stridden': 'stride',
    'struck': 'strike',
    'strung': 'string',
    'strove': 'strive', 'striven': 'strive',
    'swore': 'swear', 'sworn': 'swear',
    'swept': 'sweep',
    'swelled': 'swell', 'swollen': 'swell',
    'swam': 'swim', 'swum': 'swim',
    'swung': 'swing',
    'took': 'take', 'taken': 'take',
    'taught': 'teach',
    'tore': 'tear', 'torn': 'tear',
    'told': 'tell', 'retold': 'retell',
    'thought': 'think', 'misunderstood': 'misunderstand',
    'threw': 'throw', 'thrown': 'throw',
    'trod': 'tread', 'trodden': 'tread',
    'understood': 'understand',
    'underwent': 'undergo', 'undergone': 'undergo',
    'undid': 'undo', 'undone': 'undo',
    'overdid': 'overdo', 'overdone': 'overdo',
    'redid': 'redo', 'redone': 'redo',
    'outdid': 'outdo', 'outdone': 'outdo',
    'rewrote': 'rewrite', 'rewritten': 'rewrite',
    'woke': 'wake', 'woken': 'wake',
    'wore': 'wear', 'worn': 'wear',
    'wove': 'weave', 'woven': 'weave',
    'wept': 'weep',
    'won': 'win',
    'wound': 'wind', 'rewound': 'rewind',
    'withdrew': 'withdraw', 'withdrawn': 'withdraw',
    'withheld': 'withhold',
    'withstood': 'withstand',
    'wrung': 'wring',
    'wrote': 'write', 'written': 'write',

    // ===== 不规则名词复数 =====
    'men': 'man', 'women': 'woman', 'children': 'child',
    'feet': 'foot', 'teeth': 'tooth', 'geese': 'goose',
    'mice': 'mouse', 'lice': 'louse', 'oxen': 'ox',
    'people': 'person', 'dice': 'die',
    'leaves': 'leaf', 'lives': 'life', 'knives': 'knife',
    'wives': 'wife', 'wolves': 'wolf', 'shelves': 'shelf',
    'halves': 'half', 'selves': 'self', 'loaves': 'loaf',
    'thieves': 'thief', 'calves': 'calf', 'hooves': 'hoof',
    'scarves': 'scarf', 'dwarves': 'dwarf', 'wharves': 'wharf',
    // 希腊/拉丁来源复数（技术与学术文本常见）。
    // 注意：bases/data/media 不在此列——bases 需保留规则还原 base 的路径，
    // data/media 现代英语多用作原形（先查原形兜底）
    'analyses': 'analysis', 'crises': 'crisis', 'theses': 'thesis',
    'diagnoses': 'diagnosis',
    'ellipses': 'ellipsis', 'emphases': 'emphasis',
    'hypotheses': 'hypothesis', 'oases': 'oasis',
    'parentheses': 'parenthesis', 'syntheses': 'synthesis',
    'axes': 'axis',
    'criteria': 'criterion', 'phenomena': 'phenomenon',
    'strata': 'stratum',
    'bacteria': 'bacterium', 'curricula': 'curriculum',
    'memoranda': 'memorandum', 'addenda': 'addendum',
    'millennia': 'millennium',
    'indices': 'index', 'appendices': 'appendix',
    'matrices': 'matrix', 'vertices': 'vertex',
    'cacti': 'cactus', 'foci': 'focus', 'fungi': 'fungus',
    'nuclei': 'nucleus', 'radii': 'radius',
    'syllabi': 'syllabus', 'alumni': 'alumnus',

    // ===== 不规则比较级/最高级 =====
    'better': 'good', 'best': 'good',
    'worse': 'bad', 'worst': 'bad',
    'elder': 'old', 'eldest': 'old',
    'less': 'little', 'least': 'little',
    'more': 'much', 'most': 'much',
    'further': 'far', 'farther': 'far',
  };

  /// 返回 [word]（任意大小写）的可能原形候选，不含原词自身，按可能性排序。
  ///
  /// 返回空列表表示无法还原（原词可能已是原形，或规则不适用）。
  static List<String> candidates(String word) {
    final w = word.toLowerCase();
    final irregular = _irregular[w];
    if (irregular != null) return [irregular];
    final out = <String>[];
    void add(String s) {
      if (s.length >= 2 && !out.contains(s)) out.add(s);
    }

    // 派生双写规则：stopped→stop / running→run / bigger→big
    void stemVariants(String stem) {
      add(stem);
      // 加 e 变体仅对长度足够的词干启用（us→use 这类以 s 结尾的除外），
      // 避免 thing→the 这类误命中常用词表、导致书内词被过滤的垃圾候选
      if (stem.length >= 3 || stem.endsWith('s')) add('${stem}e');
      if (stem.length >= 2 &&
          stem[stem.length - 1] == stem[stem.length - 2]) {
        add(stem.substring(0, stem.length - 1));
      }
    }

    // 所有者格：company's → company（复数所有格 companies' 的撇号
    // 不在词法 token 内，天然走 companies 的 ies 规则）。
    // 词干若本身是不规则形式（children's）则连同原形一并给出。
    if (w.length >= 4 && w.endsWith("'s")) {
      final stem = w.substring(0, w.length - 2);
      add(stem);
      final irr = _irregular[stem];
      if (irr != null) add(irr);
      return out;
    }

    // 复数 -ies → y（studies→study, cities→city）
    if (w.endsWith('ies') && w.length >= 5) {
      add('${w.substring(0, w.length - 3)}y');
      return out;
    }
    // 复数 -sses/-xes/-zes/-ches/-shes → 去 es（boxes→box, classes→class）
    if (w.length >= 5 &&
        (w.endsWith('sses') ||
            w.endsWith('xes') ||
            w.endsWith('zes') ||
            w.endsWith('ches') ||
            w.endsWith('shes'))) {
      add(w.substring(0, w.length - 2));
      return out;
    }
    // -es 且词根不以 e 结尾的类别：buses→bus / viruses→virus / echoes→echo。
    // 去 es 与去 s 两个候选都给（cases→case / shoes→shoe 各取所需），
    // 产生的垃圾候选（buse/cas）查表不命中、无副作用。
    if (w.length >= 5 && (w.endsWith('ses') || w.endsWith('oes'))) {
      add(w.substring(0, w.length - 2));
      add(w.substring(0, w.length - 1));
      return out;
    }
    // 过去式 -ied → y（carried→carry, tried→try）
    if (w.endsWith('ied') && w.length >= 5) {
      add('${w.substring(0, w.length - 3)}y');
      return out;
    }
    // 进行时 -ing：walking→walk, coding→code, running→run
    if (w.endsWith('ing') && w.length >= 5) {
      stemVariants(w.substring(0, w.length - 3));
      return out;
    }
    // 过去式 -ed：walked→walk, loved→love, stopped→stop
    if (w.endsWith('ed') && w.length >= 5) {
      stemVariants(w.substring(0, w.length - 2));
      return out;
    }
    // 最高级 -est：largest→large, fastest→fast
    if (w.endsWith('est') && w.length >= 6) {
      stemVariants(w.substring(0, w.length - 3));
      return out;
    }
    // 比较级 -er：faster→fast, wider→wide
    if (w.endsWith('er') && w.length >= 5) {
      stemVariants(w.substring(0, w.length - 2));
      return out;
    }
    // 复数 -s：tests→test（排除 class/status/axis 这类非复数 -s 词）
    if (w.endsWith('s') &&
        w.length >= 4 &&
        !w.endsWith('ss') &&
        !w.endsWith('us') &&
        !w.endsWith('is')) {
      final stem = w.substring(0, w.length - 1);
      if (stem.length >= 3) add(stem);
      return out;
    }
    // 副词 -ly：quickly→quick；-ily → y（happily→happy）
    if (w.endsWith('ly') && w.length >= 6) {
      if (w.endsWith('ily')) {
        add('${w.substring(0, w.length - 3)}y');
      } else {
        add(w.substring(0, w.length - 2));
      }
      return out;
    }
    return out;
  }
}
