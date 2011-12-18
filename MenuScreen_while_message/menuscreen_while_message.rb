#===================================
# by bStefan aka. regendo
# by request from AABattery
# : http://www.rpgmakervxace.net/index.php?/user/608-aabattery/
# please give credit if used
# for use with RMVX ACE
#===================================
# Call Scene_Menu while a message
# : is being displayed
#===================================
# implement over Main
#===================================
# customize:
# : add Scenes you don't want the
# : script to happen to NOCALLMENU
# : (like Scene_Battle, which would
# : be really annoying)
#===================================

class Window_Message < Window_Base
  NOCALLMENU = [Scene_Battle] #scenes in which call_menu shall not work.
  
  alias update_old update
  def update
    update_old
    call_menu if Input.trigger?(:B) && !forbidden_scene_by_regendo
  end
  
  def call_menu
    Sound.play_ok
    SceneManager.call(Scene_Menu)
    Window_MenuCommand::init_command_position
  end
  
  def input_pause
    self.pause = true
    wait(10)
    Fiber.yield until Input.trigger?(:C)
    Input.update
    self.pause = false
  end
  
  def forbidden_scene_by_regendo
    if NOCALLMENU
      a = NOCALLMENU.any? do |scene|
        SceneManager.scene_is?(scene)
      end
      a
    else
      false
    end
  end
end