import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:vidrocket_pro/providers/ad_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adProvider = Provider.of<AdProvider>(context, listen: false);
      adProvider.loadBannerAd();
      adProvider.loadInterstitialAd();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VidRocket Pro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              Navigator.pushNamed(context, '/downloads');
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'Enter Video URL',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (_urlController.text.isNotEmpty) {
                        Provider.of<AdProvider>(context, listen: false).showInterstitialAd();
                        Navigator.pushNamed(context, '/browser', arguments: _urlController.text);
                      }
                    },
                    child: const Text('Search'),
                  ),
                ],
              ),
            ),
          ),
          Consumer<AdProvider>(
            builder: (context, adProvider, child) {
              if (adProvider.isBannerAdReady) {
                return SizedBox(
                  width: adProvider.bannerAd!.size.width.toDouble(),
                  height: adProvider.bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: adProvider.bannerAd!),
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
        ],
      ),
    );
  }
}
