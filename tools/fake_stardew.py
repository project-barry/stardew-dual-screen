#!/usr/bin/env python3
"""A stand-in for Stardew Valley running the Stardew Valley Dual Screen Mod
(by Profmags, https://github.com/JoeCorrell/AYN-Thor-Dualscreen-Mods), to try
the Barry app without the game. It listens on ws://127.0.0.1:7786 as the mod
does, sends a made-up farm in the mod's messages (docs/protocol.md), and acts
on the app's commands. The clock runs.

  python3 tools/fake_stardew.py [--port 7786] [--old]

--old leaves out what the mod added in 2.0 (crafting details and the
craft_recipe command, villager positions, the farmer picture), like a 0.3
mod.

Everything here is invented: the farm, the people and the pictures, which
are simple shapes drawn here. Nothing is taken from the game.
"""
import argparse
import base64
import hashlib
import json
import math
import socket
import struct
import threading
import time
import zlib

GUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"


# --- Pictures -----------------------------------------------------------------

def png(w, h, pixel):
    """A PNG of w x h, with pixel(x, y) -> (r, g, b, a)."""
    rows = b"".join(b"\0" + bytes(c for x in range(w) for c in pixel(x, y)) for y in range(h))

    def chunk(kind, data):
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data))
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(rows)) + chunk(b"IEND", b""))


def hue(name):
    """A colour from a name, the same every time."""
    d = hashlib.md5(name.encode()).digest()
    return d[0] // 2 + 90, d[1] // 2 + 90, d[2] // 2 + 90


def icon(name):
    """A 16 x 16 item: a round blob in the name's colour, outlined."""
    r, g, b = hue(name)

    def px(x, y):
        d = math.hypot(x - 7.5, y - 8)
        if d < 5.5:
            shade = 1.25 if (x < 7 and y < 7) else 1
            return min(255, int(r * shade)), min(255, int(g * shade)), min(255, int(b * shade)), 255
        if d < 6.8:
            return 60, 30, 20, 255
        return 0, 0, 0, 0
    return png(16, 16, px)


def face(name, size=64):
    """A portrait: a face in the name's colour on a light frame."""
    r, g, b = hue(name)

    def px(x, y):
        u, v = x / size, y / size
        if math.hypot(u - .5, v - .48) < .3:
            if math.hypot(u - .4, v - .42) < .04 or math.hypot(u - .6, v - .42) < .04:
                return 40, 25, 20, 255
            if abs(v - .6) < .02 and abs(u - .5) < .1:
                return 120, 40, 40, 255
            return 240, 200, 160, 255
        if v < .5 and math.hypot(u - .5, v - .4) < .36:
            return r, g, b, 255
        return 0, 0, 0, 0
    return png(size, size, px)


def panel(w, h, border, fill=(250, 222, 160), edge=(140, 70, 30)):
    def px(x, y):
        e = min(x, y, w - 1 - x, h - 1 - y)
        if e < border // 3:
            return edge + (255,)
        if e < border // 2:
            return 205, 120, 50, 255
        return fill + (255,)
    return png(w, h, px)


def tile(base, seed):
    """A 16 x 16 ground tile: base colour with a little speckle."""
    def px(x, y):
        n = (x * 7 + y * 13 + seed * 31) % 11
        k = 0.85 if n < 2 else 1.1 if n > 8 else 1
        return tuple(min(255, int(c * k)) for c in base) + (255,)
    return png(16, 16, px)


