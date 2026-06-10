import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/app_state.dart';
import '../models/app_user.dart';
import '../models/member.dart';
import '../services/api_client.dart';
import '../services/service_factory.dart';
import '../widgets/page_frame.dart';
import '../widgets/player_showcase_card.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _dpiController = TextEditingController();
  final _sensitivityController = TextEditingController();
  final _resolutionController = TextEditingController();
  final _viewmodelController = TextEditingController();
  final _crosshairController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _editing = false;
  String? _error;
  String? _selectedImageName;
  AppUser? _user;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _imageUrlController.dispose();
    _dpiController.dispose();
    _sensitivityController.dispose();
    _resolutionController.dispose();
    _viewmodelController.dispose();
    _crosshairController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Meu perfil'),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        children: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(minHeight: 3),
            ),
          if (_error != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0x33111827),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF7F1D1D)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
          _buildPlayerStyleProfile(context),
          if (_editing) ...[
            const SizedBox(height: 14),
            _buildFormCard(context),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayerStyleProfile(BuildContext context) {
    final user = _user;
    final userName = user?.name ?? 'Usuario';
    final userNickname = (user?.nickname ?? '').trim();
    final nickname = userNickname.isNotEmpty
        ? userNickname
        : (userName.trim().isNotEmpty ? userName : 'perfil');
    final previewMember = Member(
      id: user?.id ?? 0,
      teamId: 0,
      fullName: userName,
      nickname: nickname,
      age: 0,
      role: 'player',
      imageUrl: user?.imageUrl,
      inGameRole: 'player',
      dpi: user?.dpi,
      sensitivity: user?.sensitivity,
      resolution: user?.resolution,
      viewmodel: user?.viewmodel,
      crosshair: user?.crosshair ?? '',
      twitter: null,
      instagram: null,
      twitch: null,
    );

    final infoCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user?.name ?? 'Seu perfil',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              user?.email ?? '',
              style: GoogleFonts.montserrat(
                fontSize: 17,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _InfoChip(label: 'Nick', value: _nicknameController.text),
                _InfoChip(label: 'DPI', value: _dpiController.text),
                _InfoChip(label: 'Sens', value: _sensitivityController.text),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: _saving
                    ? null
                    : () {
                        setState(() {
                          _editing = true;
                        });
                      },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar perfil'),
              ),
            ),
          ],
        ),
      ),
    );

    final imageCard = SizedBox(
      height: 520,
      child: PlayerShowcaseCard(
        player: previewMember,
        baseImageScale: 1,
        imageYOffset: 0,
      ),
    );

    final configCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuracoes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _InfoChip(label: 'DPI', value: _dpiController.text),
                _InfoChip(label: 'Sens', value: _sensitivityController.text),
                _InfoChip(
                  label: 'Res',
                  value: _resolutionController.text.isEmpty
                      ? 'Nao informado'
                      : _resolutionController.text,
                ),
              ],
            ),
          ],
        ),
      ),
    );

    final crosshairCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Crosshair',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF020617),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: SelectableText(
                _crosshairController.text.isEmpty
                    ? 'Nao informado'
                    : _crosshairController.text,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );

    final viewmodelCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Viewmodel',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF020617),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: SelectableText(
                _viewmodelController.text.isEmpty
                    ? 'Nao informado'
                    : _viewmodelController.text,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        if (!isWide) {
          return Column(
            children: [
              infoCard,
              const SizedBox(height: 14),
              imageCard,
              const SizedBox(height: 14),
              configCard,
              const SizedBox(height: 14),
              crosshairCard,
              const SizedBox(height: 14),
              viewmodelCard,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  infoCard,
                  const SizedBox(height: 14),
                  configCard,
                  const SizedBox(height: 14),
                  crosshairCard,
                  const SizedBox(height: 14),
                  viewmodelCard,
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(flex: 4, child: imageCard),
          ],
        );
      },
    );
  }

  Widget _buildFormCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dados do perfil',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Atualize suas informações e configurações.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white60,
                    ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: _requiredValidator('Informe o nome'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nicknameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Nick'),
                validator: _requiredValidator('Informe o nick'),
              ),
              const SizedBox(height: 12),
              _ImagePickerField(
                fileName: _selectedImageName,
                onPick: _saving ? null : _pickImage,
                onClear: _saving ? null : _clearImage,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dpiController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'DPI'),
                      validator: (value) {
                        final parsed = int.tryParse((value ?? '').trim());
                        if (parsed == null || parsed <= 0) {
                          return 'DPI invalido';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _sensitivityController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration:
                          const InputDecoration(labelText: 'Sensibilidade'),
                      validator: (value) {
                        final parsed = double.tryParse((value ?? '').trim());
                        if (parsed == null || parsed <= 0) {
                          return 'Sens invalida';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _resolutionController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Resolucao'),
                validator: _requiredValidator('Informe a resolucao'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _viewmodelController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Viewmodel'),
                validator: _requiredValidator('Informe o viewmodel'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _crosshairController,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Crosshair'),
                validator: _requiredValidator('Informe o crosshair'),
              ),
              const SizedBox(height: 18),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton.icon(
                    onPressed: _saving ? null : _saveProfile,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Salvando' : 'Salvar perfil'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _saving
                        ? null
                        : () {
                            setState(() {
                              _editing = false;
                            });
                          },
                    icon: const Icon(Icons.close_outlined),
                    label: const Text('Cancelar'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _deleteAccount,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Excluir conta'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadProfile() async {
    final session = AppStateScope.of(context);
    final auth = buildAuthService(session);

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = await auth.me();
      if (!mounted) return;
      await session.updateUser(user);
      _fillControllers(user);
      setState(() {
        _user = user;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Nao foi possivel carregar o perfil.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    final session = AppStateScope.of(context);
    final auth = buildAuthService(session);
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final user = await auth.updateMe(
        name: _nameController.text.trim(),
        nickname: _nicknameController.text.trim(),
        imageUrl: _imageUrlController.text.trim(),
        dpi: int.parse(_dpiController.text.trim()),
        sensitivity: double.parse(_sensitivityController.text.trim()),
        resolution: _resolutionController.text.trim(),
        viewmodel: _viewmodelController.text.trim(),
        crosshair: _crosshairController.text.trim(),
      );

      if (!mounted) return;
      await session.updateUser(user);
      setState(() {
        _user = user;
        _editing = false;
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('Perfil atualizado com sucesso.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Nao foi possivel salvar o perfil.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _deleteAccount() async {
    if (_saving) return;
    final session = AppStateScope.of(context);
    final auth = buildAuthService(session);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir conta'),
          content: const Text(
            'Essa acao remove seu perfil permanentemente. Deseja continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await auth.deleteMe();
      await session.clearAuth();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/auth', (_) => false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Nao foi possivel excluir a conta.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  void _fillControllers(AppUser user) {
    _nameController.text = user.name;
    _nicknameController.text = user.nickname ?? '';
    _imageUrlController.text = user.imageUrl ?? '';
    _selectedImageName = _inferImageLabel(user.imageUrl);
    _dpiController.text = user.dpi?.toString() ?? '';
    _sensitivityController.text = user.sensitivity?.toString() ?? '';
    _resolutionController.text = user.resolution ?? '';
    _viewmodelController.text = user.viewmodel ?? '';
    _crosshairController.text = user.crosshair ?? '';
    _editing = false;
  }

  String? Function(String?) _requiredValidator(String message) {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return message;
      }
      return null;
    };
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      setState(() {
        _error = 'Nao foi possivel ler a imagem selecionada.';
      });
      return;
    }

    final mimeType = _mimeFromExtension(file.extension ?? '');
    final encoded = base64Encode(bytes);
    final dataUrl = 'data:$mimeType;base64,$encoded';

    setState(() {
      _imageUrlController.text = dataUrl;
      _selectedImageName = file.name;
      _error = null;
    });
  }

  void _clearImage() {
    setState(() {
      _imageUrlController.clear();
      _selectedImageName = null;
    });
  }

  String _mimeFromExtension(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'png':
      default:
        return 'image/png';
    }
  }

  String? _inferImageLabel(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return null;
    if (imageUrl.startsWith('data:image/')) {
      return 'Imagem carregada';
    }
    return 'Imagem externa';
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF111317),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2A2E39)),
      ),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.montserrat(color: Colors.white),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            TextSpan(text: value.isEmpty ? '-' : value),
          ],
        ),
      ),
    );
  }
}

class _ImagePickerField extends StatelessWidget {
  const _ImagePickerField({
    required this.fileName,
    required this.onPick,
    required this.onClear,
  });

  final String? fileName;
  final VoidCallback? onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF3A3A3A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Foto do perfil',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('Selecionar imagem'),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Text(
                  fileName ?? 'Nenhuma imagem selecionada',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fileName != null
                        ? Colors.white70
                        : Colors.white54,
                  ),
                ),
              ),
              if (fileName != null) ...[
                TextButton(
                  onPressed: onClear,
                  child: const Text('Remover'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
