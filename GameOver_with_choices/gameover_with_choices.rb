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
# current release: 3.0-gowc pre
# current release notes:
# # new features:
# # # game-over retry functionality has been made a seperate script, GameOver:Retry_Battle (GORB)
# # bugfixes:
# # not working as intended:
# # missing features:
#------------------------
# 3.0   - game-over retry functionality has been made a separate script, GameOver:Retry_Battle (GORB)
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
#========================

module Regendo
  
  unless @scripts
    @scripts = Hash.new
    def self.contains?(key)
      @scripts[key] == true
    end
  end
  @scripts[:GOWC] = true
  
  module GOWC
  
    # CUSTOMISATION OPTIONS
    
    LOAD_TEXT = "Load Savefile"
    
    # allows loading a save file
    # set by script call: Regendo::GOWC::ALLOW_LOAD_GAME = true/false
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
    # set by script call: Regendo::GORB::REGAIN_ITEMS/ARMOURS/WEAPONS = true/false
    REGAIN_ITEMS = true
    REGAIN_ARMOURS = true
    REGAIN_WEAPONS = true
    
    # fully restore party?
    # if true, hp, mp, and states will be reset to the beginning of the initial battle
    # if false, the party will be revived and fully healed
    # set by scriot call: Regendo::GORB::FULL_RESTORE = true/false
    FULL_RESTORE = true
    
    # chance to lose gold on battle retry as a string
    # 1: lose gold
    # 0: don't lose gold
    # use floating point numbers for percentages, e.g. 0.854 for a 85.4% chance of losing gold
    # you can do formulas, e.g. base the loss chance on equipped items or the party leader's luck stat.
    LOSE_GOLD_CHANCE = "0.5"
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
    set_handlers_first
    @command_window.set_handler(:load, method(:command_load_game))
    @command_window.set_handler(:to_title, method(:goto_title))
    @command_window.set_handler(:shutdown, method(:command_shutdown))
    set_handlers_last
  end
  
  def set_handlers_first; end
  def set_handlers_last; end
  
  def close_command_window
    @command_window.close if @command_window
    update until @command_window.close?
  end
  
  def goto_title
    fadeout_all
    regendo_gowc_goto_title
  end
  
  def restore_members
    values = Marshal.load(Marshal.dump(@regendo_gowc_values))
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
    if Regendo::GOWC::FULL_RESTORE
      restore_members
    else
      $game_party.members.each do |member|
        member.recover_all
      end
    end
    
    items = Marshal.load(Marshal.dump(@regendo_gowc_values[:items]))
    weapons = Marshal.load(Marshal.dump(@regendo_gowc_values[:weapons]))
    armours = Marshal.load(Marshal.dump(@regendo_gowc_values[:armours]))
    $game_party.regendo_gowc_set_items(items) if Regendo::GOWC::REGAIN_ITEMS
    $game_party.regendo_gowc_set_armours(armours) if Regendo::GOWC::REGAIN_ARMOURS
    $game_party.regendo_gowc_set_weapons(weapons) if Regendo::GOWC::REGAIN_WEAPONS
    
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
    return unless regendo_gowc_check_rng(Regendo::GOWC::LOSE_GOLD_CHANCE)
    amount = [eval(Regendo::GOWC::LOSE_GOLD_AMOUNT).abs.round, $game_party.gold].min
    $game_party.lose_gold(amount)
    @regendo_gowc_values[:gold] += amount
  end
  
  def regendo_gowc_lose_items
    
    items = Marshal.load(Marshal.dump($game_party.regendo_gowc_get_items))
    armours = Marshal.load(Marshal.dump($game_party.regendo_gowc_get_armours))
    weapons = Marshal.load(Marshal.dump($game_party.regendo_gowc_get_weapons))
    
    # removes key items from list
    items.delete_if { |key, value| $data_items[key].key_item? }
    
    Regendo::GOWC::LOSE_ITEMS_MAX_TIMES.times do
      next unless regendo_gowc_check_rng(Regendo::GOWC::LOSE_ITEMS_CHANCE)
      
      i = Regendo::GOWC::CAN_LOSE_ITEMS && !items.empty?
      a = Regendo::GOWC::CAN_LOSE_ARMOURS && !armours.empty?
      w = Regendo::GOWC::CAN_LOSE_WEAPONS && !weapons.empty?
      
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
  
end

if (Regendo.contains?("Horizontal_Command") && Regendo::GOWC::USE_MULTIPLE_COLS)
  class Window_GameOver < Window_HorizontalCommand
    def initialize; @horz = true; end
  end
else
  class Window_GameOver < Window_Command
    def initialize; @horz = false; end
  end
end

class Window_GameOver

  def initialize
    if is_mcis_window?
      super(0, 0, col_max)
    else
      super(0, 0)
    end
    update_placement
    self.openness = 0
    open
  end
  
  def is_mcis_window?
    return @horz
  end
  
  def col_max
    Regendo::GOWC::COL_NUMBER
  end
  
  def window_width(width = 255)
    return super if is_mcis_window?
    @width = eval(Regendo::GOWC::WIDTH)
  end
  
  def update_placement
    self.x = eval(Regendo::GOWC::X_COORD)
    self.y = eval(Regendo::GOWC::Y_COORD)
  end
  
  def make_command_list
    add_commands_first
    add_command(load_text, :load, can_load_game?) if Regendo::GOWC::ALLOW_LOAD_GAME
    add_command(Vocab.to_title, :to_title)
    add_command(Vocab.shutdown, :shutdown)
    add_commands_last
  end
  
  def add_commands_first; end
  def add_commands_last; end
  
  def load_text
    Regendo::GOWC::LOAD_TEXT
  end
  
  def can_load_game?
    DataManager.save_file_exists?
  end
  
end

module BattleManager
  
  class << self
    alias_method :setup_regendo_gowc, :setup
  end
  
  def self.setup(troop_id, can_escape = true, can_lose = false)
    gowc_pre_setup(troop_id, can_escape, can_lose)
    setup_regendo_gowc(troop_id, can_escape, can_lose)
    gowc_post_setup
  end
  
  def self.gowc_pre_setup(troop_id, can_escape, can_lose); end
  def self.gowc_post_setup; end
  
  def self.initialize_regendo_gowc_values(troop_id)
    return if @regendo_gameover_values
    @regendo_gameover_values = Hash.new
    @regendo_gameover_values[:gold] = 0
    @regendo_gameover_values[:items_lost] = { :item => {}, :armour => {}, :weapon => {} }
    @regendo_gameover_values[:items_scheduled_lose] = { :item => {}, :armour => {}, :weapon => {} }
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
  
  # unfortunately this needed to be overwritten
  # except for the addition of the parts marked as new, everything is the same as in the standard script
  def self.process_defeat
    $game_message.add(sprintf(Vocab::Defeat, $game_party.name))
    wait_for_message
    if @can_lose
      revive_battle_members
      replay_bgm_and_bgs
      SceneManager.return
    else
      gowc_pre_transfer # new
      SceneManager.goto(Scene_Gameover)
      gowc_post_transfer # new
    end
    battle_end(2)
    return true
  end
  
  def self.gowc_pre_transfer; end
  def self.gowc_post_transfer; end
end