def world_map():
    """300 x 180: grass, a river, a path, the farm, the town and the beach."""
    def px(x, y):
        if y > 150 + 6 * math.sin(x / 20):
            return (230, 210, 150, 255) if y < 160 + 6 * math.sin(x / 20) else (60, 120, 200, 255)
        if abs(x - 200 - 12 * math.sin(y / 15)) < 5:
            return 70, 130, 210, 255
        if abs(y - 95) < 2 or abs(x - 120) < 2:
            return 200, 170, 110, 255
        if 20 < x < 100 and 20 < y < 80:
            return 130, 90, 50, 255
        if 220 < x < 290 and 40 < y < 110:
            return (180, 80, 60, 255) if (x // 10 + y // 10) % 2 else (150, 150, 150, 255)
        return 90, 160, 70, 255
    return png(300, 180, px)


def tab(n):
    colours = [(200, 140, 60), (90, 170, 90), (220, 90, 120), (90, 140, 220),
               (170, 120, 80), (230, 200, 90), (150, 150, 160)]
    c = colours[n % len(colours)]

    def px(x, y):
        if 2 <= x <= 13 and 2 <= y <= 13:
            return c + (255,) if 3 <= x <= 12 and 3 <= y <= 12 else (90, 45, 20, 255)
        return 0, 0, 0, 0
    return png(16, 16, px)


def heart(full):
    shape = ["0110110", "1111111", "1111111", "0111110", "0011100", "0001000"]

    def px(x, y):
        if shape[y][x] == "1":
            return (220, 40, 60, 255) if full else (120, 90, 90, 255)
        return 0, 0, 0, 0
    return png(7, 6, px)


def ui_sprites(season):
    s = {
        "ui:panel": (panel(60, 60, 20), 20),
        "ui:slot": (panel(64, 64, 12, (240, 200, 140), (170, 100, 50)), 0),
        "ui:slot_selected": (panel(64, 64, 12, (255, 235, 150), (220, 60, 40)), 0),
        "ui:heart": (heart(True), 0),
        "ui:heart_empty": (heart(False), 0),
        "ui:coin": (png(20, 16, lambda x, y: (240, 190, 40, 255) if math.hypot(x - 10, y - 8) < 7 else (0, 0, 0, 0)), 0),
        "ui:button": (panel(9, 9, 3), 3),
        "ui:map": (world_map(), 0),
        "ui:player": (face("farmer"), 0),
        "ui:farmer": (face("farmer", 32), 0),
        "ui:pet": (icon("pet"), 0),
        "ui:ground": (tile({"Spring": (110, 170, 80), "Summer": (90, 160, 60),
                            "Fall": (170, 120, 60), "Winter": (220, 230, 240)}[season], 0), 0),
    }
    for i, name in enumerate(["backpack", "skills", "relationships", "map", "crafting", "journal", "settings"]):
        s["ui:tab_" + name] = (tab(i), 0)
    return s


GROUNDS = [("walls_and_floors", (150, 110, 80)), ("spring", (110, 170, 80)), ("summer", (90, 160, 60)),
           ("fall", (170, 120, 60)), ("winter", (220, 230, 240)), ("spring", (190, 170, 120))]


# --- The made-up farm ----------------------------------------------------------

ITEMS = {
    "(T)Hoe": ("Hoe", "Tool"), "(T)WateringCan": ("Watering Can", "Tool"),
    "(T)Axe": ("Axe", "Tool"), "(T)Pickaxe": ("Pickaxe", "Tool"), "(W)0": ("Rusty Sword", "Weapon"),
    "(O)24": ("Parsnip", "Vegetable"), "(O)472": ("Parsnip Seeds", "Seed"),
    "(O)388": ("Wood", "Resource"), "(O)390": ("Stone", "Resource"), "(O)16": ("Wild Horseradish", "Forage"),
    "(O)18": ("Daffodil", "Forage"), "(O)20": ("Leek", "Forage"), "(O)22": ("Dandelion", "Forage"),
    "(O)78": ("Cave Carrot", "Forage"), "(O)330": ("Clay", "Resource"), "(O)334": ("Copper Bar", "Resource"),
    "(O)378": ("Copper Ore", "Resource"), "(O)382": ("Coal", "Resource"), "(O)196": ("Salad", "Cooking"),
    "(O)176": ("Egg", "Animal Product"), "(O)184": ("Milk", "Animal Product"), "(O)613": ("Apple", "Fruit"),
    "(O)72": ("Diamond", "Mineral"), "(O)96": ("Dwarf Scroll I", "Artifact"), "(BC)13": ("Furnace", "Crafting"),
    "(BC)12": ("Keg", "Crafting"), "(O)346": ("Beer", "Artisan Goods"), "(BC)15": ("Preserves Jar", "Crafting"),
    "(O)344": ("Jelly", "Artisan Goods"), "(O)286": ("Cherry Bomb", "Bomb"), "(O)298": ("Hardwood Fence", "Crafting"),
    "(O)322": ("Wood Fence", "Crafting"), "(BC)143": ("Torch", "Crafting"), "(O)401": ("Straw Floor", "Crafting"),
    "(O)262": ("Wheat", "Vegetable"), "(O)304": ("Hops", "Vegetable"), "(O)766": ("Slime", "Monster Loot"),
}

VILLAGERS = [
    # name, birthday season, day, hearts, location, map x, y (thousandths)
    ("Abby", "Spring", 4, 3, "Pierre's General Store", 760, 470),
    ("Bram", "Spring", 9, 5, "The Beach", 620, 860),
    ("Cora", "Spring", 18, 1, "Town Square", 800, 540),
    ("Dale", "Summer", 2, 7, "Cindersap Forest", 230, 700),
    ("Edie", "Spring", 26, 2, "The Mountain", 640, 160),
    ("Finn", "Fall", 13, 0, "", -1, -1),
    ("Gwen", "Winter", 21, 9, "Saloon", 830, 500),
]

LOVES = {
    "Abby": ["(O)72", "(O)613", "(O)196"], "Bram": ["(O)346", "(O)24"], "Cora": ["(O)18", "(O)22", "(O)72"],
    "Dale": ["(O)334", "(O)382"], "Edie": ["(O)344", "(O)176"], "Finn": ["(O)78"], "Gwen": ["(O)346", "(O)184"],
}

RECIPES = [
    # key, product, count, description, [(ingredient, needed)]
    ("Furnace", "(BC)13", 1, "Turns ore and coal into metal bars.", [("(O)378", 20), ("(O)390", 25)]),
    ("Keg", "(BC)12", 1, "Place a fruit or vegetable in here. Eventually it will turn into a beverage.",
     [("(O)388", 30), ("(O)334", 1)]),
    ("Preserves Jar", "(BC)15", 1, "Turns produce into jams and pickles.", [("(O)388", 50), ("(O)390", 40), ("(O)382", 8)]),
    ("Torch", "(BC)143", 1, "Provides a modest amount of light.", [("(O)388", 1), ("(O)766", 2)]),
    ("Wood Fence", "(O)322", 1, "Keeps grass and animals in.", [("(O)388", 2)]),
    ("Cherry Bomb", "(O)286", 1, "Generates a small explosion. Stand back!", [("(O)378", 4), ("(O)382", 1)]),
    ("Straw Floor", "(O)401", 1, "Place on the ground to create paths.", [("(O)388", 1), ("(O)262", 1)]),
]


class Farm:
    def __init__(self, old):
        self.old = old
        self.lock = threading.Lock()
        self.time = 620
        self.day, self.season, self.year = 12, "Spring", 1
        self.gold = 4250
        self.energy, self.health = 214, 100
        self.selected = 1
        self.capacity = 36
        self.config = {k: True for k in ["hideGameHud", "allowInventoryEdits", "allowQuestCancel", "farmerMarker",
                                         "sendCrops", "sendMachines", "sendAnimals", "sendBundles", "sendVillagers",
                                         "sendMap", "sendCrafting"]}
        slots = ["(T)Hoe", "(T)WateringCan", "(T)Axe", "(T)Pickaxe", "(W)0", ("(O)472", 15), ("(O)24", 7),
                 ("(O)196", 2), None, ("(O)388", 143), ("(O)390", 87), ("(O)382", 5),
                 ("(O)16", 3), ("(O)18", 5), ("(O)20", 2), None, ("(O)334", 4), ("(O)378", 31),
                 ("(O)176", 6), ("(O)184", 2), ("(O)613", 3), ("(O)72", 1), ("(O)96", 1), None,
                 ("(O)766", 12), ("(O)262", 18), ("(O)330", 4), None, None, None, None, None, None, None, None, None]
        self.items = []
        for s in slots:
            if s is None:
                self.items.append(None)
            elif isinstance(s, str):
                self.items.append({"id": s, "count": 1, "quality": 0})
            else:
                self.items.append({"id": s[0], "count": s[1], "quality": 2 if s[0] == "(O)24" else 0})
        self.water = 31
        self.quests = [
            {"title": "Getting Started", "detail": "If you want to become a farmer, you have to start with the basics.",
             "objective": "Cultivate and harvest a parsnip.", "daysLeft": -1, "reward": 100, "daily": False,
             "cancellable": False, "complete": False},
            {"title": "Item Delivery", "detail": "Bram wants a cold Beer. \"It's for a friend,\" he says.",
             "objective": "Bring Bram a Beer.", "daysLeft": 2, "reward": 240, "daily": True,
             "cancellable": True, "complete": False},
            {"title": "Gathering", "detail": "Cora needs 20 Wood for a birdhouse.",
             "objective": "Gather 20 Wood for Cora: 0/20", "daysLeft": 1, "reward": 180, "daily": True,
             "cancellable": True, "complete": False},
        ]
        self.shipped = [("(O)24", 5), ("(O)16", 2)]

    def tick(self):
        with self.lock:
            self.time += 10
            if self.time % 100 == 60:
                self.time += 40
            if self.time >= 2600:
                self.time, self.day = 600, self.day % 28 + 1
            self.energy = max(0, self.energy - 1)
            if self.water > 0 and self.time % 30 == 0:
                self.water -= 1

    def clock(self):
        return self.time

    # Messages, as the mod sends them ("1"/"0" for flags, as it does).
    def msg(self, kind, **fields):
        return json.dumps({"type": kind, **fields})

    @staticmethod
    def flag(v):
        return "1" if v else "0"

    def day_msg(self):
        extra = {} if self.old else {"playerName": "Sam", "farmName": "Clover", "playerLevel": 6,
                                     "totalEarnings": 18890}
        return self.msg("sdv_day", season=self.season, day=self.day, year=self.year,
                        weekday=["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"][
                            (self.day - 1) % 7], timeOfDay=self.time, weatherToday="Sunny",
                        weatherTomorrow="Rain", gold=self.gold, energy=self.energy, maxEnergy=270,
                        health=self.health, maxHealth=100, location="Clover Farm", luck=48, mapX=210, mapY=290,
                        **extra)

    def inventory_msg(self):
        out = []
        for i, it in enumerate(self.items):
            if it is None:
                out.append({"slot": i, "id": ""})
                continue
            name, cat = ITEMS[it["id"]]
            can = it["id"] == "(T)WateringCan"
            sword = it["id"] == "(W)0"
            out.append({"slot": i, "id": it["id"], "name": name, "count": it["count"], "quality": it["quality"],
                        "water": self.water if can else -1, "waterMax": 40 if can else 0,
                        "bottomless": "0", "cooldownMs": 0 if sword else -1, "cooldownMax": 4000 if sword else 0,
                        "category": cat})
        return self.msg("sdv_inventory", selected=self.selected, capacity=self.capacity, items=out)

    def count(self, qid):
        return sum(it["count"] for it in self.items if it and it["id"] == qid)

    def take(self, qid, n):
        for it in self.items:
            if it and it["id"] == qid and n > 0:
                k = min(n, it["count"])
                it["count"] -= k
                n -= k
        self.items = [it if it and it["count"] > 0 else None for it in self.items]

    def give(self, qid, n):
        for it in self.items:
            if it and it["id"] == qid:
                it["count"] += n
                return True
        for i, it in enumerate(self.items[:self.capacity]):
            if it is None:
                self.items[i] = {"id": qid, "count": n, "quality": 0}
                return True
        return False

    def crafting_msg(self):
        out = []
        for key, product, n, desc, needs in RECIPES:
            ready = all(self.count(q) >= k for q, k in needs)
            if self.old:
                if ready:
                    out.append({"id": product, "name": ITEMS[product][0]})
                continue
            out.append({"id": product, "name": ITEMS[product][0], "key": key, "description": desc,
                        "ready": self.flag(ready), "crafted": 2 if key == "Torch" else 0, "outputCount": n,
                        "ingredients": [{"id": q, "name": ITEMS[q][0], "have": self.count(q), "required": k}
                                        for q, k in needs]})
        return self.msg("sdv_crafting", recipes=out)

    def villagers_msg(self):
        out = []
        order = {"Spring": 0, "Summer": 1, "Fall": 2, "Winter": 3}
        for name, season, bday, hearts, place, x, y in VILLAGERS:
            days = order[season] * 28 + bday - (order[self.season] * 28 + self.day)
            if days < 0:
                days += 112
            v = {"name": name, "npc": name, "hearts": hearts, "maxHearts": 10, "birthdaySeason": season,
                 "birthdayDay": bday, "birthdayIn": days, "giftsThisWeek": 1 if name == "Abby" else 0,
                 "talkedToday": self.flag(name in ("Abby", "Gwen"))}
            if not self.old:
                v.update(location=place, mapX=x, mapY=y)
            out.append(v)
        return self.msg("sdv_villagers", villagers=out)

    def gifts_msg(self):
        out = []
        for name, *_ in VILLAGERS:
            loves = [{"id": q, "name": ITEMS[q][0], "carried": self.flag(self.count(q) > 0)} for q in LOVES[name]]
            out.append({"name": name, "carrying": self.flag(any(self.count(q) for q in LOVES[name])), "loves": loves})
        return self.msg("sdv_gifts", villagers=out)

    def quests_msg(self):
        return self.msg("sdv_quests", quests=[
            {"index": i, **{k: (self.flag(v) if isinstance(v, bool) else v) for k, v in q.items()}}
            for i, q in enumerate(self.quests)])

    def config_msg(self):
        return self.msg("sdv_config", **{k: self.flag(v) for k, v in self.config.items()})

    def everything(self):
        c = self.config
        f = self.flag
        msgs = [self.msg("game_info", gameId="stardew", saveName="Clover"), self.config_msg()]
        msgs.append(self.msg("sdv_grounds", grounds=[{"id": "ui:ground:%s:%d:0" % (n, i * 16)}
                                                     for i, (n, _) in enumerate(GROUNDS)]))
        msgs += [self.day_msg(), self.inventory_msg(), self.quests_msg()]
        msgs.append(self.villagers_msg() if c["sendVillagers"] else self.msg("sdv_villagers", villagers=[]))
        crops = []
        if c["sendCrops"]:
            for i in range(14):
                crops.append({"id": "(O)24", "name": "Parsnip", "location": "Farm", "daysLeft": 0 if i < 4 else 2,
                              "needsWater": f(i % 3 == 0), "ready": f(i < 4)})
            for i in range(9):
                crops.append({"id": "(O)262", "name": "Wheat", "location": "Farm", "daysLeft": 3,
                              "needsWater": f(i < 5), "ready": "0"})
            crops.append({"id": "(O)304", "name": "Hops", "location": "Greenhouse", "daysLeft": 6,
                          "needsWater": "0", "ready": "0"})
        msgs.append(self.msg("sdv_crops", crops=crops))
        msgs.append(self.msg("sdv_skills", farming=4, mining=3, foraging=2, fishing=1, combat=2, farmingNext=130,
                             miningNext=280, foragingNext=210, fishingNext=270, combatNext=95))
        machines = []
        if c["sendMachines"]:
            machines = [
                {"id": "(BC)12", "name": "Keg", "outputId": "(O)346", "output": "Beer", "count": 1,
                 "location": "Farm", "minutes": 0, "ready": "1"},
                {"id": "(BC)12", "name": "Keg", "outputId": "(O)346", "output": "Beer", "count": 1,
                 "location": "Farm", "minutes": 1260, "ready": "0"},
                {"id": "(BC)15", "name": "Preserves Jar", "outputId": "(O)344", "output": "Apple Jelly", "count": 1,
                 "location": "Shed", "minutes": 2900, "ready": "0"},
                {"id": "(BC)13", "name": "Furnace", "outputId": "(O)334", "output": "Copper Bar", "count": 1,
                 "location": "Farm", "minutes": 20, "ready": "0"},
            ]
        msgs.append(self.msg("sdv_machines", machines=machines))
        bundles = []
        if c["sendBundles"]:
            bundles = [
                {"room": "Crafts Room", "name": "Spring Foraging", "have": 2, "required": 4, "missing": [
                    {"id": "(O)20", "name": "Leek", "count": 1, "quality": 0, "carried": "1"},
                    {"id": "(O)22", "name": "Dandelion", "count": 1, "quality": 0, "carried": "0"}]},
                {"room": "Pantry", "name": "Spring Crops", "have": 1, "required": 4, "missing": [
                    {"id": "(O)24", "name": "Parsnip", "count": 1, "quality": 0, "carried": "1"},
                    {"id": "(O)262", "name": "Wheat", "count": 1, "quality": 0, "carried": "1"},
                    {"id": "(O)304", "name": "Hops", "count": 1, "quality": 0, "carried": "0"}]},
                {"room": "Pantry", "name": "Animal", "have": 3, "required": 5, "missing": [
                    {"id": "(O)176", "name": "Egg", "count": 1, "quality": 0, "carried": "1"},
                    {"id": "(O)184", "name": "Milk", "count": 1, "quality": 2, "carried": "0"}]},
                {"room": "Vault", "name": "2,500g", "have": 0, "required": 1, "missing": [
                    {"id": "", "name": "2,500g", "count": 1, "quality": 0, "carried": f(self.gold >= 2500)}]},
            ]
        msgs.append(self.msg("sdv_bundles", bundles=bundles))
        animals = []
        if c["sendAnimals"]:
            for name, kind, hearts, petted, produce in [("Clucky", "White Chicken", 3, True, "(O)176"),
                                                        ("Nugget", "Brown Chicken", 2, False, ""),
                                                        ("Daisy", "Cow", 4, False, "(O)184")]:
                a = {"name": name, "type": kind, "hearts": hearts, "petted": f(petted), "baby": "0",
                     "produceId": produce, "produce": ITEMS[produce][0] if produce else ""}
                if not self.old:
                    a["spriteId"] = "animal:" + kind
                animals.append(a)
        msgs.append(self.msg("sdv_animals", animals=animals))
        msgs.append(self.gifts_msg() if c["sendVillagers"] else self.msg("sdv_gifts", villagers=[]))
        msgs.append(self.crafting_msg() if c["sendCrafting"] else self.msg("sdv_crafting", recipes=[]))
        msgs.append(self.msg("sdv_calendar", season=self.season, today=self.day, days=[
            {"day": d, "festival": fest, "festivalWhen": when, "festivalWhere": where,
             "names": ", ".join(n for n, s, b, *_ in VILLAGERS if s == self.season and b == d),
             "npc": next((n for n, s, b, *_ in VILLAGERS if s == self.season and b == d), "")}
            for d, fest, when, where in [(4, "", "", ""), (9, "", "", ""), (13, "Egg Festival", "9am to 2pm", "Town"),
                                         (18, "", "", ""), (24, "Flower Dance", "9am to 2pm", "Forest"),
                                         (26, "", "", "")]]))
        msgs.append(self.msg("sdv_cart", open=f((self.day - 1) % 7 in (4, 6))))
        msgs.append(self.msg("sdv_orders", orders=[
            {"title": "Cave Patrol", "objective": "Slay 120 monsters in the mines: 37/120", "daysLeft": 5}]))
        msgs.append(self.msg("sdv_cooking", recipes=[{"id": "(O)196", "name": "Salad"}]))
        msgs.append(self.msg("sdv_shipping", total=sum(5 * 35 if q == "(O)24" else 50 for q, _ in self.shipped) + 120,
                             items=[{"id": q, "name": ITEMS[q][0], "count": n, "worth": n * 35}
                                    for q, n in self.shipped]))
        msgs.append(self.msg("sdv_trees", trees=[{"id": "(O)613", "name": "Apple", "location": "Farm", "count": 2}]
                             if c["sendCrops"] else []))
        msgs.append(self.msg("sdv_pet", name="Biscuit", petted="0", bowl="1"))
        msgs.append(self.msg("sdv_mines", deepest=47, skull=0))
        msgs.append(self.msg("sdv_collections", donated=12, total=95, carried=[
            {"id": "(O)72", "name": "Diamond"}, {"id": "(O)96", "name": "Dwarf Scroll I"}]))
        return msgs

    def sprites(self):
        """Every picture, as the mod sends them the first time."""
        out = []
        for sid, (data, inset) in ui_sprites(self.season).items():
            if self.old and (sid in ("ui:farmer", "ui:pet") or sid.startswith("ui:tab_")):
                continue
            out.append(json.dumps({"type": "sdv_sprite", "id": sid, "inset": inset, "insetX": inset,
                                   "insetY": 0 if sid == "ui:scroll" else inset,
                                   "png": base64.b64encode(data).decode()}))
        for i, (n, base) in enumerate(GROUNDS):
            out.append(json.dumps({"type": "sdv_sprite", "id": "ui:ground:%s:%d:0" % (n, i * 16), "inset": 0,
                                   "png": base64.b64encode(tile(base, i)).decode()}))
        for qid in ITEMS:
            out.append(json.dumps({"type": "sdv_sprite", "id": qid, "png": base64.b64encode(icon(qid)).decode()}))
        for name, *_ in VILLAGERS:
            out.append(json.dumps({"type": "sdv_sprite", "id": "npc:" + name, "inset": 0,
                                   "png": base64.b64encode(face(name)).decode()}))
        if not self.old:
            for kind in ("White Chicken", "Brown Chicken", "Cow"):
                out.append(json.dumps({"type": "sdv_sprite", "id": "animal:" + kind, "inset": 0,
                                       "png": base64.b64encode(icon(kind)).decode()}))
        return out

    def apply(self, cmd):
        """A command from the app; returns the messages to send after it."""
        t = cmd.get("type")
        a = cmd.get("slot", cmd.get("from", cmd.get("value", -1)))
        b = cmd.get("to", -1)
        c = self.config
        with self.lock:
            if t == "select_slot" and c["allowInventoryEdits"] and 0 <= a < 12:
                self.selected = a
                return [self.inventory_msg()]
            if t == "move_item" and c["allowInventoryEdits"] and 0 <= a < len(self.items) and 0 <= b < len(self.items):
                self.items[a], self.items[b] = self.items[b], self.items[a]
                return [self.inventory_msg()]
            if t == "shift_toolbar" and c["allowInventoryEdits"]:
                rows = [self.items[i:i + 12] for i in range(0, self.capacity, 12)]
                rows = rows[1:] + rows[:1] if a > 0 else rows[-1:] + rows[:-1]
                self.items = sum(rows, []) + self.items[self.capacity:]
                return [self.inventory_msg()]
            if t == "sort_bag" and c["allowInventoryEdits"]:
                bag = self.items[12:self.capacity]
                bag = sorted([i for i in bag if i], key=lambda i: ITEMS[i["id"]][1] + ITEMS[i["id"]][0]) + \
                    [None] * sum(1 for i in bag if not i)
                self.items[12:self.capacity] = bag
                return [self.inventory_msg()]
            if t == "eat_slot" and c["allowInventoryEdits"] and 0 <= a < len(self.items) and self.items[a]:
                if ITEMS[self.items[a]["id"]][1] in ("Cooking", "Vegetable", "Fruit", "Forage", "Animal Product"):
                    self.take(self.items[a]["id"], 1)
                    self.energy = min(270, self.energy + 40)
                    return [self.inventory_msg(), self.day_msg()]
                return []
            if t == "cancel_quest" and c["allowQuestCancel"] and 0 <= a < len(self.quests):
                if self.quests[a]["cancellable"]:
                    del self.quests[a]
                return [self.quests_msg()]
            if t == "set_option" and cmd.get("key") in c:
                c[cmd["key"]] = a != 0
                return self.everything()
            if t == "craft_recipe" and not self.old and c["allowInventoryEdits"] and c["sendCrafting"]:
                for key, product, n, _, needs in RECIPES:
                    if key == cmd.get("key") and all(self.count(q) >= k for q, k in needs):
                        for q, k in needs:
                            self.take(q, k)
                        self.give(product, n)
                return [self.inventory_msg(), self.crafting_msg()]
            if t == "refresh":
                return self.everything()
        return []


# --- The socket, as the mod's: one JSON object per text frame -----------------

def frame(text):
    body = text.encode()
    n = len(body)
    if n < 126:
        head = bytes([0x81, n])
    elif n <= 0xFFFF:
        head = bytes([0x81, 126]) + struct.pack(">H", n)
    else:
        head = bytes([0x81, 127]) + struct.pack(">Q", n)
    return head + body


def read_exact(sock, n):
    data = b""
    while len(data) < n:
        got = sock.recv(n - len(data))
        if not got:
            raise ConnectionError
        data += got
    return data


def read_frame(sock):
    b0, b1 = read_exact(sock, 2)
    op, n = b0 & 0x0F, b1 & 0x7F
    if n == 126:
        n = struct.unpack(">H", read_exact(sock, 2))[0]
    elif n == 127:
        n = struct.unpack(">Q", read_exact(sock, 8))[0]
    mask = read_exact(sock, 4) if b1 & 0x80 else b"\0\0\0\0"
    data = bytes(c ^ mask[i % 4] for i, c in enumerate(read_exact(sock, n)))
    return op, data


class Server:
    def __init__(self, farm, port):
        self.farm = farm
        self.port = port
        self.clients = []
        self.lock = threading.Lock()

    def send(self, conn, texts):
        try:
            conn.sendall(b"".join(frame(t) for t in texts))
        except OSError:
            pass

    def broadcast(self, texts):
        with self.lock:
            clients = list(self.clients)
        for c in clients:
            self.send(c, texts)

    def serve(self, conn):
        try:
            req = b""
            while b"\r\n\r\n" not in req:
                got = conn.recv(4096)
                if not got:
                    return
                req += got
            key = next(line.split(":", 1)[1].strip() for line in req.decode(errors="replace").split("\r\n")
                       if line.lower().startswith("sec-websocket-key:"))
            accept = base64.b64encode(hashlib.sha1((key + GUID).encode()).digest()).decode()
            conn.sendall(("HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n"
                          "Sec-WebSocket-Accept: %s\r\n\r\n" % accept).encode())
            print("app connected", flush=True)
            with self.lock:
                self.clients.append(conn)
            with self.farm.lock:
                msgs = self.farm.everything() + self.farm.sprites()
            self.send(conn, msgs)
            while True:
                op, data = read_frame(conn)
                if op == 0x8:
                    break
                if op != 0x1:
                    continue
                try:
                    cmd = json.loads(data)
                except ValueError:
                    continue
                print("command", cmd, flush=True)
                self.broadcast(self.farm.apply(cmd))
        except (ConnectionError, OSError, StopIteration):
            pass
        finally:
            with self.lock:
                if conn in self.clients:
                    self.clients.remove(conn)
            conn.close()
            print("app disconnected", flush=True)

    def clock(self):
        while True:
            time.sleep(7)
            self.farm.tick()
            with self.farm.lock:
                msgs = [self.farm.day_msg(), self.farm.inventory_msg()]
            self.broadcast(msgs)

    def run(self):
        s = socket.socket()
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        s.bind(("127.0.0.1", self.port))
        s.listen()
        print("fake Stardew on ws://127.0.0.1:%d" % self.port, flush=True)
        threading.Thread(target=self.clock, daemon=True).start()
        while True:
            conn, _ = s.accept()
            conn.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
            threading.Thread(target=self.serve, args=(conn,), daemon=True).start()


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    p.add_argument("--port", type=int, default=7786)
    p.add_argument("--old", action="store_true", help="act like a 0.3 mod")
    args = p.parse_args()
    try:
        Server(Farm(args.old), args.port).run()
    except KeyboardInterrupt:
        pass
