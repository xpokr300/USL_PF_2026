#!/bin/bash

# --- KONFIGURACE ---
GIT_BRANCH="master"
OUTPUT_FILE="index.html"

process_files() {
    local dir=$1
    local out=$2
    # Projdeme všechny .htm soubory v dané složce
    for file in "$dir"*.htm; do
        [ -f "$file" ] || continue
        filename=$(basename "$file" .htm)
        # Přeskočíme navigaci a prázdné indexy z Engarde
        [[ "$filename" == "index" || "$filename" == "navbar" ]] && continue
        
        # Převedeme kódování a vytáhneme obsah BODY, upravíme cesty k obrázkům
        iconv -f windows-1250 -t utf-8 "$file" 2>/dev/null | \
        sed -n '/<[Bb][Oo][Dd][Yy][^>]*>/,/<\/[Bb][Oo][Dd][Yy]>/p' | \
        sed '1d;$d' | \
        sed "s|src=\"|src=\"$dir|g" | \
        sed "s|href=\"|href=\"$dir|g" >> "$out"
        
        echo "<br><hr><br>" >> "$out"
    done
}

generate_index_html() {
    TEMP_OUTPUT="${OUTPUT_FILE}.temp"
    
    # 1. HLAVIČKA A STYLY (Včetně přepínače záložek)
    echo "<!DOCTYPE html><html><head><meta charset='utf-8'>" > "$TEMP_OUTPUT"
    
    # Ukradneme originální CSS styl z prvního souboru 
    FIRST_HTM=$(ls -d *-AUX/*.htm 2>/dev/null | head -n 1)
    if [ -n "$FIRST_HTM" ]; then
        iconv -f windows-1250 -t utf-8 "$FIRST_HTM" | sed -n '/<[Ss][Tt][Yy][Ll][Ee]>/,/<\/[Ss][Tt][Yy][Ll][Ee]>/p' >> "$TEMP_OUTPUT"
    fi

    echo "<style>
        body { font-family: sans-serif; }
        .nav-tabs { text-align: center; margin: 20px 0; }
        .tab-btn { padding: 12px 25px; cursor: pointer; border: 1px solid #0055aa; background: #fff; color: #0055aa; margin: 5px; border-radius: 5px; font-weight: bold; transition: 0.3s; }
        .tab-btn.active { background: #0055aa; color: white; }
        .category-section { display: none; }
        .category-section.active { display: block; }
        hr { border: 0; height: 2px; background: #eee; margin: 40px 0; }
    </style>" >> "$TEMP_OUTPUT"

    echo "</head><body>" >> "$TEMP_OUTPUT"
    
    # Logo na střed 
    echo "<div style='text-align:center;'><img src='logo.png' style='max-width:200px;' onerror='this.style.display=\"none\"'></div>" >> "$TEMP_OUTPUT"

    # Tlačítka přepínače
    echo "<div class='nav-tabs'>
        <button id='btn-muzi' class='tab-btn active' onclick='showCat(\"muzi\")'>MUŽI</button>
        <button id='btn-zeny' class='tab-btn' onclick='showCat(\"zeny\")'>ŽENY</button>
    </div>" >> "$TEMP_OUTPUT"

    # 2. ROZTŘÍDĚNÍ OBSAHU
    
    # Sekce MUŽI (hledá složky s 'MUZI' v názvu)
    echo "<div id='muzi' class='category-section active'>" >> "$TEMP_OUTPUT"
    for dir in $(ls -td *MUZI*-AUX/ 2>/dev/null); do
        echo "<h1 style='text-align:center; color:#0055aa;'>$(basename "$dir" -AUX)</h1>" >> "$TEMP_OUTPUT"
        process_files "$dir" "$TEMP_OUTPUT"
    done
    echo "</div>" >> "$TEMP_OUTPUT"

    # Sekce ŽENY (hledá složky s 'ZENY' v názvu)
    echo "<div id='zeny' class='category-section'>" >> "$TEMP_OUTPUT"
    for dir in $(ls -td *ZENY*-AUX/ 2>/dev/null); do
        echo "<h1 style='text-align:center; color:#0055aa;'>$(basename "$dir" -AUX)</h1>" >> "$TEMP_OUTPUT"
        process_files "$dir" "$TEMP_OUTPUT"
    done
    echo "</div>" >> "$TEMP_OUTPUT"

    # JavaScript pro přepínání kategorií
    echo "<script>
        function showCat(id) {
            document.querySelectorAll('.category-section').forEach(s => s.classList.remove('active'));
            document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
            document.getElementById(id).classList.add('active');
            document.getElementById('btn-' + id).classList.add('active');
        }
    </script>" >> "$TEMP_OUTPUT"

    echo "<p style='text-align:center; font-size:0.8em; color:gray;'>Aktualizováno: $(date '+%d.%m.%Y %H:%M:%S')</p>" >> "$TEMP_OUTPUT"
    echo "</body></html>" >> "$TEMP_OUTPUT"
    
    mv "$TEMP_OUTPUT" "$OUTPUT_FILE"
}

# --- RUČNÍ SPOUŠTĚNÍ (LOOP) ---
echo "===================================================="
echo " MANUÁLNÍ DEPLOYER (S podporou záložek)"
echo "===================================================="

while true; do
    echo ">>> Stiskni [ENTER] pro MERGE a odeslání na GitHub"
    echo ">>> Stiskni [Q] a Enter pro ukončení"
    read -r input

    if [[ $input == "q" || $input == "Q" ]]; then
        exit 0
    fi

    echo "Generuji index.html..."
    generate_index_html
    
    echo "Odesílám na GitHub..."
    git add .
    git commit -m "Update výsledků: $(date '+%H:%M:%S')"
    git push origin "$GIT_BRANCH"
    
    echo "----------------------------------------------------"
    echo "HOTOVO: Web je aktualizován."
    echo "----------------------------------------------------"
done