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
	def self.run
		DataManager.init
		Audio.setup_midi if use_midi?
		if DataManager.save_file_exists? == false #-
			DataManager.setup_new_game            # |
			$game_map.autoplay                    # |
			SceneManager.goto(Scene_Map)          # | new code
		else                                      # |
			@scene = first_scene_class.new        # / this line not
		end                                       #-
		@scene.main while @scene
	end
end