#!/usr/bin/env bash

shopt -s nocasematch

use_color=1; [[ -n ${NO_COLOR:-} ]] && use_color=0
c(){ 
  local code=$1; shift
  if (( use_color )); then printf "\e[%sm%s\e[0m" "$code" "$*"; else printf "%s" "$*"; fi
}

C_RED(){ c 31 "$*"; }
C_GRN(){ c 32 "$*"; }
C_YEL(){ c 33 "$*"; }
C_BLU(){ c 34 "$*"; }
C_MAG(){ c 35 "$*"; }
C_CYN(){ c 36 "$*"; }
C_DIM(){ c 2  "$*"; }
C_BLD(){ c 1  "$*"; }

EM_OK="✅"; EM_BAD="✖"; EM_WARN="⚠️"; EM_GIFT="🎁"; EM_DOOR="🚪"; EM_BOOK="📘"; EM_NPC="🗣️"; EM_LOOT="🧰"; EM_HEART="❤"; EM_HEART_EMPTY="♡"; EM_LIGHT="🔦"; EM_NOTE="📝"; EM_APPLE="🍎"; EM_LIQUID="🧪"

health_bar(){
  local out=""; local i
  for ((i=1;i<=MAX_HEALTH;i++)); do
    if (( i<=HEALTH )); then out+="$(C_RED "$EM_HEART ")"; else out+="$(C_DIM "$EM_HEART_EMPTY ")"; fi
  done
  echo -n "$out"
}

# normalise answers
norm_ans(){ local s="$1"; s="${s,,}"; s="${s// /}"; s="${s//\$/}"; s="${s//,/}"; echo "$s"; }

subject_color(){
  local subj=$1 text=$2
  case $subj in
    geo)   C_GRN "$text" ;;
    math)  C_YEL "$text" ;;
    sci)   C_CYN "$text" ;;
    tech)  C_BLU "$text" ;;
    music) C_MAG "$text" ;;
    *)     printf "%s" "$text" ;;
  esac
}

travel_anim(){ local steps=10; printf " "; for ((i=1;i<=steps;i++)); do printf "-"; sleep 0.03; done; printf ">\n"; }

MAX_HEALTH=3
HEALTH=$MAX_HEALTH

level_name(){ local n=$1; case $n in 0) echo "Newcomer";;1) echo "Learner";;2) echo "Researcher";;3) echo "Investigator";;4) echo "Mastermind";;*) echo "Town Scholar";; esac }

declare -A ROOM_DESC ROOM_EXITS ROOM_NPCS ROOM_ITEMS READABLES
declare -A NPC_Q NPC_A NPC_REWARD_ITEM NPC_REWARD_FLAG NPC_LINES
declare -A SUBJECT_REWARD_ITEM INV FLAGS ROOM_UNLOCKED

put_item(){ ROOM_ITEMS["$1:$2"]=1; }
rm_item(){ unset ROOM_ITEMS["$1:$2"]; }
room_has(){ [[ ${ROOM_ITEMS["$1:$2"]+yes} ]]; }
inv_has(){ [[ ${INV["$1"]+yes} ]]; }
inv_add(){ INV["$1"]=1; }
inv_rm(){ unset INV["$1"]; }

ROOM_DESC[town_square]="You're in the Town Square. A notice board stands nearby. Paths lead to Library, Shop, Police Station, and School."
ROOM_DESC[library]="Quiet shelves line the walls. A librarian peers over spectacles."
ROOM_DESC[shop]="A small general store. Shelves of goods and a cheerful shopkeeper."
ROOM_DESC[police]="A tidy station. An officer sits behind the front desk."
ROOM_DESC[school]="A bright classroom. A teacher is arranging worksheets."
ROOM_DESC[town_hall]="The grand Town Hall doors are shut. Rumour says scholarly deeds may open them."

ROOM_EXITS[town_square]="library shop police school"
ROOM_EXITS[library]="town_square"
ROOM_EXITS[shop]="town_square"
ROOM_EXITS[police]="town_square"
ROOM_EXITS[school]="town_square"
ROOM_EXITS[town_hall]="town_square"

ROOM_NPCS["town_square:guide"]=1
ROOM_NPCS["library:librarian"]=1
ROOM_NPCS["shop:shopkeeper"]=1
ROOM_NPCS["police:officer"]=1
ROOM_NPCS["school:teacher"]=1

