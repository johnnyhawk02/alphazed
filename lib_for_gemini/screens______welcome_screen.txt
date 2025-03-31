      appBar: AppBar(
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
      ),
      backgroundColor: const Color(0xFFFAE1DD), // Explicit soft warm pink