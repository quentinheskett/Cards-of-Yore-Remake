extends Node2D

const CARD_SCENE_PATH = "res://scenes/card.tscn"
const CARD_DRAW_SPEED = 0.2

var player_deck = ["Ronin", "Samurai", "Yabusame", "Ronin"]
var card_database_reference

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player_deck.shuffle()
	card_database_reference = preload("res://scripts/card_database.gd")

func draw_card():
	var card_drawn = player_deck[0]
	player_deck.erase(card_drawn)
	if player_deck.size() == 0:
		$Area2D/CollisionShape2D.disabled = true
		$Sprite2D.visible = false
	
	var card_scene = preload(CARD_SCENE_PATH)
	var new_card = card_scene.instantiate()
	var card_image_path = str("res://assets/sprites/cards/small/" + card_drawn.to_lower() + "_small.png")
	new_card.get_node("CardImage").texture = load(card_image_path)
	new_card.get_node("Attack").text = str(card_database_reference.CARDS[card_drawn][0])
	new_card.get_node("Health").text = str(card_database_reference.CARDS[card_drawn][1])
	$"../CardManager".add_child(new_card)
	new_card.name = "Card"
	$"../PlayerHand".add_card_to_hand(new_card, CARD_DRAW_SPEED)
	new_card.get_node("AnimationPlayer").play("card_flip")
