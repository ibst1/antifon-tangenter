# Antifon-tangenter

Kortkommandon för [Antifon](https://github.com/ibst1) (livetolkning av gudstjänsten) i hela Windows,
på datorn man styr Antifon från på distans – och, om man vill, ett litet fönster som alltid ligger
överst med knapparna och läget.

I webbläsaren fungerar Antifons kortkommandon bara när driftssidan är i fokus. Antifon-tangenter
gör dem globala: tryck t.ex. Ctrl+Shift+F9 var som helst i Windows för att starta gudstjänsten.
Programmet ligger som en ikon (**A**) vid klockan.

## Så kommer du igång

1. Ladda ner den senaste zip-filen under **Releases** och packa upp den var som helst
   (t.ex. i Dokument).
2. Starta **Antifon-tangenter.exe** en gång. Den registrerar länken `antifon-tangenter://`,
   så att Antifons driftssida kan starta den, och gör genvägen **Antifon-tangenter** på skrivbordet
   och i Startmenyn.
3. Öppna Antifons driftssida (logga in med fjärrdriftens lösenord) och tryck
   **⌨ Starta Antifon-tangenter** under Inställningar → Fjärrdrift. Webbläsaren frågar om den får öppna
   Antifon-tangenter – svara ja (och bocka gärna i att alltid tillåta).

Sedan räcker genvägen: programmet minns adressen och startar med den.

Programmet hämtar adressen och en egen nyckel från driftssidan och sparar dem i
`Antifon-tangenter.ini` bredvid programmet. Kortkommandona är desamma som på tolkdatorn och ändras
under **Inställningar → Kortkommandon** i Antifon; programmet följer med inom några sekunder.

## Ikonen vid klockan

Antifon-tangenter ligger som en ikon (**A** på en rundad kvadrat) vid klockan: grön = kontakt med Antifon,
röd = ingen kontakt, grå = ansluter. Håll musen över ikonen för att se läget. Ett klick visar eller döljer
fönstret med knapparna. Högerklick ger samma knappar som fönstret (med kortkommandona), **Öppna driftssidan**,
**Starta med Windows** och **Avsluta**.

## Fönstret med knapparna

Fönstret visar läget (gudstjänsten, predikan, antal lyssnare) och en knapp per funktion med
kortkommandot bredvid. Det ligger alltid överst. Stäng det med krysset – programmet ligger kvar vid klockan –
eller klicka på ikonen. Fönstrets läge sparas.

## Bra att veta

- Nyckeln ger bara rätt att trycka på kortkommandona och läsa läget, inget annat. Byt den under
  **Inställningar → Kortkommandon → Byt nyckel** i Antifon; starta sedan programmet igen från driftssidan.
- Programmet är den oförändrade officiella `AutoHotkey64.exe` (AutoHotkey v2), omdöpt, som kör skriptet
  `Antifon-tangenter.ahk` bredvid. Skriptet är vanlig text och går att läsa.
- Händelser och fel skrivs i `Antifon-tangenter.log` bredvid programmet.
- Kör inte programmet på själva tolkdatorn – där fungerar Antifons kortkommandon redan i hela Windows.

## Ny version

Höj versionen i första raden i `Antifon-tangenter.ahk` och tagga, t.ex. `git tag v1.0.1 && git push --tags`.
GitHub bygger då zip-filen (`build.ps1`) och lägger den under Releases.

## Licens

MIT. AutoHotkey omfattas av sin egen licens (GPL-2.0), se autohotkey.com.
