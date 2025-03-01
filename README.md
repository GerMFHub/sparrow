# sparrow swarm POC commnunication
Spiečiaus veikimo simuliaciniai modeliai. Pagrindinią užduotį atlieka trianguliacijos modelis skirtas objekto buvimo vietos nustatymui naudojant kelis skirtingus signalų analizės metodus. Jis integruojasi su GPS, Bluetooth, ir SDR sistemomis, bei kitomis sistemomis, kurios sugeba perduoti reikiamą informaciją apjungdamas jų duomenis tikslesnei lokalizacijai.

🔗 Integracija su įrenginiais
✔ GPS modulis – pateikia apytiksles globalias koordinates.
✔ Bluetooth įrenginiai – naudojami artimojo atstumo nustatymui pagal RSSI.
✔ SDR imtuvai (Software-Defined Radio) – leidžia apskaičiuoti TDOA (laiko skirtumo) ir AoA (kampinio atvykimo) duomenis.
✔ Kitos duomenis perduodančios sistemos


🧠 Naudojami algoritmai
✔ TDOA (Time Difference of Arrival) – nustato objektą pagal signalo atvykimo laiko skirtumus.
✔ RSS (Received Signal Strength) – įvertina atstumą pagal signalo stiprumą.
✔ AoA (Angle of Arrival) – apskaičiuoja signalo atvykimo kampą.
✔ Kalmano filtras – sumažina matavimo klaidas ir užtikrina stabilų objekto stebėjimą.

⚙️ Kodo veikimo principas
1️⃣ Gauti GPS duomenis per UART iš GPS modulio.
2️⃣ Nuskaityti Bluetooth RSSI per HCI komandą („hcitool rssi“).
3️⃣ Fiksuoti SDR signalus, apskaičiuoti TDOA/AoA.
4️⃣ Apjungti visus matavimus naudojant multilateracijos metodą.
5️⃣ Naudoti Kalmano filtrą rezultatų tikslinimui.
6️⃣ Gauti duomenis iš kitų sistemų (Wi-Fi, LTE/5G bokštų, IoT ir kitų įrenginių) siekiant pagerinti lokalizacijos tikslumą.
7️⃣ Grąžinti apskaičiuotas objekto koordinates realiuoju laiku.
