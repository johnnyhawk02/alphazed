import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../models/game_state.dart';
import '../config/game_config.dart';
import 'letter_to_picture_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});
  
  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _assetsLoaded = false;
  double _loadingProgress = 0.0;
  bool _isInitialized = false;
  bool _showWelcomeMessage = false;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize the animation controller immediately
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    
    // Start the animation immediately to avoid white screen
    _animationController.forward();
    
    // Start loading process immediately to reduce delay
    _initializeLoading();
  }
  
  void _initializeLoading() {
    // Mark as initialized to avoid white screen
    setState(() {
      _isInitialized = true;
    });
    
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
    // Preload critical assets first to show UI faster
    await _preloadCriticalAssets();
    
    // Simulate loading progress for remaining assets
    for (int i = 1; i <= 10; i++) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 150)); // Reduced delay
      setState(() {
        _loadingProgress = i / 10;
      });
    }
    
    // Load game items in parallel with the animation
    await gameState.loadGameItems();
    
    if (!mounted) return;
    setState(() {
      _assetsLoaded = true;
    });
    
    // Wait for the animation controller to finish its animation
    if (_animationController.status != AnimationStatus.completed) {
      await _animationController.forward().orCancel;
    }
    
    // Add a delay to show the completed progress and the completion animation
    await Future.delayed(const Duration(milliseconds: 1000));
    
    // Show welcome message instead of navigating to another screen
    if (_assetsLoaded && mounted) {
      setState(() {
        _showWelcomeMessage = true;
      });
    }
  }
  
  // Preload the most critical assets to show UI faster
  Future<void> _preloadCriticalAssets() async {
    try {
      // Preload animation assets
      await precacheImage(const AssetImage('assets/icons/app_logo.png'), context);
      
      // Give the UI a chance to render before continuing with loading
      await Future.delayed(const Duration(milliseconds: 50));
    } catch (e) {
      // Ignore errors in preloading, we'll continue with the loading process
      print('Error preloading assets: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // If not initialized yet, show a branded loading indicator to prevent white screen
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: GameConfig.defaultBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            color: GameConfig.primaryButtonColor,
          ),
        ),
      );
    }
    
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      appBar: _showWelcomeMessage ? AppBar(
        elevation: 1,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          'Alphabet Learning',
          style: GameConfig.titleTextStyle,
        ),
        actions: [
          // Developer option button
          IconButton(
            icon: const Icon(Icons.developer_mode),
            onPressed: () => _showDeveloperOptions(context),
            tooltip: 'Developer Options',
          ),
        ],
      ) : null,
      backgroundColor: GameConfig.defaultBackgroundColor,
      body: Container(
        // Force the entire app background to be the pink color
        color: GameConfig.defaultBackgroundColor,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            // Only navigate if we are showing the welcome message
            if (_showWelcomeMessage) {
              // Start the game properly before navigating
              final gameState = Provider.of<GameState>(context, listen: false);
              
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) {
                    // Call startGame inside the builder to ensure it's called after navigation
                    // This ensures the game audio plays only after transition to the game screen
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      gameState.startGame();
                    });
                    return const LetterPictureMatch();
                  },
                ),
              );
            }
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  GameConfig.defaultBackgroundColor.withOpacity(0.95),
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
                        child: _showWelcomeMessage 
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Tap anywhere to start!',
                                    style: GameConfig.titleTextStyle.copyWith(fontSize: 24),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 20),
                                  Icon(
                                    Icons.touch_app,
                                    size: 60,
                                    color: GameConfig.primaryButtonColor,
                                  )
                                ],
                              )
                            : (_assetsLoaded
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
                                  )),
                      ),
                    ),
                    
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        _showWelcomeMessage ? '' : 'Learn the alphabet through fun!',
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
        ),
      ),
    );
  }
  
  void _showDeveloperOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Developer Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Reset Progress'),
              onTap: () {
                // Close the dialog
                Navigator.of(context).pop();
                // Add reset functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configure App'),
              onTap: () {
                // Close the dialog
                Navigator.of(context).pop();
                // Add configuration screen navigation
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}