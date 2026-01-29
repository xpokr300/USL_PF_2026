#!/bin/bash

# --- KONFIGURACE ---
GIT_BRANCH="master"
OUTPUT_FILE="index.html"

generate_index_html() {
    TEMP_OUTPUT="${OUTPUT_FILE}.temp"
    
    # Najdeme první exportovaný soubor pro styl
    FIRST_HTM=$(ls -d *-AUX/*.htm 2>/dev/null | head -n 1)

    # 1. ZAČÁTEK HTML
    cat <<EOF > "$TEMP_OUTPUT"
<!DOCTYPE html>
<html lang="cs">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Živé výsledky turnaje</title>
EOF

    # Přidáme originální styl z Engarde (aby tabulky vypadaly správně)
    if [ -n "$FIRST_HTM" ]; then
        iconv -f windows-1250 -t utf-8 "$FIRST_HTM" | sed -n '/<[Ss][Tt][Yy][Ll][Ee]>/,/<\/[Ss][Tt][Yy][Ll][Ee]>/p' >> "$TEMP_OUTPUT"
    fi

    cat <<EOF >> "$TEMP_OUTPUT"
    <style>
        body { font-family: sans-serif; max-width: 1000px; margin: 0 auto; padding: 20px; background-color: #f4f4f9; }
        .header-area { text-align: center; margin-bottom: 30px; background: white; padding: 20px; border-radius: 12px; }
        .header-area img { max-width: 200px; height: auto; }
        .tournament-container { background: #fff; border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,0.1); margin-bottom: 40px; overflow: hidden; }
        .tour-header { background: #004a99; color: #fff; padding: 15px 20px; }
        .tour-header h2 { margin: 0; font-size: 1.5rem; }
        .tour-content { padding: 20px; }
        table { width: 100% !important; border-collapse: collapse; margin-bottom: 20px; }
    </style>
</head>
<body>
    <div class="header-area">
        <img src="logo.png" alt="Logo" onerror="this.style.display='none'">
        <h1>Oficiální výsledky</h1>
    </div>
EOF

    # 2. SLUČOVÁNÍ SLOŽEK
    for dir in $(ls -td *-AUX/ 2>/dev/null); do
        dirname=$(basename "$dir" "-AUX")
        echo "<div class='tournament-container'><div class='tour-header'><h2>Turnaj: $dirname</h2></div><div class='tour-content'>" >> "$TEMP_OUTPUT"
        
        for file in "$dir"*.htm; do
            [ -f "$file" ] || continue
            filename=$(basename "$file" .htm)
            [[ "$filename" == "index" || "$filename" == "navbar" ]] && continue
            
            # Pouze čistá data z Engarde bez nadpisů sekcí
            iconv -f windows-1250 -t utf-8 "$file" 2>/dev/null | \
            sed -n '/<[Bb][Oo][Dd][Yy][^>]*>/,/<\/[Bb][Oo][Dd][Yy]>/p' | \
            sed '1d;$d' | \
            sed "s|src=\"|src=\"$dir|g" | \
            sed "s|href=\"|href=\"$dir|g" >> "$TEMP_OUTPUT"
        done
        echo "</div></div>" >> "$TEMP_OUTPUT"
    done

    echo "<p style='text-align:center; color:gray; font-size:0.8em;'>Aktualizováno: $(date '+%H:%M:%S')</p></body></html>" >> "$TEMP_OUTPUT"
    mv "$TEMP_OUTPUT" "$OUTPUT_FILE"
}

# --- RUČNÍ SPOUŠTĚNÍ ---
echo "===================================================="
echo " MANUÁLNÍ DEPLOYER ENGARDE VÝSLEDKŮ"
echo "===================================================="
echo "Větev: $GIT_BRANCH | Vercel limit: 100/den"
echo ""

while true; do
    echo ">>> Stiskni [ENTER] pro aktualizaci webu a odeslání na GitHub"
    echo ">>> Stiskni [Q] a Enter pro ukončení"
    read -r input

    if [[ $input == "q" || $input == "Q" ]]; then
        echo "Ukončuji..."
        exit 0
    fi

    # Spustíme generování
    generate_index_html
    
    # Odeslání na GitHub
    echo "--- Generuji index.html a odesílám... ---"
    git add .
    git commit -m "Manual update: $(date '+%H:%M:%S')"
    git push origin "$GIT_BRANCH"
    
    echo ""
    echo "ÚSPĚCH: Odesláno. Za chvíli se to projeví na Vercelu."
    echo "----------------------------------------------------"
done