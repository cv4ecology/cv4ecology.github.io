$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$files = @(
    Get-ChildItem -LiteralPath $root -File
    foreach ($directory in @('pages', 'editions', 'workshops', 'assets', 'scripts', '.github')) {
        $path = Join-Path $root $directory
        if (Test-Path -LiteralPath $path) {
            Get-ChildItem -LiteralPath $path -File -Recurse
        }
    }
)
$knownPaths = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
foreach ($file in $files) {
    [void] $knownPaths.Add($file.FullName)
    $parent = $file.Directory
    while ($null -ne $parent -and $parent.FullName.StartsWith($root, [StringComparison]::Ordinal)) {
        [void] $knownPaths.Add($parent.FullName)
        $parent = $parent.Parent
    }
}

$patterns = @{
    Html = '(?is)\b(?:href|src|poster|action)\s*=\s*(?:"(?<url>[^"]*)"|''(?<url>[^'']*)''|(?<url>[^\s>]+))'
    Css = '(?is)url\(\s*(?:"(?<url>[^"]*)"|''(?<url>[^'']*)''|(?<url>[^)\s]+))\s*\)'
    Markdown = '!?\[[^\]\r\n]*\]\(\s*(?:<(?<url>[^>]+)>|(?<url>[^\s)]+))(?:\s+"[^"]*")?\s*\)'
}
$failures = @()
$checked = 0
$site = 'https://' + [IO.File]::ReadAllText((Join-Path $root 'CNAME')).Trim()
$titles = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
$descriptions = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
$htmlChecked = 0
$indexableUrls = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)

function Get-HtmlAttributes([string] $tag) {
    $attributes = @{}
    foreach ($match in [regex]::Matches($tag, '([\w:-]+)\s*=\s*(?:"([^"]*)"|''([^'']*)'')')) {
        $attributes[$match.Groups[1].Value] = [Net.WebUtility]::HtmlDecode($match.Groups[2].Value + $match.Groups[3].Value)
    }
    return $attributes
}

