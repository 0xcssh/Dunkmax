import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/leaderboard.dart';
import '../../core/models/jump_log_entry.dart';
import '../../services/jump_log_store.dart';
import '../../theme/app_theme.dart';
import '../progress/jump_video_screen.dart';

/// FEED tab: leaderboards.
///
/// The reference app's board ranks a whole community — that needs a backend
/// and user accounts, neither of which exists here. Rather than fill the
/// board with invented athletes (see CLAUDE.md: no fabricated social proof),
/// this ranks the athlete's OWN logged jumps, best-first, through the pure
/// `Leaderboard` core. The community board is shown honestly locked.
class FeedTab extends StatelessWidget {
  final JumpLogStore jumpLogStore;

  const FeedTab({super.key, required this.jumpLogStore});

  @override
  Widget build(BuildContext context) {
    final ranked = Leaderboard.rank(jumpLogStore.entries);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          const _Header(),
          const SizedBox(height: 20),
          const _HeroCard(),
          const SizedBox(height: 24),
          const _SectionHeader(
            icon: Icons.emoji_events_outlined,
            title: 'YOUR BEST JUMPS',
            subtitle: 'Every jump you have analyzed, ranked by vertical.',
          ),
          const SizedBox(height: 12),
          if (ranked.isEmpty)
            const _EmptyBoardCard()
          else
            for (final row in ranked) ...[
              _RankedJumpRow(row: row),
              const SizedBox(height: 12),
            ],
          const SizedBox(height: 12),
          const _CommunityLockedCard(),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: DunkColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.groups_outlined, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        const Text(
          'LEADERBOARDS',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DunkColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DunkColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: DunkColors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.emoji_events, color: DunkColors.primary, size: 26),
          ),
          const SizedBox(height: 14),
          const Text('Leaderboards', style: DunkTheme.cardTitle),
          const SizedBox(height: 4),
          const Text(
            'Your personal board — every analyzed jump, ranked best-first.',
            style: TextStyle(color: DunkColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: DunkColors.primary, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: DunkColors.textTertiary, fontSize: 12),
        ),
      ],
    );
  }
}

/// One ranked row: badge · date + stat line · video thumbnail.
class _RankedJumpRow extends StatelessWidget {
  final RankedJump row;

  const _RankedJumpRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final entry = row.entry;
    final videoPath = entry.videoPath;
    final hasVideo = videoPath != null && File(videoPath).existsSync();

    return Material(
      color: DunkColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: hasVideo
            ? () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => JumpVideoScreen(
                      videoPath: videoPath,
                      verticalInches: entry.verticalInches,
                      recordedAt: entry.recordedAt,
                    ),
                  ),
                )
            : null,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DunkColors.stroke),
          ),
          child: Row(
            children: [
              _RankBadge(rank: row.rank),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(entry.recordedAt),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${entry.verticalInches}" vert',
                            style: const TextStyle(
                              color: DunkColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(
                            text: ' · ${entry.attemptType?.title ?? 'Jump'}',
                            style: const TextStyle(
                              color: DunkColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _JumpThumbnail(entry: entry, showPlayButton: hasVideo),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;

  const _RankBadge({required this.rank});

  // Podium fills, matching the reference: gold / silver / bronze.
  static const _gold = Color(0xFFE0A72B);
  static const _silver = Color(0xFF9BA1A8);
  static const _bronze = Color(0xFFB2703B);

  @override
  Widget build(BuildContext context) {
    final isPodium = rank <= 3;
    final color = switch (rank) {
      1 => _gold,
      2 => _silver,
      3 => _bronze,
      _ => DunkColors.primary,
    };

    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: isPodium
          ? const Icon(Icons.military_tech, color: Colors.white, size: 28)
          : Text(
              '#$rank',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
    );
  }
}

class _JumpThumbnail extends StatelessWidget {
  final JumpLogEntry entry;
  final bool showPlayButton;

  const _JumpThumbnail({required this.entry, required this.showPlayButton});

  @override
  Widget build(BuildContext context) {
    final thumbnailPath = entry.thumbnailPath;
    final hasThumbnail =
        thumbnailPath != null && File(thumbnailPath).existsSync();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 90,
        height: 64,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasThumbnail)
              Image.file(
                File(thumbnailPath),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _ThumbnailPlaceholder(),
              )
            else
              const _ThumbnailPlaceholder(),
            if (showPlayButton)
              Center(
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ThumbnailPlaceholder extends StatelessWidget {
  const _ThumbnailPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DunkColors.surfaceRaised,
      child: const Icon(
        Icons.videocam_off_outlined,
        color: DunkColors.textTertiary,
        size: 20,
      ),
    );
  }
}

class _EmptyBoardCard extends StatelessWidget {
  const _EmptyBoardCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: DunkColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DunkColors.stroke),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: DunkColors.surfaceRaised,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_outlined,
              color: DunkColors.textTertiary,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No jumps ranked yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Analyze your first jump to start your board.',
            textAlign: TextAlign.center,
            style: TextStyle(color: DunkColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// The community board needs accounts and a server — neither is built. Shown
/// locked and empty rather than teased with blurred fake names.
class _CommunityLockedCard extends StatelessWidget {
  const _CommunityLockedCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DunkColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DunkColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lock_outline, color: DunkColors.textTertiary, size: 16),
              SizedBox(width: 6),
              Text(
                'COMMUNITY',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Global rankings need athlete accounts — coming soon.',
            style: TextStyle(color: DunkColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DunkColors.surfaceRaised,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.groups_outlined, color: DunkColors.textTertiary, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "We won't show you made-up athletes. Once accounts ship, "
                    'this board fills with real verified jumps.',
                    style: TextStyle(color: DunkColors.textSecondary, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _monthAbbreviations = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// e.g. "Aug 4, 2026". Placeholder until the ARB catalog lands (CLAUDE.md).
String _formatDate(DateTime date) =>
    '${_monthAbbreviations[date.month - 1]} ${date.day}, ${date.year}';
