#!/bin/bash

# --- KONFIGURACE ---
GIT_BRANCH="main"
CHECK_INTERVAL=10
OUTPUT_FILE="index.html"

generate_index_html() {
    TEMP_OUTPUT="${OUTPUT_FILE}.temp"
    
    # HLAVIČKA - Modrý design + Logo
    cat <<EOF > "$TEMP_OUTPUT"
<!DOCTYPE html>
<html lang="cs">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Živé výsledky turnaje</title>
<style>
    body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;line-height:1.6;max-width:960px;margin:0 auto;padding:20px;background-color:#f4f4f9;color:#333}
    .header-area{text-align:center; margin-bottom:30px;}
    .header-area img{max-width:200px; height:auto; margin-bottom:10px;}
    h1{color:#004a99; margin:0;}
    .tournament-container{background:#fff;border-radius:12px;box-shadow:0 4px 12px rgba(0,0,0,0.08);margin-bottom:40px;overflow:hidden}
    .tour-header{background:#004a99;color:#fff;padding:15px 20px;margin:0}
    .tour-header h2{margin:0;font-size:1.5rem}
    .tour-content{padding:20px}
    .file-section{margin-bottom:30px; border-bottom:1px solid #eee; padding-bottom:20px}
    .file-section h3{color:#004a99; text-transform: capitalize; border-left: 4px solid #004a99; padding-left: 10px;}
    table { width: 100% !important; border-collapse: collapse; margin-top: 10px; background: white; }
    th, td { padding: 8px; text-align: left; border-bottom: 1px solid #ddd; }
    img { max-width: 100%; height: auto; }
</style>
</head>
<body>
    <div class="header-area">
        <img src="logo.png" alt="Logo" onerror="this.style.display='none'">
        <h1>Živé výsledky</h1>
    </div>
EOF

    # PROJDEME VŠECHNY SLOŽKY AUX (Bez ohledu na název)
    for dir in $(ls -td *-AUX/ 2>/dev/null); do
        dirname=$(basename "$dir" "-AUX")
        
        echo "<div class='tournament-container'>" >> "$TEMP_OUTPUT"
        echo "<div class='tour-header'><h2>Turnaj: $dirname</h2></div>" >> "$TEMP_OUTPUT"
        echo "<div class='tour-content'>" >> "$TEMP_OUTPUT"

        # Najde úplně všechny .htm soubory v této složce
        for file in "$dir"*.htm; do
            if [ -f "$file" ]; then
                filename=$(basename "$file" .htm)
                # Vynecháme indexové soubory, pokud by tam byly
                [[ "$filename" == "index" ]] && continue

                echo "<div class='file-section'>" >> "$TEMP_OUTPUT"
                echo "<h3>$filename</h3>" >> "$TEMP_OUTPUT"
                
                # PŘEVOD KÓDOVÁNÍ + EXTRAKCE DAT (ignoruje velikost písmen v <BODY>)
                iconv -f windows-1250 -t utf-8 "$file" 2>/dev/null | \
                sed -n '/<[Bb][Oo][Dd][Yy][^>]*>/,/<\/[Bb][Oo][Dd][Yy]>/p' | \
                sed '1d;$d' | \
                sed "s|src=\"|src=\"$dir|g" | \
                sed "s|href=\"|href=\"$dir|g" >> "$TEMP_OUTPUT"
                
                echo "</div>" >> "$TEMP_OUTPUT"
            fi
        done
        
        echo "</div></div>" >> "$TEMP_OUTPUT"
    done

    echo "<p style='text-align:center;color:#888;font-size:0.8em'>Aktualizováno: $(date '+%H:%M:%S')</p></body></html>" >> "$TEMP_OUTPUT"

    # Uložení finálního souboru
    mv "$TEMP_OUTPUT" "$OUTPUT_FILE"
}

# --- SMYČKA PRO GIT ---
while true; do
    generate_index_html
    
    # Pokud se něco změnilo, pošli to pryč
    if [ -n "$(git status --porcelain)" ]; then
        echo "--- Změna zjištěna, odesílám na GitHub ---"
        git add .
        git commit -m "Auto-update $(date '+%H:%M')"
        git push origin "$GIT_BRANCH"
    fi

    sleep "$CHECK_INTERVAL"
done