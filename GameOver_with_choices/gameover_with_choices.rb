#=================================================
# by bStefan aka. regendo
# please give credit if used
# for use with RMVX ACE
#=================================================
# GameOver with choices
#=================================================
# adds four choices to Scene_Gameover:
# : Retry Battle (if you lost the battle)
# : Load Savegame (if there is a savefile)
# : Return to Title
# : Quit Game
#=================================================
# implement over Main
# implement under Multiple_Cols_in_Command_Window
#  if existant
#=================================================

module Regendo
  
  unless @scripts
    @scripts = Hash.new
    def self.contains?(key)
      @scripts[key] == true
    end
  end
  @scripts["GameOver_Window"] = true
  
  module GameOver_Window
    def self.multiple_cols?
      return false unless Regendo.contains?("Horizontal_Command")
      USE_MULTIPLE_COLUMNS
    end
    #=======
    #CONFIG
    #=======
	
    RETRY = true #if false, Retry Battle function will not be aviable
  
    REGAIN = false # if true, Retry Battle will make the party regain any
                   #  items, weapons, or armours lost in that battle.
    
    #==============================================
    #requires Horizontal_Command script by regendo
    #==============================================
    if Regendo.contains?("Horizontal_Command")
       USE_MULTIPLE_COLUMNS = true #use Horizontal_Command Script?
       COLUMNS = 2 #requires  ^ set to true
    end
     
    #=================================================
    #only used if not using Horizontal_Command Script
    #=================================================
      WINDOW_WIDTH = 225
  end
end

if Regendo::GameOver_Window.multiple_cols?
  class Window_GameOver < Window_HorizontalCommand #more than one column possible
  end
else
  class Window_GameOver < Window_Command #only one column
  end
end

class Window_GameOver
	def initialize
		if Regendo::GameOver_Window.multiple_cols?
          if Regendo::GameOver_Window::COLUMNS
		    super(0, 0, Regendo::GameOver_Window::COLUMNS)
		  else
		    super(0, 0)
		  end
        else
          super(0, 0)
        end
		update_placement
		self.openness = 0
		open
	end
	
  unless Regendo::GameOver_Window.multiple_cols?
    def window_width
        Regendo::GameOver_Window::WINDOW_WIDTH
    end
  end
  
	def update_placement
		self.x = (Graphics.width - width) / 2
		self.y = (Graphics.height - height) / 1.1
	end
	
	#======================================
	# add your own to this list
	# also requires changes at
	# Scene_Gameover#create_command_window
	#======================================
	def make_command_list
        add_command("Retry Battle", :tryagain) if SceneManager.scene.is_defeat?
		add_command("Load Savestate", :load, load_enabled)
		add_command(Vocab::to_title, :to_title)
		add_command(Vocab::shutdown, :shutdown)
	end
	
	def load_enabled
		DataManager.save_file_exists?
	end
end

class Scene_Gameover < Scene_Base
    attr_reader :command_window
	alias start_old start
	def start
		start_old
		create_command_window
	end
	
	def pre_terminate
		super
		close_command_window
	end
	
	def update
		super
	end
	
	#======================================
	# add your own to this list
	# also requires changes at
	# Window_GameOver#make_command_list
	# and requires adding your own methods
	#======================================
	
	def create_command_window
		@command_window = Window_GameOver.new
        @command_window.set_handler(:tryagain, method(:command_retry)) if is_defeat?
		@command_window.set_handler(:load, method(:command_load))
		@command_window.set_handler(:to_title, method(:goto_title))
		@command_window.set_handler(:shutdown, method(:command_shutdown))
	end
	
	def close_command_window
		@command_window.close if @command_window
		update until @command_window.close?
	end
	
	def command_load
		close_command_window
		fadeout_all
		SceneManager.call(Scene_Load)
	end
	
	def goto_title
		close_command_window
		fadeout_all
		SceneManager.goto(Scene_Title)
	end
	
	def command_shutdown
		close_command_window
		fadeout_all
		SceneManager.exit
	end
  
  def command_retry
	  close_command_window
    fadeout_all
    regain_stuff if regain_stuff?
    SceneManager.goto(Scene_Battle)
    BattleManager.setup(@troop_id, @can_escape, @can_lose)
    $game_party.members.each do |actor|
      actor.recover_all
    end
    BattleManager.bmgs_by_regendo(@map_bgm, @map_bgs)
    BattleManager.play_battle_bgm
    Sound.play_battle_start
  end
  
  def is_defeat (b = true)
    @defeat = b
  end
  
  def is_defeat?
    Regendo::GameOver_Window::RETRY ? @defeat : false
  end
  
  def regain_stuff
    $game_party.regendo_set_items(@items)
    $game_party.regendo_set_weapons(@weapons)
    $game_party.regendo_set_armours(@armours)
  end
  
  def regain_stuff?
    Regendo::GameOver_Window::RETRY ? Regendo::GameOver_Window::REGAIN : false
  end
  
  def battle_setup (regendo_new_values, can_escape = true, can_lose = false)
    @troop_id = regendo_new_values[:troop_id]
    @items = regendo_new_values[:items]
    @weapons = regendo_new_values[:weapons]
    @armours = regendo_new_values[:armours]
    @can_escape = can_escape
    @can_lose = can_lose
  end
  
  def bgms_setup(map_bgm, map_bgs)
    @map_bgm = map_bgm
    @map_bgs = map_bgs
  end
end

module BattleManager
  class << self
    alias_method :setup_old, :setup
  end
  def self.setup(troop_id, can_escape = true, can_lose = false)
    self.setup_old(troop_id, can_escape, can_lose)
    @regendo_new_values = {}
    @regendo_new_values[:troop_id] = troop_id
    @regendo_new_values[:items] = $game_party.regendo_copy_items
    @regendo_new_values[:weapons] = $game_party.regendo_copy_weapons
    @regendo_new_values[:armours] = $game_party.regendo_copy_armours
  end
  
  def self.bmgs_by_regendo(map_bgm, map_bgs)
    @map_bgm = map_bgm
    @map_bgs = map_bgs
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
      SceneManager.scene.is_defeat
      SceneManager.scene.battle_setup(@regendo_new_values, @can_escape, @can_lose) #this also
      SceneManager.scene.bgms_setup(@map_bgm, @map_bgs)
    end
    battle_end(2)
    return true
  end
end

class Game_Party < Game_Unit
  
  def regendo_copy_items; Marshal.load(Marshal.dump(@items)); end
  def regendo_copy_weapons; Marshal.load(Marshal.dump(@weapons)); end
  def regendo_copy_armours; Marshal.load(Marshal.dump(@armors)); end
  def regendo_copy_armors; Marshal.load(Marshal.dump(@armors)); end
    
  def regendo_set_items(new_items); @items = new_items; end
  def regendo_set_weapons(new_weapons); @weapons = new_weapons; end
  def regendo_set_armours(new_armours); @armors = new_armours; end
  def regendo_set_armors(new_armors); @armors = new_armors; end
  
end