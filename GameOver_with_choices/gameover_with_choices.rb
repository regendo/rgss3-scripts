#========================
# GameOver with Choices (GOWC)
#------------------------
# for RMVXAce
#========================
# brought to you by
# regendo, aka. bStefan
#------------------------
# up-to-date versions of this script are exclusively available at
# http://www.rpgmakervxace.net/topic/357-gameover-with-choices/
# and https://github.com/regendo/rgss3-scripts
#========================

# The Terms of Use specified in the README.md file in the github repository apply to this script.


# This script is Paste & Play compatible. You can use this script without modifying anything.
# However, looking at the customisation options is strongly recommended.


#========================
# CHANGELOG
#========================
# current release: 2.2-gowc pre
# current release notes:
# # new features:
# # # hp, mp, tp, states can be reset upon battle retry
# # bugfixes:
# # not working as intended:
# # missing features:
# # # player does not get notified about losing gold/items
#------------------------
# 2.2   - now able to reset hp, mp, tp, states when retrying battles
# 2.1   - now has a chance to lose gold, items, armour parts, weapons upon retrying battles
# 2.0   - complete rewrite
# 1.3   - now able to regain items, weapons, armours when retrying battles
# 1.2   - now compatible with "Multiple Columns in selectable windows" script by regendo
# 1.1   - now able to retry lost battles
# 1.0   - initial release

# above update notes do not include minor updates such as bug fixes
#========================

#========================
# Compability check:
#-------------------------------
# class Scene_Gameover:
# # 2 aliases
# # # def start_with_regendo_gameover_window
# # # def regendo_gowc_goto_title
# # 2 def overwrites
# # # def update
# # # def pre_terminate
# # 11 new methods
# # # def create_command_window
# # # def set_handlers
# # # def close_command_window
# # # def command_retry
# # # def command_load_game
# # # def command_shutdown
# # # def regendo_gowc_lose_gold
# # # def regendo_gowc_lose_items
# # # def regendo_gowc_check_rng(percentage)
# # # def set_regendo_gowc_values(gowc_values)
# # # def set_defeat
#-------------------------------
# class Window_GameOver:
# # completely new
#-------------------------------
# class Game_Party:
# # 6 new methods
# # # def regendo_gowc_get_items
# # # def regendo_gowc_get_weapons
# # # def regendo_gowc_get_armours
# # # def regendo_gowc_set_items(items)
# # # def regendo_gowc_set_weapons(weapons)
# # # def regendo_gowc_set_armours(armours)
# # 2 aliases
# # # def regendo_gowc_get_armors
# # # def regendo_gowc_set_armors(armors)
#-------------------------------
# module BattleManager:
# # 2 aliases
# # # def setup_regendo_gowc
# # # def save_regendo_gowc_bgms
# # 5 new methods
# # # def setup_regendo_gowc_retry
# # # def initialize_regendo_gowc_values
# # # def regendo_gowc_do_lose_items
# # # def set_regendo_gowc_bgms(bgm, bgs)
# # # def regendo_gowc_get_iaw
# # 1 overwrite
# # # def process_defeat
#========================

module Regendo
  
  unless @scripts
    @scripts = Hash.new
    def self.contains?(key)
      @scripts[key] == true
    end
  end
  @scripts["GameOver_Window"] = true
  
  module GameOver_Window
  
    # CUSTOMISATION OPTIONS
    
    RETRY_TEXT = "Retry Battle"
    
    LOAD_TEXT = "Load Savefile"
  
    # allows a lost battle to be retried
    # retry only works when "continue even if lose" is not checked
    # set by script call: Regendo::GameOver_Window::ALLOW_RETRY = true/false
    ALLOW_RETRY = true
    
    # allows loading a save file
    # set by script call: Regendo::GameOver_Window::ALLOW_LOAD_GAME = true/false
    ALLOW_LOAD_GAME = true
    
    
    # use a window with multiple columns
    # requires Multiple Cols in Command Windows script by regendo
    USE_MULTIPLE_COLS = true
    COL_NUMBER = 2
    
    # X and Y coordinates for the window as a String
    # default X: "[(Graphics.width - width)/2, 0].max"
    # default Y: "[(Graphics.height - height)/1.1, 0].max"
    X_COORD = "[(Graphics.width - width)/2, 0].max"
    Y_COORD = "[(Graphics.height - height)/1.1, 0].max"
    
    # window width as a string
    # only applies if not using the multiple columns script
    WIDTH = "Graphics.width * 0.4"
    
    # regain lost/used stuff when retrying battle?
    # set by script call: Regendo::GameOver_Window::REGAIN_ITEMS/ARMOURS/WEAPONS = true/false
    REGAIN_ITEMS = true
    REGAIN_ARMOURS = true
    REGAIN_WEAPONS = true
    
    # fully restore party?
    # if true, hp, mp, tp, and states will be reset to the beginning of the initial battle
    # if false, the party will be revived and fully healed
    FULL_RESTORE = true
    
    # chance to lose gold on battle retry
    # 1: lose gold
    # 0: don't lose gold
    # use floating point numbers for percentages, e.g. 0.854 for a 85.4% chance of losing gold
    LOSE_GOLD_CHANCE = 0.5
    # amount of gold lost as a string
    # examples:
    # # "500": lose 500 gold
    # # "250 * $game_party.battle_members.size": 250 gold per battle member
    # # "$game_party.gold": lose all gold
    # # "$game_party.gold * 0.5": lose half of your gold
    # # "$game_party.gold * Random.rand * 0.5": lose up to half of your money
    # get creative!
    LOSE_GOLD_AMOUNT = "$game_party.gold * 0.25"
    
    # chance of losing items when retrying
    LOSE_ITEMS_CHANCE = 0
    
    # max. amount of items lost at the same time
    LOSE_ITEMS_MAX_TIMES = 4
    
    # can you lose items? (key items can't be lost)
    CAN_LOSE_ITEMS = true
    # can you lose armours? (equipped items can't be lost)
    CAN_LOSE_ARMOURS = true
    # can you lose weapons? (equipped items can't be lost)
    CAN_LOSE_WEAPONS = true
    
  end
