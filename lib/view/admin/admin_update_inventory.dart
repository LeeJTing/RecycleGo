import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/controller/admin/inventory_controller.dart';
import 'package:recycle_go/models/RecycleInventory.dart';
import 'package:recycle_go/utils/async_task_runner.dart';

class AdminUpdateInventory extends StatefulWidget {
  final RecycleInventory? item;

  const AdminUpdateInventory({super.key, this.item});

  @override
  State<AdminUpdateInventory> createState() => _AdminUpdateInventoryState();
}

class _AdminUpdateInventoryState extends State<AdminUpdateInventory> {
  @override
  Widget build(BuildContext context) {

    throw UnimplementedError();
  }

}
