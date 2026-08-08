import 'package:flutter/material.dart';
import 'package:wordmatch/core/constants/app_sizes.dart';
import 'package:wordmatch/core/theme/app_color_scheme.dart';

/// 隐私政策页面
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('隐私政策'),
        backgroundColor: colors.mintDeep,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
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
              title: '隐私政策',
              content: '更新日期：2025年1月1日\n\n'
                  '欢迎使用 WordMatch 词汇学习应用（以下简称"本应用"）。我们非常重视您的隐私保护和个人信息安全。本隐私政策将帮助您了解我们如何处理您的信息。',
            ),
            _buildSection(
              context,
              title: '一、我们收集的信息',
              content: '本应用仅收集最少必要的数据以提供核心功能：\n\n'
                  '1. 学习进度数据：包括您已学习的单词、学习次数、正确率等，这些数据仅存储在您的设备本地，不会上传至任何服务器。\n\n'
                  '2. 词库数据：您导入或选择的词库信息，同样仅存储在设备本地。\n\n'
                  '3. 应用设置：包括主题偏好、学习计划等配置信息，存储在设备本地。\n\n'
                  '我们不会收集您的姓名、电话号码、身份证号、电子邮箱等个人身份信息。',
            ),
            _buildSection(
              context,
              title: '二、信息的使用',
              content: '我们使用上述信息仅用于以下目的：\n\n'
                  '1. 提供词汇学习功能，包括学习进度跟踪和复习提醒。\n'
                  '2. 保存您的学习偏好和应用设置。\n'
                  '3. 优化您的学习体验。\n\n'
                  '我们不会将您的信息用于任何其他目的，也不会将您的信息出售或分享给任何第三方。',
            ),
            _buildSection(
              context,
              title: '三、网络服务说明',
              content: '本应用的以下功能需要使用网络：\n\n'
                  '1. TTS 语音发音：使用有道词典 API 提供单词发音服务。当您点击发音按钮时，应用会向有道服务器发送待发音的单词文本，不包含任何个人身份信息。\n\n'
                  '2. AI 智能清洗：如果您配置了大模型 API Key，应用会将待清洗的词库文本发送至您指定的 AI 服务接口进行处理。此功能为可选功能，由您自主配置，相关数据传输遵循您所选 AI 服务的隐私政策。\n\n'
                  '除上述场景外，本应用不会主动发起任何网络请求。',
            ),
            _buildSection(
              context,
              title: '四、信息的存储',
              content:
                  '1. 所有学习数据和设置信息均存储在您的设备本地，使用 SharedPreferences 和本地数据库进行持久化。\n\n'
                  '2. 我们不运营任何云端服务器来存储您的个人数据。\n\n'
                  '3. 当您卸载本应用时，所有本地数据将被一并删除。\n\n'
                  '4. 建议您定期通过应用内的导出功能备份重要学习数据。',
            ),
            _buildSection(
              context,
              title: '五、信息安全',
              content: '1. 我们采取合理的技术措施保护您的信息安全，包括本地数据加密存储。\n\n'
                  '2. 您自行配置的 API Key 仅存储在设备本地，不会传输至我们或任何第三方服务器。\n\n'
                  '3. 网络通信均使用 HTTPS 加密传输，确保数据传输安全。\n\n'
                  '4. 请您妥善保管设备，避免设备被他人未经授权访问。',
            ),
            _buildSection(
              context,
              title: '六、未成年人保护',
              content:
                  '我们高度重视对未成年人个人信息的保护。本应用适合所有年龄段用户使用，不会主动收集未成年人的个人信息。如果您是未成年人的监护人，请您指导未成年人合理使用本应用。',
            ),
            _buildSection(
              context,
              title: '七、隐私政策的变更',
              content:
                  '我们可能会适时修订本隐私政策。政策变更后，我们会在应用内通知您。若您在政策变更后继续使用本应用，即视为您同意受修订后的隐私政策约束。',
            ),
            _buildSection(
              context,
              title: '八、联系我们',
              content: '如您对本隐私政策有任何疑问、意见或建议，请通过以下方式联系我们：\n\n'
                  '电子邮箱：privacy@wordmatch.app\n\n'
                  '我们将尽快回复您的来信。',
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
