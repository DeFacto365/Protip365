#!/usr/bin/env python3

import re
import sys

def fix_unused_warnings(filename, warnings):
    """Add @Suppress annotations for unused parameters/variables"""
    
    with open(filename, 'r') as f:
        lines = f.readlines()
    
    # Sort warnings by line number in reverse (fix from bottom up)
    warnings.sort(reverse=True)
    
    for line_num, warning_type, var_name in warnings:
        line_idx = line_num - 1
        
        if line_idx >= len(lines):
            continue
            
        line = lines[line_idx]
        indent = len(line) - len(line.lstrip())
        indent_str = ' ' * indent
        
        if warning_type == 'Parameter':
            # Add @Suppress before parameter line
            if '@Suppress' not in lines[max(0, line_idx-1)]:
                lines.insert(line_idx, f'{indent_str}@Suppress("UNUSED_PARAMETER")\n')
        elif warning_type == 'Variable':
            # Add @Suppress before variable declaration
            if '@Suppress' not in lines[max(0, line_idx-1)]:
                lines.insert(line_idx, f'{indent_str}@Suppress("UNUSED")\n')
    
    with open(filename, 'w') as f:
        f.writelines(lines)

def parse_warnings(warning_file):
    """Parse warnings log file"""
    warnings_by_file = {}
    
    with open(warning_file, 'r') as f:
        for line in f:
            # Parse: w: file:///path/to/file.kt:LINE:COL Parameter/Variable 'name' is never used
            match = re.search(r'file://(.+?):(\d+):\d+ (Parameter|Variable) \'(\w+)\' is never used', line)
            if match:
                filepath, line_num, warning_type, var_name = match.groups()
                if filepath not in warnings_by_file:
                    warnings_by_file[filepath] = []
                warnings_by_file[filepath].append((int(line_num), warning_type, var_name))
    
    return warnings_by_file

if __name__ == '__main__':
    warnings = parse_warnings('/tmp/unused.log')
    
    for filepath, file_warnings in warnings.items():
        print(f"Fixing {filepath}...")
        fix_unused_warnings(filepath, file_warnings)
    
    print(f"✅ Fixed {len(warnings)} files with unused warnings!")

