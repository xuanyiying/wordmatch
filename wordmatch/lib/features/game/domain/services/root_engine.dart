/// 词根拆解结果
class RootBreakdown {
  final String prefix;
  final String root;
  final String suffix;
  final String meaning;

  const RootBreakdown({
    this.prefix = '',
    this.root = '',
    this.suffix = '',
    this.meaning = '',
  });

  bool get isValid => root.isNotEmpty || prefix.isNotEmpty || suffix.isNotEmpty;

  String get formatted {
    final parts = <String>[];
    if (prefix.isNotEmpty) parts.add(prefix);
    if (root.isNotEmpty) parts.add(root);
    if (suffix.isNotEmpty) parts.add(suffix);
    return parts.join('-');
  }
}

/// 词根拆解规则引擎
class RootEngine {
  RootEngine._();

  static const Map<String, String> prefixes = {
    'un': '否定',
    're': '再',
    'pre': '前',
    'dis': '否定',
    'mis': '错误',
    'over': '过度',
    'out': '超出',
    'sub': '下',
    'super': '超',
    'inter': '之间',
    'trans': '跨越',
    'ex': '向外',
    'in': '向内',
    'im': '否定',
    'il': '否定',
    'ir': '否定',
    'anti': '反对',
    'auto': '自动',
    'bi': '双',
    'co': '共同',
    'counter': '反对',
    'de': '向下',
    'en': '使',
    'fore': '前',
    'mid': '中间',
    'mini': '小',
    'multi': '多',
    'non': '非',
    'post': '后',
    'pro': '向前',
    'semi': '半',
    'under': '下',
    'up': '向上',
  };

  static const Map<String, String> suffixes = {
    'tion': '名词',
    'sion': '名词',
    'ment': '名词',
    'ness': '名词',
    'ity': '名词',
    'ence': '名词',
    'ance': '名词',
    'able': '可…的',
    'ible': '可…的',
    'ful': '充满',
    'less': '无',
    'ous': '形容词',
    'ive': '形容词',
    'al': '形容词',
    'ial': '形容词',
    'ical': '形容词',
    'ent': '形容词',
    'ant': '形容词',
    'ly': '副词',
    'ing': '进行',
    'ed': '过去',
    'er': '者',
    'or': '者',
    'ist': '主义者',
    'ism': '主义',
    'ize': '化',
    'ise': '化',
    'fy': '化',
    'ate': '做',
    'en': '使',
    'dom': '领域',
    'ship': '身份',
    'hood': '状态',
    'ward': '方向',
    'ure': '结果',
    'age': '总称',
  };

