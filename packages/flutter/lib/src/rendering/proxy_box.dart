// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/painting.dart';

import 'object.dart';

export 'package:flutter/gestures.dart'
    show
    PointerEvent,
    PointerDownEvent,
    PointerMoveEvent,
    PointerUpEvent,
    PointerCancelEvent;

/// An interface for providing custom clips.
///
/// This class is used by a number of clip widgets (e.g., [ClipRect] and
/// [ClipPath]).
///
/// The [getClip] method is called whenever the custom clip needs to be updated.
///
/// The [shouldReclip] method is called when a new instance of the class
/// is provided, to check if the new instance actually represents different
/// information.
///
/// The most efficient way to update the clip provided by this class is to
/// supply a reclip argument to the constructor of the [CustomClipper]. The
/// custom object will listen to this animation and update the clip whenever the
/// animation ticks, avoiding both the build and layout phases of the pipeline.
///
/// See also:
///
///  * [ClipRect], which can be customized with a [CustomClipper].
///  * [ClipRRect], which can be customized with a [CustomClipper].
///  * [ClipOval], which can be customized with a [CustomClipper].
///  * [ClipPath], which can be customized with a [CustomClipper].
abstract class CustomClipper<T> {
  /// Creates a custom clipper.
  ///
  /// The clipper will update its clip whenever [reclip] notifies its listeners.
  const CustomClipper({Listenable reclip});

  /// Returns a description of the clip given that the render object being
  /// clipped is of the given size.
  T getClip(Size size);

  /// Returns an approximation of the clip returned by [getClip], as
  /// an axis-aligned Rect. This is used by the semantics layer to
  /// determine whether widgets should be excluded.
  ///
  /// By default, this returns a rectangle that is the same size as
  /// the RenderObject. If getClip returns a shape that is roughly the
  /// same size as the RenderObject (e.g. it's a rounded rectangle
  /// with very small arcs in the corners), then this may be adequate.
  Rect getApproximateClipRect(Size size) => Offset.zero & size;

  /// Called whenever a new instance of the custom clipper delegate class is
  /// provided to the clip object, or any time that a new clip object is created
  /// with a new instance of the custom painter delegate class (which amounts to
  /// the same thing, because the latter is implemented in terms of the former).
  ///
  /// If the new instance represents different information than the old
  /// instance, then the method should return true, otherwise it should return
  /// false.
  ///
  /// If the method returns false, then the [getClip] call might be optimized
  /// away.
  ///
  /// It's possible that the [getClip] method will get called even if
  /// [shouldReclip] returns false or if the [shouldReclip] method is never
  /// called at all (e.g. if the box changes size).
  bool shouldReclip(covariant CustomClipper<T> oldClipper);

  @override
  String toString() => '$runtimeType';
}

/// How to behave during hit tests.
enum HitTestBehavior {
  /// Targets that defer to their children receive events within their bounds
  /// only if one of their children is hit by the hit test.
  deferToChild,

  /// Opaque targets can be hit by hit tests, causing them to both receive
  /// events within their bounds and prevent targets visually behind them from
  /// also receiving events.
  opaque,

  /// Translucent targets both receive events within their bounds and permit
  /// targets visually behind them to also receive events.
  translucent,
}

/// Where to paint a box decoration.
enum DecorationPosition {
  /// Paint the box decoration behind the children.
  background,

  /// Paint the box decoration in front of the children.
  foreground,
}

/// Signature for listening to [PointerDownEvent] events.
///
/// Used by [Listener] and [RenderPointerListener].
typedef void PointerDownEventListener(PointerDownEvent event);

/// Signature for listening to [PointerMoveEvent] events.
///
/// Used by [Listener] and [RenderPointerListener].
typedef void PointerMoveEventListener(PointerMoveEvent event);

/// Signature for listening to [PointerUpEvent] events.
///
/// Used by [Listener] and [RenderPointerListener].
typedef void PointerUpEventListener(PointerUpEvent event);

/// Signature for listening to [PointerCancelEvent] events.
///
/// Used by [Listener] and [RenderPointerListener].
typedef void PointerCancelEventListener(PointerCancelEvent event);

/// The interface used by [CustomPaint] (in the widgets library) and
/// [RenderCustomPaint] (in the rendering library).
///
/// To implement a custom painter, either subclass or implement this interface
/// to define your custom paint delegate. [CustomPaint] subclasses must
/// implement the [paint] and [shouldRepaint] methods, and may optionally also
/// implement the [hitTest] method.
///
/// The [paint] method is called whenever the custom object needs to be repainted.
///
/// The [shouldRepaint] method is called when a new instance of the class
/// is provided, to check if the new instance actually represents different
/// information.
///
/// The most efficient way to trigger a repaint is to either extend this class
/// and supply a `repaint` argument to the constructor of the [CustomPainter],
/// where that object notifies its listeners when it is time to repaint, or to
/// extend [Listenable] (e.g. via [ChangeNotifier]) and implement
/// [CustomPainter], so that the object itself provides the notifications
/// directly. In either case, the [CustomPaint] widget or [RenderCustomPaint]
/// render object will listen to the [Listenable] and repaint whenever the
/// animation ticks, avoiding both the build and layout phases of the pipeline.
///
/// The [hitTest] method is called when the user interacts with the underlying
/// render object, to determine if the user hit the object or missed it.
///
/// ## Sample code
///
/// This sample extends the same code shown for [RadialGradient] to create a
/// custom painter that paints a sky.
///
/// ```dart
/// class Sky extends CustomPainter {
///   @override
///   void paint(Canvas canvas, Size size) {
///     var rect = Offset.zero & size;
///     var gradient = new RadialGradient(
///       center: const FractionalOffset(0.7, 0.2),
///       radius: 0.2,
///       colors: [const Color(0xFFFFFF00), const Color(0xFF0099FF)],
///       stops: [0.4, 1.0],
///     );
///     canvas.drawRect(
///       rect,
///       new Paint()..shader = gradient.createShader(rect),
///     );
///   }
///
///   @override
///   bool shouldRepaint(Sky oldDelegate) {
///     // Since this Sky painter has no fields, it always paints
///     // the same thing, and therefore we return false here. If
///     // we had fields (set from the constructor) then we would
///     // return true if any of them differed from the same
///     // fields on the oldDelegate.
///     return false;
///   }
/// }
/// ```
///
/// See also:
///
///  * [Canvas], the class that a custom painter uses to paint.
///  * [CustomPaint], the widget that uses [CustomPainter], and whose sample
///    code shows how to use the above `Sky` class.
///  * [RadialGradient], whose sample code section shows a different take
///    on the sample code above.
abstract class CustomPainter extends Listenable {
  /// Creates a custom painter.
  ///
  /// The painter will repaint whenever `repaint` notifies its listeners.
  const CustomPainter({Listenable repaint}) : _repaint = repaint;