put_item town_square board
put_item library atlas
put_item shop apple
put_item shop flashlight
put_item police note_evidence
put_item school cipher_note

READABLES[board]="Welcome to Tiny Town! Try: look, go <place>, talk <npc>, pickup <item>, list, read <item>, eat apple, info."
READABLES[note_evidence]="A scribbled note: 'Trust, but verify. Call triple zero in a true emergency.'"
READABLES[cipher_note]="ROT-13 tip: 'uryyb' -> 'hello'."
READABLES[atlas]="Maps of the world. Paris is marked boldly on France."

NPC_Q[librarian]="What is the capital of France?"; NPC_A[librarian]="paris"; NPC_REWARD_ITEM[librarian]="library_card"
NPC_Q[shopkeeper]="A $20 item has 25% off. New price? (Answer with or without $)"; NPC_A[shopkeeper]="15"; NPC_REWARD_ITEM[shopkeeper]="apple"
NPC_Q[officer]="What is the emergency number in Australia?"; NPC_A[officer]="000"; NPC_REWARD_FLAG[officer]="badge_code"
NPC_Q[guide]="Collect knowledge from around town. The teacher at the School can test you by subject."

NPC_LINES[librarian]="Books are doors to other worlds.|Knowledge never sleeps.|Mind the quiet, please."
NPC_LINES[shopkeeper]="See anything you like?|Big savings today!|Apples are extra crunchy."
NPC_LINES[officer]="Stay safe out there.|We serve and protect.|Report suspicious behaviour."
NPC_LINES[teacher]="Ready to learn?|Five questions, five chances.|Pick a subject you enjoy."

# Subjects
declare -a SUBJECT_geo SUBJECT_math SUBJECT_sci SUBJECT_tech SUBJECT_music
SUBJECT_geo=(
  "What is the capital of France?|paris"
  "Which river runs through Cairo?|nile"
  "Which country has the city of Kyoto?|japan"
  "Mount Everest lies on the border of Nepal and which country?|china"
  "What is the largest ocean on Earth?|pacific"
  "What continent is Madagascar part of?|africa"
  "What is the longest river in the world?|amazon"
  "What is the capital of Japan?|tokyo"
  "Which desert is the largest in the world?|antarcticpolar"
  "What is the smallest country in the world?|vaticancity"
  "The Great Barrier Reef is off the coast of which country?|australia"
)
SUBJECT_math=(
  "What is 7×8?|56"
  "What is the square root of 81?|9"
  "A triangle's angles sum to how many degrees?|180"
  "Half of 3/4 is what fraction?|3/8"
  "What is 25% of 200?|50"
  "Solve: 12 + 15 × 0?|12"
  "What is the value of Pi to two decimal places?|3.14"
  "What is 15% of 100?|15"
  "How many sides does a hexagon have?|6"
  "What is the next prime number after 7?|11"
  "What is 5 factorial (5!)?|120"
)
SUBJECT_sci=(
  "Water freezes at what °C?|0"
  "Plants mainly absorb which gas from the air?|carbondioxide"
  "What force pulls objects toward Earth?|gravity"
  "What is H2O commonly called?|water"
  "The Sun is a ____?|star"
  "Which part of the plant conducts photosynthesis? (singular)|leaf"
  "What is the chemical symbol for gold?|au"
  "What is the powerhouse of the cell?|mitochondria"
  "How many planets are in our solar system?|8"
  "What is the hardest natural substance on Earth?|diamond"
  "What gas do humans breathe out?|carbondioxide"
)
SUBJECT_tech=(
  "In Bash, which command prints the current directory?|pwd"
  "What does 'CPU' stand for?|centralprocessingunit"
  "Git command to record staged changes?|commit"
  "What does HTML stand for?|hypertextmarkuplanguage"
  "In networks, what does 'IP' stand for?|internetprotocol"
  "What is the default port for SSH?|22"
  "What does 'URL' stand for?|uniformresourcelocator"
  "What is the most popular programming language in 2023?|python"
  "What does 'GPU' stand for?|graphicsprocessingunit"
  "What company developed the first commercially successful microprocessor?|intel"
  "What is the name of the first web browser?|worldwideweb"
)
SUBJECT_music=(
  "How many semitones in an octave?|12"
  "Treble clef circles which note line?|g"
  "A whole note equals how many quarter notes?|4"
  "Tempo marking meaning 'slow'?|largo"
  "What do we call the speed of music?|tempo"
  "What scale has no sharps or flats (ionian)?|c"
  "Who is known as the 'King of Pop'?|michaeljackson"
  "Which instrument has 88 keys?|piano"
  "What is the name of the Beatles' first album?|pleasepleaseme"
  "How many strings does a standard guitar have?|6"
  "What does 'forte' mean in music?|loud"
)

