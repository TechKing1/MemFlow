import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_models/landing_viewmodel.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LandingViewModel(
        onContinuePressed: () {
          Navigator.pushReplacementNamed(context, '/dashboard');
        },
      ),
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Forensense',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 32),
              Consumer<LandingViewModel>(
                builder: (context, viewModel, _) {
                  return ElevatedButton(
                    onPressed: viewModel.handleContinue,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 16,
                      ),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    child: const Text('Continue'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
