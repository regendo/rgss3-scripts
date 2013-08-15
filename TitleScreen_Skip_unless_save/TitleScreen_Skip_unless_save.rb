#=====================================
# TitleScreen Skip unless save (TSS)
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
    return f_s_c_skips_title_screen if DataManager.save_file_exists?
    DataManager.setup_new_game
    $game_map.autoplay
    Scene_Map
    end
  end
end