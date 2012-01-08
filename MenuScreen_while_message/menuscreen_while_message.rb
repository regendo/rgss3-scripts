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
  end
end
  
class Window_Message < Window_Base
  NOCALLMENU = Regendo::Menu_during_Message::NOCALLMENU
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