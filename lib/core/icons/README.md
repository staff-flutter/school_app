# Custom Icons Implementation

This project supports multiple ways to add custom icons:

## 1. SVG Icons (Recommended)

### Adding SVG Icons:
1. Place your SVG files in `assets/icons/`
2. Add them to `pubspec.yaml` under assets
3. Use `CustomIcons.svgIcon()` or predefined methods

### Example Usage:
```dart
// Using predefined social media icons
CustomIcons.instagramIcon(size: 32)

// Using custom SVG icon
CustomIcons.svgIcon('assets/icons/my_custom_icon.svg', size: 24, color: Colors.blue)

// Using in IconButton
CustomIcons.iconButton(
  onPressed: () => print('Pressed'),
  iconAsset: 'assets/icons/my_icon.svg',
  isSvg: true,
  size: 24,
  color: Colors.red,
)
```

## 2. Image Icons (PNG/JPG)

### Adding Image Icons:
1. Place your image files in `assets/icons/`
2. Add them to `pubspec.yaml` under assets
3. Use `CustomIcons.imageIcon()`

### Example Usage:
```dart
// Using image icon
CustomIcons.imageIcon('assets/icons/my_custom_icon.png', size: 24, color: Colors.blue)
```

## 3. Custom Icon Font (Advanced)

For custom icon fonts, create a .ttf file and define IconData:

```dart
class MyCustomIcons {
  static const IconData myIcon = IconData(0xe800, fontFamily: 'MyCustomFont');
}
```

## Current Implementation

The project includes:
- ✅ Flutter SVG support
- ✅ Custom icons class with helper methods
- ✅ Predefined social media icons (Instagram, Facebook, LinkedIn, YouTube)
- ✅ SVG assets for social media platforms
- ✅ Flexible icon system supporting both SVG and image assets

## Adding New Custom Icons

### For SVG Icons:
1. Add your SVG file to `assets/icons/`
2. Update `pubspec.yaml` assets section
3. Add a method to `CustomIcons` class if needed

### For Image Icons:
1. Add your PNG/JPG file to `assets/icons/`
2. Update `pubspec.yaml` assets section
3. Use `CustomIcons.imageIcon()` directly

## Benefits

- **Scalable**: SVG icons scale perfectly at any size
- **Colorable**: Easy to change colors programmatically
- **Lightweight**: SVG files are typically smaller than PNG/JPG
- **Flexible**: Support for both vector and raster icons
- **Maintainable**: Centralized icon management

