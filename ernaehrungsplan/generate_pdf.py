#!/usr/bin/env python3
"""Erzeugt den Body-Recomp-Ernährungsplan als PDF (18.08.2026–07.01.2027)."""

from __future__ import annotations

from datetime import date, timedelta
from pathlib import Path

from reportlab.lib.colors import Color, HexColor, white
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen import canvas

FONT_DIR = Path("/usr/share/fonts/truetype/macos")
pdfmetrics.registerFont(TTFont("Inter", str(FONT_DIR / "Inter-Regular.ttf")))
pdfmetrics.registerFont(TTFont("Inter-Med", str(FONT_DIR / "Inter-Medium.ttf")))
pdfmetrics.registerFont(TTFont("Inter-Semi", str(FONT_DIR / "Inter-SemiBold.ttf")))
pdfmetrics.registerFont(TTFont("Inter-Bold", str(FONT_DIR / "Inter-Bold.ttf")))

PAGE_W, PAGE_H = A4
MARGIN = 16 * mm

FOREST = HexColor("#16382C")
FOREST_2 = HexColor("#1F4D3C")
CREAM = HexColor("#F6F1E8")
PAPER = HexColor("#FBF8F3")
INK = HexColor("#1C1C1C")
MUTED = HexColor("#5E5A54")
LINE = HexColor("#E4DDD2")
ACCENT = HexColor("#C4A35A")

PLAN_COLORS = {
    "A": HexColor("#2E7D4F"),
    "B": HexColor("#1F5F8B"),
    "C": HexColor("#B45309"),
    "D": HexColor("#6B2D5B"),
}

MEAL_COLORS = {
    "Frühstück": HexColor("#C17F3A"),
    "Mittagessen": HexColor("#2E7D4F"),
    "Nachmittagssnack": HexColor("#3D7EA6"),
    "Abendessen": HexColor("#16382C"),
}

WEEKDAYS = [
    "Montag",
    "Dienstag",
    "Mittwoch",
    "Donnerstag",
    "Freitag",
    "Samstag",
    "Sonntag",
]
MONTHS = [
    "",
    "Januar",
    "Februar",
    "März",
    "April",
    "Mai",
    "Juni",
    "Juli",
    "August",
    "September",
    "Oktober",
    "November",
    "Dezember",
]

START = date(2026, 8, 18)
END = date(2027, 1, 7)

