// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter2js/flutter_internals.dart' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

import 'basic.dart';
import 'framework.dart';
import 'localizations.dart';
import 'media_query.dart';
import 'ticker_provider.dart';

export 'package:flutter/painting.dart'
    show
        AssetImage,
        ExactAssetImage,
        FileImage,
        ImageConfiguration,
        ImageInfo,
        ImageStream,
        ImageProvider,
        MemoryImage,
        NetworkImage;

/// Creates an [ImageConfiguration] based on the given [BuildContext] (and
/// optionally size).
///
/// This is the object that must be passed to [BoxPainter.paint] and to
/// [ImageProvider.resolve].
///
/// If this is not called from a build method, then it should be reinvoked
/// whenever the dependencies change, e.g. by calling it from
/// [State.didChangeDependencies], so that any changes in the environment are
/// picked up (e.g. if the device pixel ratio changes).
///
/// See also:
///
///  * [ImageProvider], which has an example showing how this might be used.
ImageConfiguration createLocalImageConfiguration(BuildContext context,
    {Size size}) {
  return new ImageConfiguration(
    bundle: DefaultAssetBundle.of(context),
    devicePixelRatio:
        MediaQuery.of(context, nullOk: true)?.devicePixelRatio ?? 1.0,
    locale: Localizations.localeOf(context, nullOk: true),
    textDirection: Directionality.of(context),
    size: size,
    platform: defaultTargetPlatform,
  );
}

/// Prefetches an image into the image cache.
///
/// Returns a [Future] that will complete when the first image yielded by the
/// [ImageProvider] is available.
///
/// If the image is later used by an [Image] or [BoxDecoration] or [FadeInImage],
/// it will probably be loaded faster.  The consumer of the image does not need
/// to use the same [ImageProvider] instance.  The [ImageCache] will find the image
/// as long as both images share the same key.
///
/// The [BuildContext] and [Size] are used to select an image configuration
/// (see [createLocalImageConfiguration]).
///
/// See also:
///
///   * [ImageCache], which holds images that may be reused.
Future<Null> precacheImage(ImageProvider provider, BuildContext context,
    {Size size}) {
  final ImageConfiguration config =
      createLocalImageConfiguration(context, size: size);
  final Completer<Null> completer = new Completer<Null>();
  final ImageStream stream = provider.resolve(config);
  void listener(ImageInfo image, bool sync) {
    completer.complete();
  }

  stream.addListener(listener);
  completer.future.then((Null _) {
    stream.removeListener(listener);
  });
  return completer.future;
}

/// A widget that displays an image.
///
/// Several constructors are provided for the various ways that an image can be
/// specified:
///
///  * [new Image], for obtaining an image from an [ImageProvider].
///  * [new Image.asset], for obtaining an image from an [AssetBundle]
///    using a key.
///  * [new Image.network], for obtaining an image from a URL.
///  * [new Image.file], for obtaining an image from a [File].
///  * [new Image.memory], for obtaining an image from a [Uint8List].
///
/// The following image formats are supported: {@macro flutter.package:flutter/ui.dart.imageFormats}
///
/// To automatically perform pixel-density-aware asset resolution, specify the
/// image using an [AssetImage] and make sure that a [MaterialApp], [WidgetsApp],
/// or [MediaQuery] widget exists above the [Image] widget in the widget tree.
///
/// The image is painted using [paintImage], which describes the meanings of the
/// various fields on this class in more detail.
///
/// See also:
///
///  * [Icon], which shows an image from a font.
///  * [new Ink.image], which is the preferred way to show an image in a
///    material application (especially if the image is in a [Material] and will
///    have an [InkWell] on top of it).
class Image extends StatefulWidget {
  /// Creates a widget that displays an image.
  ///
  /// To show an image from the network or from an asset bundle, consider using
  /// [new Image.network] and [new Image.asset] respectively.
  ///
  /// The [image], [alignment], [repeat], and [matchTextDirection] arguments
  /// must not be null.
  ///
  /// Either the [width] and [height] arguments should be specified, or the
  /// widget should be placed in a context that sets tight layout constraints.
  /// Otherwise, the image dimensions will change as the image is loaded, which
  /// will result in ugly layout changes.
  const Image({
    Key key,
    @required this.image,
    this.width,
    this.height,
    this.color,
    this.colorBlendMode,
    this.fit,
    this.alignment: Alignment.center,
    this.repeat: ImageRepeat.noRepeat,
    this.centerSlice,
    this.matchTextDirection: false,
    this.gaplessPlayback: false,
  })
      : super(key: key);

