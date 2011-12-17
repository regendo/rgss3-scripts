# by bStefan aka. regendo
# please give credit if used
# for use with RMVX ACE

#============================================
# GameOver with choices
#============================================
# adds three choices to Scene_Gameover:
# Load Savegame, Return to Title, Quit Game
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
end