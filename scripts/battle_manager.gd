extends Node

const SMALL_CARD_SCALE = 0.8
const CARD_MOVE_SPEED = 0.2

var battle_timer
var empty_basic_card_slots = []
var opponent_cards_on_battlefield = []
var player_cards_on_battlefield = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	battle_timer = $"../BattleTimer"
	battle_timer.one_shot = true
	battle_timer.wait_time = 1.0
	empty_basic_card_slots.append($"../CardSlots/OpponentCardSlot2")
	empty_basic_card_slots.append($"../CardSlots/OpponentCardSlot3")
	empty_basic_card_slots.append($"../CardSlots/OpponentCardSlot4")
	empty_basic_card_slots.append($"../CardSlots/OpponentCardSlot5")
	empty_basic_card_slots.append($"../CardSlots/OpponentCardSlot6")
	empty_basic_card_slots.append($"../CardSlots/OpponentCardSlot7")

func _on_end_turn_button_pressed() -> void:
	opponent_turn()
	
	
func opponent_turn():
	$"../EndTurnButton".disabled = true
	$"../EndTurnButton".visible = false
	
	# wait a moment
	await wait(1.0)
	
	if $"../OpponentDeck".opponent_deck.size() != 0:
		$"../OpponentDeck".draw_card()
		# wait a moment
		battle_timer.start()
		await battle_timer.timeout
	
	# check if free slots, if no end turn
	if empty_basic_card_slots.size() != 0:
		await try_play_card()
	
	if (opponent_cards_on_battlefield.size() != 0):
		var enemy_cards_to_attack = opponent_cards_on_battlefield.duplicate()
		for card in enemy_cards_to_attack:
			if player_cards_on_battlefield.size() == 0:
				# direct attack commander
				direct_attack(card, "Opponent")
			else:
				attack()
				
	
	# end turn
	end_opponent_turn()

func direct_attack(attacking_card, attacker):
	var new_pos_y
	if attacker == "Opponent":
		new_pos_y = 1080
	else:
		new_pos_y = 0
	
	var new_pos = Vector2(attacking_card.position.x, new_pos_y)
	
	attacking_card.z_index = 5
	
	print("direct attack")
	var tween = get_tree().create_tween()
	tween.tween_property(attacking_card, "position", new_pos, CARD_MOVE_SPEED)
	await wait(0.15)
	
	if attacker == "Opponent":
		pass
		#damage player
	else:
		pass
		# damage opponent
		
	var tween2 = get_tree().create_tween()
	tween2.tween_property(attacking_card, "position", attacking_card.card_in_slot.position, CARD_MOVE_SPEED)
	await wait(1.0)
	attacking_card.z_index = 0
	
func attack():
	print("attack")

func try_play_card():
	# play a card
	var opponent_hand = $"../OpponentHand".opponent_hand
	if opponent_hand.size() == 0:
		end_opponent_turn()
		return
	var random_empty_basic_card_slot = empty_basic_card_slots[randi_range(0, empty_basic_card_slots.size()-1)]
	empty_basic_card_slots.erase(random_empty_basic_card_slot)
	# temporary, play card with highest attack
	var card_with_highest_attack = opponent_hand[0]
	for card in opponent_hand:
		if card.attack > card_with_highest_attack.attack:
			card_with_highest_attack = card
	
	var tween = get_tree().create_tween()
	tween.tween_property(card_with_highest_attack, "position", random_empty_basic_card_slot.position, CARD_MOVE_SPEED)
	var tween2 = get_tree().create_tween()
	tween2.tween_property(card_with_highest_attack, "scale", Vector2(SMALL_CARD_SCALE, SMALL_CARD_SCALE), CARD_MOVE_SPEED)
	card_with_highest_attack.get_node("AnimationPlayer").play("card_flip")
	
	# remove card from opp hand
	$"../OpponentHand".remove_card_from_hand(card_with_highest_attack)
	card_with_highest_attack.card_in_slot = random_empty_basic_card_slot
	opponent_cards_on_battlefield.append(card_with_highest_attack)
	
	await wait(1.0)
	
func wait(wait_time):
	battle_timer.wait_time = wait_time
	battle_timer.start()
	await battle_timer.timeout

func end_opponent_turn():
	# reset player deck draw and turn
	$"../Deck".reset_draw()
	$"../CardManager".reset_played_basic()
	$"../EndTurnButton".disabled = false
	$"../EndTurnButton".visible = true
