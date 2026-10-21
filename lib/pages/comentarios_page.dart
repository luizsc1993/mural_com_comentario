import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/comentario_service.dart';

class ComentariosPage extends StatefulWidget {
  final String publicacaoId;
  final Map<String, dynamic> publicacao;

  const ComentariosPage({
    super.key,
    required this.publicacaoId,
    required this.publicacao,
  });

  @override
  State<ComentariosPage> createState() => _ComentariosPageState();
}

class _ComentariosPageState extends State<ComentariosPage> {
  final _texto = TextEditingController();
  final _service = ComentarioService();
  bool _enviando = false;

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (_texto.text.trim().isEmpty || _enviando) return;
    setState(() => _enviando = true);
    try {
      await _service.enviar(
        publicacaoId: widget.publicacaoId,
        texto: _texto.text,
      );
      _texto.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao comentar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _excluir(String comentarioId) async {
    try {
      await _service.excluir(
        publicacaoId: widget.publicacaoId,
        comentarioId: comentarioId,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível excluir: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.publicacao;
    return Scaffold(
      appBar: AppBar(title: const Text('Comentários')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: Column(
            children: [
              Card(
                margin: const EdgeInsets.all(16),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(post['autorNome'] ?? 'Usuário'),
                  subtitle: Text(post['texto'] ?? ''),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _service.acompanhar(widget.publicacaoId),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Erro ao carregar comentários: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final comentarios = snapshot.data!.docs;
                    if (comentarios.isEmpty) {
                      return const Center(child: Text('Ainda não há comentários. Seja o primeiro!'));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: comentarios.length,
                      itemBuilder: (context, index) {
                        final doc = comentarios[index];
                        final comentario = doc.data();
                        final data = comentario['data'] as Timestamp?;
                        final dataTexto = data == null
                            ? ''
                            : '${data.toDate().toLocal().day.toString().padLeft(2, '0')}/'
                              '${data.toDate().toLocal().month.toString().padLeft(2, '0')} '
                              '${data.toDate().toLocal().hour.toString().padLeft(2, '0')}:'
                              '${data.toDate().toLocal().minute.toString().padLeft(2, '0')}';
                        return ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                          title: Text(comentario['autorNome'] ?? 'Usuário'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(comentario['texto'] ?? ''),
                              if (dataTexto.isNotEmpty)
                                Text(dataTexto, style: Theme.of(context).textTheme.labelSmall),
                            ],
                          ),
                          trailing: comentario['autorId'] == FirebaseAuth.instance.currentUser?.uid
                              ? IconButton(
                                  tooltip: 'Excluir meu comentário',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _excluir(doc.id),
                                )
                              : null,
                        );
                      },
                    );
                  },
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _texto,
                          minLines: 1,
                          maxLines: 4,
                          maxLength: 500,
                          decoration: const InputDecoration(
                            hintText: 'Escreva um comentário...',
                            border: OutlineInputBorder(),
                            counterText: '',
                          ),
                          onSubmitted: (_) => _enviar(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        tooltip: 'Enviar comentário',
                        onPressed: _enviando ? null : _enviar,
                        icon: _enviando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
