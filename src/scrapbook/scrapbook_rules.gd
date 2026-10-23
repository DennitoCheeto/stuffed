class_name ScrapbookRules
extends Resource
## What the Scrapbook (spec 03 §8) collects, page by page. Entries come from the game's own data
## (weapon pool, enemy types, bosses, floor pickups, plushies), so a new weapon or enemy shows up
## in the book by itself. Texts live with each thing (card texts, `scrapbook_text`). Tune it in
## data/scrapbook.tres.

const WEAPONS: String = "weapons"
const ITEMS: String = "items"
const ENEMIES: String = "enemies"
const FLOOR_PICKUPS: String = "floor_pickups"
const PLUSHIES: String = "plushies"
## The Enemies page entry for elites (any zombie type can be one).
const ELITE_ID: String = "elite"

## Weapons, their evolutions and items.
@export var pool: UpgradePool
## Normal zombie types, in the order they appear in a run.
@export var enemies: Array[EnemyStats] = []
@export var elite_rules: EliteRules
## The zombie an elite is drawn as in the book.
@export var elite_body: EnemyStats
@export var elite_name: String = "Elite"
@export_multiline var elite_text: String = ""
## Mini-boss first, then the boss.
@export var bosses: Array[BossDef] = []
@export var floor_pickups: FloorPickupRules
@export var rescue: RescueRules


## Every page with its entries, in book order.
func pages() -> Array[ScrapbookPage]:
	return [_weapons(), _items(), _enemies(), _floor_pickups(), _plushies()]


## The Enemies page id of a zombie type (its display name in snake case, "big_ted").
static func enemy_id(stats: EnemyStats) -> String:
	return stats.display_name.to_lower().replace(" ", "_").replace("-", "_")


func _weapons() -> ScrapbookPage:
	var page: ScrapbookPage = ScrapbookPage.new(WEAPONS, "Weapons")
	for upgrade: UpgradeDef in pool.upgrades:
		if upgrade.kind != UpgradeDef.Kind.WEAPON:
			continue
		var text: String = upgrade.weapon.at_level(1).card_text
		var entry: ScrapbookEntry = page.add(_icon(upgrade.id, upgrade.display_name, text))
		entry.icon = upgrade.icon
		var partner: UpgradeDef = pool.partner_of(upgrade)
		if partner != null:
			entry.note = "Evolves with %s" % partner.display_name
	for evolution: EvolutionDef in pool.evolutions:
		var name: String = evolution.display_name()
		var entry: ScrapbookEntry = page.add(_icon(evolution.evolved.id, name, evolution.card_text))
		entry.icon = evolution.icon
		var weapon: UpgradeDef = pool.find(evolution.weapon)
		var item: UpgradeDef = pool.find(evolution.partner)
		entry.note = "Evolution: %s + %s" % [weapon.display_name, item.display_name]
	return page


func _items() -> ScrapbookPage:
	var page: ScrapbookPage = ScrapbookPage.new(ITEMS, "Items")
	for upgrade: UpgradeDef in pool.upgrades:
		if upgrade.kind != UpgradeDef.Kind.ITEM:
			continue
		var entry: ScrapbookEntry = page.add(
			_icon(upgrade.id, upgrade.display_name, upgrade.card_text)
		)
		entry.icon = upgrade.icon
		entry.note = "Per level, up to level %d" % upgrade.max_level
	return page


func _enemies() -> ScrapbookPage:
	var page: ScrapbookPage = ScrapbookPage.new(ENEMIES, "Enemies")
	for stats: EnemyStats in enemies:
		_zombie(page, enemy_id(stats), stats.display_name, stats.scrapbook_text, stats.look)
	var elite: ScrapbookEntry = _zombie(page, ELITE_ID, elite_name, elite_text, elite_body.look)
	elite.size = elite_rules.size
	elite.elite = true
	for boss: BossDef in bosses:
		var body: EnemyStats = boss.enemy
		var entry: ScrapbookEntry = _zombie(
			page, enemy_id(body), body.display_name, body.scrapbook_text, body.look
		)
		entry.size = boss.size
	return page


func _floor_pickups() -> ScrapbookPage:
	var page: ScrapbookPage = ScrapbookPage.new(FLOOR_PICKUPS, "Floor pickups")
	for kind: FloorPickupDef in floor_pickups.kinds:
		var entry: ScrapbookEntry = ScrapbookEntry.new(
			String(kind.id), kind.display_name, kind.scrapbook_text
		)
		entry.picture = ScrapbookEntry.Picture.PICKUP
		entry.pickup = kind.id
		page.add(entry)
	return page


func _plushies() -> ScrapbookPage:
	var page: ScrapbookPage = ScrapbookPage.new(PLUSHIES, "Plushies")
	for who: PlushieDef in rescue.plushies:
		var entry: ScrapbookEntry = ScrapbookEntry.new(who.id, who.display_name, who.scrapbook_text)
		entry.picture = ScrapbookEntry.Picture.PLUSHIE
		entry.plushie = who
		entry.note = "Rescued"
		page.add(entry)
	return page


func _icon(id: StringName, name: String, text: String) -> ScrapbookEntry:
	return ScrapbookEntry.new(String(id), name, text)


func _zombie(
	page: ScrapbookPage, id: String, name: String, text: String, look: EnemyStats.Look
) -> ScrapbookEntry:
	var entry: ScrapbookEntry = ScrapbookEntry.new(id, name, text)
	entry.picture = ScrapbookEntry.Picture.ZOMBIE
	entry.look = look
	return page.add(entry)
