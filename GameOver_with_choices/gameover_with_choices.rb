#========================
# GameOver with Choices (GOWC)
#------------------------
# for RMVXAce
#========================
# brought to you by
# regendo, aka. bStefan
#------------------------
# up-to-date versions are exclusively available at
# http://www.rpgmakervxace.net/topic/357-gameover-with-choices/
# and https://github.com/regendo/rgss3-scripts
#========================

# The Terms of Use specified in the README.md file in the github repository apply to this script.

#========================
# CHANGELOG
#========================
# current release: 2.0-gowc
# current release notes:
# # complete rewrite
# # 1.3 functionalities supported: 6/6
# # # Quit Game (y)
# # # To Title (y)
# # # Load Savefile (y)
# # # Retry Battle (y)
# # # MCIS compability (y)
# # # Restore lost items (y)
# # now with more customisation!
#------------------------
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
# # various overwrites
# # a few new methods
# class Window_GameOver:
# # completely new
# class Game_Party:
# # 6 new methods
# module BattleManager:
# # 2 aliases
# # 1 new method
# # overwrites:
# # # process_defeat
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
  
  def command_retry
    SceneManager.goto(Scene_Battle)
    fadeout_all
    
    troop_id = @regendo_gowc_values[:troop_id]
    can_escape = @regendo_gowc_values[:can_escape]
    can_lose = @regendo_gowc_values[:can_lose]
    bgm = @regendo_gowc_values[:bgm]
    bgs = @regendo_gowc_values[:bgs]
    items = @regendo_gowc_values[:items]
    weapons = @regendo_gowc_values[:weapons]
    armours = @regendo_gowc_values[:armours]
    
    BattleManager.setup(troop_id, can_escape, can_lose)
    $game_party.members.each do |member|
      member.recover_all
    end
    $game_party.regendo_gowc_set_items(items) if Regendo::GameOver_Window::REGAIN_ITEMS
    $game_party.regendo_gowc_set_armours(armours) if Regendo::GameOver_Window::REGAIN_ARMOURS
    $game_party.regendo_gowc_set_weapons(weapons) if Regendo::GameOver_Window::REGAIN_WEAPONS
    BattleManager.set_regendo_gowc_bgms(bgm, bgs)
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
  
  def set_regendo_gowc_values(value)
    @regendo_gowc_values = value
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
  def regendo_gowc_get_armours; return @armours; end
  
  def regendo_gowc_set_items(items); @items = items; end
  def regendo_gowc_set_weapons(weapons); @weapons = weapons; end
  def regendo_gowc_set_armours(armours); @armours = armours; end
  
end

module BattleManager
  
  class << self
    alias_method :setup_regendo_gowc, :setup
    alias_method :save_regendo_gowc_bgms, :save_bgm_and_bgs
  end
  
  def self.setup(troop_id, can_escape = true, can_lose = false)
    setup_regendo_gowc(troop_id, can_escape, can_lose)
    @regendo_gameover_values = Hash.new
    @regendo_gameover_values[:troop_id] = troop_id
    regendo_gowc_get_iaw
  end
  
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
    @regendo_gameover_values[:bgm] = bgm
    @regendo_gameover_values[:bgs] = bgs
  end
  
  # gets party's items, armours, weapons
  def self.regendo_gowc_get_iaw
    @regendo_gameover_values[:items] = Marshal.load(Marshal.dump($game_party.regendo_gowc_get_items))
    @regendo_gameover_values[:armours] = Marshal.load(Marshal.dump($game_party.regendo_gowc_get_armours))
    @regendo_gameover_values[:weapons] = Marshal.load(Marshal.dump($game_party.regendo_gowc_get_weapons))
  end
end
