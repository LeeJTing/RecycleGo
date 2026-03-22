import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';

class InputField extends StatelessWidget {
  final String labelText;
  final String hintText;
  final bool obscureText;
  final TextInputType keyboardType;

  const InputField({super.key, required this.labelText, required this.hintText, this.obscureText = false, this.keyboardType = TextInputType.text});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Container(
      alignment: Alignment.topLeft,
      padding: EdgeInsets.symmetric(horizontal: size.width*0.1),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Text(
            labelText,
            style: TextDesign.normalText()
          ),
          const SizedBox(height: 3,),
          Input(hintText: hintText, obscureText: obscureText, keyBoardType: keyboardType,),
        ],
      ),
    );
  }
}

class Input extends StatefulWidget {
  final String hintText;
  final bool obscureText;
  final TextInputType keyBoardType;

  const Input({super.key, required this.hintText, required this.obscureText, required this.keyBoardType});

  @override
  State<Input> createState() => _InputState();
}

class _InputState extends State<Input> {
  final AppColors theme = AppThemes.color;
  late var borderSideColor = theme.border;

  @override
  void dispose() {

    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      style: TextDesign.normalText(),
      obscureText: widget.obscureText,
      keyboardType: widget.keyBoardType,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: TextDesign.smallText(color:theme.onHint),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: borderSideColor),
          borderRadius: BorderRadius.circular(10)
        )
      ),
    );
  }
}
