#==========================================
# Multiple Cols Command Window
#==========================================
# by bStefan aka. regendo
# requested by monstrumgod
# : http://www.rpgmakervxace.net/index.php?/user/313-monstrumgod/
# please give credit if used
#==========================================
# C&P this as a new script above Main
#==========================================


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
    def self.spacing
      32
    end
    
    def self.standard_padding
      12
    end
    
    def self.standard_cols
      2
    end
  end
end
  #==============
  # Script
  #==============
class Window_HorizontalCommand < Window_Command  
  def initialize(x = 0, y = 0, cols = standard_cols, width = "fitting")
    col_max(cols)
    @list = []
    make_command_list
    width == "fitting" ? window_width(fitting_width) : window_width(width)
    clear_command_list
    super(x, y)
  end
  # the value is only so that window_width can be called without specifying
  # : width. Changing the standard value from 255 to something else, unless
  # : it's a method, will not actually change the result.
  def window_width(width = 255)
    @width ? @width : @width = width
    @width > Graphics.width ? @width = Graphics.width : @width
  end
  
  def col_max(cols = standard_cols)
    @cols ? @cols : @cols = cols
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
    Regendo::Horizontal_Command::spacing
  end
  def standard_padding
    Regendo::Horizontal_Command::standard_padding
  end
  def standard_cols
    Regendo::Horizontal_Command::standard_cols
  end
  
end