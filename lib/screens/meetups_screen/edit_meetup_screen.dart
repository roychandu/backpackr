// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../common_widgets/app_colors.dart';
import '../../common_widgets/app_text_styles.dart';
import '../../models/meetup.dart';
import '../../services/meetup_service.dart';
import '../../utils/error_handler.dart';

class EditMeetupScreen extends StatefulWidget {
  final Meetup meetup;
  final VoidCallback onMeetupUpdated;

  const EditMeetupScreen({
    super.key,
    required this.meetup,
    required this.onMeetupUpdated,
  });

  @override
  State<EditMeetupScreen> createState() => _EditMeetupScreenState();
}

class _EditMeetupScreenState extends State<EditMeetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _meetupService = MeetupService();

  // Form controllers
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _capacityController;

  // Form state
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.meetup.title);
    _descriptionController = TextEditingController(
      text: widget.meetup.description,
    );
    _locationController = TextEditingController(text: widget.meetup.location);
    _capacityController = TextEditingController(
      text: widget.meetup.maxCapacity.toString(),
    );

    _selectedDate = widget.meetup.dateTime;
    _selectedTime = TimeOfDay.fromDateTime(widget.meetup.dateTime);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.text1,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.text1,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _updateMeetup() async {
    // Dismiss keyboard first
    FocusScope.of(context).unfocus();

    // Wait a brief moment for keyboard to dismiss
    await Future.delayed(const Duration(milliseconds: 100));

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields correctly'),
          backgroundColor: AppColors.cta1,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      // Combine date and time
      final meetupDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      await _meetupService.updateMeetup(
        meetupId: widget.meetup.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        dateTime: meetupDateTime,
        location: _locationController.text.trim(),
        maxCapacity: int.parse(_capacityController.text),
      );

      if (!mounted) return;

      // Close the screen
      Navigator.of(context).pop();

      // Call the success callback
      widget.onMeetupUpdated();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Meetup updated successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUpdating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorHandler.getFriendlyErrorMessage(e)),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.text1),
        ),
        title: Text(
          'Edit Meetup',
          style: AppTextStyles.h4.copyWith(
            color: AppColors.text1,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.text1.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.text1.withOpacity(0.15),
                              ),
                            ),
                            child: TextFormField(
                              controller: _titleController,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.text1,
                              ),
                              decoration: InputDecoration(
                                hintText:
                                    'Meetup title (e.g., Coffee & Co-working)',
                                hintStyle: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.text1.withOpacity(0.5),
                                ),
                                prefixIcon: Icon(
                                  Icons.title_rounded,
                                  color: AppColors.primary,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a title';
                                }
                                if (value.trim().length < 3) {
                                  return 'Title must be at least 3 characters';
                                }
                                return null;
                              },
                              textCapitalization: TextCapitalization.words,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Description
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.text1.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.text1.withOpacity(0.15),
                              ),
                            ),
                            child: TextFormField(
                              controller: _descriptionController,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.text1,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Tell people about your meetup...',
                                hintStyle: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.text1.withOpacity(0.5),
                                ),
                                prefixIcon: Icon(
                                  Icons.description_rounded,
                                  color: AppColors.primary,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              maxLines: 3,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a description';
                                }

                                return null;
                              },
                              textCapitalization: TextCapitalization.sentences,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Date
                      InkWell(
                        onTap: _selectDate,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.text1.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.text1.withOpacity(0.15),
                                ),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.text1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Time
                      InkWell(
                        onTap: _selectTime,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.text1.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.text1.withOpacity(0.15),
                                ),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    _selectedTime.format(context),
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.text1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Location
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.text1.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.text1.withOpacity(0.15),
                              ),
                            ),
                            child: TextFormField(
                              controller: _locationController,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.text1,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Location (e.g., Le Marais, Paris)',
                                hintStyle: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.text1.withOpacity(0.5),
                                ),
                                prefixIcon: Icon(
                                  Icons.location_on_rounded,
                                  color: AppColors.primary,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a location';
                                }
                                return null;
                              },
                              textCapitalization: TextCapitalization.words,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Max Capacity
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.text1.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.text1.withOpacity(0.15),
                              ),
                            ),
                            child: TextFormField(
                              controller: _capacityController,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.text1,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Max capacity (2-100)',
                                hintStyle: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.text1.withOpacity(0.5),
                                ),
                                prefixIcon: Icon(
                                  Icons.group_rounded,
                                  color: AppColors.primary,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter max capacity';
                                }
                                final capacity = int.tryParse(value);
                                if (capacity == null || capacity < 2) {
                                  return 'Capacity must be at least 2';
                                }
                                if (capacity > 100) {
                                  return 'Capacity cannot exceed 100';
                                }
                                // Check if capacity is less than current attendees
                                if (capacity < widget.meetup.currentAttendees) {
                                  return 'Capacity cannot be less than current attendees (${widget.meetup.currentAttendees})';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),

            // Update Button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border(
                  top: BorderSide(
                    color: AppColors.text1.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isUpdating ? null : _updateMeetup,
                  icon: _isUpdating
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.text1,
                          ),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(_isUpdating ? 'Updating...' : 'Update Meetup'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.text1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
