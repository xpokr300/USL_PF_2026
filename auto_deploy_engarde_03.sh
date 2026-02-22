#!/bin/bash

# --- KONFIGURACE ---
GIT_BRANCH="master"
INDEX_FILE="index.html"

generate_pages() {
    # Vyčistíme starý index a začneme nový
    echo "<!DOCTYPE html><html><head><meta charset='utf-8'><title>Výsledky šermu</title>" > "$INDEX_FILE"
    echo "<style>
        body { font-family: sans-serif; text-align: center; background: #f4f4f4; padding: 50px; }
        .menu-container { background: white; padding: 30px; border-radius: 10px; shadow: 0 4px 15px rgba(0,0,0,0.1); display: inline-block; min-width: 300px; }
        .btn { display: block; padding: 15px; margin: 10px 0; background: #0055aa; color: white; text-decoration: none; border-radius: 5px; font-weight: bold; transition: 0.3s; }
        .btn:hover { background: #003366; }
        h1 { color: #333; }
        .footer { margin-top: 20px; font-size: 0.8em; color: #888; }
    </style></head><body>" >> "$INDEX_FILE"

    echo "<div style='text-align:center; margin-bottom:20px;'><img src='logo.png' style='max-width:200px;' onerror='this.style.display=\"none\"'></div>" >> "$INDEX_FILE"
    
    echo "<div class='menu-container'><h1>Výsledky turnajů</h1>" >> "$INDEX_FILE"
    echo "<p>Univerzitní šermířská liga - 4. kolo 2025/2026</p>" > "$INDEX_FILE"
    echo "<p> Právnická fakulta 28.3.2026</p>" > "$INDEX_FILE"

    # Projdeme všechny -AUX složky a pro každou vytvoříme samostatný HTML soubor
    for dir in $(ls -td *-AUX/ 2>/dev/null); do
        category_name=$(basename "$dir" -AUX)
        target_html="${category_name}.html"
        
        # Přidáme odkaz do hlavního rozcestníku
        echo "<a href='${target_html}' class='btn'>${category_name}</a>" >> "$INDEX_FILE"

        # GENERUJEME SAMOSTATNOU STRÁNKU PRO DANÝ TURNAJ
        echo "<!DOCTYPE html><html><head><meta charset='utf-8'><title>${category_name}</title>" > "$target_html"
        
        # Ukradneme styl z prvního souboru v dané složce
        FIRST_HTM=$(ls "$dir"*.htm 2>/dev/null | head -n 1)
        if [ -n "$FIRST_HTM" ]; then
            iconv -f windows-1250 -t utf-8 "$FIRST_HTM" | sed -n '/<[Ss][Tt][Yy][Ll][Ee]>/,/<\/[Ss][Tt][Yy][Ll][Ee]>/p' >> "$target_html"
        fi
        
        echo "</head><body>" >> "$target_html"
        echo "<a href='index.html' style='display:inline-block; margin: 10px; padding: 5px 15px; background: #eee; text-decoration: none; color: #333; border-radius: 3px;'>← Zpět na rozcestník</a>" >> "$target_html"
        echo "<h1 style='text-align:center;'>${category_name}</h1>" >> "$target_html"

        # Vložíme obsah všech htm souborů ze složky
        ls -tr "$dir"*.htm | while read -r file; do
            [ -f "$file" ] || continue
            filename=$(basename "$file" .htm)
            [[ "$filename" == "index" || "$filename" == "navbar" ]] && continue
            
            iconv -f windows-1250 -t utf-8 "$file" 2>/dev/null | \
            sed -n '/<[Bb][Oo][Dd][Yy][^>]*>/,/<\/[Bb][Oo][Dd][Yy]>/p' | \
            sed '1d;$d' | \
            sed "s|src=\"|src=\"$dir|g" | \
            sed "s|href=\"|href=\"$dir|g" >> "$target_html"
            
            echo "<br><hr><br>" >> "$target_html"
        done
        
        echo "</body></html>" >> "$target_html"
    done

    echo "<div class='footer'>Aktualizováno: $(date '+%H:%M:%S')</div></div></body></html>" >> "$INDEX_FILE"
}

# --- RUČNÍ SPOUŠTĚNÍ ---
echo "===================================================="
echo " MULTI-PAGE DEPLOYER"
echo "===================================================="

while true; do
    echo ">>> Stiskni [ENTER] pro vygenerování stránek a push"
    echo ">>> Stiskni [Q] pro ukončení"
    read -r input

    if [[ $input == "q" || $input == "Q" ]]; then exit 0; fi

    generate_pages
    
    git add .
    git commit -m "Update: $(date '+%H:%M:%S')"
    git push origin "$GIT_BRANCH"
    
    echo "----------------------------------------------------"
    echo "HOTOVO: Rozcestník i podstránky odeslány."
    echo "----------------------------------------------------"
done