import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class atsTextField extends StatefulWidget {
  atsTextField(
      {super.key,
      required this.labelText,
      this.textEditingController,
      this.onEditingComplete,
      this.keyboardType,
      this.enabled = true,
      this.onChanged,
      this.textAlign = TextAlign.start});

  final TextEditingController? textEditingController;
  final String labelText;

  final TextInputType? keyboardType;

  final bool enabled;

  Function? onEditingComplete;
  Function? onChanged;

  TextAlign textAlign = TextAlign.start;

  @override
  State<atsTextField> createState() => _atsTextFieldState();
}

class _atsTextFieldState extends State<atsTextField> {
  @override
  Widget build(BuildContext context) {
    return TextField(
        textAlign: widget.textAlign,
        keyboardType: widget.keyboardType,
        controller: widget.textEditingController,
        enabled: widget.enabled,
        onEditingComplete: widget.onEditingComplete as void Function()?,
        onChanged: widget.onChanged as void Function(String)?,
        decoration: InputDecoration(
          floatingLabelAlignment: FloatingLabelAlignment.center,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(50)),
          ),
          labelText: widget.labelText,
        ));
  }
}