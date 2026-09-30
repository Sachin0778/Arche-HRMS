import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/datasources/receipt_file_store.dart';
import '../../domain/entities/expense_claim.dart';
import '../../domain/repositories/claim_repository.dart';
import '../cubit/submit_claim_cubit.dart';
import '../widgets/claim_tile.dart';

class SubmitClaimScreen extends StatelessWidget {
  const SubmitClaimScreen({super.key});

  static Route<void> route() => MaterialPageRoute(builder: (_) => const SubmitClaimScreen());

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthCubit>().state.user!;
    return BlocProvider(
      create: (context) => SubmitClaimCubit(
        context.read<ClaimRepository>(),
        context.read<ReceiptFileStore>(),
        employeeId: user.id,
      ),
      child: const _SubmitClaimView(),
    );
  }
}

class _SubmitClaimView extends StatefulWidget {
  const _SubmitClaimView();

  @override
  State<_SubmitClaimView> createState() => _SubmitClaimViewState();
}

class _SubmitClaimViewState extends State<_SubmitClaimView> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();
  bool _showNonTextErrors = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final cubit = context.read<SubmitClaimCubit>();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: cubit.state.expenseDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
    );
    if (picked != null) cubit.selectDate(picked);
  }

  Future<void> _pickReceipt(ImageSource source) async {
    final cubit = context.read<SubmitClaimCubit>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 80, maxWidth: 1600);
      if (file != null) cubit.attachReceipt(file.path);
    } on PlatformException catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(source == ImageSource.camera
            ? 'Camera unavailable: ${e.message ?? e.code}'
            : 'Could not open gallery: ${e.message ?? e.code}'),
      ));
    }
  }

  void _showReceiptOptions() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickReceipt(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickReceipt(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    setState(() => _showNonTextErrors = true);
    final cubit = context.read<SubmitClaimCubit>();
    final textValid = _formKey.currentState!.validate();
    final s = cubit.state;
    final otherValid =
        s.category != null && Validators.claimDate(s.expenseDate) == null && s.hasReceipt;
    if (!textValid || !otherValid) return;
    cubit.submit(
      amount: double.parse(_amountController.text.trim().replaceAll(',', '')),
      description: _descriptionController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Expense Claim')),
      body: BlocConsumer<SubmitClaimCubit, SubmitClaimState>(
        listener: (context, state) {
          if (state.status == SubmitStatus.success) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(const SnackBar(content: Text('Claim submitted for review')));
            Navigator.of(context).pop();
          } else if (state.status == SubmitStatus.failure && state.errorMessage != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: theme.colorScheme.error,
              ));
          }
        },
        builder: (context, state) {
          final busy = state.status == SubmitStatus.submitting;
          final dateError = _showNonTextErrors ? Validators.claimDate(state.expenseDate) : null;
          final categoryError = _showNonTextErrors && state.category == null ? 'Select a category' : null;
          final receiptError = _showNonTextErrors && !state.hasReceipt ? 'Attach a receipt image' : null;

          return Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Category', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in ClaimCategory.values)
                      ChoiceChip(
                        avatar: Icon(categoryIcon(c), size: 18),
                        label: Text(c.label),
                        selected: state.category == c,
                        onSelected: busy ? null : (_) => context.read<SubmitClaimCubit>().selectCategory(c),
                      ),
                  ],
                ),
                if (categoryError != null) _FieldError(categoryError),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _amountController,
                  enabled: !busy,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixText: '${Formatters.currencySymbol} ',
                  ),
                  validator: Validators.amount,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: busy ? null : _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Expense date',
                      suffixIcon: const Icon(Icons.calendar_today_outlined),
                      errorText: dateError,
                    ),
                    child: Text(
                      state.expenseDate == null ? 'Select date' : Formatters.date(state.expenseDate!),
                      style: state.expenseDate == null
                          ? theme.textTheme.bodyLarge?.copyWith(color: theme.hintColor)
                          : theme.textTheme.bodyLarge,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  enabled: !busy,
                  maxLines: 3,
                  maxLength: 300,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    alignLabelWithHint: true,
                  ),
                  validator: Validators.description,
                ),
                const SizedBox(height: 8),
                Text('Receipt', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                _ReceiptPicker(
                  path: state.receiptPath,
                  enabled: !busy,
                  onPick: _showReceiptOptions,
                  onRemove: () => context.read<SubmitClaimCubit>().removeReceipt(),
                ),
                if (receiptError != null) _FieldError(receiptError),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: busy ? null : _submit,
                  icon: busy
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send_outlined),
                  label: Text(busy ? 'Submitting…' : 'Submit claim'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReceiptPicker extends StatelessWidget {
  const _ReceiptPicker({
    required this.path,
    required this.enabled,
    required this.onPick,
    required this.onRemove,
  });

  final String? path;
  final bool enabled;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (path == null || path!.isEmpty) {
      return InkWell(
        onTap: enabled ? onPick : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outline),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_outlined, size: 32, color: theme.colorScheme.primary),
              const SizedBox(height: 8),
              const Text('Attach receipt (camera or gallery)'),
            ],
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Image.file(
            File(path!),
            height: 220,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              height: 140,
              color: theme.colorScheme.surfaceContainerHighest,
              alignment: Alignment.center,
              child: const Text('Preview unavailable'),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                IconButton.filledTonal(
                  tooltip: 'Replace',
                  onPressed: enabled ? onPick : null,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton.filledTonal(
                  tooltip: 'Remove',
                  onPressed: enabled ? onRemove : null,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldError extends StatelessWidget {
  const _FieldError(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 12),
      child: Text(message, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
    );
  }
}