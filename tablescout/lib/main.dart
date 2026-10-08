import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tablescout/services/websocket_service.dart';

import 'session/session_manager.dart';
import 'router/app_router.dart';


Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();
  
  await WebSocketService.instance.connect();

  final sessionManager = SessionManager();
  final appRouter = AppRouter(sessionManager);

  runApp(
    ChangeNotifierProvider.value(
      value: sessionManager,
      child: MainApp(
        appRouter: appRouter,
        ),
    ),
  );  
}

class MainApp extends StatelessWidget {
  final AppRouter appRouter;
  const MainApp({
    super.key,
    required this.appRouter,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TableScout',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter.router,
    );
  }
}