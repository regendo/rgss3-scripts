#=========================
# GameOver:Retry_Battle (GORB)
#--------------------------------
# for RMVXAce
#=========================
# brought to you by
# regendo, aka. bStefan
#--------------------------------
# up-to-date versions of this script are exclusively available at
###########################################################################################
# < insert RMVXAce.net script topic here >                                                   #####################################
###########################################################################################
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
    
    # allows a lost battle to be retried
    # retry only works when "continue even if lose" is not checked
    # set by script call: Regendo::GORB::ALLOW_RETRY = true/false
    ALLOW_RETRY = true
    
  end
  
end

if Regendo.contains?(:GOWC) # no changes unless the required GOWC script is installed



else # if GOWC isn't installed
  # displays an informative error message
  msgbox "Your project uses regendo's GameOver:Retry_Battle script." +
  "\nThis script requires GameOver_With_Choices v3.0 or later to work." +
  "\nIt has been noticed that this condition is not met." +
  "\nYou can get the script on github.com/regendo/rgss3-scripts" +
  "\nThis script will be disabled in the meanwhile to prevent crashes."
end
