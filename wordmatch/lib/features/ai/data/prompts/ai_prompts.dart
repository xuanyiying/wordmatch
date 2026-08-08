/// AI 功能统一 Prompt 模板
///
/// 所有 prompt 要求模型返回严格 JSON，外层统一为 {"result": {...}}，
/// 便于 [AiClient.extractResult] 统一解析。
///
/// 审计要点（高效/准确/省成本）：
/// - 高效：减少冗余策略说明，扁平化"规则→示例"结构，去除两步推理
/// - 准确：去除"必须真题原句"幻觉陷阱，强化 schema 强约束、音标字段绑定目标词
/// - 省成本：压缩 prompt token 数 ~40%（删除重复强调、合并示例、压缩模板）
///
/// 输出 token 由 maxTokens 控制；本文件仅优化 input token（即 prompt 本身）。
class AiPrompts {
  AiPrompts._();

  // ─── System Prompts ───

  /// 通用 JSON 专家角色（system 重复代价低，可保留描述性）
  static const String systemJsonExpert =
      '你是英语学习助手，生成助记、例句、词汇网络等。'
      '所有回答必须严格使用 JSON 格式，不要输出任何解释文字、markdown 标题或额外换行。';

  /// 助记专用角色（更聚焦记忆技巧）
  static const String systemMnemonicExpert =
      '你是英语单词助记法专家，擅长谐音梗、词根拆解和脑洞联想。'
      '助记要简短好记，发音联想必须贴近单词真实读音。'
      '所有回答必须严格使用 JSON 格式，不要输出任何解释文字。';

  /// 口语对话角色（更地道自然）
  static const String systemDialogueCoach =
      '你是英语口语教练，擅长设计地道自然的对话。'
      '场景按目标单词的语义匹配高频日常情境，不预设地域或年龄段。'
      '对话中使用自然口语填充词（gonna / wanna / kinda / you know / well / really / I mean）。'
      '目标词必须在对话语境中自然出现。'
      '所有回答必须严格使用 JSON 格式，不要输出任何解释文字。';

  /// 阅读教学专家角色（词串烧用）
  static const String systemReadingTeacher =
      '你是英语阅读教学专家，擅长把零散单词编成符合高考/四级难度的英语短文。'
      '短文必须确保每个目标单词都真实出现，wordId 与给定列表完全一致。'
      '所有回答必须严格使用 JSON 格式，不要输出任何解释文字。';

  /// 错因消歧专家角色（游戏匹配失败提示用）
  static const String systemDisambiguationCoach =
      '你是英语词汇教学专家，擅长指出学生配对错误的原因并给出简短、有针对性的点拨。'
      '只针对「本次错误」解释，帮助用户明白「为什么错了、正确关联是什么」。'
      '文案 ≤60 字、口语化、带鼓励感，不堆砌术语。'
      '所有回答必须严格使用 JSON 格式，不要输出任何解释文字。';

  // ─── User Prompts ───

  /// 实时助记生成
  ///
  /// [word] 为目标单词纯英文文本，[definition] 为其中文释义（可能含词性）。
  static String mnemonicPrompt(String word, List<String> definition) => '''
为 "$word"（${definition.join('；')}）生成一条中文助记（≤60字）。

策略按优先级选其一：谐音 homophone > 拆词 association > 故事 story。
- 谐音：用贴近真实读音的中文谐音串起发音和词义
- 拆词：拆分词根/词缀并关联词义（如 pre+dict → 提前说 → 预测）
- 故事：用画面感故事链接音形义
type 必须与策略一致。没有接近谐音则改用拆词或故事。

```json
{"result":{"type":"homophone","content":"阿班等→阿班等不及了→放弃"}}
```
''';

  /// AI 生成例句
  ///
  /// 注：模型无法联网检索真题库，避免要求"真题原句"导致幻觉编造；
  /// 改为"仿真题风格"要求模型用真题常见话题和难度造句。
  ///
  /// [word] 为目标单词纯英文文本，[definition] 为中文释义。
  /// [knownPhonetic] 可选：若词库已提供真实美式音标则直接使用，避免模型猜测失真。
  static String exampleSentencesPrompt(
    String word,
    List<String> definition, {
    String knownPhonetic = '',
  }) => '''
为 "$word"（${definition.join('；')}）提供 2 个英文例句。

要求：
1. 第 1 句模仿高考真题风格（校园/家庭/环保/科技/社会话题），第 2 句模仿四六级风格（大学/实习/社交话题）
2. 句长 8-20 词，难度对标高中-四级
3. 高亮词用 ***word*** 包裹，须为 "$word" 在该语境下的正确形态（时态/单复数/派生词）
4. 每句附准确中文翻译
5. `phonetic` 是 "$word" 的美式 IPA 音标，必须依据真实读音生成${knownPhonetic.isEmpty ? '' : '（已知为 "$knownPhonetic"，直接使用该值）'}

```json
{
  "result": {
    "phonetic": "/əˈbændən/",
    "sentences": [
      {"en":"They ***abandoned*** the match because of the heavy rain.","zh":"因为大雨，他们放弃了比赛。"},
      {"en":"The village was ***abandoned*** after the flood.","zh":"洪水过后，这个村庄被废弃了。"}
    ]
  }
}
```
''';

