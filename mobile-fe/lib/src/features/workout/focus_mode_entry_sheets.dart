part of 'focus_mode_screen.dart';

class _NoteSheet extends StatefulWidget {
  const _NoteSheet({
    required this.title,
    required this.hint,
    required this.initialValue,
    required this.suggestions,
    this.supportingText,
  });

  final String title;
  final String hint;
  final String? initialValue;
  final List<String> suggestions;
  final String? supportingText;

  @override
  State<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<_NoteSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _append(String suggestion) {
    final current = _controller.text.trim();
    _controller.text = current.isEmpty ? suggestion : '$current. $suggestion';
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: _SheetFrame(
        title: widget.title,
        maxHeightFactor: 0.74,
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.supportingText != null) ...[
                Text(
                  widget.supportingText!,
                  style: AgonezTypography.of(context).bodySmall,
                ),
                const SizedBox(height: 10),
              ],
              TextField(
                controller: _controller,
                minLines: 3,
                maxLines: 5,
                maxLength: 1000,
                decoration: InputDecoration(hintText: widget.hint),
              ),
              if (widget.suggestions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final suggestion in widget.suggestions)
                      ActionChip(
                        label: Text(suggestion),
                        onPressed: () => _append(suggestion),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        footer: AgonezPrimaryButton(
          label: l10n.noteSave,
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
        ),
      ),
    );
  }
}

class _MoreDataSheet extends StatefulWidget {
  const _MoreDataSheet({required this.selected});

  final int? selected;

  @override
  State<_MoreDataSheet> createState() => _MoreDataSheetState();
}

