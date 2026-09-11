import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../manager/authentication_cubit.dart';
import '../manager/authentication_state.dart';

class MofidLoginPage extends StatefulWidget {
  const MofidLoginPage({super.key});

  @override
  State<MofidLoginPage> createState() => _MofidLoginPageState();
}

class _MofidLoginPageState extends State<MofidLoginPage> {
  WebViewController? _controller;
  String? _loadedState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<AuthenticationCubit>();
      if (cubit.state is! AuthenticationLoginReady) {
        cubit.beginLogin();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ورود به مفید')),
      body: BlocConsumer<AuthenticationCubit, AuthenticationState>(
        listener: (context, state) {
          if (state is AuthenticationSignedIn && Navigator.canPop(context)) {
            Navigator.pop(context, true);
          }
          if (state is AuthenticationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          final request = switch (state) {
            AuthenticationLoginReady(:final request) => request,
            AuthenticationCompleting(:final request) => request,
            _ => null,
          };

          if (request != null) {
            _ensureController(request.authorizationUri, request.state);
          }

          final controller = _controller;
          if (controller == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Stack(
            children: <Widget>[
              WebViewWidget(controller: controller),
              if (state is AuthenticationCompleting)
                const ColoredBox(
                  color: Color(0x66000000),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }

  void _ensureController(Uri authorizationUri, String state) {
    if (_controller != null && _loadedState == state) {
      return;
    }

    _loadedState = state;
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri != null &&
                uri.toString().startsWith(AuthenticationCubit.redirectUri)) {
              context.read<AuthenticationCubit>().completeRedirect(uri);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(authorizationUri);
  }
}