  static const Map<String, String> roots = {
    'dict': '说',
    'spect': '看',
    'port': '搬运',
    'tract': '拉',
    'duct': '引导',
    'ject': '投',
    'clud': '关闭',
    'rupt': '打破',
    'struct': '建造',
    'scrib': '写',
    'script': '写',
    'cred': '相信',
    'viv': '活',
    'mort': '死',
    'anim': '生命',
    'cap': '取',
    'cept': '取',
    'ceed': '走',
    'cess': '走',
    'flect': '弯曲',
    'flex': '弯曲',
    'grad': '步',
    'gress': '步',
    'mit': '发送',
    'miss': '发送',
    'pend': '悬挂',
    'pens': '悬挂',
    'pos': '放置',
    'press': '压',
    'rect': '直',
    'secut': '跟随',
    'sequ': '跟随',
    'sist': '站立',
    'stat': '站立',
    'tain': '保持',
    'ten': '保持',
    'tend': '伸展',
    'tens': '伸展',
    'ven': '来',
    'vent': '来',
    'vert': '转',
    'vers': '转',
    'vis': '看',
    'vid': '看',
    'volv': '转',
    'volve': '转',
    'gen': '产生',
    'loc': '地方',
    'log': '说话',
    'ology': '学科',
    'meter': '测量',
    'phon': '声音',
    'scop': '观察',
    'graph': '写画',
    'gram': '写画',
    'path': '感情',
    'ped': '脚',
    'phil': '爱',
    'poli': '城市',
    'pop': '人民',
    'psych': '心理',
    'sci': '知道',
    'sign': '标记',
    'spir': '呼吸',
    'tele': '远',
    'therm': '热',
    'vac': '空',
    'val': '价值',
    'verb': '词语',
    'vinc': '征服',
    'vict': '征服',
    'voc': '声音',
    'flu': '流',
    'form': '形状',
    'frag': '破碎',
    'fract': '破碎',
    'fund': '底部',
    'fus': '倾倒',
    'gest': '携带',
    'grav': '重',
    'greg': '群',
    'her': '粘附',
    'hes': '粘附',
    'lev': '举起',
    'liber': '自由',
    'lig': '绑定',
    'liqu': '液体',
    'luc': '光',
    'lum': '光',
    'magn': '大',
    'man': '手',
    'mar': '海',
    'mater': '母亲',
    'min': '小',
    'mir': '惊奇',
    'mon': '警告',
    'mov': '移动',
    'mut': '改变',
    'nav': '船',
    'nomin': '名字',
    'nov': '新',
    'numer': '数',
    'oper': '工作',
    'opt': '选择',
    'ori': '升起',
    'pac': '和平',
    'pater': '父亲',
    'pet': '追求',
    'ple': '充满',
    'plex': '折叠',
    'plic': '折叠',
    'pon': '放置',
    'pot': '力量',
    'preci': '价格',
    'prim': '第一',
    'pug': '打斗',
    'punc': '刺',
    'purg': '清洁',
    'put': '计算',
    'quer': '抱怨',
    'quis': '寻求',
    'rat': '推理',
    'rig': '僵硬',
    'rog': '问',
    'rub': '红',
    'sac': '神圣',
    'sanct': '神圣',
    'scind': '切',
    'sens': '感觉',
    'sent': '感觉',
    'ser': '连接',
    'sert': '连接',
    'simil': '相似',
    'solv': '松开',
    'solu': '松开',
    'som': '睡眠',
    'soph': '智慧',
    'sort': '种类',
    'spers': '散开',
    'spin': '刺',
    'spond': '承诺',
    'string': '绑定',
    'strict': '绑定',
    'tang': '触摸',
    'tact': '触摸',
    'teg': '覆盖',
    'tempor': '时间',
    'terr': '土地',
    'test': '证据',
    'tim': '害怕',
    'tom': '切',
    'tor': '扭曲',
    'tort': '扭曲',
    'trib': '给予',
    'trud': '推',
    'trus': '推',
    'turb': '扰乱',
    'urg': '工作',
    'vad': '走',
    'vas': '走',
    'vel': '覆盖',
    'ver': '真实',
    'vig': '活力',
    'vol': '意愿',
  };

  /// 对单词进行词根拆解（最长匹配算法）
  static RootBreakdown analyze(String word) {
    final lowerWord = word.toLowerCase();

    // 1. 匹配后缀（从长到短）
    String suffix = '';
    String suffixMeaning = '';
    String remaining = lowerWord;

    final sortedSuffixes = suffixes.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final s in sortedSuffixes) {
      if (lowerWord.length > s.length + 2 && lowerWord.endsWith(s)) {
        suffix = s;
        suffixMeaning = suffixes[s]!;
        remaining = lowerWord.substring(0, lowerWord.length - s.length);
        break;
      }
    }

    // 2. 匹配前缀（从长到短）
    String prefix = '';
    String prefixMeaning = '';
    String rootPart = remaining;

    final sortedPrefixes = prefixes.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final p in sortedPrefixes) {
      if (remaining.length > p.length + 2 && remaining.startsWith(p)) {
        prefix = p;
        prefixMeaning = prefixes[p]!;
        rootPart = remaining.substring(p.length);
        break;
      }
    }

    // 3. 匹配词根
    String matchedRoot = '';
    String rootMeaning = '';

    if (rootPart.length >= 3) {
      if (roots.containsKey(rootPart)) {
        matchedRoot = rootPart;
        rootMeaning = roots[rootPart]!;
      } else {
        for (var len = rootPart.length - 1; len >= 3; len--) {
          for (var start = 0; start <= rootPart.length - len; start++) {
            final sub = rootPart.substring(start, start + len);
            if (roots.containsKey(sub)) {
              matchedRoot = sub;
              rootMeaning = roots[sub]!;
              break;
            }
          }
          if (matchedRoot.isNotEmpty) break;
        }
      }
    }

    if (matchedRoot.isEmpty && prefix.isEmpty && suffix.isEmpty) {
      return const RootBreakdown();
    }

    final meaningParts = <String>[];
    if (prefixMeaning.isNotEmpty) meaningParts.add(prefixMeaning);
    if (rootMeaning.isNotEmpty) meaningParts.add(rootMeaning);
    if (suffixMeaning.isNotEmpty) meaningParts.add(suffixMeaning);

    return RootBreakdown(
      prefix: prefix,
      root: matchedRoot,
      suffix: suffix,
      meaning: meaningParts.join(' + '),
    );
  }
}
