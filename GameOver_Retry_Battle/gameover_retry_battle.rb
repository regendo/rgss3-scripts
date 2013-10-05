#=========================
# GameOver:Retry_Battle (GORB)
#--------------------------------
# for RMVXAce
#=========================
# brought to you by
# regendo, aka. bStefan
#--------------------------------
# up-to-date versions of this script are exclusively available at
# TODO
# and https://github.com/regendo/rgss3-scripts
#=========================

# The Terms of Use specified in the README.md file in the github repository apply to this script.

# This script requires GameOver_with_Choices (GOWC) also by regendo.
# You can easily find it in above github repository.
# This script needs to be placed between GOWC and Main in the script explorer.


# This script is Paste & Play compatible. You can use this script without modifying anything.
# However, looking at the customisation options is strongly recommended.


#=========================
# CHANGELOG
#=========================
# current release: 1.0-gorb pre
# current release notes:
# # new features:
# # # split from GOWC, this now is a seperate script
# # # hp, mp, states can be reset upon battle retry
# # bugfixes:
# # # BattleManager's @regendo_gameover_values now gets disposed after battle
# # not working as intended:
# # missing features:
# # # player does not get notified about losing gold/items
# # # reset tp
#--------------------------------
# 1.0   - initial release; split from GOWC; regain hp/mp/states
#--------------------------------

# above update notes do not include minor updates such as bug fixes

# GOWC changelog relevant to this script:
#--------------------------------
# 3.0   - game-over retry functionality has been made a separate script, GameOver:Retry_Battle (GORB)
# 2.1   - now has a chance to lose gold, items, armour parts, weapons upon retrying battles
# 2.0   - complete rewrite
# 1.3   - now able to regain items, weapons, armours when retrying battles
# 1.2   - now compatible with "Multiple Columns in selectable windows" script by regendo
# 1.1   - now able to retry lost battles
#========================

#========================
# Compability check:
#-------------------------------
#========================


module Regendo
  
  unless @scripts
    @scripts = Hash.new
    def self.contains?(key)
      @scripts[key] == true
    end
  end
  @scripts[:GORB] = true
  
  module GORB
    
    # CUSTOMISATION OPTIONS
    RETRY_TEXT = "Retry Battle!"
    
    # allows you to lock the retry option away for certain time periods
    # the retry option will not be displayed if locked
    RETRY_UNLOCKED = true
    
  end # module GORB
  
end # module Regendo

if Regendo.contains?(:GOWC) # no changes unless the required GOWC script is installed

class Window_GameOver
  
  alias :add_gorb_first :add_commands_first
  def add_commands_first
    add_command(:retry_text, :retry, can_retry?) if retry_unlocked?
    add_gorb_first
  end
  
  def retry_text
    Regendo::GORB::RETRY_TEXT
  end
  
  def retry_unlocked?
    SceneManager.scene.retry_unlocked?
  end
  
  def can_retry?
    SceneManager.scene.can_retry?
  end
  
end # Window_GameOver

class Scene_Gameover < Scene_Base

  alias :start_regendo_gorb :start
  def start
    @retry_possible = false
    start_regendo_gorb
  end

  alias :set_gorb_first :set_handlers_first
  def set_handlers_first
    @command_window.set_handler(:retry, method(:command_retry)) if retry_unlocked?
    set_gorb_first
  end
  
  # decides if the retry option will be displayed
  def retry_unlocked?
    return false unless Regendo::GORB::RETRY_UNLOCKED
    return @retry_possible # only true if the game over resulted from a lost battle
  end
  
  # decides if the retry option will be selectable
  def can_retry?
    return true
  end
  
  # is called if a battle was lost
  def set_retry(gorb_values)
    @retry_possible = true
    @gorb_values = gorb_values
  end
  
  def command_retry
    # TODO
  end
  
end # Scene_Gameover