end

# DO NOT EDIT BELOW

class Scene_Gameover < Scene_Base
  
  alias :start_with_regendo_gameover_window :start
  alias :regendo_gowc_goto_title :goto_title
  def start
    start_with_regendo_gameover_window
    create_command_window
  end
  
  # overwrites update method
  # prevents returning to title screen upon button press
  def update
    super
  end
  
  def pre_terminate
    super
    close_command_window
  end
  
  def create_command_window
    @command_window = Window_GameOver.new
    set_handlers
  end
  
  def set_handlers
    @command_window.set_handler(:retry, method(:command_retry)) if @defeat && Regendo::GameOver_Window::ALLOW_RETRY
    @command_window.set_handler(:load, method(:command_load_game))
    @command_window.set_handler(:to_title, method(:goto_title))
    @command_window.set_handler(:shutdown, method(:command_shutdown))
  end
  
  def close_command_window
    @command_window.close if @command_window
    update until @command_window.close?
  end
  
  def goto_title
    fadeout_all
    regendo_gowc_goto_title
  end
  
  def restore_members
    values = @regendo_gowc_values
    $game_party.members.each_with_index do |member, index|
      member.hp = values[:hp][index]
      member.mp = values[:mp][index]
      member.tp = values[:tp][index]
      member.clear_states
      values[:states][index].each do |state|
        member.add_state(state)
      end
      member.state_turns = values[:state_turns][index]
      member.state_steps = values[:state_turns][index]
    end
  end
  
  def command_retry
    SceneManager.goto(Scene_Battle)
    fadeout_all
    
    regendo_gowc_lose_gold
    regendo_gowc_lose_items
    
    BattleManager.setup_regendo_gowc_retry(@regendo_gowc_values)
    if Regendo::GameOver_Window::FULL_RESTORE
      restore_members
    else
      $game_party.members.each do |member|
        member.recover_all
      end
    end
    
    items = Marshal.load(Marshal.dump(@regendo_gowc_values[:items]))
    weapons = Marshal.load(Marshal.dump(@regendo_gowc_values[:weapons]))
    armours = Marshal.load(Marshal.dump(@regendo_gowc_values[:armours]))
    $game_party.regendo_gowc_set_items(items) if Regendo::GameOver_Window::REGAIN_ITEMS
    $game_party.regendo_gowc_set_armours(armours) if Regendo::GameOver_Window::REGAIN_ARMOURS
    $game_party.regendo_gowc_set_weapons(weapons) if Regendo::GameOver_Window::REGAIN_WEAPONS
    
    BattleManager.play_battle_bgm
    Sound.play_battle_start
  end
  
  def command_load_game
    SceneManager.goto(Scene_Load)
    fadeout_all
  end
  
  def command_shutdown
    SceneManager.exit
  end
  
  def regendo_gowc_lose_gold
    return unless regendo_gowc_check_rng(Regendo::GameOver_Window::LOSE_GOLD_CHANCE)
    amount = [eval(Regendo::GameOver_Window::LOSE_GOLD_AMOUNT).abs.round, $game_party.gold].min
    $game_party.lose_gold(amount)
    @regendo_gowc_values[:gold] += amount
  end
  
  def regendo_gowc_lose_items
    
    items = Marshal.load(Marshal.dump($game_party.regendo_gowc_get_items))
    armours = Marshal.load(Marshal.dump($game_party.regendo_gowc_get_armours))
    weapons = Marshal.load(Marshal.dump($game_party.regendo_gowc_get_weapons))
    
    # removes key items from list
    items.delete_if { |key, value| $data_items[key].key_item? }
    
    Regendo::GameOver_Window::LOSE_ITEMS_MAX_TIMES.times do
      next unless regendo_gowc_check_rng(Regendo::GameOver_Window::LOSE_ITEMS_CHANCE)
      
      i = Regendo::GameOver_Window::CAN_LOSE_ITEMS && !items.empty?
      a = Regendo::GameOver_Window::CAN_LOSE_ARMOURS && !armours.empty?
      w = Regendo::GameOver_Window::CAN_LOSE_WEAPONS && !weapons.empty?
      
      val = [i, a, w].count(true)
      case val
      when 0
        return
      when 1
        kind = :item if i
        kind = :armour if a
        kind = :weapon if w
      when 2
        roll = Random.rand
        if roll <= 0.5
          kind = :item if i
          kind ||= :armour if a
        else
          kind = :weapon if w
          kind ||= armour if a
        end #if
      when 3
        roll = Random.rand
        if roll <= 1.0/3
          kind = :item
        elsif roll <= 2.0/3
          kind = :armour
        else
          kind = :weapon
        end #if
      end #case
      
      list = case kind
        when :item
          items
        when :armour
          armours
        when :weapon
          weapons
        end
      dumb_list = []
      list.each_pair do |key, value|
        value.times { dumb_list << key }
      end
      dumb_list.sort!
      
      item_id = dumb_list[Random.rand(dumb_list.size)]
      
      li = @regendo_gowc_values[:items_scheduled_lose][kind]
      li.has_key?(item_id) ? li[item_id] += 1 : li[item_id] = 1
      list[item_id] -= 1
      list.delete_if { |key, value| value < 1 }
      
    end #loop
  end #method
  
  def regendo_gowc_check_rng(percentage)
    chance = [percentage.to_f.abs, 1.0].min
    return false if chance == 0.0
    return true if chance == 1.0
    roll = Random.rand
    roll <= chance
  end
  
  def set_regendo_gowc_values(values)
    @regendo_gowc_values = values
  end
  
  def set_defeat
    @defeat = true
  end
  
