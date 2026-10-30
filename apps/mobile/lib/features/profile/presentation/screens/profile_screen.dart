import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/presentation/widgets/confirmation_toast.dart';
import '../../../../core/presentation/widgets/loading_shimmer.dart';
import '../../../../core/presentation/widgets/stagger_reveal.dart';
import '../widgets/profile_menu_section.dart';
import '../widgets/profile_screen_shell.dart';
import '../widgets/profile_summary.dart';
import '../view_models/profile_exit_view_model.dart';
import '../view_models/profile_view_model.dart';
import '../view_models/local_data_deletion_view_model.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exit = ref.watch(profileExitViewModelProvider);
    final deletion = ref.watch(localDataDeletionViewModelProvider);
    final busy = exit.isLoading || deletion.isLoading;
    final loading = ref.watch(profileViewModelProvider).isLoading;
    final routeAnimation =
        ModalRoute.of(context)?.animation ??
        const AlwaysStoppedAnimation<double>(1);
    return ConfirmationToastHost(
      confirmed:
          exit.hasError || deletion.hasError || deletion.asData?.value == true,
      message: deletion.hasError
          ? 'No se pudieron borrar los datos locales. Reintenta.'
          : deletion.asData?.value == true
          ? 'Copia sin conexión y clave eliminadas de este teléfono'
          : 'No se pudo cerrar la sesión. Reintenta.',
      isError: exit.hasError || deletion.hasError,
      noticeId: (exit.error, deletion),
      child: PopScope(
        canPop: !exit.isLoading && !deletion.isLoading,
        child: ProfileScreenShell(
          title: 'Perfil',
          close: true,
          navigationEnabled: !exit.isLoading && !deletion.isLoading,
          onBack: () => context.pop(),
          child: AnimatedBuilder(
            animation: routeAnimation,
            builder: (context, _) => ContentReveal(
              loading: loading,
              count: 6,
              play:
                  routeAnimation.status == AnimationStatus.completed ||
                  MediaQuery.disableAnimationsOf(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StaggerRevealItem(
                    order: 0,
                    child: ProfileSummary(
                      onEdit: busy
                          ? null
                          : () => context.push('/home/profile/edit'),
                    ),
                  ),
                  const SizedBox(height: 28),
                  StaggerRevealItem(
                    order: 1,
                    preserveBackdrop: true,
                    child: ProfileMenuSection(
                      title: 'Mi actividad',
                      enabled: !busy,
                      destinations: const [
                        (
                          icon: Icons.edit_note_rounded,
                          label: 'Borradores',
                          path: '/home/drafts',
                        ),
                        (
                          icon: Icons.cloud_upload_outlined,
                          label: 'Envíos',
                          path: '/home/submissions',
                        ),
                        (
                          icon: Icons.fact_check_outlined,
                          label: 'Mis apelaciones',
                          path: '/home/appeals',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  StaggerRevealItem(
                    order: 2,
                    preserveBackdrop: true,
                    child: ProfileMenuSection(
                      title: 'Alertas y zonas',
                      enabled: !busy,
                      destinations: const [
                        (
                          icon: Icons.notifications_outlined,
                          label: 'Preferencias de alertas',
                          path: '/home/alert-preferences',
                        ),
                        (
                          icon: Icons.location_on_outlined,
                          label: 'Ubicaciones de interés',
                          path: '/home/interest-zones',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  StaggerRevealItem(
                    order: 3,
                    preserveBackdrop: true,
                    child: ProfileMenuSection(
                      title: 'Privacidad',
                      enabled: !busy,
                      destinations: const [
                        (
                          icon: Icons.block_rounded,
                          label: 'Cuentas bloqueadas',
                          path: '/home/blocked-users',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  StaggerRevealItem(
                    order: 4,
                    child: LoadingShimmer(
                      isLoading: deletion.isLoading,
                      loadingLabel: 'Borrando datos locales',
                      child: OutlinedButton.icon(
                        onPressed: exit.isLoading || deletion.isLoading
                            ? null
                            : () => ref
                                  .read(
                                    localDataDeletionViewModelProvider.notifier,
                                  )
                                  .delete(),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Borrar datos de este teléfono'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  StaggerRevealItem(
                    order: 5,
                    child: LoadingShimmer(
                      isLoading: exit.isLoading,
                      loadingLabel: 'Cerrando sesión',
                      radius: 18,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFF9ECEE),
                          foregroundColor: const Color(0xFFB53F48),
                          disabledBackgroundColor: const Color(0xFFF9ECEE),
                          disabledForegroundColor: const Color(0xFFB53F48),
                          minimumSize: const Size(0, 48),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          textStyle: const TextStyle(
                            fontFamily: 'sans-serif',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: busy
                            ? null
                            : () => ref
                                  .read(profileExitViewModelProvider.notifier)
                                  .signOut(),
                        child: const Text('Cerrar sesión'),
                      ),
                    ),
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