  /// Creates a widget that displays an [ImageStream] obtained from the network.
  ///
  /// The [src], [scale], and [repeat] arguments must not be null.
  ///
  /// Either the [width] and [height] arguments should be specified, or the
  /// widget should be placed in a context that sets tight layout constraints.
  /// Otherwise, the image dimensions will change as the image is loaded, which
  /// will result in ugly layout changes.
  ///
  /// All network images are cached regardless of HTTP headers.
  ///
  /// An optional [headers] argument can be used to send custom HTTP headers
  /// with the image request.
  Image.network(
    String src, {
    Key key,
    double scale: 1.0,
    this.width,
    this.height,
    this.color,
    this.colorBlendMode,
    this.fit,
    this.alignment: Alignment.center,
    this.repeat: ImageRepeat.noRepeat,
    this.centerSlice,
    this.matchTextDirection: false,
    this.gaplessPlayback: false,
    Map<String, String> headers,
  })
      : image = new NetworkImage(src, scale: scale, headers: headers),
        super(key: key);

  /// Creates a widget that displays an [ImageStream] obtained from a [File].
  ///
  /// The [file], [scale], and [repeat] arguments must not be null.
  ///
  /// Either the [width] and [height] arguments should be specified, or the
  /// widget should be placed in a context that sets tight layout constraints.
  /// Otherwise, the image dimensions will change as the image is loaded, which
  /// will result in ugly layout changes.
  ///
  /// On Android, this may require the
  /// `android.permission.READ_EXTERNAL_STORAGE` permission.
  Image.file(
    File file, {
    Key key,
    double scale: 1.0,
    this.width,
    this.height,
    this.color,
    this.colorBlendMode,
    this.fit,
    this.alignment: Alignment.center,
    this.repeat: ImageRepeat.noRepeat,
    this.centerSlice,
    this.matchTextDirection: false,
    this.gaplessPlayback: false,
  })
      : image = new FileImage(file, scale: scale),
        super(key: key);

