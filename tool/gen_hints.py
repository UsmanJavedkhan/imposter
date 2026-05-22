import json
import os

HINTS = {
    # Animals
    "Elephant": "Trunk", "Penguin": "Antarctica", "Dolphin": "Ocean", "Kangaroo": "Australia",
    "Giraffe": "Neck", "Tiger": "Stripes", "Lion": "Jungle", "Panda": "Bamboo", "Koala": "Eucalyptus",
    "Zebra": "Savanna", "Crocodile": "Swamp", "Octopus": "Tentacles", "Eagle": "Sky", "Owl": "Night",
    "Rabbit": "Carrot", "Hedgehog": "Spikes", "Squirrel": "Acorn", "Wolf": "Pack", "Fox": "Cunning",
    "Bear": "Cave", "Camel": "Desert", "Cheetah": "Speed", "Leopard": "Spots", "Rhino": "Horn",
    "Hippo": "River", "Gorilla": "Jungle", "Chimpanzee": "Banana", "Sloth": "Slow", "Otter": "River",
    "Seal": "Beach", "Whale": "Ocean", "Shark": "Teeth", "Jellyfish": "Sting", "Starfish": "Ocean",
    "Crab": "Claws", "Lobster": "Claws", "Frog": "Pond", "Snake": "Venom", "Lizard": "Reptile",
    "Turtle": "Shell", "Peacock": "Feathers", "Flamingo": "Pink", "Ostrich": "Egg", "Parrot": "Talk",
    "Bat": "Cave", "Raccoon": "Trash", "Deer": "Antlers", "Moose": "Antlers", "Hamster": "Wheel", "Horse": "Saddle",
    # Food & Drink
    "Pizza": "Cheese", "Sushi": "Rice", "Pancake": "Syrup", "Burger": "Beef", "Spaghetti": "Sauce",
    "Taco": "Shell", "Burrito": "Wrap", "Sandwich": "Bread", "Hotdog": "Sausage", "Popcorn": "Cinema",
    "Donut": "Glaze", "Croissant": "Butter", "Bagel": "Cream", "Waffle": "Grid", "Cupcake": "Frosting",
    "Brownie": "Chocolate", "Pretzel": "Salt", "Lasagna": "Layers", "Dumpling": "Steam", "Noodles": "Slurp",
    "Curry": "Spice", "Ramen": "Broth", "Steak": "Grill", "Bacon": "Crispy", "Omelette": "Eggs",
    "Cereal": "Milk", "Yogurt": "Creamy", "Cheese": "Dairy", "Chocolate": "Cocoa", "Icecream": "Cold",
    "Smoothie": "Blend", "Coffee": "Caffeine", "Tea": "Leaves", "Lemonade": "Sour", "Milkshake": "Straw",
    "Pineapple": "Tropical", "Watermelon": "Seeds", "Strawberry": "Red", "Banana": "Peel", "Mango": "Yellow",
    "Avocado": "Green", "Broccoli": "Tree", "Carrot": "Orange", "Potato": "Fries", "Tomato": "Ketchup",
    "Pumpkin": "Halloween", "Honey": "Bees", "Pancakes": "Stack", "Muffin": "Bake", "Pasta": "Italian",
    # Movies
    "Titanic": "Iceberg", "Avatar": "Blue", "Frozen": "Snow", "Joker": "Clown", "Inception": "Dream",
    "Gladiator": "Arena", "Jaws": "Shark", "Shrek": "Ogre", "Up": "Balloons", "Coco": "Music", "Cars": "Race",
    "Moana": "Ocean", "Aladdin": "Lamp", "Tarzan": "Jungle", "Matrix": "Code", "Terminator": "Robot",
    "Rocky": "Boxing", "Twilight": "Vampire", "Casablanca": "Romance", "Psycho": "Shower", "Alien": "Space",
    "Predator": "Hunter", "Godzilla": "Monster", "Batman": "Gotham", "Superman": "Cape", "Spiderman": "Web",
    "Ironman": "Suit", "Thor": "Hammer", "Hulk": "Green", "Deadpool": "Mask", "Encanto": "Magic", "Tangled": "Hair",
    "Dumbo": "Ears", "Bambi": "Deer", "Pinocchio": "Nose", "Cinderella": "Slipper", "Mulan": "Warrior", "Brave": "Archery",
    "Ratatouille": "Rat", "Wall-E": "Robot", "Zootopia": "Animals", "Soul": "Jazz", "Luca": "Sea", "Onward": "Quest",
    "Avengers": "Heroes", "Interstellar": "Wormhole", "Dunkirk": "War", "Parasite": "Class", "Whiplash": "Drums", "Amelie": "Paris",
    # Sports
    "Soccer": "Goal", "Basketball": "Hoop", "Tennis": "Racket", "Cricket": "Bat", "Baseball": "Diamond", "Golf": "Clubs",
    "Boxing": "Gloves", "Swimming": "Pool", "Cycling": "Bike", "Running": "Track", "Skiing": "Snow", "Snowboarding": "Mountain",
    "Surfing": "Waves", "Skateboarding": "Tricks", "Volleyball": "Net", "Badminton": "Shuttlecock", "Hockey": "Puck",
    "Rugby": "Scrum", "Football": "Touchdown", "Wrestling": "Mat", "Karate": "Belt", "Judo": "Throw", "Fencing": "Sword",
    "Archery": "Arrow", "Rowing": "Oars", "Sailing": "Wind", "Diving": "Board", "Gymnastics": "Beam", "Climbing": "Rope",
    "Bowling": "Pins", "Darts": "Bullseye", "Billiards": "Cue", "Curling": "Ice", "Polo": "Horse", "Handball": "Court",
    "Squash": "Wall", "Marathon": "Distance", "Triathlon": "Three", "Hurdles": "Jump", "Javelin": "Spear", "Discus": "Disc",
    "Weightlifting": "Barbell", "Kayaking": "Paddle", "Canoeing": "River", "Paragliding": "Glide", "Motocross": "Dirt",
    "Racing": "Speed", "Dodgeball": "Dodge", "Cheerleading": "Pompoms", "Yoga": "Stretch",
    # Countries
    "India": "Taj", "Japan": "Sushi", "Brazil": "Carnival", "Canada": "Maple", "France": "Eiffel", "Germany": "Beer",
    "Italy": "Pizza", "Spain": "Flamenco", "Mexico": "Tacos", "Egypt": "Pyramids", "Kenya": "Safari", "Nigeria": "Lagos",
    "Russia": "Vodka", "China": "Wall", "Australia": "Kangaroo", "Argentina": "Tango", "Norway": "Fjords", "Sweden": "IKEA",
    "Finland": "Sauna", "Iceland": "Glaciers", "Greece": "Olympus", "Turkey": "Bazaar", "Thailand": "Temples", "Vietnam": "Pho",
    "Indonesia": "Bali", "Malaysia": "Towers", "Singapore": "City", "Portugal": "Lisbon", "Ireland": "Shamrock", "Scotland": "Kilt",
    "Poland": "Pierogi", "Austria": "Alps", "Switzerland": "Chocolate", "Netherlands": "Tulips", "Belgium": "Waffles", "Denmark": "Vikings",
    "Morocco": "Desert", "Peru": "Machu", "Chile": "Andes", "Colombia": "Coffee", "Cuba": "Cigars", "Jamaica": "Reggae",
    "Iran": "Persia", "Iraq": "Tigris", "Israel": "Jerusalem", "Nepal": "Everest", "Pakistan": "Cricket", "Bangladesh": "Delta",
    "Ukraine": "Kyiv", "Hungary": "Budapest",
    # Jobs
    "Doctor": "Hospital", "Teacher": "School", "Engineer": "Blueprint", "Pilot": "Plane", "Chef": "Kitchen", "Nurse": "Care",
    "Lawyer": "Court", "Farmer": "Crops", "Police": "Badge", "Firefighter": "Hose", "Astronaut": "Space", "Scientist": "Lab",
    "Artist": "Paint", "Musician": "Instrument", "Dancer": "Stage", "Actor": "Film", "Singer": "Microphone", "Writer": "Pen",
    "Journalist": "News", "Photographer": "Camera", "Architect": "Building", "Plumber": "Pipes", "Electrician": "Wires",
    "Carpenter": "Wood", "Mechanic": "Engine", "Dentist": "Teeth", "Surgeon": "Operation", "Vet": "Animals", "Barber": "Scissors",
    "Tailor": "Thread", "Baker": "Bread", "Butcher": "Meat", "Cashier": "Register", "Waiter": "Restaurant", "Librarian": "Books",
    "Pharmacist": "Medicine", "Soldier": "Army", "Sailor": "Ship", "Detective": "Clues", "Judge": "Gavel", "Accountant": "Numbers",
    "Banker": "Money", "Programmer": "Code", "Designer": "Layout", "Painter": "Brush", "Gardener": "Plants", "Fisherman": "Net",
    "Magician": "Tricks", "Referee": "Whistle",
    # Household Items
    "Toothbrush": "Teeth", "Pillow": "Sleep", "Blanket": "Warm", "Mirror": "Reflection", "Lamp": "Light", "Clock": "Time",
    "Chair": "Sit", "Table": "Surface", "Sofa": "Couch", "Television": "Screen", "Fridge": "Cold", "Microwave": "Heat",
    "Toaster": "Bread", "Kettle": "Boil", "Blender": "Mix", "Spoon": "Stir", "Fork": "Prongs", "Knife": "Cut", "Plate": "Dish",
    "Cup": "Drink", "Bowl": "Soup", "Bottle": "Liquid", "Towel": "Dry", "Soap": "Water", "Shampoo": "Hair", "Comb": "Tangle",
    "Scissors": "Snip", "Umbrella": "Rain", "Broom": "Sweep", "Bucket": "Carry", "Vacuum": "Dust", "Iron": "Wrinkles",
    "Hairdryer": "Blow", "Candle": "Flame", "Curtain": "Window", "Carpet": "Floor", "Doormat": "Welcome", "Wallet": "Money",
    "Keys": "Lock", "Remote": "Control", "Charger": "Battery", "Battery": "Power", "Notebook": "Pages", "Pencil": "Write",
    "Eraser": "Rub", "Stapler": "Staples", "Calendar": "Dates", "Backpack": "School", "Hanger": "Clothes", "Ladder": "Climb",
    # Famous People
    "Einstein": "Relativity", "Newton": "Gravity", "Gandhi": "Peace", "Mandela": "Freedom", "Lincoln": "President", "Napoleon": "France",
    "Cleopatra": "Egypt", "Shakespeare": "Plays", "Beethoven": "Symphony", "Mozart": "Piano", "Picasso": "Cubism", "DaVinci": "MonaLisa",
    "Darwin": "Evolution", "Tesla": "Electricity", "Edison": "Lightbulb", "Galileo": "Telescope", "Aristotle": "Philosophy", "Socrates": "Athens",
    "Columbus": "Voyage", "Marco Polo": "Travels", "Beyonce": "Singer", "Madonna": "Pop", "Eminem": "Rap", "Adele": "Ballad", "Drake": "Rapper",
    "Rihanna": "Diamonds", "Messi": "Soccer", "Ronaldo": "Portugal", "Federer": "Tennis", "Jordan": "Basketball", "Pele": "Brazil",
    "Maradona": "Football", "Bolt": "Sprint", "Phelps": "Swimming", "Serena": "Williams", "Oprah": "Talkshow", "Spielberg": "Director",
    "Hitchcock": "Suspense", "Disney": "Mickey", "Jobs": "Apple", "Gates": "Microsoft", "Musk": "Rockets", "Bezos": "Amazon",
    "Zuckerberg": "Facebook", "Churchill": "Britain", "Roosevelt": "NewDeal", "Kennedy": "Camelot", "Obama": "Hope", "Curie": "Radium", "Hawking": "Cosmos",
    # Video Games
    "Mario": "Plumber", "Zelda": "Triforce", "Tetris": "Blocks", "Pacman": "Maze", "Pokemon": "Catch", "Minecraft": "Crafting",
    "Fortnite": "Battle", "Roblox": "Build", "Sonic": "Speed", "Pong": "Paddle", "Kirby": "Pink", "Metroid": "Samus", "Halo": "Spartan",
    "Doom": "Demons", "Portal": "Cake", "Skyrim": "Dragons", "Fallout": "Wasteland", "Overwatch": "Heroes", "Valorant": "Agents",
    "Among Us": "Crewmate", "Terraria": "Mining", "Stardew": "Farming", "Witcher": "Geralt", "Cyberpunk": "Future", "Tekken": "Fighting",
    "Streetfighter": "Hadouken", "Mortal Kombat": "Fatality", "Pubg": "Survival", "Crossy Road": "Chicken", "Candy Crush": "Candy",
    "Angry Birds": "Slingshot", "Subway Surfers": "Run", "Temple Run": "Escape", "Clash Royale": "Towers", "Hearthstone": "Cards",
    "Starcraft": "Zerg", "Warcraft": "Orcs", "Diablo": "Hell", "Bioshock": "Rapture", "Borderlands": "Loot", "Splatoon": "Ink",
    "Pikmin": "Plants", "Donkey Kong": "Banana", "Bomberman": "Bombs", "Galaga": "Aliens", "Asteroids": "Space", "Frogger": "Cross",
    "Centipede": "Bug", "Spaceinvaders": "Invasion", "Rocket League": "Cars",
    # Nature
    "Mountain": "Peak", "River": "Flow", "Ocean": "Waves", "Forest": "Trees", "Desert": "Sand", "Volcano": "Lava", "Waterfall": "Cascade",
    "Glacier": "Ice", "Canyon": "Gorge", "Cave": "Dark", "Island": "Isolated", "Beach": "Shore", "Valley": "Lowland", "Meadow": "Grass",
    "Jungle": "Dense", "Swamp": "Marsh", "Lake": "Water", "Pond": "Small", "Rainbow": "Colors", "Lightning": "Bolt", "Thunder": "Sound",
    "Tornado": "Twister", "Hurricane": "Storm", "Earthquake": "Tremor", "Sunset": "Dusk", "Sunrise": "Dawn", "Cloud": "Sky", "Snow": "White",
    "Rain": "Drops", "Wind": "Breeze", "Fog": "Mist", "Dew": "Morning", "Storm": "Tempest", "Cliff": "Edge", "Reef": "Coral", "Tree": "Branches",
    "Flower": "Petals", "Cactus": "Spines", "Mushroom": "Fungus", "Leaf": "Green", "Seashell": "Beach", "Coral": "Reef", "Iceberg": "Float",
    "Geyser": "Eruption", "Meteor": "Shower", "Comet": "Tail", "Star": "Twinkle", "Moon": "Crater", "Planet": "Orbit", "Galaxy": "Stars",
}

here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
path = os.path.join(here, "assets", "words", "themes.json")

with open(path, encoding="utf-8") as f:
    data = json.load(f)

missing = []
for theme in data["themes"]:
    new_words = []
    for entry in theme["words"]:
        w = entry["word"] if isinstance(entry, dict) else entry
        if w not in HINTS:
            missing.append(w)
            continue
        new_words.append({"word": w, "hint": HINTS[w]})
    theme["words"] = new_words

if missing:
    raise SystemExit("MISSING HINTS for: " + ", ".join(missing))

data["version"] = 2
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")

total = sum(len(t["words"]) for t in data["themes"])
print("OK - wrote {} word+hint entries across {} themes".format(total, len(data["themes"])))
