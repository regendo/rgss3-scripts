#==========================================
# Multiple Cols In Selectable (MCIS)
#==========================================
# by bStefan aka. regendo
# requested by monstrumgod
# : http://www.rpgmakervxace.net/index.php?/user/313-monstrumgod/
# please give credit if used
#==========================================
# C&P this as a new script above Main
#==========================================

#============================================================
#                         HOW TO USE
#============================================================
# 1. make a new window class
#   class Window_Something < Window_HorizontalCommand
# 2. add commands to Window_Something#make_command_list
#   add_command("Displayed_Name", :symbol, condition)
# example:
#   add_command("Give Item", :give, $game_variables[0] > 5)
# 3. make a scene use this window
#   @command_window = Window_Something.new
#   @command_window.set_handler(:give, method(:give_item))
# 4. define that method
#   def give_item
#     #code
#   end
# 5. Enjoy
#============================================================


module Regendo
  
  unless @scripts
    @scripts = Hash.new
    def self.contains?(key)
      @scripts[key] == true
    end
  end
  @scripts["Horizontal_Command"] = true
  
  module Horizontal_Command
    #==============
    # CONFIG
    #==============
	
	#spacing in pixels
    SPACING = 32
    
	#padding in pixels
    PADDING = 12
    
	#number of columns if no number is given upon calling intialize	
    COLS = 2
  end
end
  #==============
  # Script
  #==============
class Window_HorizontalCommand < Window_Command  
  def initialize(x = 0, y = 0, cols = standard_cols, width = :fitting)
    col_max(cols)
    @list = []
    make_command_list
    window_width(width == :fitting ? fitting_width : width)
    clear_command_list
    super(x, y)
  end
  # the value is only so that window_width can be called without specifying
  # : width. Changing the standard value from 255 to something else, unless
  # : it's a method, will not actually change the result.
  def window_width(width = 255)
    @width ||= [Graphics.width, width].min
  end
  
  def col_max(cols = standard_cols)
    @cols ||= cols
  end
  
  def visible_line_number
    row_max
  end
  
  def fitting_width
    (item_width + spacing) * col_max - spacing + standard_padding * 2
  end
  
 def item_width
  bmp = Bitmap.new(1,1)
  length = []
  @list.each do |index|
   length.push((bmp.text_size(index[:name])).width)
  end
  if @width
   if length.max > (@width - standard_padding * 2 + spacing) / col_max - spacing
      (@width - standard_padding * 2 + spacing) / col_max - spacing
   else
      length.max
   end
  else
   length.max
  end
 end
  
  def spacing
    Regendo::Horizontal_Command::SPACING
  end
  
  def standard_padding
    Regendo::Horizontal_Command::PADDING
  end
  
  def standard_cols
    Regendo::Horizontal_Command::COLS
  end
  
end