  /// Creates a widget that displays an [ImageStream] obtained from an asset
  /// bundle. The key for the image is given by the `name` argument.
  ///
  /// The `package` argument must be non-null when displaying an image from a
  /// package and null otherwise. See the `Assets in packages` section for
  /// details.
  ///
  /// If the `bundle` argument is omitted or null, then the
  /// [DefaultAssetBundle] will be used.
  ///
  /// By default, the pixel-density-aware asset resolution will be attempted. In
  /// addition:
  ///
  /// * If the `scale` argument is provided and is not null, then the exact
  /// asset specified will be used.
  //
  // TODO(ianh): Implement the following (see ../services/image_resolution.dart):
  // ///
  // /// * If [width] and [height] are both specified, and [scale] is not, then
  // ///   size-aware asset resolution will be attempted also, with the given
  // ///   dimensions interpreted as logical pixels.
  // ///
  // /// * If the images have platform, locale, or directionality variants, the
  // ///   current platform, locale, and directionality are taken into account
  // ///   during asset resolution as well.
  ///
  /// The [name] and [repeat] arguments must not be null.
  ///
  /// Either the [width] and [height] arguments should be specified, or the
  /// widget should be placed in a context that sets tight layout constraints.
  /// Otherwise, the image dimensions will change as the image is loaded, which
  /// will result in ugly layout changes.
  ///
  /// ## Sample code
  ///
  /// Suppose that the project's `pubspec.yaml` file contains the following:
  ///
  /// ```yaml
  /// flutter:
  ///   assets:
  ///     - images/cat.png
  ///     - images/2x/cat.png
  ///     - images/3.5x/cat.png
  /// ```
  ///
  /// On a screen with a device pixel ratio of 2.0, the following widget would
  /// render the `images/2x/cat.png` file:
  ///
  /// ```dart
  /// new Image.asset('images/cat.png')
  /// ```
  ///
  /// This corresponds to the file that is in the project's `images/2x/`
  /// directory with the name `cat.png` (the paths are relative to the
  /// `pubspec.yaml` file).
  ///
  /// On a device with a 4.0 device pixel ratio, the `images/3.5x/cat.png` asset
  /// would be used. On a device with a 1.0 device pixel ratio, the
  /// `images/cat.png` resource would be used.
  ///
  /// The `images/cat.png` image can be omitted from disk (though it must still
  /// be present in the manifest). If it is omitted, then on a device with a 1.0
  /// device pixel ratio, the `images/2x/cat.png` image would be used instead.
  ///
  ///
  /// ## Assets in packages
  ///
  /// To create the widget with an asset from a package, the [package] argument
  /// must be provided. For instance, suppose a package called `my_icons` has
  /// `icons/heart.png` .
  ///
  /// Then to display the image, use:
  ///
  /// ```dart
  /// new Image.asset('icons/heart.png', package: 'my_icons')
  /// ```
  ///
  /// Assets used by the package itself should also be displayed using the
  /// [package] argument as above.
  ///
  /// If the desired asset is specified in the `pubspec.yaml` of the package, it
  /// is bundled automatically with the app. In particular, assets used by the
  /// package itself must be specified in its `pubspec.yaml`.
  ///
  /// A package can also choose to have assets in its 'lib/' folder that are not
  /// specified in its `pubspec.yaml`. In this case for those images to be
  /// bundled, the app has to specify which ones to include. For instance a
  /// package named `fancy_backgrounds` could have:
  ///
  /// ```
  /// lib/backgrounds/background1.png
  /// lib/backgrounds/background2.png
  /// lib/backgrounds/background3.png
  ///```
  ///
  /// To include, say the first image, the `pubspec.yaml` of the app should
  /// specify it in the assets section:
  ///
  /// ```yaml
  ///  assets:
  ///    - packages/fancy_backgrounds/backgrounds/background1.png
  /// ```
  ///
  /// The `lib/` is implied, so it should not be included in the asset path.
  ///
  ///
  /// See also:
  ///
  ///  * [AssetImage], which is used to implement the behavior when the scale is
  ///    omitted.
  ///  * [ExactAssetImage], which is used to implement the behavior when the
  ///    scale is present.
  ///  * <https://flutter.io/assets-and-images/>, an introduction to assets in
  ///    Flutter.
  Image.asset(
    String name, {
    Key key,
    AssetBundle bundle,
    double scale,
    this.width,
    this.height,
    this.color,
    this.colorBlendMode,
    this.fit,
    this.alignment: Alignment.center,
    this.repeat: ImageRepeat.noRepeat,
    this.centerSlice,
    this.matchTextDirection: false,
    this.gaplessPlayback: false,
    String package,
  })
      : image = scale != null
            ? new ExactAssetImage(name,
                bundle: bundle, scale: scale, package: package)
            : new AssetImage(name, bundle: bundle, package: package),
        super(key: key);

  /// Creates a widget that displays an [ImageStream] obtained from a [Uint8List].
  ///
  /// The [bytes], [scale], and [repeat] arguments must not be null.
  ///
  /// Either the [width] and [height] arguments should be specified, or the
  /// widget should be placed in a context that sets tight layout constraints.
  /// Otherwise, the image dimensions will change as the image is loaded, which
  /// will result in ugly layout changes.
  Image.memory(
    Uint8List bytes, {
    Key key,
    double scale: 1.0,
    this.width,
    this.height,
    this.color,
    this.colorBlendMode,
    this.fit,
    this.alignment: Alignment.center,
    this.repeat: ImageRepeat.noRepeat,
    this.centerSlice,
    this.matchTextDirection: false,
    this.gaplessPlayback: false,
  })
      : image = new MemoryImage(bytes, scale: scale),
        super(key: key);

