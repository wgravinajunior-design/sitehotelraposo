import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../screens/admin_page.dart';

class Footer extends StatelessWidget {
  final Function(int) onNavItemTap;

  const Footer({super.key, required this.onNavItemTap});

  void _launchWhatsApp() async {
    final Uri url = Uri.parse('https://wa.me/5522999912144');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _launchPhone() async {
    final Uri url = Uri.parse('tel:+552238472144');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _launchEmail() async {
    final Uri url = Uri.parse('mailto:contatos@hotelfazendaraposo.com.br');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _launchSocial(String platform) async {
    String path = platform == 'instagram' 
        ? 'https://www.instagram.com/hotelfazendaraposo/' 
        : 'https://www.facebook.com/hotelfazendaraposo/';
    final Uri url = Uri.parse(path);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth < 800;

    return Container(
      width: double.infinity,
      color: HotelColors.darkSlate,
      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 60.0),
      child: Column(
        children: [
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBrandingColumn(),
                    const SizedBox(height: 40),
                    _buildLinksColumn(),
                    const SizedBox(height: 40),
                    _buildContactColumn(),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(flex: 3, child: _buildBrandingColumn()),
                    const SizedBox(width: 40),
                    Expanded(flex: 2, child: _buildLinksColumn()),
                    const SizedBox(width: 40),
                    Expanded(flex: 3, child: _buildContactColumn()),
                  ],
                ),
          const SizedBox(height: 40),
          const Divider(color: HotelColors.primaryGreen, thickness: 1.0),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: isMobile ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '© 2026 Hotel Fazenda Raposo. Todos os direitos reservados.',
                style: HotelTypography.bodyTextSmall.copyWith(color: HotelColors.textGrey),
                textAlign: TextAlign.center,
              ),
              if (!isMobile)
                Row(
                  children: [
                    Text(
                      'Desenvolvido em Flutter Web | ',
                      style: HotelTypography.bodyTextSmall.copyWith(color: HotelColors.accentGold.withOpacity(0.8)),
                    ),
                    GestureDetector(
                      onTap: () => _showAdminLoginDialog(context),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Text(
                          'Painel Admin',
                          style: HotelTypography.bodyTextSmall.copyWith(
                            color: HotelColors.accentGold,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (isMobile) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _showAdminLoginDialog(context),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Text(
                  'Painel Administrativo',
                  style: HotelTypography.bodyTextSmall.copyWith(
                    color: HotelColors.accentGold,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAdminLoginDialog(BuildContext context) {
    final TextEditingController pinController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: HotelColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          title: Row(
            children: [
              const Icon(Icons.lock_outline, color: HotelColors.accentGold),
              const SizedBox(width: 12),
              Text(
                'Acesso Administrativo',
                style: HotelTypography.cardTitle.copyWith(fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Digite a senha para acessar o painel de gerenciamento do hotel:',
                style: HotelTypography.bodyTextSmall,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pinController,
                obscureText: true,
                keyboardType: TextInputType.text,
                style: const TextStyle(letterSpacing: 8, fontSize: 18, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: '••••',
                  hintStyle: const TextStyle(letterSpacing: 8),
                  filled: true,
                  fillColor: HotelColors.bgLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: const BorderSide(color: HotelColors.lightGrey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: const BorderSide(color: HotelColors.accentGold, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancelar', style: HotelTypography.buttonText.copyWith(color: HotelColors.textGrey)),
            ),
            ElevatedButton(
              onPressed: () {
                final password = pinController.text;
                if (password == 'raposo2026' || password == '1234') {
                  Navigator.of(dialogContext).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminPage(),
                    ),
                  ).then((value) {
                    if (value == true) {
                      onNavItemTap(-1);
                    }
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Senha incorreta! Tente novamente.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: HotelColors.primaryGreen,
                foregroundColor: HotelColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Entrar', style: HotelTypography.buttonText),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBrandingColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: HotelColors.primaryGreen,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: const Icon(
                Icons.nature_people_rounded,
                color: HotelColors.accentGold,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HOTEL FAZENDA',
                  style: HotelTypography.cardSubtitle.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: HotelColors.accentGold,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  'Raposo',
                  style: HotelTypography.cardTitle.copyWith(
                    fontSize: 24,
                    color: HotelColors.white,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'O Hotel Fazenda Raposo integra-se à natureza em uma área de 1.500.000 m² de muito verde, com lago natural, lazer para toda a família e fonte própria de águas minerais com propriedades terapêuticas reconhecidas.',
          style: HotelTypography.bodyTextSmall.copyWith(
            color: HotelColors.textGrey.withOpacity(0.8),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            _buildSocialIcon(Icons.facebook, () => _launchSocial('facebook')),
            const SizedBox(width: 12),
            _buildSocialIcon(Icons.camera_alt, () => _launchSocial('instagram')), // Instagram
          ],
        ),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: HotelColors.primaryGreen.withOpacity(0.3),
            shape: BoxShape.circle,
            border: Border.all(color: HotelColors.primaryGreen, width: 1.0),
          ),
          child: Icon(icon, color: HotelColors.accentGold, size: 20),
        ),
      ),
    );
  }

  Widget _buildLinksColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NAVEGAÇÃO',
          style: HotelTypography.cardSubtitle.copyWith(color: HotelColors.white),
        ),
        const SizedBox(height: 20),
        _buildFooterLink('O Hotel', () => onNavItemTap(1)),
        _buildFooterLink('Acomodações', () => onNavItemTap(2)),
        _buildFooterLink('Água Mineral', () => onNavItemTap(3)),
        _buildFooterLink('Lazer', () => onNavItemTap(4)),
        _buildFooterLink('Galeria', () => onNavItemTap(5)),
        _buildFooterLink('Eventos', () => onNavItemTap(6)),
        _buildFooterLink('Contato', () => onNavItemTap(7)),
      ],
    );
  }

  Widget _buildFooterLink(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Text(
            label,
            style: HotelTypography.bodyTextSmall.copyWith(
              color: HotelColors.textGrey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CONTATOS & LOCALIZAÇÃO',
          style: HotelTypography.cardSubtitle.copyWith(color: HotelColors.white),
        ),
        const SizedBox(height: 20),
        _buildContactItem(
          Icons.location_on_outlined,
          'Av. Augusto Maria Martinez Toja, 224\nRaposo, Itaperuna - RJ, 28333-000',
        ),
        const SizedBox(height: 12),
        _buildContactItem(
          Icons.phone_outlined,
          '(22) 3847-2144',
          onTap: _launchPhone,
        ),
        const SizedBox(height: 12),
        _buildContactItem(
          Icons.chat_bubble_outline_rounded,
          '(22) 99991-2144 (WhatsApp)',
          onTap: _launchWhatsApp,
        ),
        const SizedBox(height: 12),
        _buildContactItem(
          Icons.mail_outline_rounded,
          'contatos@hotelfazendaraposo.com.br',
          onTap: _launchEmail,
        ),
        const SizedBox(height: 20),
        Text(
          'CENTRAL DE RESERVAS',
          style: HotelTypography.bookingLabel.copyWith(color: HotelColors.accentGold),
        ),
        const SizedBox(height: 4),
        Text(
          'Segunda a Sábado: 9h às 17h\nDomingo: 9h às 14h',
          style: HotelTypography.bodyTextSmall.copyWith(color: HotelColors.textGrey, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildContactItem(IconData icon, String label, {VoidCallback? onTap}) {
    return MouseRegion(
      cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: HotelColors.accentGold, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: HotelTypography.bodyTextSmall.copyWith(
                  color: HotelColors.textGrey,
                  decoration: onTap != null ? TextDecoration.underline : TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
