# Design System Auto-Refactor Script
# Applies design system changes to all Flutter view files

$ErrorActionPreference = "Stop"

Write-Host "Starting Design System Auto-Refactor..." -ForegroundColor Cyan
Write-Host ""

# Define paths
$viewsPath = "lib\app\views"
$modulesPath = "lib\app\modules"
$filesProcessed = 0
$filesModified = 0

# Function to apply design system changes
function Apply-DesignSystem {
    param([string]$filePath)
    
    Write-Host "Processing: $filePath" -ForegroundColor Yellow
    
    $content = Get-Content $filePath -Raw -Encoding UTF8
    $originalContent = $content
    
    # Skip if already refactored
    if ($content -match "design_system\.dart") {
        Write-Host "  Already refactored" -ForegroundColor Gray
        return $false
    }
    
    # Add imports after flutter/material.dart
    if ($content -match "import 'package:flutter/material\.dart';") {
        $content = $content -replace "(import 'package:flutter/material\.dart';)", "`$1`nimport 'package:school_app/app/core/widgets/design_system.dart';`nimport 'package:school_app/app/core/theme/design_tokens.dart';"
    }
    
    # Replace colors
    $content = $content -replace "Colors\.grey\[50\]", "DesignTokens.background"
    $content = $content -replace "Colors\.grey\.shade50", "DesignTokens.background"
    $content = $content -replace "Color\(0xFFF5F5F5\)", "DesignTokens.background"
    $content = $content -replace "Color\(0xFFF9FAFB\)", "DesignTokens.background"
    
    # Text colors
    $content = $content -replace "Color\(0xFF111827\)", "DesignTokens.textPrimary"
    $content = $content -replace "Colors\.grey\[600\]", "DesignTokens.textSecondary"
    $content = $content -replace "Colors\.grey\.shade600", "DesignTokens.textSecondary"
    $content = $content -replace "Color\(0xFF6B7280\)", "DesignTokens.textSecondary"
    $content = $content -replace "Colors\.grey\[400\]", "DesignTokens.textMuted"
    $content = $content -replace "Color\(0xFF9CA3AF\)", "DesignTokens.textMuted"
    
    # Border colors
    $content = $content -replace "Colors\.grey\[300\]", "DesignTokens.border"
    $content = $content -replace "Color\(0xFFE5E7EB\)", "DesignTokens.border"
    
    # Brand colors
    $content = $content -replace "Color\(0xFF4F46E5\)", "DesignTokens.brandPrimary"
    
    # Replace spacing
    $content = $content -replace "EdgeInsets\.all\(4\)", "EdgeInsets.all(DesignTokens.spacingXS)"
    $content = $content -replace "EdgeInsets\.all\(8\)", "EdgeInsets.all(DesignTokens.spacingS)"
    $content = $content -replace "EdgeInsets\.all\(12\)", "EdgeInsets.all(DesignTokens.spacingM)"
    $content = $content -replace "EdgeInsets\.all\(16\)", "EdgeInsets.all(DesignTokens.spacingL)"
    $content = $content -replace "EdgeInsets\.all\(24\)", "EdgeInsets.all(DesignTokens.spacingXL)"
    $content = $content -replace "EdgeInsets\.all\(32\)", "EdgeInsets.all(DesignTokens.spacingXXL)"
    
    $content = $content -replace "SizedBox\(height:\s*4\)", "SizedBox(height: DesignTokens.spacingXS)"
    $content = $content -replace "SizedBox\(height:\s*8\)", "SizedBox(height: DesignTokens.spacingS)"
    $content = $content -replace "SizedBox\(height:\s*12\)", "SizedBox(height: DesignTokens.spacingM)"
    $content = $content -replace "SizedBox\(height:\s*16\)", "SizedBox(height: DesignTokens.spacingL)"
    $content = $content -replace "SizedBox\(height:\s*24\)", "SizedBox(height: DesignTokens.spacingXL)"
    $content = $content -replace "SizedBox\(width:\s*4\)", "SizedBox(width: DesignTokens.spacingXS)"
    $content = $content -replace "SizedBox\(width:\s*8\)", "SizedBox(width: DesignTokens.spacingS)"
    $content = $content -replace "SizedBox\(width:\s*12\)", "SizedBox(width: DesignTokens.spacingM)"
    $content = $content -replace "SizedBox\(width:\s*16\)", "SizedBox(width: DesignTokens.spacingL)"
    
    # Replace border radius
    $content = $content -replace "BorderRadius\.circular\(24\)", "BorderRadius.circular(DesignTokens.radiusCard)"
    $content = $content -replace "BorderRadius\.circular\(16\)", "BorderRadius.circular(DesignTokens.radiusButton)"
    $content = $content -replace "BorderRadius\.circular\(14\)", "BorderRadius.circular(DesignTokens.radiusButtonSmall)"
    
    # Replace scaffold backgrounds
    $content = $content -replace "backgroundColor:\s*Colors\.grey\[50\]", "backgroundColor: DesignTokens.background"
    $content = $content -replace "backgroundColor:\s*Color\(0xFFF5F5F5\)", "backgroundColor: DesignTokens.background"
    
    # Write back if modified
    if ($content -ne $originalContent) {
        Set-Content $filePath -Value $content -Encoding UTF8 -NoNewline
        Write-Host "  Modified" -ForegroundColor Green
        return $true
    }
    
    Write-Host "  No changes" -ForegroundColor Gray
    return $false
}

# Process all view files
Write-Host "Processing views directory..." -ForegroundColor Cyan
Get-ChildItem -Path $viewsPath -Filter "*.dart" -Recurse | ForEach-Object {
    $filesProcessed++
    if (Apply-DesignSystem $_.FullName) {
        $filesModified++
    }
}

# Process all module view files
Write-Host "Processing modules directory..." -ForegroundColor Cyan
Get-ChildItem -Path $modulesPath -Filter "*.dart" -Recurse | Where-Object {
    $_.FullName -match "\\views\\"
} | ForEach-Object {
    $filesProcessed++
    if (Apply-DesignSystem $_.FullName) {
        $filesModified++
    }
}

Write-Host ""
Write-Host "Refactor Complete!" -ForegroundColor Green
Write-Host "Files processed: $filesProcessed" -ForegroundColor Cyan
Write-Host "Files modified: $filesModified" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Run: flutter clean"
Write-Host "  2. Run: flutter pub get"
Write-Host "  3. Run: flutter run"
Write-Host "  4. Test all screens"
Write-Host ""
Write-Host "Manual review needed for:" -ForegroundColor Yellow
Write-Host "  - Gradient containers to AppCard"
Write-Host "  - ElevatedButton to AppButton"
Write-Host "  - FloatingActionButton to AppFAB"
Write-Host "  - TextField to AppTextField"
Write-Host "  - Chip to AppPill"
Write-Host "  - AlertDialog to GlassCard"
