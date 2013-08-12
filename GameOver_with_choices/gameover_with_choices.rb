#========================
# GameOver with Choices
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
# current release: 2.0-gowc pre
# current release notes:
# # complete rewrite
# # not all functionalities already supported
#------------------------
# 2.0   - complete rewrite
# 1.3   - now able to regain items, weapons, armours when retrying battles
# 1.2   - now compatible with "Multiple Columns in selectable windows" script by regendo
# 1.1   - now able to retry lost battles
# 1.0   - initial release

# above update notes do not include minor updates such as bug fixes
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
    ALLOW_RETRY = false
    
    # allows loading a save file
    # set by script call: Regendo::GameOver_Window::ALLOW_LOAD_GAME = true/false
    ALLOW_LOAD_GAME = true
    
    
    # use a window with multiple columns
    # requires Multiple Cols in Command Windows script by regendo
    USE_MULTIPLE_COLS = false
    COL_NUMBER = 2
    
    # X and Y coordinates for the window as a String
    # default X: "[(Graphics.width - width)/2, 0].max"
    # default Y: "[(Graphics.height - height)/1.1, 0].max"
    X_COORD = "[(Graphics.width - width)/2, 0].max"
    Y_COORD = "[(Graphics.height - height)/1.1, 0].max"
    
  end
end

# DO NOT EDIT BELOW

class Scene_Gameover < Scene_Base
  
  alias :start_with_regendo_gameover_window :start
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
    fadeout_all
  end
  
  def create_command_window
    @command_window = Window_GameOver.new
    set_handlers
  end
  
  def set_handlers
    @command_window.set_handler(:retry, method(:command_retry))
    @command_window.set_handler(:load, method(:command_load_game))
    @command_window.set_handler(:to_title, method(:goto_title))
    @command_window.set_handler(:shutdown, method(:command_shutdown))
  end
  
  def close_command_window
    @command_window.close if @command_window
    update until @command_window.close?
  end
  
  def command_retry
    # TODO
  end
  
  def command_load_game
    SceneManager.goto(Scene_Load)
  end
  
  def command_shutdown
    SceneManager.exit
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
      super(0, 0, Regendo::GameOver_Window::COL_NUMBER)
      @horz = true
    else
      super(0, 0)
      @horz = false
    end
    update_placement
    self.openness = 0
    open
  end
  
  def window_width
    return super if @horz
    return Graphics.width * 0.4
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
  
end

module BattleManager
  
  class << self
    alias_method :setup_old, :setup
  end
  
  def self.setup(troop_id, can_escape = true, can_lose = false)
    setup_old(troop_id, can_escape, can_lose)
    @regendo_gameover_values = Hash.new
    @regendo_gameover_values[:troop_id] = troop_id
  end
  
end