module BattleManager
  
  class << self
    alias_method :battle_end_gorb, :battle_end
    alias_method :gorb_post_transfer, :gowc_post_transfer
    alias_method :gorb_post_setup, :gowc_post_setup
  end
  
  def self.battle_end(result)
    @gorb_values = nil
    battle_end_gorb(result)
  end
  
  def self.gowc_post_transfer
    init_gorb_items
    @gorb_values[:bgm] = @map_bgm
    @gorb_values[:bgs] = @map_bgs
    SceneManager.scene.set_retry(@gorb_values)
    gorb_post_transfer
  end
  
  def self.gowc_post_setup
    init_gorb_values
    gorb_post_setup
  end
  
  def self.regendo_gorb_setup(gorb_values)
    @gorb_values = gorb_values
    @gorb_values[:is_retry] = true
    @gorb_values[:times_retried] += 1
    troop_id = @gorb_values[:troop_id]
    can_escape = @gorb_values[:can_escape]
    can_lose = @gorb_values[:can_lose]
    gorb_setup_items
    setup(troop_id, can_escape, can_lose)
    @map_bgm = @gorb_values[:bgm]
    @map_bgs = @gorb_values[:bgs]
  end
  
  def self.gorb_setup_items
    $game_party.gorb_set_items(@gorb_values[:items]) if Regendo::GORB::REGAIN_ITEMS
    $game_party.gorb_set_weapons(@gorb_values[:weapons]) if Regendo::GORB::REGAIN_ITEMS
    $game_party.gorb_set_armours(@gorb_values[:armours]) if Regendo::GORB::REGAIN_ARMOURS
  end
  
  def self.init_gorb_values
    return if @gorb_values
    @gorb_values = {
      :troop_id => $game_troop.troop.troop_id,
      :can_escape => @can_escape,
      :can_lose => @can_lose,
      :is_retry => false,
      :times_retried => 0,
    }
    init_gorb_party_values
    init_additional_gorb_values
  end
  
  def self.init_gorb_items
    @gorb_values[:items] = Marshal.load(Marshal.dump($game_party.gorb_get_items))
    @gorb_values[:weapons] = Marshal.load(Marshal.dump($game_party.gorb_get_weapons))
    @gorb_values[:armours] = Marshal.load(Marshal.dump($game_party.gorb_get_armours))
  end
  
  def self.init_gorb_party_values
    v = @gorb_values[:party] = []
    $game_party.members.each_with_index do |member, index|
      v[index] = {
        :hp => Marshal.load(Marshal.dump(member.hp))
        :mp => Marshal.load(Marshal.dump(member.mp))
        :states => []
        :state_turns => Marshal.load(Marshal.dump(member.state_turns))
        :state_steps => Marshal.load(Marshal.dump(member.state_steps))
      }
      member.states.each do |state|
        v[index][:states].push(state.id)
      end # members.states.each
    end # $game_party.members.each_with_index
  end
  
  def self.init_additional_gorb_values; end
  
end # module BattleManager

class Game_Party < Game_Unit
  
  def gorb_get_items; return @items; end
  def gorb_get_weapons; return @weapons; end
  def gorb_get_armours; return @armors; end
  
  def gorb_set_items(items); @items = items; end
  def gorb_set_weapons(weapons); @weapons = weapons; end
  def gorb_set_armours(armours); @armors = armours; end
  
end

class Game_BattlerBase
  attr_accessor :state_turns
  attr_accessor :state_steps
end # class Game_BattlerBase

else # if GOWC isn't installed
  # displays an informative error message
  msgbox "Your project uses regendo's GameOver:Retry_Battle script." +
  "\nThis script requires GameOver_With_Choices v3.0 or later to work." +
  "\nIt has been noticed that this condition is not met." +
  "\nYou can easily get the script at github.com/regendo/rgss3-scripts" +
  "\nGO:RB has been disabled in the meanwhile to prevent crashes."
end
