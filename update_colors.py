import os
import re

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    if 'SenvoColors' not in content:
        return

    # Replace SenvoColors.colorName with context.themeColors.colorName
    # Also add import 'package:senvo/core/theme/senvo_theme.dart'; if not present
    new_content = re.sub(r'SenvoColors\.([a-zA-Z0-9_]+)', r'context.themeColors.\1', content)

    if new_content != content:
        if 'senvo_theme.dart' not in new_content and 'package:senvo/core/theme/senvo_theme.dart' not in new_content:
            # Try to add import after the last import
            imports = re.findall(r"^import\s+['\"].*?['\"];", new_content, re.MULTILINE)
            if imports:
                last_import = imports[-1]
                new_content = new_content.replace(last_import, last_import + "\nimport 'package:senvo/core/theme/senvo_theme.dart';")
            else:
                new_content = "import 'package:senvo/core/theme/senvo_theme.dart';\n" + new_content
        
        with open(filepath, 'w') as f:
            f.write(new_content)
        print(f"Updated {filepath}")

for root, _, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart') and file != 'senvo_theme.dart':
            process_file(os.path.join(root, file))
