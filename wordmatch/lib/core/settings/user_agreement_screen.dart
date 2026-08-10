import 'package:flutter/material.dart';
import 'package:wordmatch/core/constants/app_sizes.dart';
import 'package:wordmatch/core/theme/app_color_scheme.dart';
import 'package:wordmatch/shared/widgets/gradient_page_header.dart';

/// 用户协议页面
class UserAgreementScreen extends StatelessWidget {
  const UserAgreementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            const GradientPageHeader(title: '用户协议', subtitle: '使用前请仔细阅读'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.pagePaddingH,
                  20,
                  AppSizes.pagePaddingH,
                  32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
              context,
              title: '用户协议',
              content: '更新日期：2025年1月1日\n\n'
                  '欢迎使用 WordMatch 词汇学习应用（以下简称"本应用"）。请您在使用本应用前，仔细阅读并充分理解本用户协议（以下简称"本协议"）。您一旦使用本应用，即视为您已阅读并同意受本协议约束。',
            ),
            _buildSection(
              context,
              title: '一、服务内容',
              content: '1. 本应用是一款词汇学习工具，提供单词记忆、复习、测试等功能，帮助用户提升词汇量。\n\n'
                  '2. 本应用提供词库选择与导入功能，用户可使用内置词库或自行导入词库进行学习。\n\n'
                  '3. 本应用提供 TTS 语音发音功能，帮助用户学习单词的正确读音。\n\n'
                  '4. 本应用提供可选的 AI 智能清洗功能，帮助用户整理杂乱的词库文本。\n\n'
                  '5. 我们有权根据实际运营情况对服务内容进行调整、变更或终止部分服务，并将提前在应用内通知。',
            ),
            _buildSection(
              context,
              title: '二、用户行为规范',
              content: '1. 您应当合法、合规地使用本应用，不得利用本应用从事任何违反法律法规的活动。\n\n'
                  '2. 您不得对本应用进行反编译、反汇编、修改、或创建衍生作品。\n\n'
                  '3. 您不得使用自动化工具（如爬虫、机器人等）访问本应用。\n\n'
                  '4. 您不得通过非正常手段干扰或破坏本应用的正常运行。\n\n'
                  '5. 您应自行配置并妥善保管 AI 服务的 API Key，因 API Key 泄露或滥用导致的损失由您自行承担。',
            ),
            _buildSection(
              context,
              title: '三、知识产权',
              content: '1. 本应用的所有内容，包括但不限于软件、界面设计、图标、文案、词库等，均受知识产权法律法规保护。\n\n'
                  '2. 未经我们书面许可，您不得以任何方式复制、传播、展示、修改本应用的任何部分。\n\n'
                  '3. 您自行导入的词库内容，其知识产权归原权利人所有。您应确保导入内容不侵犯任何第三方的知识产权。\n\n'
                  '4. 有道词典 API 提供的语音服务受有道相关服务条款约束。',
            ),
            _buildSection(
              context,
              title: '四、免责声明',
              content:
                  '1. 本应用提供的词汇释义和发音仅供参考学习之用，我们不保证其完全准确无误。对于因使用本应用产生的学习效果，我们不作任何明示或暗示的保证。\n\n'
                  '2. AI 智能清洗功能依赖于第三方大模型服务，清洗结果可能存在不准确之处，请您仔细核对后再使用。因 AI 清洗结果导致的任何损失，我们不承担责任。\n\n'
                  '3. 因不可抗力、网络故障、第三方服务中断等原因导致本应用无法正常使用的，我们不承担责任。\n\n'
                  '4. 您因使用本应用而与任何第三方产生的纠纷，由您自行解决，我们不承担任何责任。',
            ),
            _buildSection(
              context,
              title: '五、数据与隐私',
              content: '1. 关于您的数据收集、使用和存储，请参阅本应用的《隐私政策》。\n\n'
                  '2. 您的学习数据仅存储在设备本地，我们不会主动收集或上传您的个人数据。\n\n'
                  '3. 您可随时通过卸载本应用的方式删除所有本地数据。',
            ),
            _buildSection(
              context,
              title: '六、协议的变更',
              content: '1. 我们有权根据法律法规变化、产品运营需要等原因对本协议进行修订。\n\n'
                  '2. 修订后的协议将在应用内公示。若您在协议变更后继续使用本应用，即视为您同意受修订后的协议约束。\n\n'
                  '3. 若您不同意变更后的协议，您有权停止使用本应用。',
            ),
            _buildSection(
              context,
              title: '七、其他',
              content: '1. 本协议的订立、执行和解释均适用中华人民共和国法律。\n\n'
                  '2. 如本协议中的任何条款无论因何种原因完全或部分无效或不具有执行力，该条款不影响本协议其他条款的效力。\n\n'
                  '3. 如您对本协议有任何疑问，请通过以下方式联系我们：\n\n'
                  '电子邮箱：privacy@wordmatch.app',
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '— WordMatch 团队 —',
                style: TextStyle(
                  fontSize: 13,
                  color: colors.inkSoft,
                ),
              ),
            ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context,
      {required String title, required String content}) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colors.mintDeep.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colors.mintDeep,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.7,
              color: colors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