  /// 同义词/反义词网络
  ///
  /// [word] 为目标单词纯英文文本，[definition] 为中文释义。
  /// [rootHint] 可选：词库已提供的真实词根拆解（如 "a+ban(禁令)+don"），
  /// 作为 related（同源词）的已知线索，提升生成准确性。
  static String wordNetworkPrompt(
    String word,
    List<String> definition, {
    String rootHint = '',
  }) => '''
为 "$word"（${definition.join('；')}）构建词汇网络${rootHint.isEmpty ? '' : '。已知该词的词根拆解为 "$rootHint"，related 中同源词应尽量与这些词根一致'}。

要求：
- synonyms：3-5 个同义词（词性词义与 "$word" 相近，优先高考/四级词汇）
- antonyms：0-3 个真反义词（确实没有则给空数组，不要硬编）
- related：2-3 个相关词（常见搭配/上下位词/同源词，注意区分词性）
- 每个词附简短中文释义（≤10字），不超过目标词难度

```json
{
  "result": {
    "synonyms":[{"word":"give up","definition":"放弃"}],
    "antonyms":[{"word":"keep","definition":"保持"}],
    "related":[{"word":"abandonment","definition":"放弃(名词)"}]
  }
}
```
''';

  /// 口语对话练习
  ///
  /// [word] 为目标单词纯英文文本，[definition] 为中文释义。
  static String dialoguePrompt(String word, List<String> definition) => '''
围绕 "$word"（${definition.join('；')}）设计一段 3-4 轮英语对话。

场景按目标词语义选最自然的一类：餐饮/课堂/社交/工作/出行，或其他合适场景。

硬性要求：
1. A、B 交替发言，总轮数 3-4 轮（6-8 句），禁止只有 2 轮
2. 目标词 "$word" 必须自然出现至少一次（正确形态），不要刻意强调
3. 每句英文附准确中文翻译（zh 字段）
4. 英文句子 ≤12 词，CEFR B1 难度；可自然使用 gonna/wanna/kinda/you know/well/really 等
5. `scenario` 是简短中文场景描述（如"宿舍聊周末兼职面试"）
6. `phonetic` 是 "$word" 的美式 IPA，依据真实读音生成

```json
{
  "result": {
    "scenario":"宿舍熄灯后聊周末兼职面试",
    "phonetic": "/əˈbændən/",
    "lines":[
      {"speaker":"A","en":"Did you ***abandon*** the milk tea job?","zh":"你不去奶茶店打工了吗？"},
      {"speaker":"B","en":"Yeah, the boss was kinda rude.","zh":"嗯，老板有点凶。"},
      {"speaker":"A","en":"Oh no, that's rough. New plan?","zh":"哎呀，那挺糟的。新计划呢？"},
      {"speaker":"B","en":"I'll try tutoring kids on weekends.","zh":"我周末去试试当家教。"}
    ]
  }
}
```
''';

  /// 每日学习报告
  static String dailyReportPrompt({
    required int completedNew,
    required int completedReview,
    required int wrongCount,
    required double accuracy,
    required List<String> wrongWords,
  }) =>
      '''
根据今日学习数据生成鼓励性学习报告。

数据：新学 $completedNew | 复习 $completedReview | 错误 $wrongCount 次 | 正确率 ${(accuracy * 100).toStringAsFixed(0)}% | 错词：${wrongWords.isEmpty ? '无' : wrongWords.join('、')}

要求：
1. encouragement：一句个性化鼓励（与数据匹配，不编造）
2. weakPoints：1-2 个真实薄弱点（无则 []）
3. suggestions：1-2 条具体可执行建议（如"复习今天错词"而非"多复习"）
4. 语气温暖像朋友，不要公文腔

```json
{
  "result": {
    "encouragement":"今天新学了15个词，很棒！",
    "weakPoints":["动词类错词较多"],
    "suggestions":["明天先复习 abandon、predict 这几个错词"]
  }
}
```
''';

  /// 游戏匹配失败的错因消歧
  ///
  /// [correctWord] 正确匹配的英文单词，[correctDefinition] 其中文释义。
  /// [userSelection] 用户点错的文本（可能是英文单词，也可能是错误释义）。
  /// 要求模型返回简短、有针对性的消歧文案。
  static String disambiguationPrompt({
    required String correctWord,
    required String correctDefinition,
    required String userSelection,
  }) => '''
用户在消消乐游戏中把「$correctWord」配错了。正确关联是「$correctDefinition」，但用户点的是「$userSelection」。

请用一句中文（≤60字）指出错误原因并给出正确提示，风格亲切、像老师点拨：
- 若用户把不同词配到了一起：说明正确匹配是「$correctWord = $correctDefinition」
- 若能看出易混点（如形近/义近/词性），简短点一句，不要长篇解释
- 不要提"试卷""考试真题"等，避免幻觉

```json
{"result":{"message":"book 作动词才是预订，这里考查名词词义“书”。"}}
```
''';

  /// AI 词库清洗（兼容现有 AiCleanService 的返回结构）
  static String wordbookCleanPrompt(String rawText) => '''
从以下文本中提取英语单词和中文释义。

清洗规则：
1. 提取每个英语单词及对应中文释义，保留词性标注（n./v./adj.等）
2. 剔除页码/序号/乱码/广告等无关内容
3. 释义多个含义用分号分隔（如 "放弃；抛弃"）
4. `phonetic` 推断美式 IPA 音标，依据真实读音生成
5. 为每个词生成一个 ≤10 词的简单例句，例句中单词与提取词一致

```json
{"result":{"words":[{"word":"abandon","phonetic":"/əˈbændən/","definition":["vt. 放弃；抛弃"],"example":"He abandoned the plan."}]}}
```

原始文本：
$rawText'''
      .trim();
}
