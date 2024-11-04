import 'package:flutter/material.dart';

class CustomTooltip extends StatelessWidget {
  final String message;
  final Widget child;

  const CustomTooltip({
    Key? key,
    required this.message,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
        final RenderBox box = context.findRenderObject() as RenderBox;
        final Offset position = box.localToGlobal(Offset.zero, ancestor: overlay);

        showDialog(
          context: context,
          builder: (context) {
            return Stack(
              children: [
                Positioned(
                  left: position.dx,
                  top: position.dy - 60,
                  child: CustomPaint(
                    painter: TooltipPainter(),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        message,
                        style: TextStyle(color: Colors.black, fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
      child: child,
    );
  }
}

class TooltipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2 - 8, 0);
    path.lineTo(size.width / 2, 12);
    path.lineTo(size.width / 2 + 8, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Custom Tooltip Example')),
        body: Center(
          child: CustomTooltip(
            message: '0:0:0',
            child: Icon(Icons.location_on, size: 50, color: Colors.red),
          ),
        ),
      ),
    );
  }
}
