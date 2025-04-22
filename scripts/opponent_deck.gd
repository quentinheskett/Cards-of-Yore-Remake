extends Node2D

const CARD_SCENE_PATH = "res://scenes/opponent_card.tscn"
const CARD_DRAW_SPEED = 0.2
const STARTING_HAND_SIZE = 5

var opponent_deck = ["Ronin", "Samurai", "Yabusame", "Ronin", "Ronin", "Ronin", "Ronin", "Amaterasu"]
var card_database_reference

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	opponent_deck.shuffle()
	card_database_reference = preload("res://scripts/card_database.gd")
	for i in range(STARTING_HAND_SIZE):
		draw_card()

func draw_card():
	var card_drawn = opponent_deck[0]
	opponent_deck.erase(card_drawn)
	if opponent_deck.size() == 0:
		$Sprite2D.visible = false
	
	var card_scene = preload(CARD_SCENE_PATH)
	var new_card = card_scene.instantiate()
	var card_image_path = str("res://assets/sprites/cards/small/" + card_drawn.to_lower() + "_small.png")
	new_card.get_node("CardImage").texture = load(card_image_path)
	new_card.attack = card_database_reference.CARDS[card_drawn][0]
	new_card.health = card_database_reference.CARDS[card_drawn][1]
	new_card.get_node("Attack").text = str(new_card.attack)
	new_card.get_node("Health").text = str(new_card.health)
	new_card.card_type = card_database_reference.CARDS[card_drawn][2]
	$"../CardManager".add_child(new_card)
	new_card.name = "Card"
	$"../OpponentHand".add_card_to_hand(new_card, CARD_DRAW_SPEED)
