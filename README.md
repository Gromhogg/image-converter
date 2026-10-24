# Image Converter

A Mac terminal script that converts images to the format you pick, using the built-in `sips` tool.

## How to use

```bash
./"Image Converter.sh"
```
Or just download the Image Covnverter.sh file.

It asks you:

1. **Which format** to convert to: jpeg, png, heic, avif, tiff, gif, bmp or pdf.
2. **Which folder** to convert. Press Enter to use the folder the script is in, or type or drag in a folder.
3. **Go ahead? (y/n)**, after showing how many images it found.

Images already in the format you picked are left alone. Each original is deleted after it converts. If a file with the new name already exists, the new file gets `-converted` added to its name instead of overwriting it.
