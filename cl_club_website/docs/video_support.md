# Video Support Documentation

This document covers video playback implementation, supported formats, conversion tools, and troubleshooting for the club website.

## Architecture Overview

### Video Player Stack

The video playback uses **media_kit** instead of the standard `video_player` package:

| Package | Rendering | Web Compositing | Safari/iOS |
|---------|-----------|-----------------|------------|
| `video_player` | HTML `<video>` (platform view) | Broken (floats above Flutter widgets) | Known issues |
| `media_kit` | Flutter `Texture` widget | Works correctly | Better support |

**Why media_kit?**
- Renders to Flutter Texture instead of HTML platform view
- Proper z-ordering with Flutter widgets (gradients, overlays, text)
- Works with `AnimatedSwitcher` crossfade animations
- Better Safari/iOS compatibility

### Key Components

```
ui_lib/lib/src/widgets/
├── highlight_media/
│   ├── highlight_media.dart        # HighlightVideo, HighlightImage, HighlightMedia
│   ├── highlight_video_player.dart # media_kit based video player widget
│   ├── highlight_media_io.dart     # Native platform file handling
│   └── highlight_media_web.dart    # Web platform stub
└── gallery/
    └── gallery_video_player.dart   # Gallery video player using media_kit

club_website/lib/src/widgets/
└── hero_video_background.dart      # Manages player lifecycle for hero section
```

### Player Lifecycle Management

The `HeroVideoBackground` widget manages the video player lifecycle **outside** the `AnimatedSwitcher`. This prevents video reset when the carousel advances:

```
HeroSection
└── HeroVideoBackground (manages Player lifecycle)
    └── AnimatedSwitcher (handles crossfade)
        └── Video widget (texture, participates in fade)
```

## Supported Formats

### Video Containers
- MP4 (recommended)
- MOV
- WebM
- MKV
- AVI
- M4V

### Video Codecs
- H.264 (recommended for maximum compatibility)
- H.265/HEVC (limited browser support)
- VP8/VP9 (WebM)

### Audio Codecs
- AAC (recommended)
- MP3
- Opus

### Streaming Formats
- HLS (`.m3u8`) - Recommended for Safari/iOS
- Progressive download (direct MP4)

## HLS Streaming (Recommended)

HLS (HTTP Live Streaming) provides the best compatibility across all browsers, especially Safari and iOS.

### Why HLS?

1. **Safari/iOS native support** - No JavaScript fallback needed
2. **Adaptive bitrate** - Adjusts quality based on connection
3. **Chunked delivery** - Better for large videos
4. **Resume support** - Can resume from where left off

### Converting Videos to HLS

Two scripts are provided in the `scripts/` folder:

#### Single Video Conversion

```bash
./scripts/video_to_hls.sh <input_video> [output_folder]

# Example
./scripts/video_to_hls.sh hero_background.mp4
# Creates: hero_background_hls/playlist.m3u8 + segment_XXX.ts files
```

#### Batch Folder Conversion

```bash
./scripts/folder_to_hls.sh <input_folder> [output_folder]

# Example
./scripts/folder_to_hls.sh ./videos ./videos/hls
# Creates: hls/video1/playlist.m3u8, hls/video2/playlist.m3u8, etc.
```

### Conversion Settings

The scripts use these settings (configurable in the script):

| Setting | Value | Description |
|---------|-------|-------------|
| Segment Duration | 6 seconds | Balance of seek granularity and HTTP overhead |
| Video Codec | H.264 High Profile | Maximum Safari/iOS compatibility |
| Video Bitrate | 2 Mbps max | Good quality, reasonable file size |
| CRF | 23 | Quality factor (18-28, lower = better) |
| Audio Codec | AAC | Universal compatibility |
| Audio Bitrate | 128 kbps | Good quality for web |

### Server Configuration

HLS files must be served with correct MIME types:

```nginx
# Nginx
types {
    application/vnd.apple.mpegurl m3u8;
    video/mp2t ts;
}
```

```apache
# Apache (.htaccess)
AddType application/vnd.apple.mpegurl .m3u8
AddType video/mp2t .ts
```

### File Structure

After conversion, deploy HLS files to your static server:

```
/static/videos/
├── hero_background/
│   ├── playlist.m3u8
│   ├── segment_000.ts
│   ├── segment_001.ts
│   └── ...
└── highlight1/
    ├── playlist.m3u8
    └── ...
```

Reference in Flutter:
```dart
HighlightVideo(
  uri: 'https://api.example.com/static/videos/hero_background/playlist.m3u8',
)
```

## Web Setup

### Required: HLS.js

For non-Safari browsers, HLS.js provides HLS support. Add to `web/index.html`:

```html
<!-- HLS.js for Safari/iOS video playback compatibility -->
<script src="https://cdn.jsdelivr.net/npm/hls.js@latest"></script>
```

### Required: MediaKit Initialization

In your app's `main.dart`:

```dart
import 'package:media_kit/media_kit.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const MyApp());
}
```

## Troubleshooting

### Video Not Playing on Safari/iOS

**Symptoms:**
- Video loads but doesn't play
- Black screen with loading indicator
- Works on Chrome but fails on Safari

**Causes & Solutions:**

