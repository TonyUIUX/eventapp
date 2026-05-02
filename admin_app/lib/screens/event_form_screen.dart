import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../models/event_model.dart';
import '../services/firestore_admin_service.dart';
import '../services/storage_service.dart';

class EventFormScreen extends StatefulWidget {
  final EventModel? event;

  const EventFormScreen({super.key, this.event});

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _adminService = FirestoreAdminService();
  final _storageService = StorageService();

  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late TextEditingController _mapLinkController;
  late TextEditingController _descriptionController;
  late TextEditingController _ticketLinkController;
  late TextEditingController _organizerController;
  late TextEditingController _phoneController;
  late TextEditingController _instagramController;
  late TextEditingController _registrationLinkController;
  late TextEditingController _websiteController;
  String? _postedBy;
  bool _isVerifiedOrg = false;

  String _selectedCategory = 'comedy';
  String _selectedPrice = 'Free';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  List<String> _selectedTags = [];
  bool _isFeatured = false;
  String _status = 'active';
  List<String> _imageUrls = [];
  final Map<String, Uint8List> _newImagesToUpload = {};

  bool _isSaving = false;
  double _uploadProgress = 0.0;

  final List<String> _categories = ['comedy', 'music', 'tech', 'fitness', 'art', 'workshop', 'food', 'kids'];
  final List<String> _priceOptions = ['Free', '₹100–500', '₹500–1000', '₹1000+', 'Custom'];
  final List<String> _availableTags = ['free', 'popular', 'new', 'outdoor', 'family', 'limited'];

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    _titleController = TextEditingController(text: e?.title ?? '');
    _locationController = TextEditingController(text: e?.location ?? '');
    _mapLinkController = TextEditingController(text: e?.mapLink ?? '');
    _descriptionController = TextEditingController(text: e?.description ?? '');
    _ticketLinkController = TextEditingController(text: e?.ticketLink ?? '');
    _organizerController = TextEditingController(text: e?.organizer ?? '');
    _phoneController = TextEditingController(text: e?.contactPhone ?? '');
    _instagramController = TextEditingController(text: e?.contactInstagram ?? '');
    _registrationLinkController = TextEditingController(text: e?.registrationLink ?? '');
    _websiteController = TextEditingController(text: e?.website ?? '');

