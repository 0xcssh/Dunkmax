import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/leaderboard.dart';
import '../../core/models/jump_log_entry.dart';
import '../../services/athlete_profile_store.dart';
import '../../services/jump_log_store.dart';
import '../../services/leaderboard_service.dart';
import '../../theme/app_theme.dart';
import '../progress/jump_video_screen.dart';
import 'display_name_dialog.dart';

/// How many rows of the global board we pull and paint.
const _globalBoardLimit = 50;

/// Why the global board has nothing to show.
enum _BoardState { loading, loaded, notConfigured, unavailable }

/// FEED tab: leaderboards.
///
/// Primary section is the GLOBAL board — every athlete's best measured
/// vertical, ranked. It is numbers only: name, vertical, height. No clips and
/// no thumbnails are ever uploaded (that would make this a user-generated-
/// content app, with the moderation obligations of App Store Guideline 1.2
/// attached); videos stay on the device and only ever appear on the personal
/// board below.
///
/// Every state here is honest: with no backend credentials, no network, or a
/// failed request, the board says so instead of inventing athletes
/// (CLAUDE.md: no fabricated social proof).
class FeedTab extends StatefulWidget {
  final JumpLogStore jumpLogStore;
  final AthleteProfileStore athleteProfileStore;
  final LeaderboardService leaderboardService;

  /// The athlete's height, published alongside their vertical so a number on
  /// the board can be read in context.
  final int heightInches;

  /// Current board name — empty until the athlete chooses one. Passed in (not
  /// just read from the store) so a change made in Settings rebuilds this tab
  /// and reloads the board.
  final String displayName;

  final VoidCallback onDisplayNameChanged;

  const FeedTab({
    super.key,
    required this.jumpLogStore,
    required this.athleteProfileStore,
    required this.leaderboardService,
    required this.heightInches,
    required this.displayName,
    required this.onDisplayNameChanged,
  });

  @override
  State<FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<FeedTab> {
  _BoardState _state = _BoardState.loading;
  List<RankedAthlete> _globalBoard = const [];
  String? _ownAthleteId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant FeedTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new name means a new row to publish and a board to re-read.
    if (oldWidget.displayName != widget.displayName) _load();
  }

  /// The athlete's best local measurement — what would be published.
  int? get _localBestInches {
    final ranked = Leaderboard.rank(widget.jumpLogStore.entries, limit: 1);
    return ranked.isEmpty ? null : ranked.first.entry.verticalInches;
  }

  Future<void> _load() async {
    final service = widget.leaderboardService;
    if (!service.isConfigured) {
      if (!mounted) return;
      setState(() {
        _state = _BoardState.notConfigured;
        _globalBoard = const [];
      });
      return;
    }

    if (mounted) setState(() => _state = _BoardState.loading);

    // Reconcile before reading: the Analyze flow deliberately knows nothing
    // about the backend, so the athlete's personal best is pushed from here,
    // whenever the board is opened or pulled. `submitBest` only writes an
    // improvement, and swallows every failure.
    final name = widget.displayName;
    final best = _localBestInches;
    if (name.isNotEmpty && best != null) {
      await service.submitBest(
        displayName: name,
        verticalInches: best,
        heightInches: widget.heightInches,
      );
    }

    final athletes = await service.topAthletes(limit: _globalBoardLimit);
    if (!mounted) return;
    setState(() {
      if (athletes == null) {
        _state = _BoardState.unavailable;
        _globalBoard = const [];
      } else {
        _state = _BoardState.loaded;
        _globalBoard =
            Leaderboard.rankAthletes(athletes, limit: _globalBoardLimit);
      }
      _ownAthleteId = service.athleteId;
    });
  }

  Future<void> _editDisplayName() async {
    final chosen = await showDisplayNameDialog(
      context,
      initialName: widget.displayName,
    );
    if (chosen == null) return;
    await widget.athleteProfileStore.setDisplayName(chosen);
    if (!mounted) return;
    // The parent re-reads the store and hands the new name back down, which
    // triggers didUpdateWidget -> _load().
    widget.onDisplayNameChanged();
  }