  /// The image to display.
  final ImageProvider image;

  /// If non-null, require the image to have this width.
  ///
  /// If null, the image will pick a size that best preserves its intrinsic
  /// aspect ratio.
  ///
  /// It is strongly recommended that either both the [width] and the [height]
  /// be specified, or that the widget be placed in a context that sets tight
  /// layout constraints, so that the image does not change size as it loads.
  /// Consider using [fit] to adapt the image's rendering to fit the given width
  /// and height if the exact image dimensions are not known in advance.
  final double width;

  /// If non-null, require the image to have this height.
  ///
  /// If null, the image will pick a size that best preserves its intrinsic
  /// aspect ratio.
  ///
  /// It is strongly recommended that either both the [width] and the [height]
  /// be specified, or that the widget be placed in a context that sets tight
  /// layout constraints, so that the image does not change size as it loads.
  /// Consider using [fit] to adapt the image's rendering to fit the given width
  /// and height if the exact image dimensions are not known in advance.
  final double height;

  /// If non-null, this color is blended with each image pixel using [colorBlendMode].
  final Color color;

  /// Used to combine [color] with this image.
  ///
  /// The default is [BlendMode.srcIn]. In terms of the blend mode, [color] is
  /// the source and this image is the destination.
  ///
  /// See also:
  ///
  ///  * [BlendMode], which includes an illustration of the effect of each blend mode.
  final BlendMode colorBlendMode;

  /// How to inscribe the image into the space allocated during layout.
  ///
  /// The default varies based on the other fields. See the discussion at
  /// [paintImage].
  final BoxFit fit;

  /// How to align the image within its bounds.
  ///
  /// The alignment aligns the given position in the image to the given position
  /// in the layout bounds. For example, a [Alignment] alignment of (-1.0,
  /// -1.0) aligns the image to the top-left corner of its layout bounds, while a
  /// [Alignment] alignment of (1.0, 1.0) aligns the bottom right of the
  /// image with the bottom right corner of its layout bounds. Similarly, an
  /// alignment of (0.0, 1.0) aligns the bottom middle of the image with the
  /// middle of the bottom edge of its layout bounds.
  ///
  /// To display a subpart of an image, consider using a [CustomPainter] and
  /// [Canvas.drawImageRect].
  ///
  /// If the [alignment] is [TextDirection]-dependent (i.e. if it is a
  /// [AlignmentDirectional]), then an ambient [Directionality] widget
  /// must be in scope.
  ///
  /// Defaults to [Alignment.center].
  ///
  /// See also:
  ///
  ///  * [Alignment], a class with convenient constants typically used to
  ///    specify an [AlignmentGeometry].
  ///  * [AlignmentDirectional], like [Alignment] for specifying alignments
  ///    relative to text direction.
  final AlignmentGeometry alignment;

  /// How to paint any portions of the layout bounds not covered by the image.
  final ImageRepeat repeat;

  /// The center slice for a nine-patch image.
  ///
  /// The region of the image inside the center slice will be stretched both
  /// horizontally and vertically to fit the image into its destination. The
  /// region of the image above and below the center slice will be stretched
  /// only horizontally and the region of the image to the left and right of
  /// the center slice will be stretched only vertically.
  final Rect centerSlice;

  /// Whether to paint the image in the direction of the [TextDirection].
  ///
  /// If this is true, then in [TextDirection.ltr] contexts, the image will be
  /// drawn with its origin in the top left (the "normal" painting direction for
  /// images); and in [TextDirection.rtl] contexts, the image will be drawn with
  /// a scaling factor of -1 in the horizontal direction so that the origin is
  /// in the top right.
  ///
  /// This is occasionally used with images in right-to-left environments, for
  /// images that were designed for left-to-right locales. Be careful, when
  /// using this, to not flip images with integral shadows, text, or other
  /// effects that will look incorrect when flipped.
  ///
  /// If this is true, there must be an ambient [Directionality] widget in
  /// scope.
  final bool matchTextDirection;

