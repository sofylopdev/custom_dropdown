import 'package:custom_selector/dropdown_menu_painter.dart';
import 'package:custom_selector/dropdown_route.dart';
import 'package:custom_selector/dropdown_scroll_behavior.dart';
import 'package:flutter/material.dart';

const Duration _kDropdownMenuDuration = Duration(milliseconds: 300);
const double _kMenuItemHeight = 48.0;
const double _kDenseButtonHeight = 24.0;
const EdgeInsets _kMenuItemPadding = EdgeInsets.symmetric(horizontal: 16.0);
const EdgeInsetsGeometry _kAlignedButtonPadding =
    EdgeInsetsDirectional.only(start: 16.0, end: 4.0);
const EdgeInsets _kUnalignedButtonPadding = EdgeInsets.zero;
const EdgeInsets _kAlignedMenuMargin = EdgeInsets.zero;
const EdgeInsetsGeometry _kUnalignedMenuMargin =
    EdgeInsetsDirectional.only(start: 16.0, end: 24.0);

class DropdownMenu<T> extends StatefulWidget {
  const DropdownMenu({
    Key key,
    this.padding,
    this.route,
    this.menuBorderColor,
    this.menuBackgroundColor,
    this.selectedItemColor,
    this.splashColor,
  }) : super(key: key);

  final DropdownRoute<T> route;
  final EdgeInsets padding;

  final menuBorderColor;
  final menuBackgroundColor;
  final Color selectedItemColor;
  final Color splashColor;

  @override
  _DropdownMenuState<T> createState() => new _DropdownMenuState<T>();
}

class _DropdownMenuState<T> extends State<DropdownMenu<T>> {
  CurvedAnimation _fadeOpacity;
  CurvedAnimation _resize;

  @override
  void initState() {
    super.initState();
    // We need to hold these animations as state because of their curve
    // direction. When the route's animation reverses, if we were to recreate
    // the CurvedAnimation objects in build, we'd lose
    // CurvedAnimation._curveDirection.
    _fadeOpacity = new CurvedAnimation(
      parent: widget.route.animation,
      curve: const Interval(0.0, 0.25),
      reverseCurve: const Interval(0.75, 1.0),
    );
    _resize = new CurvedAnimation(
      parent: widget.route.animation,
      curve: const Interval(0.25, 0.5),
      reverseCurve: const Threshold(0.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The menu is shown in three stages (unit timing in brackets):
    // [0s - 0.25s] - Fade in a rect-sized menu container with the selected item.
    // [0.25s - 0.5s] - Grow the otherwise empty menu container from the center
    //   until it's big enough for as many items as we're going to show.
    // [0.5s - 1.0s] Fade in the remaining visible items from top to bottom.
    //
    // When the menu is dismissed we just fade the entire thing out
    // in the first 0.25s.
    final MaterialLocalizations localizations =
        MaterialLocalizations.of(context);
    final DropdownRoute<T> route = widget.route;
    final double unit = 0.5 / (route.items.length + 1.5);
    final List<Widget> children = <Widget>[];

    print("Lenght of items list: ${route.items.length}");

    for (int itemIndex = 0; itemIndex < route.items.length; ++itemIndex) {
      print("DropdownItems each: ${route.items[itemIndex].value}");
      CurvedAnimation opacity;
      if (itemIndex == route.selectedIndex) {
        opacity = new CurvedAnimation(
            parent: route.animation, curve: const Threshold(0.0));
      } else {
        final double start = (0.5 + (itemIndex + 1) * unit).clamp(0.0, 1.0);
        final double end = (start + 1.5 * unit).clamp(0.0, 1.0);
        opacity = new CurvedAnimation(
            parent: route.animation, curve: new Interval(start, end));
      }
      children.add(new FadeTransition(
        opacity: opacity,
        child: Container(
          decoration: BoxDecoration(
              color: route.selectedIndex == itemIndex
                  ? widget.selectedItemColor
                  : widget.menuBackgroundColor,
              border: Border(
                  left: BorderSide(color: widget.menuBorderColor),
                  right: BorderSide(color: widget.menuBorderColor))),
          child: Material(
            color: Colors.transparent,
            child: new InkWell(
                // splashColor: widget.splashColor,
                child: new Container(
                  padding: widget.padding,
                  child: route.items[itemIndex],
                ),
                onTap: () {
                  Navigator.pop(
                    context,
                    new DropdownRouteResult<T>(route.items[itemIndex].value),
                  );
                }),
          ),
        ),
      ));
    }

    return new FadeTransition(
      opacity: _fadeOpacity,
      child: new CustomPaint(
        painter: new DropdownMenuPainter(
          borderColor: widget.menuBorderColor,
          color: widget
              .menuBackgroundColor, //widget.menuBackgroundColor ?? Theme.of(context).canvasColor,
          elevation: route.elevation,
          selectedIndex: route.selectedIndex,
          resize: _resize,
        ),
        child: new Semantics(
          scopesRoute: true,
          namesRoute: true,
          explicitChildNodes: true,
          label: localizations.popupMenuLabel,
          child: new Material(
            type: MaterialType.transparency,
            textStyle: route.style,
            child: new ScrollConfiguration(
              behavior: const DropdownScrollBehavior(),
              child: new Scrollbar(
                child: new ListView(
                  controller: widget.route.scrollController,
                  padding: kMaterialListPadding,
                  itemExtent: _kMenuItemHeight,
                  shrinkWrap: true,
                  children: children,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
