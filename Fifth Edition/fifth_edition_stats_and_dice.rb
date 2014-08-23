class Game_BattlerBase
  
  attr_writer :str              # Strength
  attr_writer :dex              # Dexterity
  attr_writer :con              # Constitution
  attr_writer :int              # Intelligence
  attr_writer :wis              # Wisdom
  attr_writer :cha              # Charisma
  attr_writer :advantage        # Advantage
  attr_writer :disadvantage     # Disadvantage
  attr_writer :proficiencies    # Proficiencies
  
  #--------------------------------------------------------------------------
  # * Checks if a given value is equal to or exceeds
  #   the maximum allowed attribute score
  #--------------------------------------------------------------------------
  def max_attr?(attr)
    attr >= max_attr
  end
  
  def max_attr; 0; end # overwritten in subclasses
  
  #--------------------------------------------------------------------------
  # * Attributes
  #--------------------------------------------------------------------------
  def str; [@str, max_attr].min; end
  def dex; [@dex, max_attr].min; end
  def con; [@con, max_attr].min; end
  def int; [@int, max_attr].min; end
  def wis; [@wis, max_attr].min; end
  def cha; [@cha, max_attr].min; end
    
  #--------------------------------------------------------------------------
  # * Attribute boni
  #--------------------------------------------------------------------------
  def attr_bonus(score)
    if ((score < 10) && ((score % 2) != 0))
      (score - 11) / 2
    else
      (score - 10) / 2
    end
  end
  def bstr; attr_bonus(str); end
  def bdex; attr_bonus(dex); end
  def bcon; attr_bonus(con); end
  def bint; attr_bonus(int); end
  def bwis; attr_bonus(wis); end
  def bcha; attr_bonus(cha); end
  
  #--------------------------------------------------------------------------
  # * Proficiency
  #--------------------------------------------------------------------------
  def bprof(key)
    proficiencies[key] ? 2 : 0
  end
  
  #--------------------------------------------------------------------------
  # * Saving Throw boni
  #--------------------------------------------------------------------------
  def sbstr; bstr + bprof(:str); end
  def sbdex; bdex + bprof(:dex); end
  def sbcon; bcon + bprof(:con); end
  def sbint; bint + bprof(:int); end
  def sbwis; bwis + bprof(:wis); end
  def sbcha; bcha + bprof(:cha); end
  
  #--------------------------------------------------------------------------
  # * Saving Throws
  # * Saving Throws against a Difficulty Class (true: success)
  #--------------------------------------------------------------------------
  def ststr; r1d20 + sbstr; end
  def stdex; r1d20 + sbdex; end
  def stcon; r1d20 + sbcon; end
  def stint; r1d20 + sbint; end
  def stwis; r1d20 + sbwis; end
  def stcha; r1d20 + sbcha; end
    
  def ststr(dc); stsrt >= dc; end
  def stdex(dc); stdex >= dc; end
  def stcon(dc); stcon >= dc; end
  def stint(dc); stint >= dc; end
  def stwis(dc); stwis >= dc; end
  def stcha(dc); stcha >= dc; end
    
  #--------------------------------------------------------------------------
  # * Skill check boni
  #--------------------------------------------------------------------------
  def sbacro; bdex + bprof(:acro); end # Acrobatics       (STR)
  def sbanih; bwis + bprof(:anih); end # Animal Handling  (WIS)
  def sbarca; bint + bprof(:arca); end # Arcana           (INT)
  def sbathl; bstr + bprof(:athl); end # Athletics        (STR)
  def sbdecp; bcha + bprof(:decp); end # Deception        (CHA)
  def sbhist; bint + bprof(:hist); end # History          (INT)
  def sbinst; bwis + bprof(:inst); end # Insight          (WIS)
  def sbintm; bcha + bprof(:intm); end # Intimidation     (CHA)
  def sbinvs; bint + bprof(:invs); end # Investigation    (INT)
  def sbmedc; bwis + bprof(:medc); end # Medicine         (WIS)
  def sbnatr; bint + bprof(:natr); end # Nature           (INT)
  def sbperc; bwis + bprof(:perc); end # Perception       (WIS)
  def sbperf; bcha + bprof(:perf); end # Performance      (CHA)
  def sbpers; bcha + bprof(:pers); end # Persuasion       (CHA)
  def sbreli; bint + bprof(:reli); end # Religion         (INT)
  def sbslei; bdex + bprof(:slei); end # Sleight of Hand  (DEX)
  def sbstea; bdex + bprof(:stea); end # Stealth          (DEX)
  def sbsurv; bwis + bprof(:surv); end # Survival         (WIS)
  
  #--------------------------------------------------------------------------
  # * Skill checks
  # * Skill checks against a Difficulty Class
  #--------------------------------------------------------------------------
  %w(acro anih arca athl decp hist inst intm invs medc natr perc perf pers reli
  slei stea surv).each do |skill|
    define_method("st" + skill) { r1d20 + send("sb" + skill) }
    define_method("st" + skill) do |dc|
      send("st" + skill) >= dc
    end
  end
  
  #--------------------------------------------------------------------------
  # * Passive Perception (Wisdom)
  #--------------------------------------------------------------------------
  def stpassperc
    ret = 10 + sbperc
    ret += 5 if advantage?
    ret -= 5 if advantage?
    remove_advantage_disadvantage
  end
  
  #--------------------------------------------------------------------------
  # * Advantage and Disadvantage impact d20 rolls and passive perception checks
  # * 2d20 are rolled for each normal roll of 1d20, then the higher (advantage)
  #   or lower (disadvantage) roll is chosen. (implemented in #rolld20)
  # * Advantage and disadvantage cancel each other out
  #--------------------------------------------------------------------------
  def advantage?
    @advantage && !@disadvantage
  end
  
  def disadvantage?
    @disadvantage && !@advantage
  end
  
  def gain_advantage
    if (@advantage == false)
      @advantage = true
    elsif (@advantage >= 0)
      @advantage += 1
    end
  end
  
  def gain_disadvantage
    if (@disadvantage == false)
      @disadvantage = true
    elsif (@disadvantage >= 0)
      @disadvantage += 1
    end
  end
  
  def remove_advantage
    if (@advantage == true)
      @advantage = false
    elsif (@advantage > 0)
      @advantage -= 1
    end
  end
  
  def remove_disadvantage
    if (@disadvantage == true)
      @disadvantage = false
    elsif (@disadvantage > 0)
      @disadvantage -= 1
    end
  end
  
  def remove_advantage_disadvantage
    remove_advantage
    remove_disadvantage
  end
  
  #--------------------------------------------------------------------------
  # * creates dice methods like r1d20, r4d6, r3d8
  #   unfortunately we can't use 1d20 because that's already a thing in ruby
  # * for usage in skill formulas
  #--------------------------------------------------------------------------
  (1..10).each do |count|
    [4, 6, 8, 10, 12, 100].each do |eyes|
      define_method("r" + count.to_s + "d" + eyes.to_s) { 
        (Array.new(count) {send("rolld" + eyes.to_s)}).reduce(0, :+)
      }
    end
    define_method("r" + count.to_s + "d20") {
      ret = (Array.new(count) {rolld20}).reduce(0, :+)
      remove_advantage_disadvantage
      return ret
    }
  end
  
  #--------------------------------------------------------------------------
  # * basic dice rolling methods
  # * these are used by the above defined methods
  # * there's really no reason to use these in skill formulas
  #   just use r1d20 instead of rolld20, it's shorter anyways
  #--------------------------------------------------------------------------
  def rolld4;   1 + Random.rand(4);   end
  def rolld6;   1 + Random.rand(6);   end
  def rolld8;   1 + Random.rand(8);   end
  def rolld10;  1 + Random.rand(10);  end
  def rolld12;  1 + Random.rand(12);  end
  def rolld20
    if (advantage)
      1 + [Random.rand(20), Random.rand(20)].max
    elsif (disadvantage)
      1 + [Random.rand(20), Random.rand(20)].min
    else
      1 + Random.rand(20)
    end
  end
  def rolld100; 1 + Random.rand(100); end
  