    if (e != null) {
      _selectedCategory = _categories.contains(e.category) ? e.category : 'comedy';
      _selectedPrice = e.price;
      _selectedDate = e.date;
      _selectedTime = TimeOfDay.fromDateTime(e.date);
      _selectedTags = List.from(e.tags);
      _isFeatured = e.isFeatured;
      _status = e.status;
      _postedBy = e.postedBy;
      _isVerifiedOrg = e.isVerifiedOrg;
      _imageUrls = List.from(e.imageUrls.isNotEmpty ? e.imageUrls : (e.imageUrl.isNotEmpty ? [e.imageUrl] : []));
    }
  }

  @override
  void dispose() {
    for (var c in [
      _titleController,
      _locationController,
      _mapLinkController,
      _descriptionController,
      _ticketLinkController,
      _registrationLinkController,
      _organizerController,
      _phoneController,
      _instagramController,
      _websiteController
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null) {
      _showError('Please select a date and time.');
      return;
    }
    if (_imageUrls.isEmpty && _newImagesToUpload.isEmpty) {
      _showError('Please add at least one image.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final dateTime = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedTime!.hour, _selectedTime!.minute);
      final eventId = widget.event?.id ?? DateTime.now().millisecondsSinceEpoch.toString();

      final List<String> finalUrls = List.from(_imageUrls);
      int totalImages = _newImagesToUpload.length;
      int currentImage = 0;
      for (final entry in _newImagesToUpload.entries) {
        final url = await _storageService.uploadEventImage(entry.value, eventId, entry.key);
        finalUrls.add(url);
        currentImage++;
        setState(() => _uploadProgress = currentImage / totalImages);
      }

      final eventData = {
        'title': _titleController.text.trim(),
        'category': _selectedCategory,
        'date': dateTime,
        'location': _locationController.text.trim(),
        'mapLink': _mapLinkController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': _selectedPrice,
        'ticketLink': _ticketLinkController.text.trim(),
        'registrationLink': _registrationLinkController.text.trim(),
        'organizer': _organizerController.text.trim(),
        'contactPhone': _phoneController.text.trim(),
        'contactInstagram': _instagramController.text.trim(),
        'website': _websiteController.text.trim(),
        'imageUrl': finalUrls.isNotEmpty ? finalUrls.first : '',
        'imageUrls': finalUrls,
        'tags': _selectedTags,
        'isFeatured': _isFeatured,
        'isVerifiedOrg': _isVerifiedOrg,
        'status': _status,
        'postedBy': _postedBy ?? 'admin', // Default to admin if created manually
      };

      if (widget.event == null) {
        await _adminService.createEvent(eventData);
      } else {
        await _adminService.updateEvent(widget.event!.id, eventData);
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      _showError('Save failed: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(widget.event == null ? 'Create New Event' : 'Edit Event Details'),
        actions: [
          if (!_isSaving)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton(
                onPressed: _saveEvent,
                child: const Text('Publish Event'),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_isSaving) LinearProgressIndicator(value: _uploadProgress, color: Colors.indigo, backgroundColor: Colors.indigo.withValues(alpha: 0.1)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      children: [
                        _buildSection('Media Assets', [
                          _buildImagePicker(),
                        ]),
                        const SizedBox(height: 24),
                        _buildSection('Basic Information', [
                          _buildTextField(_titleController, 'Event Title', Icons.title, validator: (v) => v!.isEmpty ? 'Required' : null),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: _buildDropdown('Category', _selectedCategory, _categories, (v) => setState(() => _selectedCategory = v!))),
                              const SizedBox(width: 16),
                              Expanded(child: _buildDropdown('Entry Price', _selectedPrice, _priceOptions, (v) => setState(() => _selectedPrice = v!))),
                            ],
                          ),
                        ]),
                        const SizedBox(height: 24),
                        _buildSection('Schedule & Location', [
                          Row(
                            children: [
                              Expanded(child: _buildPickerTile('Event Date', _selectedDate == null ? 'Pick Date' : '${_selectedDate!.toLocal()}'.split(' ')[0], Icons.calendar_month, _pickDate)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildPickerTile('Start Time', _selectedTime == null ? 'Pick Time' : _selectedTime!.format(context), Icons.access_time, _pickTime)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(_locationController, 'Venue / Location', Icons.location_on_outlined, validator: (v) => v!.isEmpty ? 'Required' : null),
                          const SizedBox(height: 16),
                          _buildTextField(_mapLinkController, 'Google Maps Link', Icons.map_outlined),
                        ]),
                        const SizedBox(height: 24),
                        _buildSection('Description & Links', [
                          _buildTextField(_descriptionController, 'Event Description', Icons.description_outlined, maxLines: 5, validator: (v) => v!.isEmpty ? 'Required' : null),
                          const SizedBox(height: 16),
                          _buildTextField(_ticketLinkController, 'Booking URL / Ticket Link', Icons.confirmation_number_outlined),
                          const SizedBox(height: 16),
                          _buildTextField(_registrationLinkController, 'Registration URL / Form Link', Icons.app_registration_rounded),
                        ]),
                        const SizedBox(height: 24),
                        _buildSection('Organizer Details', [
                          _buildTextField(_organizerController, 'Organizer Name', Icons.business_outlined, validator: (v) => v!.isEmpty ? 'Required' : null),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: _buildTextField(_phoneController, 'Contact Phone', Icons.phone_outlined)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildTextField(_instagramController, 'Instagram Handle', Icons.alternate_email)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(_websiteController, 'Website / Linktree', Icons.link_rounded),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: const Text('Verified Organizer'),
                            subtitle: const Text('Add a verified badge to this organizer'),
                            value: _isVerifiedOrg,
                            onChanged: (v) => setState(() => _isVerifiedOrg = v),
                          ),
                        ]),
                        const SizedBox(height: 24),
                        _buildSection('Settings & Visibility', [
                          _buildTagSelector(),
                          const Divider(height: 32),
                          SwitchListTile(title: const Text('Featured Event'), subtitle: const Text('Highlight this on the home carousel'), value: _isFeatured, onChanged: (v) => setState(() => _isFeatured = v)),
                          const Divider(),
                          const Text('Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _status,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'active', child: Text('Active (Live)')),
                              DropdownMenuItem(value: 'pending', child: Text('Pending Review')),
                              DropdownMenuItem(value: 'rejected', child: Text('Rejected / Draft')),
                            ],
                            onChanged: (v) => setState(() => _status = v!),
                          ),
                          const SizedBox(height: 48),
                        ]),
                      ],
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

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> options, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
      items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildPickerTile(String label, String value, IconData icon, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Icon(icon, size: 20, color: Colors.indigo),
                const SizedBox(width: 12),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 140,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ..._imageUrls.map((url) => _ImageTile(image: NetworkImage(url), onRemove: () => setState(() => _imageUrls.remove(url)))),
              ..._newImagesToUpload.entries.map((e) => _ImageTile(image: MemoryImage(e.value), onRemove: () => setState(() => _newImagesToUpload.remove(e.key)))),
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  width: 140,
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid)),
                  child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_photo_alternate_outlined, size: 32, color: Colors.grey), SizedBox(height: 8), Text('Add Images', style: TextStyle(color: Colors.grey, fontSize: 12))]),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text('First image will be used as the cover photo.', style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
      ],
    );
  }

  Widget _buildTagSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Search Tags', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableTags.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return FilterChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (selected) => setState(() => selected ? _selectedTags.add(tag) : _selectedTags.remove(tag)),
              selectedColor: Colors.indigo.shade50,
              checkmarkColor: Colors.indigo,
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _pickImages() async {
    final images = await ImagePicker().pickMultiImage(imageQuality: 70);
    if (images.isNotEmpty) {
      for (var f in images) {
        final bytes = await f.readAsBytes();
        setState(() => _newImagesToUpload[f.name] = bytes);
      }
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(context: context, initialDate: _selectedDate ?? DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
    if (d != null) setState(() => _selectedDate = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _selectedTime ?? TimeOfDay.now());
    if (t != null) setState(() => _selectedTime = t);
  }
}

class _ImageTile extends StatelessWidget {
  final ImageProvider image;
  final VoidCallback onRemove;
  const _ImageTile({required this.image, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 140,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), image: DecorationImage(image: image, fit: BoxFit.cover), border: Border.all(color: Colors.grey.shade200)),
        ),
        Positioned(
          right: 4,
          top: 4,
          child: IconButton(onPressed: onRemove, icon: const Icon(Icons.cancel, color: Colors.white, size: 20), style: IconButton.styleFrom(backgroundColor: Colors.black26)),
        ),
      ],
    );
  }
}
