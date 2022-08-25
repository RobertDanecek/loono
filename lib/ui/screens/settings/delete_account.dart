import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:loono/constants.dart';
import 'package:loono/helpers/flushbar_message.dart';
import 'package:loono/l10n/ext.dart';
import 'package:loono/repositories/user_repository.dart';
import 'package:loono/router/app_router.gr.dart';
import 'package:loono/services/database_service.dart';
import 'package:loono/ui/widgets/button.dart';
import 'package:loono/ui/widgets/confirmation_dialog.dart';
import 'package:loono/ui/widgets/settings/app_bar.dart';
import 'package:loono/ui/widgets/settings/checkbox.dart';
import 'package:loono/utils/registry.dart';
import 'package:loono_api/loono_api.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({
    Key? key,
  }) : super(key: key);

  @override
  DeleteAccountScreenState createState() => DeleteAccountScreenState();
}

class DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool _isCheckedHistory = false;
  bool _isCheckedBadge = false;
  bool _isCheckedNotifications = false;

  bool get _areAllChecked => _isCheckedBadge & _isCheckedNotifications & _isCheckedHistory;

  final _userRepository = registry.get<UserRepository>();
  final _usersDao = registry.get<DatabaseService>().users;

  Sex get _sex {
    final user = _usersDao.user;
    return user?.sex ?? Sex.MALE;
  }

  bool _isLoading = false;

  void _setLoadingState(bool value) => setState(() => _isLoading = value);

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      inAsyncCall: _isLoading,
      progressIndicator: const CircularProgressIndicator(color: LoonoColors.primaryEnabled),
      opacity: 0.5,
      child: WillPopScope(
        onWillPop: () async => !_isLoading,
        child: Scaffold(
          appBar: settingsAppBar(context),
          backgroundColor: LoonoColors.settingsBackground,
          body: Stack(
            children: [
              Positioned(
                child: Align(
                  alignment: FractionalOffset.bottomCenter,
                  child: SizedBox(
                    height: 407,
                    width: 297,
                    child: SvgPicture.asset('assets/icons/delete_account_illustration.svg'),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 34.0, left: 17),
                child: Text(
                  context.l10n.settings_delete_account_we_will_miss_you,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 88.0),
                child: Wrap(
                  direction: Axis.vertical,
                  spacing: 40,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _isCheckedHistory = !_isCheckedHistory),
                      child: CheckboxCustom(
                        key: const Key('deleteAccountPage_checkBox_deleteCheckups'),
                        isChecked: _isCheckedHistory,
                        text: context.l10n.settings_delete_account_check_box_delete_history,
                        whatIsChecked: (val) => setState(() => _isCheckedHistory = val),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _isCheckedBadge = !_isCheckedBadge),
                      child: CheckboxCustom(
                        key: const Key('deleteAccountPage_checkBox_deleteBadges'),
                        isChecked: _isCheckedBadge,
                        text: context.l10n.settings_delete_account_check_box_delete_badges,
                        whatIsChecked: (val) => setState(() => _isCheckedBadge = val),
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _isCheckedNotifications = !_isCheckedNotifications),
                      child: CheckboxCustom(
                        key: const Key('deleteAccountPage_checkBox_stopNotifications'),
                        isChecked: _isCheckedNotifications,
                        text: context.l10n.settings_delete_account_check_box_stop_notifications,
                        whatIsChecked: (val) => setState(() => _isCheckedNotifications = val),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                child: Align(
                  alignment: const Alignment(0.00, 0.60),
                  child: SizedBox(
                    height: 65,
                    width: 339,
                    child: LoonoButton(
                      onTap: () async {
                        if (_areAllChecked) {
                          await showAdaptiveConfirmationDialog(
                            context,
                            description: context.l10n.settings_delete_account_alert,
                            confirmationButtonLabel: context.l10n.delete,
                            onConfirm: () async {
                              final autoRouter = AutoRouter.of(context);
                              WidgetsBinding.instance
                                  .addPostFrameCallback((_) => _setLoadingState(true));
                              final res = await _userRepository.deleteAccount();
                              if (res) {
                                await autoRouter.push(AfterDeletionRoute(sex: _sex));
                              } else {
                                //TODO: Fix lint..
                                // ignore: use_build_context_synchronously
                                showFlushBarError(
                                  context,
                                  context.l10n.something_went_wrong,
                                  sync: false,
                                );
                              }
                              if (mounted) _setLoadingState(false);
                            },
                          );
                        } else {
                          await AutoRouter.of(context).pop();
                        }
                      },
                      text: (!_areAllChecked)
                          ? context.l10n.back
                          : context.l10n.remove_account_action,
                    ),
                  ),
                ),
              ),
              if (_areAllChecked)
                Positioned(
                  child: Align(
                    alignment: const Alignment(0.00, 0.85),
                    child: SizedBox(
                      height: 65,
                      width: 339,
                      child: LoonoButton.light(
                        onTap: () {
                          AutoRouter.of(context).pop();
                        },
                        text: context.l10n.cancel,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