  final Listenable _repaint;

  /// Register a closure to be notified when it is time to repaint.
  ///
  /// The [CustomPainter] implementation merely forwards to the same method on
  /// the [Listenable] provided to the constructor in the `repaint` argument, if
  /// it was not null.
  @override
  void addListener(VoidCallback listener) => _repaint?.addListener(listener);

  /// Remove a previously registered closure from the list of closures that the
  /// object notifies when it is time to repaint.
  ///
  /// The [CustomPainter] implementation merely forwards to the same method on
  /// the [Listenable] provided to the constructor in the `repaint` argument, if
  /// it was not null.
  @override
  void removeListener(VoidCallback listener) =>
      _repaint?.removeListener(listener);

  /// Called whenever the object needs to paint. The given [Canvas] has its
  /// coordinate space configured such that the origin is at the top left of the
  /// box. The area of the box is the size of the [size] argument.
  ///
  /// Paint operations should remain inside the given area. Graphical operations
  /// outside the bounds may be silently ignored, clipped, or not clipped.
  ///
  /// Implementations should be wary of correctly pairing any calls to
  /// [Canvas.save]/[Canvas.saveLayer] and [Canvas.restore], otherwise all
  /// subsequent painting on this canvas may be affected, with potentially
  /// hilarious but confusing results.
  ///
  /// To paint text on a [Canvas], use a [TextPainter].
  ///
  /// To paint an image on a [Canvas]:
  ///
  /// 1. Obtain an [ImageStream], for example by calling [ImageProvider.resolve]
  ///    on an [AssetImage] or [NetworkImage] object.
  ///
  /// 2. Whenever the [ImageStream]'s underlying [ImageInfo] object changes
  ///    (see [ImageStream.addListener]), create a new instance of your custom
  ///    paint delegate, giving it the new [ImageInfo] object.
  ///
  /// 3. In your delegate's [paint] method, call the [Canvas.drawImage],
  ///    [Canvas.drawImageRect], or [Canvas.drawImageNine] methods to paint the
  ///    [ImageInfo.image] object, applying the [ImageInfo.scale] value to
  ///    obtain the correct rendering size.
  void paint(Canvas canvas, Size size);

  /// Called whenever a new instance of the custom painter delegate class is
  /// provided to the [RenderCustomPaint] object, or any time that a new
  /// [CustomPaint] object is created with a new instance of the custom painter
  /// delegate class (which amounts to the same thing, because the latter is
  /// implemented in terms of the former).
  ///
  /// If the new instance represents different information than the old
  /// instance, then the method should return true, otherwise it should return
  /// false.
  ///
  /// If the method returns false, then the [paint] call might be optimized
  /// away.
  ///
  /// It's possible that the [paint] method will get called even if
  /// [shouldRepaint] returns false (e.g. if an ancestor or descendant needed to
  /// be repainted). It's also possible that the [paint] method will get called
  /// without [shouldRepaint] being called at all (e.g. if the box changes
  /// size).
  ///
  /// If a custom delegate has a particularly expensive paint function such that
  /// repaints should be avoided as much as possible, a [RepaintBoundary] or
  /// [RenderRepaintBoundary] (or other render object with
  /// [RenderObject.isRepaintBoundary] set to true) might be helpful.
  bool shouldRepaint(covariant CustomPainter oldDelegate);

  /// Called whenever a hit test is being performed on an object that is using
  /// this custom paint delegate.
  ///
  /// The given point is relative to the same coordinate space as the last
  /// [paint] call.
  ///
  /// The default behavior is to consider all points to be hits for
  /// background painters, and no points to be hits for foreground painters.
  ///
  /// Return true if the given position corresponds to a point on the drawn
  /// image that should be considered a "hit", false if it corresponds to a
  /// point that should be considered outside the painted image, and null to use
  /// the default behavior.
  bool hitTest(Offset position) => null;

  @override
  String toString() =>
      '${describeIdentity(this)}(${ _repaint?.toString() ?? "" })';
}

/// Signature for a function that creates a [Shader] for a given [Rect].
///
/// Used by [RenderShaderMask] and the [ShaderMask] widget.
typedef Shader ShaderCallback(Rect bounds);