end

if (Regendo.contains?("Horizontal_Command") && Regendo::GameOver_Window::USE_MULTIPLE_COLS)
  class Window_GameOver < Window_HorizontalCommand
  end
else
  class Window_GameOver < Window_Command
  end
end

class Window_GameOver

  def initialize
    if (Regendo.contains?("Horizontal_Command") && Regendo::GameOver_Window::USE_MULTIPLE_COLS)
      @horz = true
      super(0, 0, Regendo::GameOver_Window::COL_NUMBER)
    else
      @horz = false
      super(0, 0)
    end
    update_placement
    self.openness = 0
    open
  end
  
  def window_width(width = 255)
    return super if @horz
    @width = eval(Regendo::GameOver_Window::WIDTH)
  end
  
  def update_placement
    self.x = eval(Regendo::GameOver_Window::X_COORD)
    self.y = eval(Regendo::GameOver_Window::Y_COORD)
  end
  
  def make_command_list
    add_command(retry_text, :retry) if Regendo::GameOver_Window::ALLOW_RETRY
    add_command(load_text, :load, can_load_game?) if Regendo::GameOver_Window::ALLOW_LOAD_GAME
    add_command(Vocab.to_title, :to_title)
    add_command(Vocab.shutdown, :shutdown)
  end
  
  def retry_text; Regendo::GameOver_Window::RETRY_TEXT; end
  def load_text; Regendo::GameOver_Window::LOAD_TEXT; end
  
  def can_load_game?
    DataManager.save_file_exists?
  end
  
end

class Game_Party < Game_Unit

  def regendo_gowc_get_items; return @items; end
  def regendo_gowc_get_weapons; return @weapons; end
  def regendo_gowc_get_armours; return @armors; end
  alias :regendo_gowc_get_armors :regendo_gowc_get_armours
  
  def regendo_gowc_set_items(items); @items = items; end
  def regendo_gowc_set_weapons(weapons); @weapons = weapons; end
  def regendo_gowc_set_armours(armours); @armors = armours; end
  alias :regendo_gowc_set_armors :regendo_gowc_set_armours
  
end

