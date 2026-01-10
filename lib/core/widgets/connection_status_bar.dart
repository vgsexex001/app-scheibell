import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/realtime_provider.dart';

/// Barra que mostra status de conexão WebSocket
class ConnectionStatusBar extends StatelessWidget {
  final bool showWhenConnected;

  const ConnectionStatusBar({
    super.key,
    this.showWhenConnected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<RealtimeProvider>(
      builder: (context, provider, _) {
        if (provider.isConnected && !showWhenConnected) {
          return const SizedBox.shrink();
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          color: provider.isConnected ? Colors.green : Colors.orange,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: SafeArea(
            bottom: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  provider.isConnected ? Icons.wifi : Icons.wifi_off,
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  provider.isConnected ? 'Conectado' : 'Reconectando...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Widget de indicador de conexão compacto (apenas ícone)
class ConnectionIndicator extends StatelessWidget {
  final double size;

  const ConnectionIndicator({
    super.key,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<RealtimeProvider>(
      builder: (context, provider, _) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: provider.isConnected ? Colors.green : Colors.orange,
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

/// Widget que mostra status de conexão como tooltip
class ConnectionStatusIcon extends StatelessWidget {
  final double size;

  const ConnectionStatusIcon({
    super.key,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<RealtimeProvider>(
      builder: (context, provider, _) {
        return Tooltip(
          message: provider.isConnected
              ? 'Conectado em tempo real'
              : 'Reconectando...',
          child: Icon(
            provider.isConnected ? Icons.wifi : Icons.wifi_off,
            size: size,
            color: provider.isConnected ? Colors.green : Colors.orange,
          ),
        );
      },
    );
  }
}