PLANS = {
    "A": {
        "titel": "Quark-Hafer · Hähnchen-Reis · Pudding · Hack-Kartoffeln",
        "kcal": 2102,
        "ew": 188,
        "mahlzeiten": [
            {
                "name": "Frühstück",
                "zeit": "5 Min.",
                "kcal": 595,
                "ew": 50,
                "items": [
                    "88 g Crownfield Haferflocken",
                    "300 g Milbona Magerquark 0,2 %",
                    "80 g TK-Beerenmischung",
                    "5 g Erdnussbutter",
                ],
                "zubereitung": "Hafer mit 150–180 ml heißem Wasser quellen lassen, Quark und Beeren unterrühren, Erdnussbutter oben drauf.",
            },
            {
                "name": "Mittagessen",
                "zeit": "15–18 Min.",
                "kcal": 586,
                "ew": 53,
                "items": [
                    "180 g Hähnchenbrustfilet",
                    "80 g Golden Sun Basmati (trocken)",
                    "200 g TK-Brokkoli",
                    "5 g Olivenöl",
                ],
                "zubereitung": "Reis aufsetzen. Brust in beschichteter Pfanne 8–10 Min. braten, Brokkoli 5–6 Min. mitdünsten. Würzen mit Salz, Pfeffer, Paprika.",
            },
            {
                "name": "Nachmittagssnack",
                "zeit": "0 Min.",
                "kcal": 257,
                "ew": 21,
                "items": [
                    "1 Becher Milbona High Protein Pudding (200 g)",
                    "120 g Banane",
                ],
                "zubereitung": "Direkt essen / mitnehmen. Keine Zubereitung.",
            },
            {
                "name": "Abendessen",
                "zeit": "15 Min.",
                "kcal": 664,
                "ew": 64,
                "items": [
                    "200 g Rinderhack 5 %",
                    "250 g Kartoffeln (roh, mit Schale)",
                    "200 g TK-Gemüsemischung",
                    "100 g körniger Frischkäse Light",
                    "5 g Olivenöl",
                ],
                "zubereitung": "Kartoffeln würfeln und 10–12 Min. garen. Hack scharf anbraten, TK-Gemüse dazu. Körniger Frischkäse zum Schluss darüber.",
            },
        ],
    },
    "B": {
        "titel": "Eier-Brot · Thunfisch-Bowl · Protein-Drink · Pute",
        "kcal": 2102,
        "ew": 223,
        "mahlzeiten": [
            {
                "name": "Frühstück",
                "zeit": "10 Min.",
                "kcal": 641,
                "ew": 55,
                "items": [
                    "3 Eier Größe M",
                    "80 g Vollkornbrot (2 Scheiben)",
                    "200 g körniger Frischkäse Light",
                    "100 g Paprika",
                    "100 g Gurke",
                ],
                "zubereitung": "Eier ohne extra Fett in beschichteter Pfanne. Mit Brot, körnigem Frischkäse und Gemüse essen.",
            },
            {
                "name": "Mittagessen",
                "zeit": "12 Min.",
                "kcal": 642,
                "ew": 58,
                "items": [
                    "180 g Thunfisch im eigenen Saft (abgetropft)",
                    "70 g Basmati (trocken)",
                    "250 g TK-Gemüsemischung",
                    "90 g Mais (Konserve, abgetropft)",
                    "5 g Olivenöl",
                ],
                "zubereitung": "Reis + Gemüse kochen. Thunfisch kalt darüber, Öl, Sojasauce, Zitrone, Pfeffer. Keine Mayo.",
            },
            {
                "name": "Nachmittagssnack",
                "zeit": "0 Min.",
                "kcal": 215,
                "ew": 35,
                "items": [
                    "1 Flasche Milbona High Protein Drink 330 ml",
                ],
                "zubereitung": "Kalt trinken. Falls nur 250-ml-Flasche: plus 80 g Magerquark.",
            },
            {
                "name": "Abendessen",
                "zeit": "18 Min.",
                "kcal": 604,
                "ew": 75,
                "items": [
                    "200 g Putenbrustfilet",
                    "190 g Kartoffeln",
                    "250 g TK-Brokkoli",
                    "7 g Olivenöl",
                    "150 g Milbona Skyr 0,2 %",
                ],
                "zubereitung": "Pute 10–12 Min. braten, Kartoffeln und Brokkoli parallel. Skyr kalt als Sauce mit Knoblauchpulver und Schnittlauch.",
            },
        ],
    },
    "C": {
        "titel": "Beeren-Porridge · Hähnchen-Wrap · Skyr · Lachs",
        "kcal": 2101,
        "ew": 184,
        "mahlzeiten": [
            {
                "name": "Frühstück",
                "zeit": "8 Min.",
                "kcal": 672,
                "ew": 48,
                "items": [
                    "81 g Haferflocken",
                    "250 g Magerquark 0,2 %",
                    "100 g TK-Beeren",
                    "150 ml Frischmilch 1,5 %",
                    "100 g Banane",
                ],
                "zubereitung": "Hafer mit Milch + etwas Wasser 4–5 Min. köcheln. Vom Herd nehmen, Quark unterrühren, Beeren und Banane drauf.",
            },
            {
                "name": "Mittagessen",
                "zeit": "12 Min.",
                "kcal": 518,
                "ew": 64,
                "items": [
                    "200 g Hähnchenbrustfilet",
                    "1 Weizen-Wrap (62 g)",
                    "80 g körniger Frischkäse Light",
                    "50 g Rucola",
                    "100 g Tomate",
                    "80 g Paprika",
                ],
                "zubereitung": "Bruststreifen scharf anbraten, Wrap 20 Sek. wärmen, mit Frischkäse, Gemüse und Hähnchen füllen. Senf statt Mayo.",
            },
            {
                "name": "Nachmittagssnack",
                "zeit": "2 Min.",
                "kcal": 222,
                "ew": 23,
                "items": [
                    "200 g Milbona Skyr 0,2 %",
                    "180 g Apfel",
                ],
                "zubereitung": "Apfel in den Skyr würfeln, optional Zimt.",
            },
            {
                "name": "Abendessen",
                "zeit": "15 Min.",
                "kcal": 689,
                "ew": 49,
                "items": [
                    "180 g Lachsfilet TK (Ocean Sea), aufgetaut",
                    "75 g Basmati (trocken)",
                    "250 g TK-Blattspinat",
                    "5 g Olivenöl",
                ],
                "zubereitung": "Lachs 4–5 Min. je Seite braten, Spinat 5 Min. mit Knoblauch, Reis parallel. Zitrone und Pfeffer.",
            },
        ],
    },
    "D": {
        "titel": "Quark-Bowl · Hack-Reis · Snack-Teller · Hähnchen-Kartoffeln",
        "kcal": 2101,
        "ew": 194,
        "mahlzeiten": [
            {
                "name": "Frühstück",
                "zeit": "10 Min.",
                "kcal": 668,
                "ew": 66,
                "items": [
                    "350 g Magerquark 0,2 %",
                    "45 g Haferflocken",
                    "100 g TK-Beeren",
                    "10 g Erdnussbutter",
                    "2 Eier Größe M",
                ],
                "zubereitung": "Quark, Hafer, Beeren und Erdnussbutter verrühren. Daneben 2 Eier hart (vorkochen) oder als Rührei.",
            },
            {
                "name": "Mittagessen",
                "zeit": "15 Min.",
                "kcal": 645,
                "ew": 49,
                "items": [
                    "180 g Rinderhack 5 %",
                    "70 g Basmati (trocken)",
                    "250 g TK-Gemüsemischung",
                    "50 g Zwiebel",
                    "5 g Olivenöl",
                ],
                "zubereitung": "Zwiebel und Hack anbraten, TK-Gemüse dazu, gewürzten Reis untermischen. Paprika, Kreuzkümmel, Salz, Pfeffer.",
            },
            {
                "name": "Nachmittagssnack",
                "zeit": "3 Min.",
                "kcal": 266,
                "ew": 27,
                "items": [
                    "200 g körniger Frischkäse Light",
                    "150 g Gurke",
                    "150 g Apfel",
                ],
                "zubereitung": "Pfeffer und Paprikapulver in den Frischkäse, Gurke und Apfel dazu. Optional 1 TL Senf.",
            },
            {
                "name": "Abendessen",
                "zeit": "18 Min.",
                "kcal": 522,
                "ew": 53,
                "items": [
                    "180 g Hähnchenbrustfilet",
                    "280 g Kartoffeln",
                    "200 g TK-Brokkoli",
                    "5 g Olivenöl",
                ],
                "zubereitung": "Kartoffeln in 1-cm-Würfeln mit Brokkoli in einer Pfanne, Hähnchen in der zweiten. Fertig in unter 20 Minuten.",
            },
        ],
    },
}


