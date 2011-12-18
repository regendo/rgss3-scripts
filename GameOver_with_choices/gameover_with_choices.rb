# by bStefan aka. regendo
# please give credit if used
# for use with RMVX ACE

#============================================
# GameOver with choices
#============================================
# adds four choices to Scene_Gameover:
# Retry Battle (if you lost the battle)
# Load Savegame (if there is a savegame)
# Return to Title, Quit Game
#============================================
# implement over Main
#============================================

class Window_GameOver < Window_Command
	def initialize
		super(0, 0)
		update_placement
		self.openness = 0
		open
	end
	
	def window_width
		return 225
	end
	
	def update_placement
		self.x = (Graphics.width - width) / 2
		self.y = (Graphics.height - height) / 1.1
	end
	
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
    SceneManager.goto(Scene_Battle)
    BattleManager.setup(@troop_id, @can_escape, @can_lose)
    $game_party.members.each do |actor|
      actor.recover_all
    end
    $game_troop.members.each do |enemy|
      enemy.recover_all
    end
    BattleManager.bmgs_by_regendo(@map_bgm, @map_bgs)
  end
  
  def is_defeat (b = true)
    @defeat = b
  end
  
  def is_defeat?
    @defeat
  end
  
  def battle_setup (troop_id, can_escape = true, can_lose = false)
    @troop_id = troop_id
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
    self.setup_old(troop_id, can_escape = true, can_lose = false)
    @troop_id = troop_id
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
      SceneManager.scene.is_defeat #this is new
      SceneManager.scene.battle_setup(@troop_id, @can_escape, @can_lose) #this also
      SceneManager.scene.bgms_setup(@map_bgm, @map_bgs) #and this
    end
    battle_end(2)
    return true
  end
end