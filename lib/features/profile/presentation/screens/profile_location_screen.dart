import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_components.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../members/presentation/providers/members_providers.dart';
import '../../data/location_service.dart';
import '../providers/profile_providers.dart';

class ProfileLocationScreen extends ConsumerStatefulWidget {
  const ProfileLocationScreen({super.key});

  @override
  ConsumerState<ProfileLocationScreen> createState() =>
      _ProfileLocationScreenState();
}

class _ProfileLocationScreenState extends ConsumerState<ProfileLocationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  bool _isInitialLoading = true;
  bool _isSaving = false;
  bool _isLocating = false;
  String? _initialAddress;

  bool get _hasValidCoordinatePair {
    final latitude = _parseCoordinate(_latitudeController.text);
    final longitude = _parseCoordinate(_longitudeController.text);
    return latitude != null &&
        longitude != null &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final member = await ref.read(currentMemberProfileProvider.future);
      if (!mounted) return;
      _addressController.text = member?.address ?? '';
      _initialAddress = member?.address;
      _cityController.text = member?.city ?? '';
      _latitudeController.text = member?.latitude?.toString() ?? '';
      _longitudeController.text = member?.longitude?.toString() ?? '';
    } catch (_) {
      if (mounted) {
        AppSnackbar.show(context, 'Gagal memuat alamat rumah.');
      }
    } finally {
      if (mounted) setState(() => _isInitialLoading = false);
    }
  }

  Future<void> _fillCurrentLocation() async {
    final shouldContinue = await _showLocationExplanation();
    if (shouldContinue != true || !mounted) return;

    setState(() => _isLocating = true);
    final result = await ref.read(locationServiceProvider).getCurrentLocation();
    if (!mounted) return;

    setState(() => _isLocating = false);
    if (result.isGranted) {
      setState(() {
        _latitudeController.text = result.position!.latitude.toStringAsFixed(6);
        _longitudeController.text =
            result.position!.longitude.toStringAsFixed(6);
      });
      AppSnackbar.show(context, 'Koordinat lokasi berhasil diambil.');
      return;
    }

    switch (result.status) {
      case LocationStatus.permissionPermanentlyDenied:
        await _showPermanentPermissionDialog();
      case LocationStatus.permissionDenied:
        AppSnackbar.show(
          context,
          'Izin lokasi ditolak. Anda tetap dapat mengisi alamat manual.',
        );
      case LocationStatus.serviceDisabled:
        AppSnackbar.show(
          context,
          'Layanan lokasi perangkat tidak aktif. Silakan isi manual.',
        );
      case LocationStatus.failed:
        AppSnackbar.show(
          context,
          'Lokasi tidak dapat diambil. Silakan coba lagi atau isi manual.',
        );
      case LocationStatus.granted:
        break;
    }
  }

  Future<void> _pickLocationOnMap() async {
    final latitude = _parseCoordinate(_latitudeController.text);
    final longitude = _parseCoordinate(_longitudeController.text);
    final initialPoint = latitude != null && longitude != null
        ? LatLng(latitude, longitude)
        : null;

    final selectedPoint = await showModalBottomSheet<LatLng>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _MapLocationPicker(
        initialPoint: initialPoint,
        onCancel: () => Navigator.pop(sheetContext),
        onConfirm: (point) => Navigator.pop(sheetContext, point),
      ),
    );

    if (!mounted || selectedPoint == null) return;
    _latitudeController.text = selectedPoint.latitude.toStringAsFixed(6);
    _longitudeController.text = selectedPoint.longitude.toStringAsFixed(6);
    setState(() {});
    AppSnackbar.show(context, 'Titik lokasi berhasil dipilih dari peta.');
  }

  Future<bool?> _showLocationExplanation() {
    return showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ambil lokasi rumah', style: AppTypography.h3),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Lokasi digunakan satu kali untuk mengisi koordinat alamat rumah. Aplikasi tidak melacak lokasi di latar belakang.',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetContext, false),
                      child: const Text('Isi Manual'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(sheetContext, true),
                      child: const Text('Lanjutkan'),
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

  Future<void> _showPermanentPermissionDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Izin lokasi diperlukan'),
        content: const Text(
          'Izin lokasi telah ditolak sebelumnya. Anda dapat mengaktifkannya dari Settings atau melanjutkan dengan alamat manual.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Isi Manual'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref.read(locationServiceProvider).openAppSettings();
            },
            child: const Text('Buka Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if ((_initialAddress?.trim().isNotEmpty ?? false) &&
        _addressController.text.trim().isEmpty) {
      final shouldClear = await _confirmAddressRemoval();
      if (!shouldClear || !mounted) return;
    }

    final session = ref.read(currentSessionProvider).valueOrNull;
    if (session == null) {
      AppSnackbar.show(context, 'Sesi pengguna tidak ditemukan.');
      return;
    }

    final latitude = _parseCoordinate(_latitudeController.text);
    final longitude = _parseCoordinate(_longitudeController.text);
    if ((_latitudeController.text.trim().isNotEmpty && latitude == null) ||
        (_longitudeController.text.trim().isNotEmpty && longitude == null)) {
      AppSnackbar.show(context, 'Latitude dan longitude harus berupa angka.');
      return;
    }
    if ((latitude == null) != (longitude == null)) {
      AppSnackbar.show(
          context, 'Latitude dan longitude harus diisi berpasangan.');
      return;
    }
    if (latitude != null &&
        (latitude < -90 ||
            latitude > 90 ||
            longitude! < -180 ||
            longitude > 180)) {
      AppSnackbar.show(
          context, 'Nilai koordinat berada di luar rentang valid.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(membersRepositoryProvider).updateProfileLocation(
            memberId: session.user.id,
            address: _nullableText(_addressController.text),
            city: _nullableText(_cityController.text),
            latitude: latitude,
            longitude: longitude,
          );
      ref.invalidate(currentMemberProfileProvider);
      ref.invalidate(membersControllerProvider);
      if (mounted) {
        AppSnackbar.show(context, 'Alamat rumah berhasil disimpan.');
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        AppSnackbar.show(
            context, 'Gagal menyimpan alamat. Periksa koneksi Anda.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  double? _parseCoordinate(String value) => double.tryParse(value.trim());

  String? _nullableText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _validateText(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return null;
  }

  Future<bool> _confirmAddressRemoval() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus alamat rumah?'),
        content: const Text(
          'Alamat yang tersimpan akan dihapus dan tombol arah di Home dapat menjadi tidak tersedia.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alamat Rumah')),
      body: _isInitialLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      children: [
                        const Text(
                          'Lokasi Rumah',
                          style: AppTypography.h2,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Simpan alamat agar keluarga lebih mudah menemukan rumah tuan rumah saat arisan.',
                          style: AppTypography.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        TextFormField(
                          controller: _addressController,
                          maxLines: 3,
                          validator: _validateText,
                          decoration: const InputDecoration(
                            labelText: 'Alamat Lengkap',
                            hintText: 'Jalan, nomor rumah, RT/RW',
                            prefixIcon: Icon(Icons.home_outlined),
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _cityController,
                          validator: _validateText,
                          decoration: const InputDecoration(
                            labelText: 'Kota / Kecamatan',
                            prefixIcon: Icon(Icons.location_city_outlined),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        OutlinedButton.icon(
                          onPressed: _isLocating ? null : _fillCurrentLocation,
                          icon: _isLocating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.my_location_outlined),
                          label: Text(
                            _isLocating
                                ? 'Mengambil lokasi...'
                                : 'Ambil Lokasi Saat Ini',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        OutlinedButton.icon(
                          onPressed: _pickLocationOnMap,
                          icon: const Icon(Icons.place_outlined),
                          label: const Text('Tentukan Lokasi di Peta'),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _latitudeController,
                                readOnly: true,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                  signed: true,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Latitude',
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: TextFormField(
                                controller: _longitudeController,
                                readOnly: true,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                  signed: true,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Longitude',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _hasValidCoordinatePair
                              ? 'Titik lokasi siap disimpan.'
                              : 'Pilih lokasi otomatis atau tentukan titik di peta sebelum menyimpan.',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        AppButton(
                          label: 'Simpan Alamat',
                          icon: Icons.save_outlined,
                          isLoading: _isSaving,
                          onPressed: _isSaving || !_hasValidCoordinatePair
                              ? null
                              : _save,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _MapLocationPicker extends StatefulWidget {
  const _MapLocationPicker({
    required this.initialPoint,
    required this.onCancel,
    required this.onConfirm,
  });

  final LatLng? initialPoint;
  final VoidCallback onCancel;
  final ValueChanged<LatLng> onConfirm;

  @override
  State<_MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<_MapLocationPicker> {
  static const _defaultCenter = LatLng(-6.200000, 106.816666);

  late LatLng _selectedPoint;

  @override
  void initState() {
    super.initState();
    _selectedPoint = widget.initialPoint ?? _defaultCenter;
  }

  void _selectPoint(LatLng point) {
    setState(() => _selectedPoint = point);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.78,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xs,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.map_outlined, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    const Expanded(
                      child: Text(
                        'Tentukan titik rumah',
                        style: AppTypography.h3,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Tutup',
                      onPressed: widget.onCancel,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  'Ketuk lokasi rumah pada peta untuk memindahkan pin ke titik yang tepat.',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: _selectedPoint,
                    initialZoom: widget.initialPoint == null ? 5.5 : 16,
                    onTap: (_, point) => _selectPoint(point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.bani_rasijan',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedPoint,
                          width: 52,
                          height: 64,
                          child: const Icon(
                            Icons.location_pin,
                            color: AppColors.error,
                            size: 52,
                          ),
                        ),
                      ],
                    ),
                    const RichAttributionWidget(
                      attributions: [
                        const TextSourceAttribution(
                            'OpenStreetMap contributors'),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Lat ${_selectedPoint.latitude.toStringAsFixed(6)}  ·  Long ${_selectedPoint.longitude.toStringAsFixed(6)}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ElevatedButton.icon(
                      onPressed: () => widget.onConfirm(_selectedPoint),
                      icon: const Icon(Icons.check),
                      label: const Text('Gunakan Titik Ini'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