foreach ($file in $files | Where-Object { $_.Extension -in @('.html', '.md', '.css') }) {
    $text = [IO.File]::ReadAllText($file.FullName)
    $text = [regex]::Replace($text, '(?s)<!--.*?-->|/\*.*?\*/', '')
    if ($file.Extension -eq '.md') {
        $text = [regex]::Replace($text, '(?ms)^```.*?^```[^\r\n]*', '')
    }
    $references = @()
    if ($file.Extension -in @('.html', '.md')) {
        $references += [regex]::Matches($text, $patterns.Html)
    }
    if ($file.Extension -in @('.css', '.html')) {
        $references += [regex]::Matches($text, $patterns.Css)
    }
    if ($file.Extension -eq '.md') {
        $references += [regex]::Matches($text, $patterns.Markdown)
    }
    foreach ($reference in $references) {
        $url = [Net.WebUtility]::HtmlDecode($reference.Groups['url'].Value).Trim()
        if (!$url -or $url -match '^(?:[a-z][a-z0-9+.-]*:|//|#|\?)') {
            continue
        }
        $urlPath = [Uri]::UnescapeDataString(($url -split '[?#]', 2)[0])
        if ($urlPath.IndexOfAny([IO.Path]::GetInvalidPathChars()) -ge 0) {
            $failures += "$($file.Name): $url (invalid local URL)"
            continue
        }
        $base = $file.DirectoryName
        if ($urlPath.StartsWith('/')) {
            $base = $root
            $urlPath = $urlPath.TrimStart('/')
        }
        $target = [IO.Path]::GetFullPath((Join-Path $base $urlPath.Replace('/', '\'))).TrimEnd('\')
        $checked++
        if (!$knownPaths.Contains($target)) {
            $relative = $file.FullName.Substring($root.Length + 1)
            $failures += "${relative}: $url (missing target or incorrect filename case)"
        }
    }
    if ($file.Extension -ne '.html') { continue }
    $relative = $file.FullName.Substring($root.Length + 1).Replace('\', '/')
    # This pre-existing schedule placeholder is not a published content page.
    if ($relative -eq 'pages/schedule.html' -and [string]::IsNullOrWhiteSpace($text)) { continue }
    $htmlChecked++
    $headings = [regex]::Matches($text, '(?i)<h([1-6])\b')
    if (@($headings | Where-Object { $_.Groups[1].Value -eq '1' }).Count -ne 1) {
        $failures += "${relative}: expected exactly one main heading"
    }
    if (!$relative.StartsWith('pages/demo/')) {
        $previousLevel = 0
        foreach ($heading in $headings) {
            $level = [int] $heading.Groups[1].Value
            if ($level -gt $previousLevel + 1) {
                $failures += "${relative}: heading level jumps from $previousLevel to $level"
            }
            $previousLevel = $level
        }
    }
    if ($text -notmatch '(?i)<html\b[^>]*\blang="en"') {
        $failures += "${relative}: page language must be English"
    }
    if ($text -match '(?i)user-scalable\s*=\s*(?:no|0)|maximum-scale\s*=\s*1(?:\D|$)') {
        $failures += "${relative}: viewport must allow zoom"
    }
    if ($text -notmatch '(?is)<body\b[^>]*>\s*<a href="#main-content" class="skip-link">Skip to main content</a>') {
        $failures += "${relative}: skip link must be the first body element"
    }
    $skipTargets = [regex]::Matches($text, '(?i)<[^>]+\bid="main-content"[^>]*>')
    if ($skipTargets.Count -ne 1 -or $skipTargets[0].Value -notmatch 'tabindex="-1"') {
        $failures += "${relative}: skip link needs one focusable main-content target"
    }
    foreach ($youtubeLink in [regex]::Matches($text, '(?is)<a\b[^>]*class="icon brands fa-youtube"[^>]*>(.*?)</a>')) {
        if ($youtubeLink.Groups[1].Value -notmatch '<span class="label">YouTube</span>') {
            $failures += "${relative}: YouTube icon must be labeled YouTube"
        }
    }
    $titleMatches = [regex]::Matches($text, '(?is)<title>(.*?)</title>')
    $title = ''
    if ($titleMatches.Count -gt 0) {
        $title = [Net.WebUtility]::HtmlDecode($titleMatches[0].Groups[1].Value)
    }
    if ($titleMatches.Count -ne 1 -or !$title -or !$titles.Add($title)) {
        $failures += "${relative}: missing, duplicate, or non-unique page title"
    }
    $metadata = @{}
    foreach ($tag in [regex]::Matches($text, '(?is)<meta\b[^>]*>')) {
        $attributes = Get-HtmlAttributes $tag.Value
        $key = $attributes['name']
        if (!$key) { $key = $attributes['property'] }
        if ($key) {
            if ($metadata.ContainsKey($key)) { $failures += "${relative}: duplicate metadata: $key" }
            $metadata[$key] = $attributes['content']
        }
    }
    $description = $metadata['description']
    if (!$description -or !$descriptions.Add($description)) {
        $failures += "${relative}: missing or non-unique page description"
    }
    $canonical = "$site/" + ($relative -replace 'index\.html$', '')
    $canonicalLinks = @(
        foreach ($tag in [regex]::Matches($text, '(?is)<link\b[^>]*>')) {
            $attributes = Get-HtmlAttributes $tag.Value
            if ($attributes['rel'] -eq 'canonical') { $attributes['href'] }
        }
    )
    if ($canonicalLinks.Count -ne 1 -or $canonicalLinks[0] -cne $canonical) {
        $failures += "${relative}: canonical URL must be $canonical"
    }
    $expectedMetadata = @{
        'og:type' = 'website'; 'og:site_name' = 'CV4Ecology'; 'og:title' = $title
        'og:description' = $description; 'og:url' = $canonical
        'twitter:card' = 'summary_large_image'; 'twitter:title' = $title
        'twitter:description' = $description; 'twitter:image' = $metadata['og:image']
        'twitter:image:alt' = $metadata['og:image:alt']
    }
    foreach ($key in $expectedMetadata.Keys) {
        if (!$metadata[$key] -or $metadata[$key] -cne $expectedMetadata[$key]) {
            $failures += "${relative}: missing or inconsistent preview metadata: $key"
        }
    }
    $image = $metadata['og:image']
    if ($relative -match '^editions/(\d{4})/') {
        $edition = $Matches[1]
        $editionImages = @{
            '2022' = 'site/camtraps.jpg'; '2023' = 'headers/fish2023banner.png'
            '2025' = 'headers/banner2025.jpg'; '2026' = 'headers/banner2026.png'
            '2027' = 'headers/course_header2027.png'
        }
        if ($image -cne "$site/assets/images/$($editionImages[$edition])") {
            $failures += "${relative}: sharing preview must use the $edition banner"
        }
    }
    if (!$image -or !$image.StartsWith("$site/", [StringComparison]::Ordinal)) {
        $failures += "${relative}: preview image must be an absolute URL on $site"
    } else {
        $imagePath = [Uri]::UnescapeDataString($image.Substring($site.Length + 1)).Replace('/', '\')
        $imageTarget = [IO.Path]::GetFullPath((Join-Path $root $imagePath))
        if (!$knownPaths.Contains($imageTarget)) { $failures += "${relative}: preview image file is missing" }
    }
    if ($relative.StartsWith('pages/demo/') -and $metadata['robots'] -ne 'noindex') {
        $failures += "${relative}: template reference pages must use noindex"
    }
    if ($metadata['robots'] -notmatch '(?i)\bnoindex\b') {
        [void] $indexableUrls.Add($canonical)
    }
    if ($relative -eq '404.html') {
        if ($metadata['robots'] -ne 'noindex' -or $text -notmatch '<nav aria-label="Find a page">') {
            $failures += '404.html: expected noindex and recovery navigation'
        }
        foreach ($reference in $references) {
            $url = $reference.Groups['url'].Value
            if ($url -notmatch '^(?:/|#|[a-z][a-z0-9+.-]*:)' ) {
                $failures += '404.html: local links and assets must be root-relative to work at missing nested URLs'
            }
        }
        continue
    }
    $menus = [regex]::Matches($text, '(?is)<nav\b[^>]*id="menu"[^>]*>.*?</nav>')
    if ($menus.Count -ne 1) {
        $failures += "${relative}: expected one standard main menu"
        continue
    }
    $menu = $menus[0].Value
    foreach ($label in @('Course Materials', 'People', 'Other Workshops')) {
        if ($menu -notmatch ('class="opener[^"]*"[^>]*role="button"[^>]*tabindex="0"[^>]*aria-expanded="(?:true|false)">' + $label + '</span>')) {
            $failures += "${relative}: missing accessible menu group: $label"
        }
    }
    $year = '2027'
    if ($relative -match '^editions/(\d{4})/') { $year = $Matches[1] }
    $currentLinks = @()
    $menuTargets = @()
    foreach ($tag in [regex]::Matches($menu, '(?is)<a\b[^>]*>')) {
        $attributes = Get-HtmlAttributes $tag.Value
        $target = [IO.Path]::GetFullPath((Join-Path $file.DirectoryName $attributes['href'].Replace('/', '\')))
        $menuTargets += $target
        if ($attributes['aria-current'] -eq 'page') { $currentLinks += $target }
    }
    foreach ($group in [regex]::Matches($menu, '(?is)<li><span\b([^>]*)>[^<]+</span><ul>(.*?)</ul></li>')) {
        if ($group.Groups[2].Value -match 'aria-current="page"' -and $group.Groups[1].Value -notmatch 'aria-expanded="true"') {
            $failures += "${relative}: menu group containing the current page must start expanded"
        }
    }
    if ($currentLinks.Count -ne 1 -or $currentLinks[0] -cne $file.FullName) {
        $failures += "${relative}: main menu must identify exactly this page as current"
    }
    foreach ($name in @('course-content', 'students', 'instructors', 'speakers')) {
        $target = Join-Path $root "editions\$year\$name.html"
        if ($knownPaths.Contains($target) -and $menuTargets -cnotcontains $target) {
            $failures += "${relative}: menu is missing $year $name"
        }
    }
}
$sitemapPath = Join-Path $root 'sitemap.xml'
if (!(Test-Path -LiteralPath $sitemapPath)) {
    $failures += 'sitemap.xml: file is missing'
} else {
    $sitemap = New-Object Xml.XmlDocument
    $sitemap.XmlResolver = $null
    $sitemap.Load($sitemapPath)
    $namespaces = New-Object Xml.XmlNamespaceManager $sitemap.NameTable
    $namespaces.AddNamespace('sm', 'http://www.sitemaps.org/schemas/sitemap/0.9')
    $sitemapUrls = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
    foreach ($location in $sitemap.SelectNodes('/sm:urlset/sm:url/sm:loc', $namespaces)) {
        $url = $location.InnerText
        if (!$sitemapUrls.Add($url)) { $failures += "sitemap.xml: duplicate URL $url" }
        if (!$indexableUrls.Contains($url)) { $failures += "sitemap.xml: unexpected or non-indexable URL $url" }
    }
    foreach ($url in $indexableUrls) {
        if (!$sitemapUrls.Contains($url)) { $failures += "sitemap.xml: missing content page $url" }
    }
}
$robotsPath = Join-Path $root 'robots.txt'
if (!(Test-Path -LiteralPath $robotsPath) -or
    [IO.File]::ReadAllText($robotsPath) -notmatch ('(?m)^Sitemap: ' + [regex]::Escape("$site/sitemap.xml") + '\s*$')) {
    $failures += 'robots.txt: sitemap discovery URL is missing or incorrect'
}
if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Output $_ }
    throw "$($failures.Count) site validation errors found."
}
Write-Output "Validated $checked local references; all targets exist with matching filename case."
Write-Output "Validated navigation and search/sharing metadata on $htmlChecked content pages."
Write-Output "Validated heading structure and sitemap coverage for $($indexableUrls.Count) indexable pages."
