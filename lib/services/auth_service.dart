import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _google = GoogleSignIn.instance;

  static bool _googleInited = false;

  /// 필요 시 "웹 클라이언트 ID(serverClientId)" 넣기
  /// (serverClientId 관련 에러 뜰 때만 넣어도 됨)
  static const String? _serverClientId = null;

  static Future<void> _ensureGoogleInit() async {
    if (_googleInited) return;
    await _google.initialize(serverClientId: _serverClientId);
    _googleInited = true;
  }

  /// EditorScreen에서 사용
  static User? get user => _auth.currentUser;

  /// ✅ 앱 시작 시: 로그인 상태가 없으면 익명 로그인으로 시작
  static Future<UserCredential?> ensureAnonymous() async {
    final current = _auth.currentUser;
    if (current != null) return null; // 이미 로그인(익명/구글 등) 되어있음

    return _auth.signInAnonymously();
  }

  /// ✅ Google 로그인 -> Firebase 로그인 (익명이면 자동으로 구글로 업그레이드됨)
  static Future<UserCredential> signInWithGoogle() async {
    await _ensureGoogleInit();

    // 1) Authentication: idToken
    final GoogleSignInAccount account = await _google.authenticate(
      scopeHint: const <String>['email', 'profile'],
    );

    final String? idToken = account.authentication.idToken;
    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'missing-id-token',
        message: 'Google idToken을 가져오지 못했습니다.',
      );
    }

    // 2) Authorization: accessToken (v7에서는 여기서 얻음)
    const scopes = <String>['email', 'profile'];

    GoogleSignInClientAuthorization? authz =
        await account.authorizationClient.authorizationForScopes(scopes);

    authz ??= await account.authorizationClient.authorizeScopes(scopes);

    final String? accessToken = authz.accessToken;

    // 3) Firebase credential
    final OAuthCredential credential = GoogleAuthProvider.credential(
      idToken: idToken,
      accessToken: accessToken,
    );

    // ✅ 여기서 signInWithCredential 하면,
    // 익명 계정이면 자동으로 "구글 계정으로 전환/연결"되는 케이스가 많음.
    // (만약 "account-exists-with-different-credential" 에러 뜨면 그때 추가 처리)
    return _auth.signInWithCredential(credential);
  }

  static Future<void> signOut() async {
    await _auth.signOut();
    await _google.signOut();
  }
}