  /// Whether to continue showing the old image (true), or briefly show nothing
  /// (false), when the image provider changes.
  final bool gaplessPlayback;

  @override
  _ImageState createState() => new _ImageState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(new DiagnosticsProperty<ImageProvider>('image', image));
    description.add(new DoubleProperty('width', width, defaultValue: null));
    description.add(new DoubleProperty('height', height, defaultValue: null));
    description.add(
        new DiagnosticsProperty<Color>('color', color, defaultValue: null));
    description.add(new EnumProperty<BlendMode>(
        'colorBlendMode', colorBlendMode,
        defaultValue: null));
    description.add(new EnumProperty<BoxFit>('fit', fit, defaultValue: null));
    description.add(new DiagnosticsProperty<AlignmentGeometry>(
        'alignment', alignment,
        defaultValue: null));
    description.add(new EnumProperty<ImageRepeat>('repeat', repeat,
        defaultValue: ImageRepeat.noRepeat));
    description.add(new DiagnosticsProperty<Rect>('centerSlice', centerSlice,
        defaultValue: null));
    description.add(new FlagProperty('matchTextDirection',
        value: matchTextDirection, ifTrue: 'match text direction'));
  }
}

class _ImageState extends State<Image> {
  ImageStream _imageStream;
  ImageInfo _imageInfo;
  bool _isListeningToStream = false;

  @override
  void didChangeDependencies() {
    _resolveImage();

    if (TickerMode.of(context))
      _listenToStream();
    else
      _stopListeningToStream();

    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(Image oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.image != oldWidget.image) _resolveImage();
  }

  @override
  void reassemble() {
    _resolveImage(); // in case the image cache was flushed
    super.reassemble();
  }

  void _resolveImage() {
    final ImageStream newStream = widget.image.resolve(
        createLocalImageConfiguration(context,
            size: widget.width != null && widget.height != null
                ? new Size(widget.width, widget.height)
                : null));
    assert(newStream != null);
    _updateSourceStream(newStream);
  }

  void _handleImageChanged(ImageInfo imageInfo, bool synchronousCall) {
    setState(() {
      _imageInfo = imageInfo;
    });
  }

  // Update _imageStream to newStream, and moves the stream listener
  // registration from the old stream to the new stream (if a listener was
  // registered).
  void _updateSourceStream(ImageStream newStream) {
    if (_imageStream?.key == newStream?.key) return;

    if (_isListeningToStream) _imageStream.removeListener(_handleImageChanged);

    if (!widget.gaplessPlayback)
      setState(() {
        _imageInfo = null;
      });

    _imageStream = newStream;
    if (_isListeningToStream) _imageStream.addListener(_handleImageChanged);
  }

  void _listenToStream() {
    if (_isListeningToStream) return;
    _imageStream.addListener(_handleImageChanged);
    _isListeningToStream = true;
  }

  void _stopListeningToStream() {
    if (!_isListeningToStream) return;
    _imageStream.removeListener(_handleImageChanged);
    _isListeningToStream = false;
  }

  @override
  void dispose() {
    assert(_imageStream != null);
    _stopListeningToStream();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new RawImage(
      image: _imageInfo?.image,
      width: widget.width,
      height: widget.height,
      scale: _imageInfo?.scale ?? 1.0,
      color: widget.color,
      colorBlendMode: widget.colorBlendMode,
      fit: widget.fit,
      alignment: widget.alignment,
      repeat: widget.repeat,
      centerSlice: widget.centerSlice,
      matchTextDirection: widget.matchTextDirection,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description
        .add(new DiagnosticsProperty<ImageStream>('stream', _imageStream));
    description.add(new DiagnosticsProperty<ImageInfo>('pixels', _imageInfo));
  }
}
