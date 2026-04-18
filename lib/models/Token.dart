import 'package:recycle_go/models/Connector.dart';

class Token {
  final String? token;
  final String accountId;
  final String accountType;
  final DateTime expiresAt;
  final bool used;
  final DateTime? createdAt;

  Token({
    this.token,
    required this.accountId,
    required this.accountType,
    required this.expiresAt,
    this.used = false,
    this.createdAt,
  });

  factory Token.fromJson(Map<String, dynamic> json) {
    return Token(
      token: json['token'],
      accountId: json['account_id'],
      accountType: json['account_type'],
      expiresAt: DateTime.parse(json['expires_at']),
      used: json['used'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'account_id': accountId,
      'account_type': accountType,
      'expires_at': expiresAt.toIso8601String(),
      'used': used,
    };
    if (token != null) data['token'] = token;
    return data;
  }
}

class TokenModel extends Connector {
  static final TokenModel _instance = TokenModel._internal();
  TokenModel._internal();
  factory TokenModel() => _instance;

  Future<String> createToken(String accountId, String accountType) async {
    final expiresAt = DateTime.now().add(const Duration(hours: 24));
    final response = await client.from('tokens').insert({
      'account_id': accountId,
      'account_type': accountType,
      'expires_at': expiresAt.toIso8601String(),
      'used': false,
    }).select().single();
    
    return response['token'];
  }

  Future<Token?> verifyToken(String tokenValue) async {
    final response = await client
        .from('tokens')
        .select()
        .eq('token', tokenValue)
        .eq('used', false)
        .gt('expires_at', DateTime.now().toIso8601String())
        .maybeSingle();

    if (response != null) {
      return Token.fromJson(response);
    }
    return null;
  }

  Future<void> markAsUsed(String tokenValue) async {
    await client
        .from('tokens')
        .update({'used': true})
        .eq('token', tokenValue);
  }
}