def daterange(start: date, end: date):
    d = start
    while d <= end:
        yield d
        d += timedelta(days=1)


def plan_letter(d: date) -> str:
    return "ABCD"[(d - START).days % 4]


def fmt_date(d: date) -> str:
    return f"{d.day:02d}. {MONTHS[d.month]} {d.year}"


def fmt_date_short(d: date) -> str:
    return f"{d.day:02d}.{d.month:02d}.{d.year}"


def weekday_name(d: date) -> str:
    return WEEKDAYS[d.weekday()]


class PlanPDF:
    def __init__(self, path: Path):
        self.path = path
        self.c = canvas.Canvas(str(path), pagesize=A4)
        self.c.setTitle("Ernährungsplan Body Recomp 18.08.2026 – 07.01.2027")
        self.c.setAuthor("Fitness-Nutritionist Plan")
        self.c.setSubject("Täglicher Lidl-Ernährungsplan, 2100 kcal, min. 180 g Protein")
        self.page = 0
        self.total_hint = 160

    def new_page(self, footer: str | None = None):
        if self.page:
            self.c.showPage()
        self.page += 1
        self.c.setFillColor(PAPER)
        self.c.rect(0, 0, PAGE_W, PAGE_H, fill=1, stroke=0)
        self._footer(footer)

    def _footer(self, extra: str | None = None):
        self.c.setFillColor(FOREST)
        self.c.rect(0, 0, PAGE_W, 11 * mm, fill=1, stroke=0)
        self.c.setFillColor(HexColor("#E8D9A8"))
        self.c.setFont("Inter", 7.5)
        left = extra or "Nur Lidl  ·  2.100 kcal  ·  min. 180 g Protein  ·  alle Mengen roh/trocken"
        self.c.drawString(MARGIN, 4.2 * mm, left)
        self.c.drawRightString(PAGE_W - MARGIN, 4.2 * mm, f"Seite {self.page}")

    def _header_bar(self, title: str, subtitle: str = ""):
        self.c.setFillColor(FOREST)
        self.c.rect(0, PAGE_H - 28 * mm, PAGE_W, 28 * mm, fill=1, stroke=0)
        self.c.setFillColor(ACCENT)
        self.c.rect(0, PAGE_H - 28.8 * mm, PAGE_W, 1.6 * mm, fill=1, stroke=0)
        self.c.setFillColor(white)
        self.c.setFont("Inter-Bold", 16)
        self.c.drawString(MARGIN, PAGE_H - 14 * mm, title)
        if subtitle:
            self.c.setFont("Inter", 9)
            self.c.setFillColor(HexColor("#D5E5DC"))
            self.c.drawString(MARGIN, PAGE_H - 21.5 * mm, subtitle)

    def cover(self):
        self.new_page("Body-Recomp-Plan  ·  18.08.2026 – 07.01.2027")
        self.c.bookmarkPage("cover")
        self.c.setFillColor(FOREST)
        self.c.rect(0, 0, PAGE_W, PAGE_H, fill=1, stroke=0)
        self.c.setFillColor(ACCENT)
        self.c.rect(0, PAGE_H - 8 * mm, PAGE_W, 8 * mm, fill=1, stroke=0)
        self.c.rect(0, 0, PAGE_W, 8 * mm, fill=1, stroke=0)

        y = PAGE_H - 42 * mm
        self.c.setFillColor(HexColor("#E8D9A8"))
        self.c.setFont("Inter-Med", 11)
        self.c.drawString(MARGIN, y, "FITNESS  ·  NUTRITION  ·  NUR LIDL")
        y -= 16 * mm
        self.c.setFillColor(white)
        self.c.setFont("Inter-Bold", 28)
        self.c.drawString(MARGIN, y, "Ernährungsplan")
        y -= 12 * mm
        self.c.setFont("Inter-Bold", 28)
        self.c.drawString(MARGIN, y, "Body Recomposition")
        y -= 14 * mm
        self.c.setFillColor(ACCENT)
        self.c.setFont("Inter-Semi", 14)
        self.c.drawString(MARGIN, y, "18. August 2026  –  7. Januar 2027")

        y -= 22 * mm
        box_h = 46 * mm
        self.c.setFillColor(FOREST_2)
        self.c.roundRect(MARGIN, y - box_h, PAGE_W - 2 * MARGIN, box_h, 6, fill=1, stroke=0)
        facts = [
            ("Körper", "90 kg  ·  180 cm  ·  25 Jahre"),
            ("Ziel", "Fettabbau + Muskelaufbau"),
            ("Täglich", "exakt ca. 2.100 kcal  ·  mind. 180 g Protein"),
            ("System", "4 rotierende Tage A–B–C–D, Start 18.08. = Tag A"),
        ]
        fy = y - 10 * mm
        for label, value in facts:
            self.c.setFillColor(ACCENT)
            self.c.setFont("Inter-Semi", 8.5)
            self.c.drawString(MARGIN + 8 * mm, fy, label.upper())
            self.c.setFillColor(white)
            self.c.setFont("Inter", 11)
            self.c.drawString(MARGIN + 38 * mm, fy, value)
            fy -= 9 * mm

        y = y - box_h - 16 * mm
        self.c.setFillColor(HexColor("#E8D9A8"))
        self.c.setFont("Inter-Semi", 11)
        self.c.drawString(MARGIN, y, "So nutzt du dieses PDF")
        y -= 8 * mm
        self.c.setFillColor(HexColor("#D5E5DC"))
        self.c.setFont("Inter", 10)
        lines = [
            "1. Blättere zum heutigen Datum (Lesezeichen links: Monat → Tag).",
            "2. Iss genau die vier Mahlzeiten: Frühstück, Mittag, Snack, Abend.",
            "3. Alle Grammzahlen mit der Küchenwaage abwiegen (roh / trocken).",
            "4. Einkaufen nur bei Lidl. Wöchentliche Liste steht am Ende.",
            "5. Die Tage A–B–C–D wiederholen sich bis zum 7. Januar 2027.",
        ]
        for line in lines:
            self.c.drawString(MARGIN, y, line)
            y -= 6.2 * mm

        self.c.setFillColor(ACCENT)
        self.c.setFont("Inter-Med", 9)
        self.c.drawString(MARGIN, 18 * mm, "143 Tage  ·  4 Mahlzeiten pro Tag  ·  Zubereitung max. 15–20 Minuten")

    def anleitung(self):
        self.new_page()
        self.c.bookmarkPage("anleitung")
        self._header_bar("Anleitung & feste Regeln", "Damit die 2.100 kcal und 180 g Protein wirklich stimmen")
        y = PAGE_H - 40 * mm
        rules = [
            ("Küchenwaage", "Schätzen zerstört die Vorgabe – vor allem bei Reis, Öl und Erdnussbutter. 5 g Öl = 1 kleiner Teelöffel, kein „Schuss“."),
            ("Rohgewicht", "Fleisch, Kartoffeln, Reis und Hafer immer roh bzw. trocken wiegen. Thunfisch abgetropft, Brot wie angegeben."),
            ("Frei erlaubt", "Wasser, ungesüßter Kaffee/Tee, Gewürze, Senf, Sojasauce, Zitrone, Chili, Knoblauchpulver, Kräuter."),
            ("Nicht im Plan", "Säfte, extra Brot, Nüsse „zwischendurch“, Fertigsaucen, panierte Filets, Mayo."),
            ("Gemüse", "Brokkoli, Gurke, Paprika, Spinat darfst du erhöhen. Nicht verringern. Bei Hunger: extra Gemüse, nicht extra Reis."),
            ("Training", "Kohlenhydrate (Reis/Kartoffeln/Hafer) um das Workout legen. Bei Abendsport einfach Mittag- und Abend-Beilage tauschen."),
            ("Batch-Cooking", "Sonntag 20 Min.: Reis für 3–4 Tage, 8–10 Eier hart, 600–800 g Hähnchen braten. Max. 3 Tage kühl lagern."),
            ("Tausch", "Hähnchen ↔ Pute 1:1. Skyr ↔ Magerquark 1:1. 55 g Reis trocken ≈ 250 g Kartoffeln."),
        ]
        for title, text in rules:
            self.c.setFillColor(FOREST)
            self.c.roundRect(MARGIN, y - 18 * mm, PAGE_W - 2 * MARGIN, 20 * mm, 4, fill=1, stroke=0)
            self.c.setFillColor(ACCENT)
            self.c.circle(MARGIN + 7 * mm, y - 8 * mm, 2.2 * mm, fill=1, stroke=0)
            self.c.setFillColor(white)
            self.c.setFont("Inter-Semi", 10.5)
            self.c.drawString(MARGIN + 13 * mm, y - 5.5 * mm, title)
            self.c.setFont("Inter", 8.7)
            self.c.setFillColor(HexColor("#D5E5DC"))
            self._wrap_text(text, MARGIN + 13 * mm, y - 12 * mm, PAGE_W - 2 * MARGIN - 18 * mm, 8.7, "Inter")
            y -= 23 * mm

    def _wrap_text(self, text: str, x: float, y: float, width: float, size: float, font: str, color=None):
        if color:
            self.c.setFillColor(color)
        self.c.setFont(font, size)
        words = text.split()
        line = ""
        for w in words:
            test = (line + " " + w).strip()
            if self.c.stringWidth(test, font, size) <= width:
                line = test
            else:
                self.c.drawString(x, y, line)
                y -= size + 2
                line = w
        if line:
            self.c.drawString(x, y, line)
        return y

    def vorlagen(self):
        for letter in "ABCD":
            plan = PLANS[letter]
            self.new_page(f"Vorlage Tag {letter}")
            if letter == "A":
                self.c.bookmarkPage("vorlagen")
                self.c.addOutlineEntry("Die 4 Tagesvorlagen", "vorlagen", level=0)
            self.c.bookmarkPage(f"vorlage-{letter}")
            self.c.addOutlineEntry(f"Tag {letter}", f"vorlage-{letter}", level=1)
            self._header_bar(
                f"Vorlage  ·  Tag {letter}",
                f"{plan['titel']}   ·   {plan['kcal']} kcal   ·   {plan['ew']} g Eiweiß",
            )
            self.c.setFillColor(PLAN_COLORS[letter])
            self.c.roundRect(PAGE_W - MARGIN - 22 * mm, PAGE_H - 22 * mm, 18 * mm, 12 * mm, 3, fill=1, stroke=0)
            self.c.setFillColor(white)
            self.c.setFont("Inter-Bold", 16)
            self.c.drawCentredString(PAGE_W - MARGIN - 13 * mm, PAGE_H - 18.2 * mm, letter)

            y = PAGE_H - 38 * mm
            for meal in plan["mahlzeiten"]:
                y = self._meal_block(y, meal, compact=False)

    def _meal_block(self, y: float, meal: dict, compact: bool = False) -> float:
        color = MEAL_COLORS[meal["name"]]
        item_h = 4.6 * mm if compact else 5.0 * mm
        prep_lines = 2 if not compact else 1
        h = 16 * mm + len(meal["items"]) * item_h + prep_lines * 4.4 * mm
        if y - h < 16 * mm:
            self.new_page()
            y = PAGE_H - 20 * mm
            h = 16 * mm + len(meal["items"]) * item_h + prep_lines * 4.4 * mm

        self.c.setFillColor(white)
        self.c.setStrokeColor(LINE)
        self.c.setLineWidth(0.6)
        self.c.roundRect(MARGIN, y - h, PAGE_W - 2 * MARGIN, h, 5, fill=1, stroke=1)
        self.c.setFillColor(color)
        self.c.rect(MARGIN, y - h, 2.4 * mm, h, fill=1, stroke=0)

        self.c.setFillColor(color)
        self.c.setFont("Inter-Bold", 11)
        self.c.drawString(MARGIN + 8 * mm, y - 7 * mm, meal["name"].upper())
        self.c.setFont("Inter-Med", 8.5)
        self.c.setFillColor(MUTED)
        self.c.drawString(MARGIN + 62 * mm, y - 7 * mm, f"{meal['zeit']} Zubereitung")
        self.c.setFillColor(FOREST)
        self.c.setFont("Inter-Semi", 9.5)
        self.c.drawRightString(
            PAGE_W - MARGIN - 6 * mm,
            y - 7 * mm,
            f"{meal['kcal']} kcal   ·   {meal['ew']} g Eiweiß",
        )

        iy = y - 14 * mm
        self.c.setFillColor(INK)
        self.c.setFont("Inter", 9.3 if not compact else 9)
        for item in meal["items"]:
            self.c.setFillColor(color)
            self.c.circle(MARGIN + 11 * mm, iy + 1.2 * mm, 1.05 * mm, fill=1, stroke=0)
            self.c.setFillColor(INK)
            self.c.drawString(MARGIN + 16 * mm, iy, item)
            iy -= item_h

        self.c.setFillColor(MUTED)
        self.c.setFont("Inter", 8)
        self._wrap_text(
            "Zubereitung: " + meal["zubereitung"],
            MARGIN + 8 * mm,
            iy - 1 * mm,
            PAGE_W - 2 * MARGIN - 16 * mm,
            8,
            "Inter",
            MUTED,
        )
        return y - h - 4.5 * mm

    def monatskalender(self):
        months = []
        for d in daterange(START, END):
            key = (d.year, d.month)
            if key not in months:
                months.append(key)

        self.new_page()
        self.c.bookmarkPage("monate")
        self._header_bar("Monatsübersicht", "Welcher Kalendertag welcher Plantag ist (A–B–C–D)")
        y = PAGE_H - 40 * mm
        self.c.setFont("Inter", 9)
        self.c.setFillColor(MUTED)
        self.c.drawString(
            MARGIN,
            y,
            "Start: Dienstag, 18.08.2026 = Tag A. Danach immer A → B → C → D → A …",
        )
        y -= 10 * mm

        cell = 9.2 * mm
        for year, month in months:
            days = [d for d in daterange(date(year, month, 1), date(year, month, 28) + timedelta(days=4)) if d.month == month]
            days = [d for d in days if START <= d <= END or d.month == month]
            # header
            if y < 70 * mm:
                self.new_page()
                self._header_bar("Monatsübersicht (Fortsetzung)")
                y = PAGE_H - 40 * mm
            self.c.setFillColor(FOREST)
            self.c.setFont("Inter-Bold", 12)
            self.c.drawString(MARGIN, y, f"{MONTHS[month]} {year}")
            y -= 7 * mm
            self.c.setFont("Inter-Semi", 7)
            self.c.setFillColor(MUTED)
            for i, wd in enumerate(["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]):
                self.c.drawCentredString(MARGIN + i * cell + cell / 2, y, wd)
            y -= 2 * mm
            # grid
            first = date(year, month, 1)
            start_col = first.weekday()
            row = 0
            col = 0
            # empty cells before
            grid_top = y
            for d in daterange(first, date(year + (month == 12), month % 12 + 1, 1) - timedelta(days=1)):
                col = d.weekday()
                row = (d.day + start_col - 1) // 7
                x = MARGIN + col * cell
                cy = grid_top - row * cell - cell
                in_range = START <= d <= END
                letter = plan_letter(d) if in_range else ""
                if in_range:
                    self.c.setFillColor(PLAN_COLORS[letter])
                    self.c.roundRect(x + 0.8 * mm, cy + 0.8 * mm, cell - 1.6 * mm, cell - 1.6 * mm, 2, fill=1, stroke=0)
                    self.c.setFillColor(white)
                    self.c.setFont("Inter-Bold", 8)
                    self.c.drawString(x + 1.6 * mm, cy + 4.8 * mm, f"{d.day}")
                    self.c.setFont("Inter-Semi", 7)
                    self.c.drawRightString(x + cell - 1.8 * mm, cy + 1.8 * mm, letter)
                else:
                    self.c.setStrokeColor(LINE)
                    self.c.setLineWidth(0.4)
                    self.c.setFillColor(HexColor("#EFEAE2"))
                    self.c.roundRect(x + 0.8 * mm, cy + 0.8 * mm, cell - 1.6 * mm, cell - 1.6 * mm, 2, fill=1, stroke=1)
                    self.c.setFillColor(MUTED)
                    self.c.setFont("Inter", 7.5)
                    self.c.drawString(x + 1.6 * mm, cy + 3.5 * mm, f"{d.day}")
            rows = row + 1
            y = grid_top - rows * cell - 8 * mm

        # legend
        self.c.setFont("Inter-Semi", 9)
        self.c.setFillColor(FOREST)
        self.c.drawString(MARGIN, y, "Legende")
        y -= 8 * mm
        x = MARGIN
        for letter in "ABCD":
            p = PLANS[letter]
            self.c.setFillColor(PLAN_COLORS[letter])
            self.c.roundRect(x, y - 2 * mm, 8 * mm, 8 * mm, 2, fill=1, stroke=0)
            self.c.setFillColor(white)
            self.c.setFont("Inter-Bold", 10)
            self.c.drawCentredString(x + 4 * mm, y + 0.6 * mm, letter)
            self.c.setFillColor(INK)
            self.c.setFont("Inter", 8)
            self.c.drawString(x + 10 * mm, y + 0.8 * mm, f"{p['kcal']} kcal · {p['ew']} g EW")
            x += 48 * mm

    def tagesseiten(self):
        current_month = None
        for d in daterange(START, END):
            letter = plan_letter(d)
            plan = PLANS[letter]
            month_key = (d.year, d.month)
            self._day_page(d, letter, plan, is_new_month=month_key != current_month)
            current_month = month_key

    def _day_page(self, d: date, letter: str, plan: dict, is_new_month: bool = False):
        self.new_page(f"{fmt_date_short(d)}  ·  Tag {letter}  ·  {weekday_name(d)}")
        if is_new_month:
            month_dest = f"monat-{d.year}-{d.month:02d}"
            self.c.bookmarkPage(month_dest)
            self.c.addOutlineEntry(f"{MONTHS[d.month]} {d.year}", month_dest, level=0)
        key = f"tag-{d.isoformat()}"
        self.c.bookmarkPage(key)
        self.c.addOutlineEntry(f"{fmt_date_short(d)}  {weekday_name(d)}  ·  Tag {letter}", key, level=1)

        # top banner
        self.c.setFillColor(FOREST)
        self.c.rect(0, PAGE_H - 32 * mm, PAGE_W, 32 * mm, fill=1, stroke=0)
        self.c.setFillColor(PLAN_COLORS[letter])
        self.c.rect(0, PAGE_H - 33.4 * mm, PAGE_W, 1.8 * mm, fill=1, stroke=0)

        self.c.setFillColor(HexColor("#E8D9A8"))
        self.c.setFont("Inter-Med", 9)
        self.c.drawString(MARGIN, PAGE_H - 10 * mm, weekday_name(d).upper())
        self.c.setFillColor(white)
        self.c.setFont("Inter-Bold", 20)
        self.c.drawString(MARGIN, PAGE_H - 19.5 * mm, fmt_date(d))
        self.c.setFont("Inter", 9)
        self.c.setFillColor(HexColor("#D5E5DC"))
        self.c.drawString(MARGIN, PAGE_H - 27 * mm, f"{plan['kcal']} kcal   ·   {plan['ew']} g Eiweiß   ·   {plan['titel']}")

        # letter badge
        self.c.setFillColor(PLAN_COLORS[letter])
        self.c.roundRect(PAGE_W - MARGIN - 24 * mm, PAGE_H - 24 * mm, 20 * mm, 14 * mm, 4, fill=1, stroke=0)
        self.c.setFillColor(white)
        self.c.setFont("Inter-Bold", 18)
        self.c.drawCentredString(PAGE_W - MARGIN - 14 * mm, PAGE_H - 19.2 * mm, letter)

        y = PAGE_H - 38 * mm
        for meal in plan["mahlzeiten"]:
            y = self._day_meal(y, meal)

    def _day_meal(self, y: float, meal: dict) -> float:
        color = MEAL_COLORS[meal["name"]]
        rows = len(meal["items"])
        h = 28 * mm + rows * 5.1 * mm
        self.c.setFillColor(white)
        self.c.setStrokeColor(LINE)
        self.c.setLineWidth(0.7)
        self.c.roundRect(MARGIN, y - h, PAGE_W - 2 * MARGIN, h, 6, fill=1, stroke=1)
        self.c.setFillColor(color)
        self.c.roundRect(MARGIN, y - 11 * mm, PAGE_W - 2 * MARGIN, 11 * mm, 6, fill=1, stroke=0)
        self.c.rect(MARGIN, y - 11 * mm, PAGE_W - 2 * MARGIN, 6 * mm, fill=1, stroke=0)

        self.c.setFillColor(white)
        self.c.setFont("Inter-Bold", 12)
        self.c.drawString(MARGIN + 6 * mm, y - 7.4 * mm, meal["name"])
        self.c.setFont("Inter", 9)
        self.c.drawRightString(
            PAGE_W - MARGIN - 6 * mm,
            y - 7.4 * mm,
            f"{meal['kcal']} kcal   ·   {meal['ew']} g Eiweiß   ·   {meal['zeit']}",
        )

        iy = y - 17.2 * mm
        self.c.setFont("Inter", 10.2)
        for item in meal["items"]:
            self.c.setFillColor(color)
            self.c.circle(MARGIN + 10 * mm, iy + 1.4 * mm, 1.3 * mm, fill=1, stroke=0)
            self.c.setFillColor(INK)
            self.c.drawString(MARGIN + 16 * mm, iy, item)
            iy -= 5.1 * mm

        self.c.setFillColor(MUTED)
        self.c.setFont("Inter", 8)
        self._wrap_text(
            meal["zubereitung"],
            MARGIN + 6 * mm,
            iy - 0.5 * mm,
            PAGE_W - 2 * MARGIN - 12 * mm,
            8,
            "Inter",
            MUTED,
        )
        return y - h - 3.8 * mm

    def einkauf(self):
        self.new_page("Wöchentliche Lidl-Einkaufsliste")
        self.c.bookmarkPage("einkauf")
        self._header_bar(
            "Wöchentliche Lidl-Einkaufsliste",
            "Für die Standardwoche A–B–C–D–A–B–C  (2×A, 2×B, 2×C, 1×D)",
        )
        cats = [
            (
                "Kühlregal",
                [
                    "Milbona Magerquark 0,2 % — 1.450 g (3× 500 g)",
                    "Körniger Frischkäse Light — 960 g (2× 500 g)",
                    "Milbona Skyr 0,2 % — 700 g (2× 500 g)",
                    "Hähnchenbrustfilet — 940 g (1-kg-Packung)",
                    "Rinderhack 5 % — 580 g",
                    "Putenbrustfilet — 400 g",
                    "Eier Größe M — 8 Stück (10er-Pack)",
                    "Frischmilch 1,5 % — 300 ml (1-Liter-Packung reicht länger)",
                    "Milbona High Protein Pudding — 2 Becher à 200 g",
                    "Milbona High Protein Drink 330 ml — 2 Flaschen",
                ],
            ),
            (
                "Trockenwaren",
                [
                    "Crownfield Haferflocken — 380 g",
                    "Golden Sun Basmati — 520 g (1-kg-Sack für 2 Wochen)",
                    "Vollkornbrot — 160 g (1 Laib, Rest einfrieren)",
                    "Weizen-Wraps — 2 Stück (Packung, Rest einfrieren)",
                    "Maiskonserve — 180 g abgetropft (2 Dosen)",
                    "Thunfisch im eigenen Saft — 360 g abgetropft (3 Dosen)",
                    "Erdnussbutter — 20 g (1 Glas hält Wochen)",
                    "Olivenöl — ca. 70 ml",
                    "Gewürze, Senf, Sojasauce, Zitrone — nach Bedarf",
                ],
            ),
            (
                "Tiefkühl",
                [
                    "TK-Brokkoli — 1.100 g",
                    "TK-Gemüsemischung — 1.150 g",
                    "TK-Beerenmischung — 460 g",
                    "TK-Blattspinat — 500 g",
                    "Lachsfilet TK (Ocean Sea) — 360 g",
                ],
            ),
            (
                "Obst / Gemüse",
                [
                    "Kartoffeln — 1,2 kg (nimm 1,5–2-kg-Sack)",
                    "Bananen — ca. 450 g (5 Stück)",
                    "Äpfel — ca. 510 g (4 Stück)",
                    "Paprika — 360 g (3 Stück)",
                    "Gurke — 350 g (2 Stück)",
                    "Tomaten — 200 g (2–3 Stück)",
                    "Rucola — 100 g",
                    "Zwiebeln — 300 g (für alle Pfannen)",
                ],
            ),
        ]
        y = PAGE_H - 40 * mm
        col_w = (PAGE_W - 2 * MARGIN - 6 * mm) / 2
        positions = [
            (MARGIN, y),
            (MARGIN + col_w + 6 * mm, y),
            (MARGIN, y - 118 * mm),
            (MARGIN + col_w + 6 * mm, y - 118 * mm),
        ]
        box_h = 112 * mm
        for i, ((title, items), (x, top)) in enumerate(zip(cats, positions)):
            self.c.setFillColor(white)
            self.c.setStrokeColor(LINE)
            self.c.roundRect(x, top - box_h, col_w, box_h, 5, fill=1, stroke=1)
            self.c.setFillColor(FOREST)
            self.c.roundRect(x, top - 11 * mm, col_w, 11 * mm, 5, fill=1, stroke=0)
            self.c.rect(x, top - 11 * mm, col_w, 6 * mm, fill=1, stroke=0)
            self.c.setFillColor(white)
            self.c.setFont("Inter-Bold", 11)
            self.c.drawString(x + 5 * mm, top - 7.5 * mm, title)
            iy = top - 18 * mm
            self.c.setFont("Inter", 8.2)
            for item in items:
                self.c.setFillColor(ACCENT)
                self.c.circle(x + 6 * mm, iy + 1.2 * mm, 1.1 * mm, fill=1, stroke=0)
                self.c.setFillColor(INK)
                self._wrap_text(item, x + 10 * mm, iy, col_w - 14 * mm, 8.2, "Inter", INK)
                iy -= 8.6 * mm

        self.c.setFillColor(FOREST)
        self.c.setFont("Inter-Semi", 8.5)
        self.c.drawString(
            MARGIN,
            18 * mm,
            "Grundvorrat alle 3–4 Wochen: Hafer 1 kg, Basmati 2 kg, Öl, Erdnussbutter, Gewürze.",
        )

    def save(self):
        self.c.save()


def main():
    out = Path(__file__).resolve().parent / "Ernaehrungsplan_18-08-2026_bis_07-01-2027.pdf"
    pdf = PlanPDF(out)
    pdf.cover()
    pdf.c.addOutlineEntry("Deckblatt", "cover", level=0)

    pdf.anleitung()
    pdf.c.addOutlineEntry("Anleitung", "anleitung", level=0)

    pdf.vorlagen()

    pdf.monatskalender()
    pdf.c.addOutlineEntry("Monatsübersicht", "monate", level=0)

    pdf.tagesseiten()

    pdf.einkauf()
    pdf.c.addOutlineEntry("Einkaufsliste", "einkauf", level=0)

    pdf.save()
    print(f"PDF geschrieben: {out}")
    print(f"Seiten: {pdf.page}")


if __name__ == "__main__":
    main()
