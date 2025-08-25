import 'package:flutter/material.dart';
import 'package:rebatur_machine_test/core/theme/color_constant.dart';


snackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
        ),
        content: Center(
          child: Text(
            message,
            style:  TextStyle(
              fontWeight: FontWeight.w600,
              color: ColorConstant.white,
              fontFamily: 'Urbanist',
            ),
          ),
        ),
        backgroundColor: Colors.blue,
        elevation: 30,
      ),
    );
}