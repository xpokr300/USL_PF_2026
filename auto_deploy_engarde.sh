#!/bin/bash

# --- KONFIGURACE ---
GIT_BRANCH="main"      # Název tvé větve na GitHubu
CHECK_INTERVAL=10      # Kontrola každých 10 sekund
OUTPUT_FILE="index.html"

# --- FUNKCE 1: GENERÁTOR HTML (Slepí výsledky, opraví češtinu a cesty) ---
generate_index_html() {
    TEMP_OUTPUT="${OUTPUT_FILE}.temp"

    # HLAVIČKA S OPRAVENÝM KÓDOVÁNÍM (UTF-8)
    cat <<EOF > "$TEMP_OUTPUT"
<!DOCTYPE html>
<html lang="cs">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Živé výsledky turnaje</title>
<style>
    body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;line-height:1.6;max-width:960px;margin:0 auto;padding:20px;background-color:#f4f4f9;color:#333}
    h1{text-align:center;color:#004a99}
    .tournament-container{background:#fff;border-radius:12px;box-shadow:0 4px 12px rgba(0,0,0,0.08);margin-bottom:40px;overflow:hidden}
    .tour-header{background:#004a99;color:#fff;padding:15px 20px;margin:0}
    .tour-header h2{margin:0;font-size:1.5rem}
    .tour-content{padding:20px}
    .file-section{margin-bottom:30px;border-bottom:1px solid #eee;padding-bottom:20px}
    .file-section:last-child{border-bottom:none}
    .file-section h3{background:#eef4fc;color:#004a99;padding:8px 12px;border-radius:6px;display:inline-block;margin-top:0}
    table { width: 100%; border-collapse: collapse; margin-top: 10px; background: white; }
    th, td { padding: 8px; text-align: left; border-bottom: 1px solid #ddd; }
    img { max-width: 100%; height: auto; vertical-align: middle; }
</style>
</head>
<body>
<h1>Aktuální výsledky</h1>
EOF

    # Projde všechny složky -AUX (nejnovější nahoře)
    for dir in $(ls -td *-AUX/ 2>/dev/null); do
        dirname=$(basename "$dir" "-AUX")
        
        echo "<div class='tournament-container'>" >> "$TEMP_OUTPUT"
        echo "<div class='tour-header'><h2>Turnaj: $dirname</h2></div>" >> "$TEMP_OUTPUT"
        echo "<div class='tour-content'>" >> "$TEMP_OUTPUT"

        if compgen -G "${dir}*.htm" > /dev/null; then
            for file in "$dir"*.htm; do
                filename=$(basename "$file")
                echo "<div class='file-section'>" >> "$TEMP_OUTPUT"
                echo "<h3>Sekce: ${filename%.*}</h3>" >> "$TEMP_OUTPUT"
                
                # 1. Převede kódování z Windows-1250 (Engarde) do UTF-8
                # 2. Najde BODY bez ohledu na velikost písmen
                # 3. Opraví cesty k obrázkům (přidá název složky -AUX)
                iconv -f windows-1250 -t utf-8 "$file" | \
                sed -n '/<[Bb][Oo][Dd][Yy][^>]*>/,/<\/[Bb][Oo][Dd][Yy]>/p' | \
                sed '1d;$d' | \
                sed "s|src=\"|src=\"$dir|g" | \
                sed "s|href=\"|href=\"$dir|g" >> "$TEMP_OUTPUT"
                
                echo "</div>" >> "$TEMP_OUTPUT"
            done
        else
             echo "<p>Zatím žádné exportované soubory.</p>" >> "$TEMP_OUTPUT"
        fi
        echo "</div></div>" >> "$TEMP_OUTPUT"
    done

    echo "<p style='text-align:center;color:#888;font-size:0.8em'>Poslední aktualizace: $(date '+%H:%M:%S')</p></body></html>" >> "$TEMP_OUTPUT"

    # Přesuneme temp na finální soubor
    mv "$TEMP_OUTPUT" "$OUTPUT_FILE"
}

# # --- FUNKCE 2: GIT PUSH (Odešle všechno na GitHub) ---
git_push_everything() {
    echo "--- DETEKOVÁNA ZMĚNA - ODESÍLÁM NA GITHUB ---"
    git add .
    COMMIT_MSG="Auto-update výsledků: $(date '+%Y-%m-%d %H:%M:%S')"
    if git commit -m "$COMMIT_MSG"; then
        if git push origin "$GIT_BRANCH"; then
            echo "ÚSPĚCH: Odesláno na GitHub."
        else
            echo "CHYBA: Push selhal."
        fi
    fi
    echo "---------------------------------------------"
}

# --- HLAVNÍ SMYČKA ---
echo "=== Startuji kompletní automatický deployer Engarde ==="
echo "Sleduji složku a opravuji češtinu..."

while true; do
    generate_index_html
    
    # Pokud Git vidí nějakou změnu, uděláme push
    if [ -n "$(git status --porcelain)" ]; then
        sleep 2
        git_push_everything
    fi

    sleep "$CHECK_INTERVAL"
done