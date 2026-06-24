import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import 'reservation_form.dart';

class BookingBar extends StatefulWidget {
  const BookingBar({super.key});

  @override
  State<BookingBar> createState() => _BookingBarState();
}

class _BookingBarState extends State<BookingBar> {
  DateTime? _checkIn;
  DateTime? _checkOut;
  int _adults = 1;
  int _children = 0;

  Future<void> _selectDate(BuildContext context, bool isCheckIn) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: isCheckIn ? 1 : 2)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: HotelColors.primaryGreen,
              onPrimary: HotelColors.white,
              onSurface: HotelColors.darkSlate,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkIn = picked;
          // Ajusta automaticamente a data de saída se for antes ou igual a de entrada
          if (_checkOut != null && !_checkOut!.isAfter(_checkIn!)) {
            _checkOut = _checkIn!.add(const Duration(days: 1));
          }
        } else {
          _checkOut = picked;
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Selecionar';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _triggerReservation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ReservationForm(
        initialCheckin: _checkIn,
        initialCheckout: _checkOut,
        initialAdults: _adults,
        initialChildren: _children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth < 800;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: HotelColors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: HotelColors.primaryGreen.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: HotelColors.primaryGreen.withOpacity(0.1),
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.all(24.0),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildField(
                  icon: Icons.calendar_today,
                  label: 'DATA DE CHEGADA',
                  value: _formatDate(_checkIn),
                  onTap: () => _selectDate(context, true),
                ),
                const SizedBox(height: 16),
                _buildField(
                  icon: Icons.calendar_today_outlined,
                  label: 'DATA DE SAÍDA',
                  value: _formatDate(_checkOut),
                  onTap: () => _selectDate(context, false),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        icon: Icons.person,
                        label: 'ADULTOS',
                        value: _adults,
                        items: List.generate(10, (index) => index + 1),
                        onChanged: (val) => setState(() => _adults = val!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDropdown(
                        icon: Icons.child_care,
                        label: 'CRIANÇAS',
                        value: _children,
                        items: List.generate(6, (index) => index),
                        onChanged: (val) => setState(() => _children = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSubmitButton(true),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: _buildField(
                    icon: Icons.calendar_today,
                    label: 'DATA DE CHEGADA',
                    value: _formatDate(_checkIn),
                    onTap: () => _selectDate(context, true),
                  ),
                ),
                _buildDivider(),
                Expanded(
                  child: _buildField(
                    icon: Icons.calendar_today_outlined,
                    label: 'DATA DE SAÍDA',
                    value: _formatDate(_checkOut),
                    onTap: () => _selectDate(context, false),
                  ),
                ),
                _buildDivider(),
                Expanded(
                  child: _buildDropdown(
                    icon: Icons.person,
                    label: 'ADULTOS',
                    value: _adults,
                    items: List.generate(10, (index) => index + 1),
                    onChanged: (val) => setState(() => _adults = val!),
                  ),
                ),
                _buildDivider(),
                Expanded(
                  child: _buildDropdown(
                    icon: Icons.child_care,
                    label: 'CRIANÇAS',
                    value: _children,
                    items: List.generate(6, (index) => index),
                    onChanged: (val) => setState(() => _children = val!),
                  ),
                ),
                const SizedBox(width: 16),
                _buildSubmitButton(false),
              ],
            ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: HotelColors.lightGrey,
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
    );
  }

  Widget _buildField({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8.0),
          color: Colors.transparent,
          child: Row(
            children: [
              Icon(icon, color: HotelColors.accentGold, size: 24),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: HotelTypography.bookingLabel),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: HotelTypography.bodyText(
                      color: value == 'Selecionar'
                          ? HotelColors.textGrey.withOpacity(0.6)
                          : HotelColors.darkSlate,
                    ).copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required IconData icon,
    required String label,
    required int value,
    required List<int> items,
    required ValueChanged<int?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Icon(icon, color: HotelColors.accentGold, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: HotelTypography.bookingLabel),
                DropdownButton<int>(
                  value: value,
                  isDense: true,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: HotelColors.textGrey),
                  style: HotelTypography.bodyText(color: HotelColors.darkSlate).copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  onChanged: onChanged,
                  items: items.map<DropdownMenuItem<int>>((int val) {
                    return DropdownMenuItem<int>(
                      value: val,
                      child: Text(val.toString()),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(bool fullWidth) {
    return Container(
      height: 54,
      width: fullWidth ? double.infinity : 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        gradient: HotelColors.goldGradient,
        boxShadow: [
          BoxShadow(
            color: HotelColors.accentGold.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _triggerReservation,
          borderRadius: BorderRadius.circular(12.0),
          child: Center(
            child: Text(
              'RESERVE AGORA',
              style: HotelTypography.buttonText.copyWith(
                color: HotelColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
