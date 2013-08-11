#=====================================
# by bStefan aka. regendo
# please give credit if used
# for use with RMVX ACE
#=====================================
# Skips Title screen if there is no
# save file to be found.
#=====================================
# implement over Main or directly
# into SceneManager
#=====================================

module SceneManager
	class << self
		alias :f_s_c_skips_title_screen :first_scene_class
	end
	def self.first_scene_class
		if DataManager.save_file_exists?
			f_s_c_skips_title_screen
		else
			DataManager.setup_new_game
			$game_map.autoplay
			Scene_Map
		end
	end
end