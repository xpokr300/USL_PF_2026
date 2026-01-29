#!/bin/bash

# --- KONFIGURACE ---
GIT_BRANCH="master"      # Název tvé větve na GitHubu
CHECK_INTERVAL=10      # Kontrola každých 10 sekund
OUTPUT_FILE="index.html"

# --- FUNKCE 1: GENERÁTOR HTML (Slepí výsledky, opraví češtinu a cesty) ---
generate_index_html() {
    TEMP_OUTPUT="${OUTPUT_FILE}.temp"
    
    # Najdeme první htm soubor, abychom z něj vykopírovali originální styl
    FIRST_HTM=$(ls -d *-AUX/*.htm 2>/dev/null | head -n 1)

    # 1. ZAČÁTEK SOUBORU - Přebereme originální styl z Engarde
    echo "<!DOCTYPE html><html><head><meta charset='utf-8'>" > "$TEMP_OUTPUT"
    
    if [ -n "$FIRST_HTM" ]; then
        # Vytáhneme vše mezi <head> a </head> z prvního souboru a převedeme na UTF-8
        iconv -f windows-1250 -t utf-8 "$FIRST_HTM" | sed -n '/<[Hh][Ee][Aa][Dd]>/,/<\/[Hh][Ee][Aa][Dd]>/p' | sed '1d;$d' >> "$TEMP_OUTPUT"
    fi
    
    echo "</head><body style='background:#fff;'>" >> "$TEMP_OUTPUT"
    echo "<h1 style='text-align:center; font-family:sans-serif;'>Aktuální výsledky</h1>" >> "$TEMP_OUTPUT"

    # 2. PROJDEME SLOŽKY A VLOŽÍME OBSAH
    for dir in $(ls -td *-AUX/ 2>/dev/null); do
        dirname=$(basename "$dir" "-AUX")
        
        # Přidáme nadpis turnaje v Engarde stylu
        echo "<hr><h2 style='font-family:sans-serif; background:#eee; padding:5px;'>Turnaj: $dirname</h2>" >> "$TEMP_OUTPUT"
        
        for file in "$dir"*.htm; do
            [ -e "$file" ] || continue
            
            # Vložíme obsah body tak, jak je, jen opravíme cesty k obrázkům
            iconv -f windows-1250 -t utf-8 "$file" | \
            sed -n '/<[Bb][Oo][Dd][Yy][^>]*>/,/<\/[Bb][Oo][Dd][Yy]>/p' | \
            sed '1d;$d' | \
            sed "s|src=\"|src=\"$dir|g" | \
            sed "s|href=\"|href=\"$dir|g" >> "$TEMP_OUTPUT"
            
            echo "<br>" >> "$TEMP_OUTPUT"
        done
    done

    echo "<p style='text-align:center; font-size:0.7em; font-family:sans-serif;'>Poslední aktualizace: $(date '+%H:%M:%S')</p>" >> "$TEMP_OUTPUT"
    echo "</body></html>" >> "$TEMP_OUTPUT"

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