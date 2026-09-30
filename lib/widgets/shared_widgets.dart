import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:medguide/theme/app_theme.dart';
import 'package:medguide/widgets/screen_help.dart';

// ─── Secure Badge ─────────────────────────────────────────────────────────────
class SecureBadge extends StatelessWidget {
  final String? sessionText;
  const SecureBadge({super.key, this.sessionText});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceBlue,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shield_outlined,
              size: 13, color: AppColors.primaryBlue),
          const SizedBox(width: 5),
          Text(
            sessionText ?? 'Zero Trust Active',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Risk Meter Widget ────────────────────────────────────────────────────────
class RiskMeterWidget extends StatelessWidget {
  final String label;
  final double percent;

  const RiskMeterWidget({
    super.key,
    required this.label,
    required this.percent,
  });

  Color get _riskColor {
    if (percent < 0.35) return AppColors.riskLow;
    if (percent < 0.65) return AppColors.riskMedium;
    return AppColors.riskHigh;
  }

  String get _riskLabel {
    if (percent < 0.35) return 'Low';
    if (percent < 0.65) return 'Moderate';
    return 'High';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircularPercentIndicator(
          radius: 42.0,
          lineWidth: 7.0,
          animation: true,
          animationDuration: 1200,
          percent: percent,
          center: Text(
            '${(percent * 100).toInt()}%',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: _riskColor,
            ),
          ),
          circularStrokeCap: CircularStrokeCap.round,
          progressColor: _riskColor,
          backgroundColor: _riskColor.withOpacity(0.12),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: _riskColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            _riskLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _riskColor,
            ),
          ),
        ),
      ],
    );
  }
}

class CountMeterWidget extends StatelessWidget {
  final String label;
  final int count;

  const CountMeterWidget({super.key, required this.label, required this.count});

  @override
  Widget build(BuildContext context) => Column(children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: count.toDouble()),
          duration: const Duration(milliseconds: 900),
          builder: (context, value, _) => Container(
            width: 84,
            height: 84,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.teal, width: 7),
              color: AppColors.teal.withOpacity(0.08),
            ),
            child: Text('${value.round()}',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.teal)),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 92,
          child: Text(label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ),
      ]);

// ─── Section Header ───────────────────────────────────────────────────────────
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.teal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            child: Text(
              actionLabel!,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 29,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: const TextStyle(fontSize: 11, color: AppColors.textLight),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Risk Badge ───────────────────────────────────────────────────────────────
class RiskBadge extends StatelessWidget {
  final String label;
  final Color color;

  const RiskBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ─── Feature Impact Bar ───────────────────────────────────────────────────────
class FeatureImpactBar extends StatelessWidget {
  final String feature;
  final String impact;
  final double percent;
  final Color color;

  const FeatureImpactBar({
    super.key,
    required this.feature,
    required this.impact,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                feature,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  impact,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 7,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Med App Bar ──────────────────────────────────────────────────────────────
class MedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final bool showSecureBadge;
  final String? helpTopic;
  final List<Widget>? actions;

  const MedAppBar({
    super.key,
    required this.title,
    this.showBack = false,
    this.showSecureBadge = true,
    this.helpTopic,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.cardWhite,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: showBack,
      leading: showBack
          ? IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: AppColors.primaryBlue,
              ),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
      title: Text(title, style: Theme.of(context).textTheme.headlineMedium),
      actions: [
        if (showSecureBadge) const SecureBadge(),
        if (actions != null) ...actions!,
        ScreenHelpButton(topic: helpTopic ?? title),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: AppColors.border, height: 1),
      ),
    );
  }
}

// ─── Info Row ─────────────────────────────────────────────────────────────────
class InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const InfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style:
                const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Disclaimer Banner ────────────────────────────────────────────────────────
class DisclaimerBanner extends StatelessWidget {
  const DisclaimerBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.amber.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.amber.withOpacity(0.3)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.amber, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'This tool provides decision-support insights and does not replace professional medical diagnosis.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