  @override
  Widget build(BuildContext context) {
    final personalBoard = Leaderboard.rank(widget.jumpLogStore.entries);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        color: DunkColors.primary,
        backgroundColor: DunkColors.surface,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            const _Header(),
            const SizedBox(height: 20),
            _SectionHeader(
              icon: Icons.public,
              title: 'ALL-TIME VERTICAL',
              subtitle: 'Every DunkIt athlete, ranked by their best measured '
                  'jump.',
              action: widget.displayName.isEmpty
                  ? null
                  : _SectionAction(
                      label: widget.displayName,
                      onTap: _editDisplayName,
                    ),
            ),
            const SizedBox(height: 12),
            ..._buildGlobalSection(),
            const SizedBox(height: 28),
            const _SectionHeader(
              icon: Icons.emoji_events_outlined,
              title: 'YOUR BEST JUMPS',
              subtitle: 'Every jump you have analyzed, ranked by vertical.',
            ),
            const SizedBox(height: 12),
            if (personalBoard.isEmpty)
              const _EmptyBoardCard()
            else
              for (final row in personalBoard) ...[
                _RankedJumpRow(row: row),
                const SizedBox(height: 12),
              ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGlobalSection() {
    switch (_state) {
      case _BoardState.notConfigured:
        return const [
          _BoardNoticeCard(
            icon: Icons.cloud_off_outlined,
            title: 'Global board is off in this build',
            body: 'This copy of the app was built without leaderboard '
                'credentials, so there is nothing to connect to. Everything '
                'else works offline.',
          ),
        ];
      case _BoardState.loading:
        return const [_BoardLoadingCard()];
      case _BoardState.unavailable:
        return const [
          _BoardNoticeCard(
            icon: Icons.wifi_off_outlined,
            title: "Can't reach the global board",
            body: 'Check your connection and pull down to try again. Your own '
                'jumps below are stored on this device and are unaffected.',
          ),
        ];
      case _BoardState.loaded:
        return [
          if (widget.displayName.isEmpty)
            _NamePromptCard(onSetName: _editDisplayName),
          if (widget.displayName.isEmpty) const SizedBox(height: 12),
          if (_globalBoard.isEmpty)
            const _BoardNoticeCard(
              icon: Icons.emoji_events_outlined,
              title: 'No athletes ranked yet',
              body: 'Nobody has posted a measured jump yet. Analyze one and '
                  'you take the top spot.',
            )
          else
            for (final row in _globalBoard) ...[
              _GlobalAthleteRow(
                row: row,
                isSelf: _ownAthleteId != null &&
                    row.athlete.athleteId == _ownAthleteId,
              ),
              const SizedBox(height: 12),
            ],
        ];
    }
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

/// A tappable chip on the right of a section header (used for the board name).
class _SectionAction {
  final String label;
  final VoidCallback onTap;

  const _SectionAction({required this.label, required this.onTap});
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final _SectionAction? action;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
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
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            if (action != null)
              Material(
                color: DunkColors.surface,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: action!.onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.person_outline,
                          color: DunkColors.textSecondary,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 120),
                          child: Text(
                            action!.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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

/// One global-board row: badge · name · `43" vert · 5'8"`.
class _GlobalAthleteRow extends StatelessWidget {
  final RankedAthlete row;
  final bool isSelf;

  const _GlobalAthleteRow({required this.row, required this.isSelf});

  @override
  Widget build(BuildContext context) {
    final athlete = row.athlete;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelf
            ? DunkColors.primary.withValues(alpha: 0.10)
            : DunkColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelf ? DunkColors.primary : DunkColors.stroke,
        ),
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
                  athlete.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                        text: athlete.formattedVertical,
                        style: const TextStyle(
                          color: DunkColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: ' · ${athlete.formattedHeight}',
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
          if (isSelf) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: DunkColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'YOU',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One personal-board row: badge · date + stat line · video thumbnail.
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

/// Honest empty/unavailable state for the global board — never a fake board.
class _BoardNoticeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _BoardNoticeCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DunkColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DunkColors.stroke),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: DunkColors.surfaceRaised,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: DunkColors.textTertiary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    color: DunkColors.textSecondary,
                    fontSize: 13,
                    height: 1.35,
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

/// Restrained loading state — three dimmed row skeletons, no spinner circus.
class _BoardLoadingCard extends StatelessWidget {
  const _BoardLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 3; i++) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DunkColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: DunkColors.stroke),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: DunkColors.surfaceRaised,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 12,
                        width: 130,
                        decoration: BoxDecoration(
                          color: DunkColors.surfaceRaised,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 10,
                        width: 90,
                        decoration: BoxDecoration(
                          color: DunkColors.surfaceRaised,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        const Text(
          'Loading the global board…',
          style: TextStyle(color: DunkColors.textTertiary, fontSize: 12),
        ),
      ],
    );
  }
}

/// Nothing is published until the athlete picks a name — this is the ask.
class _NamePromptCard extends StatelessWidget {
  final VoidCallback onSetName;

  const _NamePromptCard({required this.onSetName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DunkColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DunkColors.primary.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: DunkColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.badge_outlined,
                  color: DunkColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "You're not on the board yet",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Pick a board name and your best measured jump gets ranked with '
            'everyone else. Only the name, the vertical and your height are '
            'shared — never your clips.',
            style: TextStyle(
              color: DunkColors.textSecondary,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: DunkColors.primary,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: onSetName,
                child: Container(
                  height: 46,
                  alignment: Alignment.center,
                  child: const Text(
                    'SET MY BOARD NAME',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
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
