#================================
# Movement Speed States
#================================
# by: regendo/bStefan
# available on RPGMakerVXAce.net
# and bitbucket.org/bstefan/rgss3-for-rmvx-ace/
#================================
# for use with RPGMakerVXAce (Enterbrain)
#================================
# Terms of Use
#--------------------------------
# YOU MAY USE THE SCRIPT
# - in uncommercial projects
# -- if credit is given
# - in commercial projects
# -- if credit is given
# -- and if you asked for, and received,
#    permission from the author
#================================
# 
# HOW TO USE
#--------------------------------
# 1.: Installing the script

# This script requires that you have
# Mephistox's "NoteTag Reader" script
# installed above this script.
# You can get it here:
#  http://www.rpgmakervxace.net/topic/1301-rgss3-notetag-reader/#entry15394
# Remember to also credit Mephistox.
# 
# To install a script, paste it into a
# new entry below your Script Editor's
# "Materials" section (but above "Main Process")
# 
# 2.: Setting up the states
# 
# Choose a state (or create a new one)
# that you want to change your party's
# movement speed. Note that the movement
# speed is only affected if the party leader
# suffers from this state. Because of this,
# if you allow your user to change the party leader,
# it would be a good idea to apply all states
# that modify the movement speed to all party members.
#
# Since this state will only have an effect
# outside of battle, it would be best to
# uncheck "remove at battle end".
# Instead, "remove by walking X steps" sounds
# more useful for our purposes.
# Remember that if you don't set any requirements
# for removal, the state will be applied permanently
# until it is removed via a script or event command.
# 
# Go to the note tag section of your state.
# This is where we have two possibilities:
# 
# I Change movement speed by a fixed number
# This will increase or decrease the movement speed
# (default 4) by a fixed number, e.g. 1.
# For this method, write in your note tag in a seperate line
#   MSIncrease => 1
# And replace 1 with the number you want to increase
# the speed with. Use negative numbers for decreasing.
# You can only use integers, no floating point numbers.
# 
# II Change movement speed by a percentage
# This will modify your movement speed by a fixed multiplier.
# For this method, write in your note tag in a seperate line
#   MSModifier => 150
# And replace 150 with the percentage you want to multiply by.
# E.g., for 150% (or times 1.5) use 150,
# for 50% (or times .5) use 50.
# Since you can only enter integers, your percentages
# can not have floating point numbers.
# (this means that you can have 150% or 10%, but not 50.5%)
# 
# 3.: The End
# 
# Repeat step 2 until you're done.
# Have fun with movement speed that depends upon
# your party leader's states.
#
# Remember that you can have multiple
# states active at once, or even have one
# state give both a fixed number and a percentage modifier.
# Your overall speed will be calculated according to
# this formula:
#  speed = (usual movement speed)*(product of modifiers)+(sum of fixed numbers)
#--------------------------------
#================================

# ABSOLUTELY DO NOT MODIFY ANYTHING BELOW THIS POINT

# Setup for Mephistox's NoteTag Reader
class RPG::State
  def movement_speed_increase
    NoteReader.get_data(note, 'MSIncrease', :int)
  end
  
  def movement_speed_modifier
    NoteReader.get_data(note, 'MSModifier', :int)
  end
end

class Game_Player < Game_Character
  
  alias real_move_speed_with_state_modifiers real_move_speed
  def real_move_speed
    speed = real_move_speed_with_state_modifiers
    # modify the movement speed
    speed *= $game_party.leader.total_movement_speed_modifiers
    speed += $game_party.leader.total_movement_speed_increases
    
    return speed
  end
  
end

class Game_Actor < Game_Battler
  
  def total_movement_speed_increases
    sum = 0
    states.each do |s|
      sum += s.movement_speed_increase || 0
    end
    return sum
  end
  
  def total_movement_speed_modifiers
    mod = 1.0
    states.each do |s|
      mod *= s.movement_speed_modifier || 100
      mod /= 100
    end
    return mod
  end
  
end