module BattleManager
  
  class << self
    alias_method :setup_regendo_gowc, :setup
    alias_method :save_regendo_gowc_bgms, :save_bgm_and_bgs
  end
  
  def self.setup_regendo_gowc_retry(gowc_values)
    @regendo_gameover_values = gowc_values
    troop_id = @regendo_gameover_values[:troop_id]
    can_escape = @regendo_gameover_values[:can_lose]
    can_lose = @regendo_gameover_values[:can_lose]
    @regendo_gameover_values[:is_retry] = true
    @regendo_gameover_values[:times_retry] += 1
    setup(troop_id, can_escape, can_lose)
    regendo_gowc_do_lose_items
  end
  
  def self.setup(troop_id, can_escape, can_lose)
    setup_regendo_gowc(troop_id, can_escape, can_lose)
    initialize_regendo_gowc_values(troop_id)
    set_regendo_gowc_bgms(@regendo_gameover_values[:bgm], @regendo_gameover_values[:bgs])
  end
  
  def self.initialize_regendo_gowc_values(troop_id)
    return if @regendo_gameover_values
    @regendo_gameover_values = Hash.new
    @regendo_gameover_values[:gold] = 0
    @regendo_gameover_values[:troop_id] = troop_id
    @regendo_gameover_values[:can_escape] = @can_escape
    @regendo_gameover_values[:can_lose] = @can_lose
    @regendo_gameover_values[:is_retry] = false
    @regendo_gameover_values[:times_retry] = 0
    @regendo_gameover_values[:items_lost] = { :item => {}, :armour => {}, :weapon => {} }
    @regendo_gameover_values[:items_scheduled_lose] = { :item => {}, :armour => {}, :weapon => {} }
    @regendo_gameover_values[:hp] = []
    @regendo_gameover_values[:mp] = []
    @regendo_gameover_values[:tp] = []
    @regendo_gameover_values[:states] = []
    @regendo_gameover_values[:state_turns] = []
    @regendo_gameover_values[:state_steps] = []
    regendo_gowc_get_party
    regendo_gowc_get_iaw
  end
  
  def self.regendo_gowc_get_party
    $game_party.members.each_with_index do |member, index|
      @regendo_gameover_values[:hp][index] = Marshal.load(Marshal.dump(member.hp))
      @regendo_gameover_values[:mp][index] = Marshal.load(Marshal.dump(member.mp))
      @regendo_gameover_values[:tp][index] = Marshal.load(Marshal.dump(member.tp))
      @regendo_gameover_values[:states][index] = []
      member.states.each do |state|
        @regendo_gameover_values[:states][index].push(state.id)
      end
      @regendo_gameover_values[:state_turns][index] = Marshal.load(Marshal.dump(member.state_turns))
      @regendo_gameover_values[:state_steps][index] = Marshal.load(Marshal.dump(member.state_steps))
    end
  end
  
  def self.regendo_gowc_do_lose_items
    @regendo_gameover_values[:items_scheduled_lose].each_pair do |kind, list|
      list.each_pair do |id, count|
        item = case kind
          when :item
            $data_items[id]
          when :armour
            $data_armors[id]
          when :weapon
            $data_weapons[id]
          end#case
        $game_party.lose_item(item, count)
        li = @regendo_gameover_values[:items_lost][kind]
        li.has_key?(id) ? li[id] += count : li[id] = count
        list[id] = 0
      end #list.each_pair
      list.delete_if { |id, count| count < 1 }
    end#each_pair
  end#method
  
  def self.process_defeat
    $game_message.add(sprintf(Vocab::Defeat, $game_party.name))
    wait_for_message
    if @can_lose
      revive_battle_members
      replay_bgm_and_bgs
      SceneManager.return
    else
      SceneManager.goto(Scene_Gameover)
      # start of new part
      SceneManager.scene.set_defeat
      SceneManager.scene.set_regendo_gowc_values(@regendo_gameover_values)
      # end of new part
    end
    battle_end(2)
    return true
  end
  
  def self.save_bgm_and_bgs
    save_regendo_gowc_bgms
    @regendo_gameover_values[:bgm] = @map_bgm
    @regendo_gameover_values[:bgs] = @map_bgs
  end
  
  def self.set_regendo_gowc_bgms(bgm, bgs)
    @map_bgm = bgm
    @map_bgs = bgs
    @regendo_gameover_values[:bgm] = @map_bgm
    @regendo_gameover_values[:bgs] = @map_bgs
  end
  
  # gets party's items, armours, weapons
  def self.regendo_gowc_get_iaw
    @regendo_gameover_values[:items] = Marshal.load(Marshal.dump($game_party.regendo_gowc_get_items))
    @regendo_gameover_values[:armours] = Marshal.load(Marshal.dump($game_party.regendo_gowc_get_armours))
    @regendo_gameover_values[:weapons] = Marshal.load(Marshal.dump($game_party.regendo_gowc_get_weapons))
  end
end

class Game_BattlerBase
  attr_accessor :state_turns
  attr_accessor :state_steps
end