SUBJECT_REWARD_ITEM[geo]="map_fragment_A"
SUBJECT_REWARD_ITEM[math]="abacus_token"
SUBJECT_REWARD_ITEM[sci]="lab_pass"
SUBJECT_REWARD_ITEM[tech]="usb_key"
SUBJECT_REWARD_ITEM[music]="tuning_fork"

# Phase 2 Rooms
ROOM_DESC[science_lab]="The Science Lab hums with equipment. Beakers, colours, and curious smells."
ROOM_DESC[music_studio]="A cozy studio with instruments and a metronome ticking softly."
ROOM_DESC[library_basement]="A dusty archive beneath the library. It's dark — a flashlight would help."
ROOM_DESC[park]="A quiet park with benches and a small pond. A nice place to think."

ROOM_NPCS["science_lab:scientist"]=1
ROOM_NPCS["music_studio:composer"]=1
ROOM_NPCS["library_basement:archivist"]=1
ROOM_NPCS["town_hall:mayor"]=1

NPC_Q[scientist]="Mix red + blue → ?"; NPC_A[scientist]="purple"; NPC_REWARD_ITEM[scientist]="experiment_note"
NPC_Q[composer]="How many beats in a bar of 3/4 time?"; NPC_A[composer]="3"; NPC_REWARD_ITEM[composer]="melody_scroll"
NPC_Q[archivist]="Decode this ROT-13: URYYB"; NPC_A[archivist]="hello"; NPC_REWARD_ITEM[archivist]="town_history"
NPC_Q[mayor]="Welcome scholar. Return when you have mastered more subjects."

READABLES[experiment_note]="Primary colors mix: red+blue=?, blue+yellow=?, red+yellow=?"
READABLES[melody_scroll]="A melody fragment with 3/4 notation and accent on beat one."
READABLES[town_history]="An account of Tiny Town's founders and the old Knowledge Tower."

knowledge_count(){ local n=0; for s in geo math sci tech music; do [[ ${FLAGS["quiz_${s}_perfect"]+yes} ]] && ((n++)); done; echo $n; }
append_exit_once(){ local room=$1 add=$2; [[ ${ROOM_EXITS[$room]} =~ (^|[[:space:]])$add($|[[:space:]]) ]] || ROOM_EXITS[$room]="${ROOM_EXITS[$room]} $add"; }

update_unlocks(){
  local k; k=$(knowledge_count)
  if [[ ${FLAGS[quiz_sci_perfect]+yes} ]]; then append_exit_once town_square science_lab; ROOM_UNLOCKED[science_lab]=1; fi
  if [[ ${FLAGS[quiz_music_perfect]+yes} ]]; then append_exit_once town_square music_studio; ROOM_UNLOCKED[music_studio]=1; fi
  if inv_has flashlight; then append_exit_once town_square library_basement; ROOM_UNLOCKED[library_basement]=1; fi
  if (( k >= 3 )); then append_exit_once town_square town_hall; ROOM_UNLOCKED[town_hall]=1; fi
  append_exit_once town_square park
}

pre_enter_checks(){
  local dest=$1
  if [[ $dest == library_basement ]] && ! inv_has flashlight; then
    echo "${EM_LIGHT} $(C_YEL "It's too dark to enter safely. You probably need a flashlight.")"
    return 1
  fi
  if [[ $dest == town_hall ]]; then
    local k; k=$(knowledge_count)
    if (( k < 3 )); then
      echo "${EM_DOOR} $(C_MAG "The Town Hall doors remain closed. Scholars only (3 subjects mastered). Current: $k/5")"
      return 1
    fi
  fi
  return 0
}

