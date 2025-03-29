import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../models/game_state.dart';
import '../config/game_config.dart';
import 'welcome_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});
  
  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _assetsLoaded = false;
  double _loadingProgress = 0.0;
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    
    _animationController.forward();
    
    // Use addPostFrameCallback to ensure the Provider is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gameState = Provider.of<GameState>(context, listen: false);
      _startLoading(gameState);
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _startLoading(GameState gameState) async {
    // Simulate loading progress
    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      setState(() {
        _loadingProgress = i / 10;
      });
    }
    
    await gameState.loadGameItems();
    
    setState(() {
      _assetsLoaded = true;
    });
    
    // Add a small delay to show the completed progress
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Check if still mounted before navigating
    if (mounted) {
      // Loading finished, navigate to WelcomeScreen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: GameConfig.defaultBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              GameConfig.defaultBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo/title
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -0.5),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _animationController,
                    curve: Curves.elasticOut,
                  )),
                  child: FadeTransition(
                    opacity: _animationController,
                    child: Text(
                      'AlphaZed',
                      style: GameConfig.titleTextStyle.copyWith(
                        fontSize: screenSize.width * 0.12,
                        color: GameConfig.primaryButtonColor,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Animated letter blocks
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.5),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _animationController,
                    curve: Curves.elasticOut,
                  )),
                  child: FadeTransition(
                    opacity: _animationController,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                        (index) => AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            final delay = index * 0.2;
                            final bounceAnimation = Curves.elasticOut.transform(
                              (_animationController.value - delay).clamp(0.0, 1.0) / (1.0 - delay),
                            );
                            
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              width: screenSize.width * 0.12,
                              height: screenSize.width * 0.12,
                              transform: Matrix4.translationValues(
                                0, 
                                30 * (1 - bounceAnimation), 
                                0,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    GameConfig.primaryButtonColor,
                                    GameConfig.primaryButtonColor.withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(screenSize.width * 0.02),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  String.fromCharCode(65 + index),
                                  style: TextStyle(
                                    fontSize: screenSize.width * 0.08,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                
                Expanded(
                  child: Center(
                    child: _assetsLoaded
                        ? Lottie.asset(
                            'assets/animations/correct.json',
                            width: 100,
                            height: 100,
                            repeat: false,
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Loading indicator
                              SizedBox(
                                width: screenSize.width * 0.6,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: _loadingProgress,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      GameConfig.primaryButtonColor,
                                    ),
                                    minHeight: 10,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Loading ${(_loadingProgress * 100).toInt()}%',
                                style: GameConfig.bodyTextStyle.copyWith(
                                  color: GameConfig.textColor.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Learn the alphabet through fun!',
                    style: GameConfig.bodyTextStyle.copyWith(
                      color: GameConfig.textColor.withOpacity(0.7),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}