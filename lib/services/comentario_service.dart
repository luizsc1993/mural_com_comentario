import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ComentarioService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _comentarios(String publicacaoId) {
    return _db
        .collection('publicacoes')
        .doc(publicacaoId)
        .collection('comentarios');
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> acompanhar(String publicacaoId) {
    return _comentarios(publicacaoId).orderBy('data').snapshots();
  }

  Future<void> enviar({
    required String publicacaoId,
    required String texto,
  }) async {
    final usuario = _auth.currentUser;
    if (usuario == null) throw Exception('Faça login para comentar.');

    final textoLimpo = texto.trim();
    if (textoLimpo.isEmpty) return;

    final perfil = await _db.collection('usuarios').doc(usuario.uid).get();
    final nome = (perfil.data()?['nome'] as String?)?.trim();
    await _comentarios(publicacaoId).add({
      'texto': textoLimpo,
      'autorNome': (nome == null || nome.isEmpty) ? (usuario.email ?? 'Usuário') : nome,
      'autorId': usuario.uid,
      'publicacaoId': publicacaoId,
      'data': FieldValue.serverTimestamp(),
    });
  }

  Future<void> excluir({
    required String publicacaoId,
    required String comentarioId,
  }) async {
    final usuario = _auth.currentUser;
    if (usuario == null) throw Exception('Faça login para excluir comentários.');

    final ref = _comentarios(publicacaoId).doc(comentarioId);
    final comentario = await ref.get();
    if (!comentario.exists) return;
    if (comentario.data()?['autorId'] != usuario.uid) {
      throw Exception('Você só pode excluir seus próprios comentários.');
    }
    await ref.delete();
  }
}