end

class Game_Enemy < Game_Battler
  
  #--------------------------------------------------------------------------
  # * Maximum attribute score
  # * Players' attributes cannot exceed 20, Monsters' can go up to 30
  #--------------------------------------------------------------------------
  def max_attr; 30; end
  
end

class Game_Actor < Game_Battler
  
  attr_writer :inspiration
  
  #--------------------------------------------------------------------------
  # * Inspiration is supposed to be granted for roleplaying your character
  #   in situations where there would be other, more optimal ways to act
  # * For example, if a character rushes to save his hometown from the BBEG's
  #   Army of Certain Doom even though it is clear that this battle cannot be
  #   won and that it would have been a better choice to instead let the army
  #   devastate the town and attack the now defenseless BBEG's castle.
  # * Officially, a character can only have 1 point of inspiration at a time
  # * However, I have added support for both boolean (has or has no inspiration)
  #   and numerical (has 0, 1, 2, many points of inspiration) versions
  #--------------------------------------------------------------------------
  def inspiration?
    (@inspiration == true) || (@inspiration > 0)
  end
  
  def gain_inspiration
    if (@inspiration == false)
      @inspiration = true
    elsif (@inspiration >= 0)
      @inspiration += 1
    end
  end
  
  def remove_inspiration
    if (@inspiration == true)
      @inspiration = false
    elsif (@inspiration > 0)
      @inspiration -= 1
    end
  end
  
  #--------------------------------------------------------------------------
  # * use inspiration to grant advantage on the next d20 roll
  #--------------------------------------------------------------------------
  def use_inspiration
    if (inspiration? && !advantage?)
      remove_inspiration
      gain_advantage
    end
  end
  
  #--------------------------------------------------------------------------
  # * Maximum attribute score
  # * Players' attributes cannot exceed 20, Monsters' can go up to 30
  #--------------------------------------------------------------------------
  def max_attr; 20; end
  
  #--------------------------------------------------------------------------
  # * Maximum Level
  #--------------------------------------------------------------------------
  def max_level; 20; end
  
  #--------------------------------------------------------------------------
  # * Get Total EXP Required for Rising to Specified Level
  #--------------------------------------------------------------------------
  def exp_for_level(level)
    case level
    when  1 then      0
    when  2 then    300
    when  3 then    900
    when  4 then   2700
    when  5 then   6500
    when  6 then  14000
    when  7 then  23000
    when  8 then  34000
    when  9 then  48000
    when 10 then  64000
    when 11 then  85000
    when 12 then 100000
    when 13 then 120000
    when 14 then 140000
    when 15 then 165000
    when 16 then 195000
    when 17 then 225000
    when 18 then 265000
    when 19 then 305000
    when 20 then 355000
    else self.class.exp_for_level(level) # this should never happen
    end
  end
  
  #--------------------------------------------------------------------------
  # * Proficiency Bonus
  #   your proficiency bonus gets added to all skill checks and saving thows
  #   if you are proficient with the skill or saving throw
  #--------------------------------------------------------------------------
  def prof
    case level
    when 1..4   then 2
    when 5..8   then 3
    when 9..12  then 4
    when 13..16 then 5
    when 17..20 then 6
    else 0
    end
  end
  
  
end