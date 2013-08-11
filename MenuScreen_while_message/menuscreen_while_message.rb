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

module Regendo
  
  unless @scripts
    @scripts = Hash.new
    def self.contains?(key)
      @scripts[key] == true
    end
  end
  @scripts["Menu_during_Message"] = true
  
  module Menu_during_Message
    
    #=======
    #CONFIG
    #=======
    NOCALLMENU = [Scene_Battle] #scenes in which call_menu shall not work.
    BUTTON = Input::B #which button will trigger the menu?
  end
end
  
class Window_Message < Window_Base

  BUTTON = Regendo::Menu_during_Message::BUTTON
  NOCALLMENU = Regendo::Menu_during_Message::NOCALLMENU
  
  alias update_old update
  def update
    update_old
    call_menu if Input.trigger?(BUTTON) && !forbidden_scene_by_regendo
  end
  
  def call_menu
    Sound.play_ok
    SceneManager.call(Scene_Menu)
    Window_MenuCommand::init_command_position
  end
  
  def input_pause
    self.pause = true
    wait(10)
    
    case BUTTON
    when Input::B
      Fiber.yield until Input.trigger?(:C)
    when Input::C
      Fiber.yield until Input.trigger?(:B)
    else
      Fiber.yield until Input.trigger?(:B) || Input.trigger?(:C)
    end
    
    Input.update
    self.pause = false
  end
  
  def forbidden_scene_by_regendo
    return false unless NOCALLMENU
    NOCALLMENU.any? do |scene|
      SceneManager.scene_is?(scene)
    end
  end
end