1. **Autoplay Policy**
   - Safari requires videos to be muted for autoplay
   - Ensure `muted: true` is set for background videos
   ```dart
   HighlightVideo(uri: url, muted: true, autoPlay: true)
   ```

2. **CORS Headers Missing**
   - Server must return proper CORS headers
   - Check browser console for CORS errors
   ```
   Access-Control-Allow-Origin: *
   Access-Control-Allow-Methods: GET, HEAD, OPTIONS
   Access-Control-Allow-Headers: Range
   ```

3. **Video Format Not Supported**
   - Convert to HLS format using provided scripts
   - Ensure H.264 codec (not H.265)

4. **Range Requests Not Supported**
   - Safari requires byte-range requests for video seeking
   - Ensure server supports `Range` header

### Video Resets on Carousel Transition

**Symptoms:**
- Video restarts from beginning when carousel advances
- Video briefly disappears during transition

**Solution:**
- Use `HeroVideoBackground` widget which manages player lifecycle outside AnimatedSwitcher
- The player is only recreated when the video URI actually changes

### Video Floats Above UI Elements

**Symptoms:**
- Video renders above gradient overlays
- Video stays opaque during crossfade animations
- UI elements appear behind video

**Cause:**
- Using `video_player` package which creates HTML platform view

**Solution:**
- Use `media_kit` which renders to Flutter Texture
- Already implemented in current codebase

### Video Player Memory Leaks

**Symptoms:**
- Browser memory usage grows over time
- App becomes sluggish after viewing multiple videos

**Solution:**
- Ensure proper disposal of Player in widget's `dispose()` method
```dart
@override
void dispose() {
  player?.dispose();
  super.dispose();
}
```

### HLS Segments Not Loading

**Symptoms:**
- First segment plays, then video stops
- 404 errors in network tab for .ts files

**Causes & Solutions:**

1. **Relative Path Issues**
   - Ensure segments are in same folder as playlist
   - Check playlist.m3u8 references correct segment paths

2. **CORS on Segment Files**
   - All .ts files must have CORS headers
   - Configure server to apply CORS to entire video folder

### Debugging Tools

#### Browser DevTools

1. **Network Tab**
   - Check if m3u8 and ts files load successfully
   - Look for 403/404 errors
   - Verify CORS headers in response

2. **Console Tab**
   - Look for media-related errors
   - HLS.js logs helpful debugging info

#### Flutter DevTools

1. **Check Player State**
```dart
player.stream.playing.listen((playing) {
  debugPrint('Playing: $playing');
});

player.stream.error.listen((error) {
  debugPrint('Error: $error');
});
```

2. **Check Video Dimensions**
```dart
player.stream.width.listen((w) => debugPrint('Width: $w'));
player.stream.height.listen((h) => debugPrint('Height: $h'));
```

#### FFprobe for Video Analysis

```bash
# Check video codec and format
ffprobe -v error -show_format -show_streams video.mp4

# Verify HLS playlist
ffprobe -v error -show_format playlist.m3u8
```

## Platform Support Matrix

| Platform | Browser | MP4 | HLS | Notes |
|----------|---------|-----|-----|-------|
| macOS | Chrome | Yes | Yes (via HLS.js) | Full support |
| macOS | Safari | Yes | Yes (native) | Requires muted for autoplay |
| iOS | Safari | Yes | Yes (native) | Requires muted for autoplay |
| iOS | Chrome | Yes | Yes | Uses Safari's engine |
| Android | Chrome | Yes | Yes (via HLS.js) | Full support |
| Windows | Chrome | Yes | Yes (via HLS.js) | Full support |
| Windows | Edge | Yes | Yes (via HLS.js) | Full support |

## Best Practices

1. **Always use HLS for production**
   - Better Safari/iOS compatibility
   - Adaptive streaming support
   - Easier CDN caching

2. **Keep videos short for hero sections**
   - 10-30 seconds ideal
   - Loop seamlessly
   - Optimize for quick loading

3. **Provide fallback images**
   - Show poster image while video loads
   - Handle video load failures gracefully

4. **Test on real devices**
   - iOS Simulator may behave differently than real iPhone
   - Test on actual Safari on Mac and iOS

5. **Monitor video performance**
   - Track video load times
   - Log playback errors for debugging

## Dependencies

```yaml
# ui_lib/pubspec.yaml
dependencies:
  media_kit: ^1.2.6
  media_kit_video: ^2.0.1
  media_kit_libs_video: ^1.0.7
  video_player: ^2.9.3  # Fallback for native platforms
  visibility_detector: ^0.4.0+2
```

## Related Files

- `ui_lib/lib/src/widgets/highlight_media/` - Video player widgets
- `ui_lib/lib/src/widgets/gallery/gallery_video_player.dart` - Gallery video player
- `club_website/lib/src/widgets/hero_video_background.dart` - Hero section player manager
- `club_website/lib/src/widgets/hero_section.dart` - Hero section with video background
- `scripts/video_to_hls.sh` - Single video HLS conversion
- `scripts/folder_to_hls.sh` - Batch HLS conversion
- `app/web/index.html` - HLS.js script inclusion
- `app/lib/main.dart` - MediaKit initialization