class _MoreDataSheetState extends State<_MoreDataSheet> {
  int? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SheetFrame(
      title: l10n.moreDataTitle,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AgonezEyebrow(l10n.moreDataHeartRate),
            const SizedBox(height: 9),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final value in const [
                  90,
                  100,
                  110,
                  120,
                  130,
                  140,
                  150,
                  160,
                ])
                  ChoiceChip(
                    label: Text('$value'),
                    selected: _selected == value,
                    onSelected: (_) => setState(() => _selected = value),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.moreDataFutureSensor,
              style: AgonezTypography.of(context).bodySmall,
            ),
          ],
        ),
      ),
      footer: Row(
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop<int?>(null),
            child: Text(l10n.commonCancel),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(_selected),
              child: Text(l10n.commonDone),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadKeypadSheet extends StatefulWidget {
  const _LoadKeypadSheet({this.current, this.prescribed, this.previous});

  final double? current;
  final double? prescribed;
  final double? previous;

  @override
  State<_LoadKeypadSheet> createState() => _LoadKeypadSheetState();
}

class _LoadKeypadSheetState extends State<_LoadKeypadSheet> {
  late String _value;

  @override
  void initState() {
    super.initState();
    _value = widget.current == null ? '' : formatLoad(widget.current!);
  }

  void _press(String value) {
    setState(() {
      if (value == 'backspace') {
        if (_value.isNotEmpty) _value = _value.substring(0, _value.length - 1);
      } else if (value == '.') {
        if (!_value.contains('.')) _value = _value.isEmpty ? '0.' : '$_value.';
      } else if (_value.length < 7) {
        final decimal = _value.indexOf('.');
        if (decimal < 0 || _value.length - decimal <= 2) {
          _value = _value == '0' ? value : '$_value$value';
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final parsed = double.tryParse(_value);
    return _SheetFrame(
      title: l10n.setLoad,
      maxHeightFactor: 0.84,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          children: [
            Container(
              height: 64,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.agonezColors.sunk,
                borderRadius: AgonezRadii.controlBorder,
                border: Border.all(color: context.agonezColors.control),
              ),
              child: Text(
                _value.isEmpty ? '— kg' : '$_value kg',
                style: AgonezTypography.inputNumberOf(context),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                if (widget.prescribed != null)
                  ActionChip(
                    label: Text(
                      '${l10n.workoutPrescribed} ${formatLoad(widget.prescribed!)}',
                    ),
                    onPressed: () =>
                        setState(() => _value = formatLoad(widget.prescribed!)),
                  ),
                if (widget.previous != null)
                  ActionChip(
                    label: Text(
                      '${l10n.workoutLastExposure('')} ${formatLoad(widget.previous!)}',
                    ),
                    onPressed: () =>
                        setState(() => _value = formatLoad(widget.previous!)),
                  ),
                if (widget.current != null)
                  ActionChip(
                    label: Text(
                      '${l10n.setLoad} ${formatLoad(widget.current!)}',
                    ),
                    onPressed: () =>
                        setState(() => _value = formatLoad(widget.current!)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              childAspectRatio: 1.7,
              mainAxisSpacing: 7,
              crossAxisSpacing: 7,
              children: [
                for (final key in const [
                  '1',
                  '2',
                  '3',
                  '4',
                  '5',
                  '6',
                  '7',
                  '8',
                  '9',
                  '.',
                  '0',
                  'backspace',
                ])
                  OutlinedButton(
                    key: Key('focus-keypad-$key'),
                    onPressed: () => _press(key),
                    child: key == 'backspace'
                        ? const Icon(Icons.backspace_outlined, size: 20)
                        : Text(
                            key,
                            style: AgonezTypography.inputNumberOf(context),
                          ),
                  ),
              ],
            ),
          ],
        ),
      ),
      footer: AgonezPrimaryButton(
        label: l10n.commonDone,
        onPressed: parsed == null || parsed < 0
            ? null
            : () => Navigator.of(context).pop(parsed),
      ),
    );
  }
}

class _RepGridSheet extends StatelessWidget {
  const _RepGridSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SheetFrame(
      title: l10n.setReps,
      maxHeightFactor: 0.76,
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 7,
          crossAxisSpacing: 7,
          childAspectRatio: 1,
        ),
        itemCount: 30,
        itemBuilder: (context, index) {
          final value = index + 1;
          return OutlinedButton(
            key: Key('focus-rep-grid-$value'),
            onPressed: () => Navigator.of(context).pop(value),
            style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
            child: Text(
              '$value',
              style: AgonezTypography.inputNumberOf(context),
            ),
          );
        },
      ),
    );
  }
}

class _EditSetSheet extends StatefulWidget {
  const _EditSetSheet({required this.exercise, required this.set});

  final FocusExerciseViewModel exercise;
  final FocusSetViewModel set;

  @override
  State<_EditSetSheet> createState() => _EditSetSheetState();
}

class _EditSetSheetState extends State<_EditSetSheet> {
  late double _load;
  late int _reps;
  late int _rir;

  @override
  void initState() {
    super.initState();
    _load = widget.set.loadKg ?? widget.set.prescribedLoadKg ?? 0;
    _reps = widget.set.repetitions ?? widget.set.repMin ?? 1;
    _rir = widget.set.rir ?? widget.set.targetRir ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repStart = math.max(1, _reps - 2);
    return _SheetFrame(
      title: l10n.setEditTitle(widget.set.ordinal),
      eyebrow: l10n.setEditingNormal,
      maxHeightFactor: 0.88,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ZoneLabel(label: l10n.setLoad),
            const SizedBox(height: 6),
            _LoadStepper(
              value: _load,
              step: widget.exercise.loadStepKg,
              enabled: true,
              diverges:
                  widget.set.prescribedLoadKg != null &&
                  _load != widget.set.prescribedLoadKg,
              enableHaptics: false,
              onChanged: (value) => setState(() => _load = value),
              onOpenKeypad: () async {
                final value = await showModalBottomSheet<double>(
                  context: context,
                  builder: (context) => _LoadKeypadSheet(
                    current: _load,
                    prescribed: widget.set.prescribedLoadKg,
                    previous: null,
                  ),
                );
                if (mounted && value != null) setState(() => _load = value);
              },
            ),
            const SizedBox(height: 12),
            _ZoneLabel(label: l10n.setReps),
            const SizedBox(height: 6),
            _SelectorRow(
              values: [
                for (var value = repStart; value < repStart + 5; value++)
                  _SelectorValue(value, '$value'),
                const _SelectorValue(null, '…'),
              ],
              selected: _reps,
              enabled: true,
              isTarget: (value) =>
                  value != null &&
                  widget.set.repMin != null &&
                  value >= widget.set.repMin! &&
                  value <= (widget.set.repMax ?? widget.set.repMin!),
              semanticLabel: (value, selected, target) =>
                  '${value ?? l10n.setOther}',
              onChanged: (value) async {
                if (value != null) {
                  setState(() => _reps = value);
                  return;
                }
                final picked = await showModalBottomSheet<int>(
                  context: context,
                  builder: (_) => const _RepGridSheet(),
                );
                if (mounted && picked != null) setState(() => _reps = picked);
              },
            ),
            const SizedBox(height: 12),
            _ZoneLabel(label: l10n.setRir),
            const SizedBox(height: 6),
            _SelectorRow(
              values: const [
                _SelectorValue(0, '0'),
                _SelectorValue(1, '1'),
                _SelectorValue(2, '2'),
                _SelectorValue(3, '3'),
                _SelectorValue(4, '4'),
                _SelectorValue(5, '5+'),
              ],
              selected: _rir,
              enabled: true,
              isTarget: (value) => value == widget.set.targetRir,
              semanticLabel: (value, selected, target) => '$value RIR',
              onChanged: (value) {
                if (value != null) setState(() => _rir = value);
              },
            ),
          ],
        ),
      ),
      footer: AgonezPrimaryButton(
        label: l10n.setSave(widget.set.ordinal),
        onPressed: () => Navigator.of(context).pop(
          FocusSetEdit(
            exercise: widget.exercise,
            set: widget.set,
            loadKg: _load,
            repetitions: _reps,
            rir: _rir,
            comment: widget.set.comment,
            heartRateBpm: widget.set.heartRateBpm,
          ),
        ),
      ),
    );
  }
}