list_room_items(){
  local room=$1; local out=(); local k
  for k in "${!ROOM_ITEMS[@]}"; do [[ $k == "$room:"* ]] || continue; out+=("${k#*$room:}"); done
  if ((${#out[@]})); then
    local line="Items: "; local i
    for i in "${out[@]}"; do line+="$(C_YEL "$i") "; done
    echo "${EM_LOOT} ${line}"
  else
    echo "No items here."
  fi
}

list_exits(){
  local from=$1; [[ -z ${ROOM_EXITS[$from]:-} ]] && return
  local line="Exits: "; local p
  for p in ${ROOM_EXITS[$from]}; do line+="$(C_BLU "$p") "; done
  echo "$line"
}

list_npcs(){
  local room=$1; local out=(); local k
  for k in "${!ROOM_NPCS[@]}"; do [[ $k == "$room:"* ]] || continue; out+=("${k#*$room:}"); done
  ((${#out[@]})) && echo "${EM_NPC} You see: $(C_CYN "${out[*]}")"
}

look(){
  echo "$(C_BLU --) $(C_BLD $(C_BLU "${CUR//_/ }")) $(C_BLU --)"
  echo "${ROOM_DESC[$CUR]}"
  list_npcs "$CUR"
  list_room_items "$CUR"
  list_exits "$CUR"
  echo "Health: $(health_bar) | Level: $(C_MAG $(level_name $(knowledge_count))) ($(knowledge_count)/5)"
}

info(){ cat <<HELP
$(C_BLD "Commands:")
  $(C_BLU look) – describe where you are
  $(C_BLU "go <place>") – travel (e.g., $(C_BLD library))
  $(C_BLU leave) – return to Town Square
  $(C_BLU "talk <npc> [subject]") – School subjects: $(C_GRN geo) $(C_YEL math) $(C_CYN sci) $(C_BLU tech) $(C_MAG music)
  $(C_BLU "pickup/drop <item>") – manage items
  $(C_BLU list) – show inventory & flags
  $(C_BLU status) – health + inventory + flags + level
  $(C_BLU "read <item>") – read notes/books/signs
  $(C_BLU "play <item>") – play a special item
  $(C_BLU "mix <colour1> <colour2>") – mix colours in the lab
  $(C_BLU "eat apple") – mini-game (1–10, 3 tries)
  $(C_BLU info) – this help
  $(C_BLU quit) – exit
HELP
}

status(){ echo "Health: $(health_bar) | Level: $(C_MAG $(level_name $(knowledge_count))) ($(knowledge_count)/5)"; list_inv; }

can_go(){ local dest=$1; for p in ${ROOM_EXITS[$CUR]:-}; do [[ $p == "$dest" ]] && return 0; done; return 1; }

go(){ local dest=${1:-}; if [[ -z $dest ]]; then echo "Go where?"; return; fi; if can_go "$dest"; then if pre_enter_checks "$dest"; then travel_anim; CUR=$dest; look; fi; else echo "You can't go directly to ${dest//_/ }. Try from Town Square."; fi }

leave(){ if [[ $CUR != town_square ]]; then travel_anim; CUR=town_square; look; else echo "You're already in the Town Square."; fi }

pickup(){ local item=${1:-}; [[ -z $item ]] && { echo "Pickup what?"; return; }; if room_has "$CUR" "$item"; then rm_item "$CUR" "$item"; inv_add "$item"; echo "${EM_GIFT} You picked up: $(C_YEL "$item")"; else echo "No such item here: $item"; fi }

drop(){ local item=${1:-}; [[ -z $item ]] && { echo "Drop what?"; return; }; if inv_has "$item"; then inv_rm "$item"; put_item "$CUR" "$item"; echo "You dropped: $(C_YEL "$item")"; else echo "You're not carrying: $item"; fi }

list_inv(){
  local inv_arr=() i; for i in "${!INV[@]}"; do inv_arr+=("$i"); done
  local flags_arr=() f; for f in "${!FLAGS[@]}"; do flags_arr+=("$f"); done
  if ((${#inv_arr[@]})); then
    local line="You carry: "; for i in "${inv_arr[@]}"; do line+="$(C_YEL "$i") "; done; echo "$line"
  else
    echo "You carry: (nothing)"
  fi
  ((${#flags_arr[@]})) && echo "Flags: $(C_CYN "${flags_arr[*]}")"
}

read_item(){ local item=${1:-}; [[ -z $item ]] && { echo "Read what?"; return; }; if inv_has "$item" || room_has "$CUR" "$item"; then if [[ -n ${READABLES[$item]:-} ]]; then echo "${EM_BOOK} $(C_MAG "${READABLES[$item]}")"; else echo "There's nothing to read on the $item."; fi; else echo "You don't see any $item here."; fi }

use_apple(){ if ! inv_has apple; then echo "You don't have an apple."; return; fi; inv_rm apple; echo "${EM_APPLE} You eat the apple…"; local target=$((1 + RANDOM % 10)); local tries=3 g; while (( tries > 0 )); do read -rp "Guess the number (1–10). Tries left $tries: " g || true; [[ $g =~ ^[0-9]+$ ]] || { echo "Numbers only."; continue; }; if (( g == target )); then echo "${EM_OK} $(C_GRN "Not poisonous! You feel better.")"; (( HEALTH < MAX_HEALTH )) && ((HEALTH++)); echo "Health: $(health_bar)"; return; elif (( g < target )); then echo "Higher."; else echo "Lower."; fi; ((tries--)); done; echo "${EM_WARN} $(C_RED "Oh no — it was poisonous!")"; ((HEALTH>0)) && ((HEALTH--)); echo "Health: $(health_bar)"; (( HEALTH == 0 )) && { echo "You collapse… Game over."; exit 0; } }

play_melody() {
  echo "The composer visually plays the melody from the scroll..."
  sleep 1

  local header="[ C ] [ G ] [ G ]"
  local line_1="  *              "
  local line_2="        *        "
  local line_3="              *  "
  local clear_line="                 "

  tput civis
  
  echo "$header"
  for _ in {1..2}; do
    printf "%s\r" "$line_1"; sleep 0.5
    printf "%s\r" "$line_2"; sleep 0.5
    printf "%s\r" "$line_3"; sleep 0.5
  done

  printf "%s\r" "$clear_line"
  tput cnorm
  echo 
}

mix_colours(){
  local colour1=${1:-}
  local colour2=${2:-}

  if [[ $CUR != "science_lab" ]]; then
    echo "You can only mix colours in the Science Lab."
    return
  fi

  if ! inv_has experiment_note; then
    echo "You should probably have some instructions before you start mixing things."
    return
  fi

  if [[ -z $colour1 || -z $colour2 ]]; then
    echo "Mix what with what? (e.g., mix red blue)"
    return
  fi

  if [[ "$colour1" > "$colour2" ]]; then
    local temp=$colour1
    colour1=$colour2
    colour2=$temp
  fi

  case "$colour1:$colour2" in
    blue:red)
      echo "${EM_LIQUID} You mix $(C_RED red) and $(C_BLU blue) to create a bubbling $(C_MAG purple) liquid!"
      ;;
    blue:yellow)
      echo "${EM_LIQUID} You mix $(C_YEL yellow) and $(C_BLU blue) to create a fizzing $(C_GRN green) liquid!"
      ;;
    red:yellow)
      echo "${EM_LIQUID} You mix $(C_RED red) and $(C_YEL yellow) to create a glowing $(C_YEL orange) liquid!"
      ;;
    *)
      echo "You mix the colours, but nothing interesting happens."
      ;;
  esac
}

shuffle_idx(){ local n=$1; local -a idx=(); for ((i=0;i<n;i++)); do idx+=($i); done; for ((i=n-1;i>0;i--)); do local j=$((RANDOM%(i+1))); local t=${idx[i]}; idx[i]=${idx[j]}; idx[j]=$t; done; printf '%s\n' "${idx[@]}"; }

npc_quiz(){ local npc=$1; local q=${NPC_Q[$npc]:-}; local a=${NPC_A[$npc]:-}; if [[ -z $q ]]; then echo "They have nothing to ask right now."; return; fi; if [[ -n ${NPC_LINES[$npc]:-} ]]; then IFS='|' read -r -a LINES <<<"${NPC_LINES[$npc]}"; local pick=${LINES[$((RANDOM%${#LINES[@]}))]}; echo "${EM_NPC} $(C_CYN "$pick")"; fi; echo "$q"; local ans=""; read -rp "> " ans || true; if [[ $(norm_ans "$ans") == $(norm_ans "$a") ]]; then echo "${EM_OK} $(C_GRN Correct.)"; [[ -n ${NPC_REWARD_ITEM[$npc]:-} ]] && { inv_add "${NPC_REWARD_ITEM[$npc]}"; echo "${EM_GIFT} You receive: $(C_YEL "${NPC_REWARD_ITEM[$npc]}")"; }; [[ -n ${NPC_REWARD_FLAG[$npc]:-} ]] && { FLAGS["${NPC_REWARD_FLAG[$npc]}"]=1; echo "${EM_GIFT} Flag acquired: $(C_CYN "${NPC_REWARD_FLAG[$npc]}")"; }; else echo "${EM_BAD} $(C_RED "Not quite. Come back later.")"; fi }

subject_quiz(){ local subj=${1:-}; local poolref=${2:-}; [[ -z $subj || -z $poolref ]] && { echo "Internal error: subject pool missing"; return; }; local -n POOL=$poolref; local need=5; local n=${#POOL[@]}; (( need>n )) && need=$n; local -a idx; mapfile -t idx < <(shuffle_idx "$n"); local correct=0 k Q A ans; for ((k=0;k<need;k++)); do IFS='|' read -r Q A <<<"${POOL[${idx[$k]}]}"; echo "$((k+1)). $Q"; read -rp "> " ans || true; if [[ $(norm_ans "$ans") == $(norm_ans "$A") ]]; then echo "${EM_OK} $(C_GRN "Correct")"; ((correct++)); else echo "${EM_BAD} $(C_RED "Incorrect") $(C_DIM "(answer: $A)")"; fi; done; echo "Score: $(C_BLD "$correct/$need")"; if (( correct == need )); then local reward=${SUBJECT_REWARD_ITEM[$subj]:-}; if [[ -n $reward ]]; then inv_add "$reward"; echo "${EM_GIFT} Perfect! You receive: $(subject_color $subj "$reward")"; fi; FLAGS["quiz_${subj}_perfect"]=1; update_unlocks; echo "${EM_DOOR} $(C_MAG "Your scholarly progress has opened new possibilities…")"; fi }

Talk(){ local npc=${1:-}; local arg=${2:-}; [[ -z $npc ]] && { echo "Talk to whom?"; return; }; [[ -z ${ROOM_NPCS["$CUR:$npc"]:-} ]] && { echo "You don't see $npc here."; return; };
  case "$npc" in
    guide)      echo "${NPC_Q[guide]}" ;;
    librarian)  npc_quiz librarian ;;
    shopkeeper) npc_quiz shopkeeper ;;
    officer)    npc_quiz officer ;;
    teacher)    if [[ -z $arg ]]; then echo "Choose a subject: $(C_GRN geo) | $(C_YEL math) | $(C_CYN sci) | $(C_BLU tech) | $(C_MAG music)"; read -rp "> " arg || true; fi; case "$arg" in
                  geo)  subject_quiz geo SUBJECT_geo ;;
                  math) subject_quiz math SUBJECT_math ;;
                  sci)  subject_quiz sci SUBJECT_sci ;;
                  tech) subject_quiz tech SUBJECT_tech ;;
                  music)subject_quiz music SUBJECT_music ;;
                  *) echo "Unknown subject. Try: geo | math | sci | tech | music" ;;
                esac ;;
    scientist)  npc_quiz scientist ;;
    composer)   npc_quiz composer ;;
    archivist)  npc_quiz archivist ;;
    mayor)      local k; k=$(knowledge_count); if (( k>=5 )); then echo "${EM_OK} $(C_GRN "Mayor: Outstanding work, Town Scholar! The Knowledge Tower shines again. YOU WIN!")"; else echo "${EM_DOOR} Mayor: Come back with more subjects mastered. ($k/5)"; fi ;;
    *) echo "They nod politely but say nothing." ;;
  esac }

CUR=town_square
update_unlocks
clear
printf "%s\n" "$(C_BLD "====================================")"
printf "%s\n" "$(C_BLD "        Tiny Town Adventure")"
printf "%s\n" "$(C_BLD "           type [ info ]")"
printf "%s\n\n" "$(C_BLD "====================================")"
look

while true; do
  echo
  read -rp "> " cmd a b || true
  case "$cmd" in
    look)      look ;;
    info)      info ;;
    go)        go "${a:-}" ;;
    leave)     leave ;;
    talk)      Talk "${a:-}" "${b:-}" ;;
    pickup)    pickup "${a:-}" ;;
    drop)      drop "${a:-}" ;;
    list)      list_inv ;;
    status)    status ;;
    read)      read_item "${a:-}" ;;
    eat)       if [[ ${a:-} == apple ]]; then use_apple; else echo "Eat what?"; fi ;;
    play)      if [[ ${a:-} == melody_scroll ]]; then if inv_has melody_scroll; then play_melody; else echo "You don't have the melody_scroll."; fi; else echo "Play what?"; fi ;;
    mix)       mix_colours "${a:-}" "${b:-}" ;;
    quit|exit) echo "Goodbye!"; break ;;
    *)         echo "I don't understand. Type 'info' for help." ;;
  esac
done
