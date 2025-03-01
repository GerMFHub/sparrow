# sparrow swarm POC commnunication
Spiečiaus veikimo simuliaciniai modeliai. Pagrindinią užduotį atlieka trianguliacijos modelis ```triangulation.asm``` skirtas objekto buvimo vietos nustatymui naudojant kelis skirtingus signalų analizės metodus. Jis integruojasi su GPS, Bluetooth, ir SDR sistemomis, bei kitomis sistemomis, kurios sugeba perduoti reikiamą informaciją apjungdamas jų duomenis tikslesnei lokalizacijai.  Modelis taip pat leidžia dronams keistis informacija apie objekto ir savo buvimo vietą, užtikrinant sinchronizuotą operacijų vykdymą. Komunikacija tarp dronų vykdoma ```secure_comms.asm```. Kitos kodo dalys atlieka kitas pagalbines funkcijas. 

🔗 Integracija su įrenginiais
✔ GPS modulis – pateikia apytiksles globalias koordinates.
✔ Bluetooth įrenginiai – naudojami artimojo atstumo nustatymui pagal RSSI.
✔ SDR imtuvai (Software-Defined Radio) – leidžia apskaičiuoti TDOA (laiko skirtumo) ir AoA (kampinio atvykimo) duomenis.
✔ Papildomi duomenų šaltiniai – Wi-Fi prieigos taškai, mobiliojo ryšio bokštai, UWB (Ultra-Wideband) ir IoT įrenginiai.
✔ Dronų tarpusavio ryšys – užtikrina nuolatinį vietos duomenų apsikeitimą tarp skirtingų dronų.

🧠 Naudojami algoritmai
✔ TDOA (Time Difference of Arrival) – nustato objektą pagal signalo atvykimo laiko skirtumus.
✔ RSS (Received Signal Strength) – įvertina atstumą pagal signalo stiprumą.
✔ AoA (Angle of Arrival) – apskaičiuoja signalo atvykimo kampą.
✔ Kalmano filtras – sumažina matavimo klaidas ir užtikrina stabilų objekto stebėjimą.
✔ Multilateracija – iš kelių skirtingų atstumų apskaičiuoja objekto koordinates.
✔ Decentralizuotas duomenų dalijimasis tarp dronų – leidžia kiekvienam dronui žinoti ne tik objekto, bet ir kitų dronų poziciją.

⚙️ Kodo veikimo principas
1️⃣ Gauti GPS duomenis per UART iš GPS modulio.
2️⃣ Nuskaityti Bluetooth RSSI per HCI komandą („hcitool rssi“).
3️⃣ Fiksuoti SDR signalus, apskaičiuoti TDOA/AoA.
4️⃣ Apjungti visus matavimus naudojant multilateracijos metodą.
5️⃣ Naudoti Kalmano filtrą rezultatų tikslinimui.
6️⃣ Gauti duomenis iš kitų sistemų (Wi-Fi, LTE/5G bokštų, IoT įrenginių) siekiant pagerinti lokalizacijos tikslumą.
7️⃣ Kiekvienas dronas gauna informaciją apie signalo šaltinio buvimo vietą bei savo ir kitų dronų tikslią lokaciją.
8️⃣ Dronų komunikacija yra šifruojama, naudojant saugius šifravimo algoritmus (AES, ECC) siekiant užkirsti kelią duomenų nutekėjimui ar manipuliacijai.
9️⃣ Dronai periodiškai keičiasi informacija, kad būtų užtikrinta nuolatinė sinchronizacija ir optimalus skrydžio maršrutas.


