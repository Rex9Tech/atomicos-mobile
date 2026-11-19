// lib/modules/ai/helpers/ask_with_neuron.helper.dart
//
// Every ask starts by naming its neuron: this shared entry opens the neuron
// chooser (existing neuron or a brand-new one), then routes the ask into
// that neuron's own conversation — with the atom pinned when the ask came
// from an atom.
import 'package:get/get.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/locales/app_locales.dart';
import 'package:rexone_mobile/routes/routes.dart';

Future<void> askWithNeuronPicker({String? atomId, String? atomTitle}) async {
  final molecule = await showMoleculePickerForAsk(
    title: AppLocales.category.selectTitle.tr,
    subtitle: AppLocales.ai.askNeuronSub.tr,
  );
  // No neuron chosen — no ask: the choice is the point of the popup.
  if (molecule == null) return;

  AppRoutes.toAi(
    mode: 'ask',
    atomId: atomId,
    atomTitle: atomTitle,
    moleculeId: molecule.id,
    moleculeName: molecule.name,
  );
}
