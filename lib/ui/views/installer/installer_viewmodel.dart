import 'package:revanced_manager/app/app.locator.dart';
import 'package:revanced_manager/models/application_info.dart';
import 'package:revanced_manager/models/patch.dart';
import 'package:revanced_manager/services/patcher_api.dart';
import 'package:revanced_manager/ui/views/app_selector/app_selector_viewmodel.dart';
import 'package:revanced_manager/ui/views/patches_selector/patches_selector_viewmodel.dart';
import 'package:stacked/stacked.dart';

class InstallerViewModel extends BaseViewModel {
  double? progress = 0.2;
  String logs = '';
  bool isPatching = false;
  bool showButtons = false;

  Future<void> initialize() async {
    await locator<PatcherAPI>().handlePlatformChannelMethods();
    runPatcher();
  }

  void addLog(String message) {
    if (logs.isNotEmpty) {
      logs += '\n';
    }
    logs += message;
    notifyListeners();
  }

  void updateProgress(double value) {
    progress = value;
    isPatching = progress == 1.0 ? false : true;
    showButtons = progress == 1.0 ? true : false;
    if (progress == 0.0) {
      logs = '';
    }
    notifyListeners();
  }

  Future<void> runPatcher() async {
    updateProgress(0.0);
    ApplicationInfo? selectedApp = locator<AppSelectorViewModel>().selectedApp;
    if (selectedApp != null) {
      String apkFilePath = selectedApp.apkFilePath;
      List<Patch> selectedPatches =
          locator<PatchesSelectorViewModel>().selectedPatches;
      if (selectedPatches.isNotEmpty) {
        addLog('Initializing patcher...');
        bool? isSuccess = await locator<PatcherAPI>().initPatcher();
        if (isSuccess != null && isSuccess) {
          addLog('Done');
          updateProgress(0.1);
          addLog('Copying original apk...');
          isSuccess = await locator<PatcherAPI>().copyInputFile(apkFilePath);
          if (isSuccess != null && isSuccess) {
            addLog('Done');
            updateProgress(0.2);
            addLog('Creating patcher...');
            isSuccess = await locator<PatcherAPI>().createPatcher();
            if (isSuccess != null && isSuccess) {
              if (selectedApp.packageName == 'com.google.android.youtube') {
                addLog('Done');
                updateProgress(0.3);
                addLog('Merging integrations...');
                isSuccess = await locator<PatcherAPI>().mergeIntegrations();
              }
              if (isSuccess != null && isSuccess) {
                addLog('Done');
                updateProgress(0.5);
                addLog('Applying patches...');
                isSuccess =
                    await locator<PatcherAPI>().applyPatches(selectedPatches);
                if (isSuccess != null && isSuccess) {
                  addLog('Done');
                  updateProgress(0.7);
                  addLog('Repacking patched apk...');
                  isSuccess = await locator<PatcherAPI>().repackPatchedFile();
                  if (isSuccess != null && isSuccess) {
                    addLog('Done');
                    updateProgress(0.9);
                    addLog('Signing patched apk...');
                    isSuccess = await locator<PatcherAPI>().signPatchedFile();
                    if (isSuccess != null && isSuccess) {
                      addLog('Done');
                      showButtons = true;
                      updateProgress(1.0);
                    }
                  }
                }
              }
            }
          }
        }
        if (isSuccess == null || !isSuccess) {
          addLog('An error occurred! Aborting...');
        }
      } else {
        addLog('No patches selected! Aborting...');
      }
    } else {
      addLog('No app selected! Aborting...');
    }
    isPatching = false;
  }

  void installResult() async {
    await locator<PatcherAPI>().installPatchedFile();
  }

  void shareResult() {
    ApplicationInfo? selectedApp = locator<AppSelectorViewModel>().selectedApp;
    if (selectedApp != null) {
      locator<PatcherAPI>().sharePatchedFile(selectedApp.packageName);
    }
  }
}