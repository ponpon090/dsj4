# DSJ4 - Deluxe Ski Jumps 4

Realistyczny symulator skoków narciarskich 3D stworzony w **Godot Engine 4.x**.

## Wymagania

- [Godot Engine 4.1+](https://godotengine.org/download)

## Uruchomienie

1. Pobierz i zainstaluj Godot 4.1 lub nowszy
2. Otwórz Godot → **Import** → wskaż plik `project.godot` w tym katalogu
3. Naciśnij **F5** lub kliknij **Play** aby uruchomić grę

## Sterowanie

| Klawisz | Akcja |
|---------|-------|
| `SPACJA` (przytrzymaj + puść) | Ładowanie i wybicie skoku |
| `↑` / `↓` | Pochylenie w trakcie lotu |
| `←` / `→` | Balansowanie lewo/prawo |
| `SPACJA` (przy lądowaniu) | Telemark (lądowanie techniczne) |
| `ESC` | Powrót do menu |

## Mechanika gry

### Fazy skoku

1. **Rozjazd (Inrun)** – Zawodnik zjeżdża po torze najazdowym i nabiera prędkości automatycznie
2. **Wybicie (Takeoff)** – Na stole rozbiegu przytrzymaj `SPACJA` i puść w optymalnym momencie (zielony pasek)
3. **Lot (Flight)** – Steruj pochyleniem (↑↓) i balansem (←→), utrzymuj pozycję V-style dla maksymalnego lotu
4. **Lądowanie (Landing)** – Wciśnij `SPACJA` w momencie kontaktu z ziemią dla telemarku

### System punktacji

Punkty składają się z:
- **Punkty odległości**: `Pkt_baza + (Odległość - K-punkt) × Przelicznik`
- **Punkty stylu**: Maks. 20 pkt, odejmowane za złe balansowanie i kiepskie lądowanie

### Skocznie

| Nazwa | K-punkt | Rozmiar | Przelicznik |
|-------|---------|---------|-------------|
| K-60 Mała skocznia | 60 m | HS65 | 2.0 pkt/m |
| K-90 Normalna skocznia | 90 m | HS95 | 2.0 pkt/m |
| K-120 Duża skocznia | 120 m | HS130 | 1.8 pkt/m |
| K-185 Skocznia lotów | 185 m | HS200 | 1.2 pkt/m |

### Pogoda i wiatr

- **Słonecznie** – minimalny wiatr
- **Pochmurno** – umiarkowany wiatr
- **Śnieg** – silny wiatr z porywami
- **Mgła** – spokojny wiatr, słaba widoczność

Zielona strzałka = tailwind (pomaga, dodaje punkty)  
Czerwona strzałka = headwind (przeszkadza, odejmuje punkty)

## Struktura projektu

```
dsj4/
├── project.godot          # Konfiguracja projektu Godot
├── scenes/
│   ├── MainMenu.tscn      # Menu główne
│   ├── Game.tscn          # Scena gry (skocznia, skoczek, kamera)
│   └── Results.tscn       # Tabela wyników
├── scripts/
│   ├── game_manager.gd    # Autoload: globalny stan gry, konfiguracja skoczni
│   ├── game.gd            # Kontroler sceny gry
│   ├── skier.gd           # Fizyka i sterowanie skoczkiem
│   ├── hud.gd             # HUD (speed, height, distance, wind, style)
│   ├── wind_system.gd     # System wiatru
│   ├── main_menu.gd       # Logika menu głównego
│   └── results.gd         # Ekran wyników / leaderboard
└── README.md
```

## Tryb turniejowy

W trybie turniejowym rozgrywane są **2 serie** skoków. Suma punktów z obu serii wyznacza końcowy wynik. Wyniki zapisywane są w tabeli wyników (widocznej w menu).

## Licencja

Projekt open-source. Silnik: [Godot Engine](https://godotengine.org/) (MIT License).
