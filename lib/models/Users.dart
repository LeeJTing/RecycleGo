import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> initialize() async{
  await Supabase.initialize(
    url: 'https://ngcrvuzbxzwinnzmcwxj.supabase.co',
    anonKey: 'sb_publishable_1yK9-NCtNnVTIEiJWU8zUg_zEE9AdFa',
  );
}

const supabaseURL = 'https://ngcrvuzbxzwinnzmcwxj.supabase.co';