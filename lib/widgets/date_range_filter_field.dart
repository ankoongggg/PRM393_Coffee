import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class DateRangeFilterField extends StatelessWidget {
  final DateTime? fromDate;
  final DateTime? toDate;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final String placeholder;

  const DateRangeFilterField({
    super.key,
    required this.fromDate,
    required this.toDate,
    required this.onTap,
    required this.placeholder,
    this.onClear,
  });

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final hasValue = fromDate != null && toDate != null;
    final text = hasValue
        ? '${_formatDate(fromDate!)} - ${_formatDate(toDate!)}'
        : placeholder;

    final textStyle = TextStyle(
      fontSize: 12,
      color: hasValue ? const Color(0xFF2C1A0E) : const Color(0xFF9E7B5A),
      fontWeight: FontWeight.w600,
    );

    return SizedBox(
      height: 38,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: InputDecorator(
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE8D5C0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE8D5C0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF6F4E37), width: 1.2),
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasValue && onClear != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Color(0xFF9E7B5A)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: onClear,
                    tooltip: 'Bỏ lọc',
                  ),
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.calendar_today, size: 16, color: Color(0xFF9E7B5A)),
                ),
              ],
            ),
            suffixIconConstraints: const BoxConstraints(minHeight: 38),
          ),
          child: Text(text, style: textStyle),
        ),
      ),
    );
  }
}

Future<PickerDateRange?> showCompactDateRangePickerDialog(
  BuildContext context, {
  DateTime? initialFrom,
  DateTime? initialTo,
}) {
  final now = DateTime.now();
  final initialRange = (initialFrom != null && initialTo != null)
      ? PickerDateRange(initialFrom, initialTo)
      : null;

  return showDialog<PickerDateRange?>(
    context: context,
    builder: (ctx) {
      PickerDateRange? tempRange = initialRange;
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Chọn khoảng ngày',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx, null),
                    icon: const Icon(Icons.close),
                    tooltip: 'Đóng',
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 330,
                child: SfDateRangePicker(
                  selectionMode: DateRangePickerSelectionMode.range,
                  initialSelectedRange: initialRange,
                  showActionButtons: false,
                  onSelectionChanged: (args) {
                    final value = args.value;
                    if (value is PickerDateRange) tempRange = value;
                  },
                  maxDate: DateTime(now.year + 5, 12, 31),
                  minDate: DateTime(now.year - 5, 1, 1),
                  enableMultiView: true,
                  navigationDirection: DateRangePickerNavigationDirection.horizontal,
                  monthViewSettings: const DateRangePickerMonthViewSettings(firstDayOfWeek: 1),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, null),
                    child: const Text('Hủy'),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6F4E37)),
                    onPressed: () => Navigator.pop(ctx, tempRange),
                    child: const Text('Áp dụng', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

