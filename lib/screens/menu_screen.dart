import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/branding.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.hiddenVault.SlokaRecitation';
  static const String _feedbackEmail =
      'mailto:support@example.com?subject=Sloka Recitation Feedback';

  Future<void> _launch(BuildContext context, String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open link')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _shareApp() {
    Share.share(
      'Check out Sloka Recitation - a beautiful app to record and manage your slokas!\n$_playStoreUrl',
      subject: 'Sloka Recitation App',
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Sloka Recitation',
      applicationVersion: '1.0.0',
      applicationIcon: const IysLogo(size: 48),
      children: const [
        SizedBox(height: 12),
        Text(
          'Sloka Recitation is designed to help devotees, students, and practitioners internalize and memorize sacred scriptures through synchronized line-by-line recitation and high-quality audio recording.',
          style: TextStyle(height: 1.45),
        ),
        SizedBox(height: 12),
        Text(
          'Inspired by the teachings of the Vedic tradition and ISKCON Youth Services (IYS).',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  void _showHowTo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'How to Import / Export a Playlist',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Noto Serif',
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildHowToSection(
                    title: 'Export & share a playlist',
                    steps: [
                      'Open the Playlist tab and tap the playlist you want to send.',
                      'Tap the Share button.',
                      'The playlist is sent as a ".slokapack" file. That single file already contains every sloka and its audio.',
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildHowToSection(
                    title: 'Import a shared playlist',
                    steps: [
                      'Open the chat where you received the ".slokapack" file (for example in WhatsApp) and download it.',
                      'Tap the file, then tap the Share icon and choose "Sloka Recitation".',
                      'You can also open the app, go to the Playlist tab and tap Import, then pick the ".slokapack" file yourself.',
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Good to know: slokas you already have are not duplicated, and all imported audio is copied onto your device so it keeps working even offline.',
                            style: TextStyle(fontSize: 13, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildHowToSection({
    required String title,
    required List<String> steps,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.amber.shade100,
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    steps[i],
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _showLegal(BuildContext context, {required bool isTerms}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isTerms ? 'Terms of Service' : 'Privacy Policy'),
        content: SingleChildScrollView(
          child: Text(
            isTerms
                ? 'By using Sloka Recitation, you agree to the following terms:\n\n'
                    '1. The app is provided "as is" without warranty of any kind.\n\n'
                    '2. You are responsible for the content you record and store in the app.\n\n'
                    '3. Do not use the app to store or distribute copyrighted material without permission.\n\n'
                    '4. The developers are not liable for any data loss.\n\n'
                    'Thank you for using Sloka Recitation.'
                : 'Privacy Policy\n\n'
                    'Sloka Recitation operates completely offline-first.\n\n'
                    '• All slokas, playlists, and audio recordings remain strictly on your local device.\n'
                    '• We do not collect, track, store, or sell any of your personal data.\n'
                    '• No audio recordings or personal texts are transmitted to external cloud servers.\n'
                    '• Microphone access is only used when you explicitly tap Record to record your recitation.',
            style: const TextStyle(height: 1.45),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          // Branding header
          Center(
            child: Column(
              children: [
                const IysLogo(size: 72),
                const SizedBox(height: 10),
                Text(
                  'Sloka Recitation',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontFamily: 'Noto Serif',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Sacred Verse Recitation & Memorization',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Quote Card
          const QuoteCard(),

          const SizedBox(height: 8),

          // Guides & Help
          _card(
            context,
            children: [
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('How to Import / Export a Playlist'),
                subtitle: const Text('Share .slokapack files with friends'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showHowTo(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About Sloka Recitation'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showAbout(context),
              ),
            ],
          ),

          // App Actions
          _card(
            context,
            children: [
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share App'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _shareApp,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.star_outline),
                title: const Text('Rate Us'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _launch(context, _playStoreUrl),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.mail_outline),
                title: const Text('Send Feedback'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _launch(context, _feedbackEmail),
              ),
            ],
          ),

          // Legal
          _card(
            context,
            children: [
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Terms of Service'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showLegal(context, isTerms: true),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showLegal(context, isTerms: false),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Center(
            child: Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.outline,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, {required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: children,
      ),
    );
  }
}
