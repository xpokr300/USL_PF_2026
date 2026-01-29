#!/bin/bash

# --- KONFIGURACE ---
GIT_BRANCH="master"
OUTPUT_FILE="index.html"

generate_index_html() {
    TEMP_OUTPUT="${OUTPUT_FILE}.temp"
    
    # 1. ZAČÁTEK SOUBORU (UTF-8 a styl z Engarde)
    echo "<!DOCTYPE html><html><head><meta charset='utf-8'>" > "$TEMP_OUTPUT"
    
    # Ukradneme originální styl z prvního souboru, aby tabulky nebyly rozbité
    FIRST_HTM=$(ls -d *-AUX/*.htm 2>/dev/null | head -n 1)
    if [ -n "$FIRST_HTM" ]; then
        iconv -f windows-1250 -t utf-8 "$FIRST_HTM" | sed -n '/<[Ss][Tt][Yy][Ll][Ee]>/,/<\/[Ss][Tt][Yy][Ll][Ee]>/p' >> "$TEMP_OUTPUT"
    fi
    
    echo "</head><body>" >> "$TEMP_OUTPUT"
    
    # Logo na začátek
    echo "<div style='text-align:center;'><img src='logo.png' style='max-width:200px;' onerror='this.style.display=\"none\"'></div>" >> "$TEMP_OUTPUT"

    # 2. MERGE OBSAHU (Bez přidávání vlastních divů a barev)
    for dir in $(ls -td *-AUX/ 2>/dev/null); do
        for file in "$dir"*.htm; do
            [ -f "$file" ] || continue
            filename=$(basename "$file" .htm)
            [[ "$filename" == "index" || "$filename" == "navbar" ]] && continue
            
            # Převedeme češtinu a vytáhneme jen vnitřek BODY
            iconv -f windows-1250 -t utf-8 "$file" 2>/dev/null | \
            sed -n '/<[Bb][Oo][Dd][Yy][^>]*>/,/<\/[Bb][Oo][Dd][Yy]>/p' | \
            sed '1d;$d' | \
            sed "s|src=\"|src=\"$dir|g" | \
            sed "s|href=\"|href=\"$dir|g" >> "$TEMP_OUTPUT"
            
            echo "<br><hr><br>" >> "$TEMP_OUTPUT"
        done
    done

    echo "</body></html>" >> "$TEMP_OUTPUT"
    mv "$TEMP_OUTPUT" "$OUTPUT_FILE"
}

# --- RUČNÍ SPOUŠTĚNÍ ---
echo "===================================================="
echo " MANUÁLNÍ DEPLOYER (Vercel limit safe)"
echo "===================================================="

while true; do
    echo ">>> Stiskni [ENTER] pro MERGE a odeslání na GitHub"
    echo ">>> Stiskni [Q] a Enter pro ukončení"
    read -r input

    if [[ $input == "q" || $input == "Q" ]]; then
        exit 0
    fi

    generate_index_html
    
    git add .
    git commit -m "Manual merge: $(date '+%H:%M:%S')"
    git push origin "$GIT_BRANCH"
    
    echo "----------------------------------------------------"
    echo "HOTOVO: Odesláno na GitHub."
    echo "----------------------------------------------------"
done