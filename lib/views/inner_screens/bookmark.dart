import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:brevity/controller/bloc/bookmark_bloc/bookmark_event.dart';
import 'package:brevity/views/common_widgets/List_of_article.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:brevity/controller/bloc/bookmark_bloc/bookmark_bloc.dart';
import 'package:brevity/controller/bloc/bookmark_bloc/bookmark_state.dart';
import 'package:brevity/controller/cubit/theme/theme_cubit.dart';
import 'package:brevity/models/article_model.dart';
import 'package:brevity/views/common_widgets/common_appbar.dart';

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen>
    with TickerProviderStateMixin {
  late Animation<double> _animation;
  late AnimationController _animationController;
  late AnimationController _particleAnimationController;

  @override
  void initState() {
    super.initState();
    context.read<BookmarkBloc>().add(LoadBookmarksEvent());

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _particleAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _particleAnimationController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access current theme from ThemeCubit for dynamic theming
    final currentTheme = context.read<ThemeCubit>().currentTheme;

    return AppScaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: const Color.fromARGB(210, 0, 0, 0),
            expandedHeight: 70,
            pinned: true,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: ParticlesHeader(
                title: "Bookmarks",
                // Apply theme's primary color to particle header
                themeColor: currentTheme.primaryColor,
                particleAnimation: _particleAnimationController,
              ),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              color: Colors.white70,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              FadeTransition(
                opacity: _animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(_animation),
                  child: BlocBuilder<BookmarkBloc, BookmarkState>(
                    builder: (context, state) {
                      if (state is BookmarksLoaded) {
                        return state.bookmarks.isEmpty
                            ? _buildEmptyState(currentTheme)
                            : _buildBookmarksList(state.bookmarks);
                      }
                      return Center(
                        child: CircularProgressIndicator(
                          // Use theme's primary color for loading indicator
                          color: currentTheme.primaryColor,
                          strokeWidth: 3,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  // Updated empty state with theme parameter for dynamic styling
  Widget _buildEmptyState(currentTheme) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: const Color(0xFF1E222A),
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    // Apply theme color to shadow with opacity
                    color: currentTheme.primaryColor.withAlpha((0.15 * 255).toInt()),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.bookmark_border_rounded,
                size: 70,
                // Use theme's primary color for bookmark icon
                color: currentTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'No Bookmarks Yet',
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Articles you save will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFFABB0B8),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                // Apply theme's primary color to button background
                backgroundColor: currentTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                // Apply theme color to button shadow
                shadowColor: currentTheme.primaryColor.withAlpha((0.5 * 255).toInt()),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.explore_outlined),
                  SizedBox(width: 8),
                  Text(
                    'Discover News',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarksList(List<Article> bookmarks) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: bookmarks.length,
      itemBuilder: (context, index) {
        final article = bookmarks[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 22, right: 22),
          child: ArticleListItem(
            showRemove: true,
            article: article,
            onSide:
                () => context.read<BookmarkBloc>().add(
                  ToggleBookmarkEvent(article),
                ),
            onTap: () => _launchUrl(article.url),
          ),
        );
      },
    );
  }
}
