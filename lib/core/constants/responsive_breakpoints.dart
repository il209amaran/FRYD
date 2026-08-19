abstract final class ResponsiveBreakpoints {
  static const double mobile = 700;
  static const double wide = 1000;

  static bool isMobile(double width) => width < mobile;
  static bool isWide(double width) => width >= wide;
}
