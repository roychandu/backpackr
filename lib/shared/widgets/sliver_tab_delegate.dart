import 'package:flutter/material.dart';

class SliverTabDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  SliverTabDelegate({required this.child, this.height = kTextTabBarHeight});

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(SliverTabDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.height != height;
  }
}
